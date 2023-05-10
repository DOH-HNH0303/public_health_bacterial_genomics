version 1.0

import "../tasks/utilities/task_summarize_table_waphl.wdl" as summarize
import "../tasks/utilities/task_report_waphl.wdl" as report

workflow waphl_report {

  input {
    String cluster_name

    File treefile
    Array[File?] roary_plot
    Array[File?] output_tars
    Array[File] mlst_tsvs
    String terra_table
    String terra_workspace
    String terra_project
    String organism="corynebacterium"
  }
  call summarize.summarize_string_data as summarize_strings  {
  input:
    terra_table = terra_table,
    terra_workspace = terra_workspace,
    terra_project = terra_project
    
}
  if (defined(output_tars)) {
  scatter (output_tar in output_tars) {
  call report.plot_roary_waphl as plot_roary{
    input:
      cluster_name=cluster_name,
      output_tar = output_tar,
      cluster_name=cluster_name
  }
}
  }
  call report.cdip_report as cdip_report {
  input:
    cluster_name=cluster_name,
    treefile=treefile,
    plot_roary=select_first([roary_plot, plot_roary.plot_roary_png]),
    assembly_tsv = summarize_Strings.ummarized_data,
    mlst_tsvs = mlst_tsvs
    
  }

  output {
    File    report = cdip_report.report
  }
}

