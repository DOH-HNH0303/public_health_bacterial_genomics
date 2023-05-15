version 1.0

task cdip_report {
  input {
    File assembly_tsv
    Array[File] mlst_tsvs
    File tree
    Array[File]? clade_trees
    Array[File]? phylo_zip
    Array[File]? plot_roary
    File treefile
    String cluster_name
    String docker = "hnh0303/seq_report_generator:1.0"
    Int threads = 6 
  }
  command <<<
    # date and version control
    date | tee DATE
    if [ -z ~{sep=' ' phylo_zip} ]; then
    for x in ~{sep=' ' phylo_zip}
    do  
        echo "test0"
        tar xzf "${x}" --one-top-level=$(basename "${x}" | cut -d. -f1)_phylo
    done;
    fi

    if [ -z ~{sep=' ' mlst_tsvs} ]; then
    mkdir mlst_tsvs 
    for x in ~{sep=' ' mlst_tsvs}
    do
        mv "${x}" mlst_tsvs
    done;
    fi

    if [ -z ~{sep=' ' clade_trees} ]; then
    mkdir clade_trees
    for x in ~{sep=' ' clade_trees}
    do
        mv "${x}" clade_trees
    done;
    fi

    echo "test1"
    mv ~{assembly_tsv} assembly.tsv
    mv ~{treefile} file.tree
    echo "test2"
    mkdir roary
    for x in ~{sep=' ' plot_roary}
    do
        echo "${x}"
        mv "${x}" plot_roary
    done;
    python3<<CODE

    from fpdf import FPDF
    from PyPDF2 import PdfFileReader, PdfReader, PdfWriter
    import numpy as np
    import pandas as pd
    from Bio import Phylo
    import matplotlib.pyplot as plt
    from pathlib import Path
    import sys
    import os
    sys.path.append('/epi_reports')
    from seq_report_generator import add_dendrogram_as_pdf, add_page_header, add_section_header, add_paragraph, add_table, combine_similar_columns, create_dt_col, create_dummy_data, join_pdfs, remove_nan_from_list, unique, new_pdf


    df = pd.read_csv("assembly.tsv", sep="\t")
    df = df[df['assembly_fasta'].notna()]
    df.rename(columns={df.columns[0]: 'Seq ID', "ts_mlst_predicted_st": 'ST Type', "fastani_genus_species": "Species ID"},inplace=True)
    df = create_dt_col(df)
    print("Here 1")
    amr_col = combine_similar_columns(df, ['abricate_amr_genes', 'amrfinderplus_amr_genes'])
    vir_col = combine_similar_columns(df,['abricate_virulence_genes', 'amrfinderplus_virulence_genes'] )
    print("Here2")
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
    pdf_report.output("~{cluster_name}"+'_temp_report.pdf', 'F')
    add_dendrogram_as_pdf(pdf_report, tree_file="file.tree", output_filename="~{cluster_name}_tree.pdf")
    plots = new_pdf()
    print("")
    for subdir, dirs, files in os.walk('.'):
      for file in files:
        print(os.path.join(subdir, file))
        if subdir == "plot_roary":
          print("plot_roary")
          add_image(plots, os.path.join(subdir, file))
    
    plots.output("~{cluster_name}"+'_plots.pdf', 'F')
    join_pdfs(["~{cluster_name}_temp_report.pdf", "~{cluster_name}_tree.pdf", "~{cluster_name}_plots.pdf"], "~{cluster_name}_report.pdf")

    CODE
  >>>
  output {
    String date = read_string("DATE")
    File report = "~{cluster_name}_report.pdf"
    
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
    if ls *recombination_predictions.gff; then
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
    continueOnReturnCode: "True"
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