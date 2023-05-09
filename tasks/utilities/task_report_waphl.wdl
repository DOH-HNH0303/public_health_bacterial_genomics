version 1.0

task cdip_report {
  input {
    Array[File?] assembly_tsvs
    Array[File?] mlst_tsvs
    File tree
    Array[File?] clade_trees
    Array[File?] phylo_zip
    String cluster_name
    String docker = "hnh0303/seq_report_generator"
    Int threads = 6
    Int snp_clade
  }
  command <<<
    # date and version control
    date | tee DATE
    if [ -z ~{phylo_zip} ]; then
    for x in ~{sep=' ' phylo_zip}
    do
        tar xzf "${x}" --one-top-level=$(basename "${x}" | cut -d. -f1)_phylo
    done;
    fi

    if [ -z ~{mlst_tsvs} ]; then
    mkdir mlst_tsvs 
    for x in ~{sep=' ' mlst_tsvs}
    do
        mv "${x}" mlst_tsvs
    done;
    fi

    if [ -z ~{assembly_tsvs} ]; then
    mkdir assembly_tsvs 
    for x in ~{sep=' ' assembly_tsvs}
    do
        mv "${x}" assembly_tsvs
    done;
    fi

    if [ -z ~{clade_trees} ]; then
    mkdir clade_trees
    for x in ~{sep=' ' clade_trees}
    do
        mv "${x}" clade_trees
    done;
    fi

    ls
    echo""
    ls assembly_tsvs
    echo ""
    
     
    python3<<CODE

    from fpdf import FPDF
    from PyPDF2 import PdfFileReader, PdfReader, PdfFileWriter
    import numpy as np
    import pandas as pd
    from Bio import Phylo
    import matplotlib.pyplot as plt
    from pathlib import Path
    import sys
    import os
    sys.path.append('/epi_reports')
    from seq_report_generator import add_dendrogram_as_pdf, add_page_header, add_section_header, add_paragraph, add_table, combine_similar_columns, create_dt_col, create_dummy_data, join_pdfs, remove_nan_from_list, unique, new_pdf

    #df = pd.read_csv("king_county_cdip_2018_2.tsv", sep="\t")
    for subdir, dirs, files in os.walk('.'):
    for file in files:
        print(os.path.join(subdir, file))
        if subdir == "assembly_tsvs":
          if not df_assembly:
            df_assembly = pd.read_csv(os.path.join(subdir, file), sep="\t")
          else:
            df_hold = pd.read_csv(os.path.join(subdir, file), sep="\t")
            df_assembly = pd.concat( [df, df_hold],axis=1,ignore_index=True) 

    df = pd.DataFrame(df, columns=["Seq ID",
       "Species ID",
       "amrfinder_amr",
       "amrfinder_stress",
       "amrfinderplus_virulence",
       "abricate_amr",
       "abricate_virulence",
       "dt_beta",
       "dt_omega",
       "ST Type"])
    #df.rename(columns={df.columns[0]: 'Seq ID', "ts_mlst_predicted_st": 'ST Type', "fastani_genus_species": "Species ID"},inplace=True)

    #df_amr = df[['Seq ID', 'abricate_amr_genes', 'amrfinderplus_amr_genes',]]
    #df_vir = df[['Seq ID', 'abricate_virulence_genes', 'amrfinderplus_virulence_genes']]

    amr_col = combine_similar_columns(df, ['abricate_amr_genes', 'amrfinderplus_amr_genes'])
    vir_col = combine_similar_columns(df,['abricate_virulence_genes', 'amrfinderplus_virulence_genes'] )

    df['AMR Genes'] = amr_col
    df['Virulence Genes'] = vir_col

    df = create_dummy_data(df, "Submitter", "Lorem ipsum")
    df = create_dummy_data(df, "Collection Date", "01.01.1000")
    df = create_dt_col(df)

    df_genes = df[['Seq ID', 'Collection Date', 'Submitter', 'Species ID', 'ST Type', 'AMR Genes', 'Virulence Genes', "DT"]]
    data = df_genes.copy()
    pdf_report = new_pdf()
    add_page_header(pdf_report, "Corynebacterium Sequencing Report")
    add_paragraph(pdf_report, text = "Are you going to want general outbreak info here? You have the option to pass me a text file to add here as a description")
    add_table(pdf_report, df_genes)
    pdf_report.output(~{cluster_name}+'_report.pdf', 'F')
    add_dendrogram_as_pdf(pdf_report, "tree")

    CODE
  >>>
  output {
    String date = read_string("DATE")
    File clade_list_file = "~{cluster_name}_output.txt"
    Array[Array[String]] clade_list = read_tsv("~{cluster_name}_output.txt")
    String split_clade_docker_image = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task plot_roary_waphl {
  input {
    String cluster_name
    File? output_tar
    File? treefile
    File? recomb_gff
    File? pirate_aln_gff
    File? pirate_for_scoary_csv
    String docker = "hnh0303/plot_roary_waphl:1.0"
    Int threads = 6
  }
  command <<<
    # date and version control
    # This task takes either a zipped input file or individual input files
    date | tee DATE
    if [ -z ~{output_tar} ]; then
    tar xzf ~{output_tar}
    if ls **recombination_predictions.gff; then
    python ../roary_plots_waphl.py \
    --recombinants *recombination_predictions.gff \
    *tree* \
    *scoary* \
    *alignment.gff
    else
    python ../roary_plots_waphl.py \
    *tree* \
    *scoary* \
    *alignment.gff
    fi
    else
    python ../roary_plots_waphl.py \
    ~{'--recombinants' + recomb_gff} \
    ~{treefile} \
    ~{pirate_for_scoary_csv} \
    ~{pirate_aln_gff}

    fi

    if [ ! -f none.tree ]; then   
    mv pangenome_matrix.png ~{cluster_name}_matrix.png
    fi

  >>>
  output {
    String date = read_string("DATE")
    File? plot_roary_png = "~{cluster_name}_matrix.png"
    String plot_roary_docker_image = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task save_output {
  input {
    String cluster_name
    File treefile
    File? recomb_gff
    File pirate_aln_gff
    File pirate_for_scoary_csv
    String cluster_name
    String docker = "hnh0303/plot_roary_waphl:1.0"
    Int threads = 6
    Int? snp_clade
  }
  command <<<
    # date and version control
    date | tee DATE

    python ../roary_plots_waphl.py \
    ~{'--recombinants' + recomb_gff} \
    ~{treefile} \
    ~{pirate_for_scoary_csv} \
    ~{pirate_aln_gff}

   
    mv pangenome_matrix.png ~{cluster_name}~{"_" + snp_clade}_matrix.png

  >>>
  output {
    String date = read_string("DATE")
    File plot_roary_png = select_first(["~{cluster_name}_matrix.png", "~{cluster_name}_~{snp_clade}_matrix.png"])
    String plot_roary_docker_image = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 2
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}