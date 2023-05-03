version 1.0

task cdip_report {
  input {
    Array[String] samplename
    Array[String] fastani_genus_species
    Array[String] amrfinderplus_amr_genes
    Array[String] amrfinderplus_stress_genes
    Array[String] amrfinderplus_virulence_genes
    Array[String] abricate_amr_genes
    Array[String] abricate_virulence_genes
    Array[String?] dt_beta
    Array[String?] dt_omega
    Array[String] ts_mlst_predicted_st
    Array[File] ts_mlst_results
    File tree
    Array[File?] clade_iqtree_core_tree
    Array[File?] clade_iqtree_pan_tree
    Array[File?] pirate_for_scoary_csv
    String cluster_name
    String docker = "hnh0303/seq_report_generator"
    Int threads = 6
    Int snp_clade
  }
  command <<<
    # date and version control
    date | tee DATE
    python3<<CODE

    from fpdf import FPDF
    from PyPDF2 import PdfFileReader, PdfReader, PdfFileWriter
    import numpy as np
    import pandas as pd
    from Bio import Phylo
    import matplotlib.pyplot as plt
    from pathlib import Path
    import sys
    sys.path.append('/epi_reports')
    from seq_report_generator import add_dendrogram_as_pdf, add_page_header, add_section_header, add_paragraph, add_table, combine_similar_columns, create_dt_col, create_dummy_data, join_pdfs, remove_nan_from_list, unique, new_pdf

    #df = pd.read_csv("king_county_cdip_2018_2.tsv", sep="\t")
    df = np.array([~{samplename},
       ~{fastani_genus_species},
       ~{amrfinderplus_amr_genes},
       ~{amrfinderplus_stress_genes},
       ~{amrfinderplus_virulence_genes},
       ~{abricate_amr_genes},
       ~{abricate_virulence_genes},
       ~{dt_beta},
       ~{dt_omega},
       ~{ts_mlst_predicted_st}]).transpose()
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