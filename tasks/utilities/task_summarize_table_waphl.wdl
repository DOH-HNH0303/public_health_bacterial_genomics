version 1.0

task summarize_string_data {
  input {
    Array[String]? sample_names
    String? terra_project
    String? terra_workspace
    String? terra_table
    Int disk_size = 100
  }
  command <<<   
    # when running on terra, comment out all input_table mentions
    python3 /scripts/export_large_tsv/export_large_tsv.py --project "~{terra_project}" --workspace "~{terra_workspace}" --entity_type ~{terra_table} --tsv_filename ~{terra_table}-data.tsv 
    
  >>>
  output {
    File summarized_data = "~{terra_table}-data.tsv"
  }
  runtime {
    docker: "broadinstitute/terra-tools:tqdm"
    memory: "8 GB"
    cpu: 1
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
}

task zip_files {
  input {
    Array[File]? clade_trees
    Array[File]? recomb_gff
    Array[File]? pirate_aln_gff
    Array[File]? pirate_gene_presence_absence
    String cluster_name
    String? cluster_tree
    Int disk_size = 100
  }
  command <<<   
    # when running on terra, comment out all input_table mentions
    ls
    mkdir ~{cluster_name}
    mv ~{sep=' ' clade_trees} ~{cluster_name}
    mv ~{sep=' ' recomb_gff} ~{cluster_name}
    mv ~{sep=' ' pirate_aln_gff} ~{cluster_name}
    mv ~{sep=' ' pirate_gene_presence_absence} ~{cluster_name}
    mv ~{cluster_tree} ~{cluster_name}

    cd ~{cluster_name}
    tar -cvzf ~{cluster_name}-archive.tar.gz *
    mv ~{cluster_name}-archive.tar.gz ../
    
  >>>
  output {
    File zipped_output = "~{cluster_name}-archive.tar"
  }
  runtime {
    docker: "broadinstitute/terra-tools:tqdm"
    memory: "8 GB"
    cpu: 1
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
}