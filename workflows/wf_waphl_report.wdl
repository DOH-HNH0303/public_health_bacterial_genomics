version 1.0

import "../tasks/utilities/task_report_waphl.wdl" as report

workflow waphl_report {

  input {
    String cluster_name
    File treefile
    Array[File?] output_tars
    Array[File?] roary_plot
    Array[isolate_tsv] isolate_tsvs
    String organism="corynebacterium"
  }
  if (output_tar)
  scatter ( for output_tar in output_tars) {}
  call report.plot_roary_waphl as plot_roary{
    input:
      cluster_name=cluster_name,
      output_tar = output_tar,
      cluster_name=cluster_name
  }
}
  call report.cdip_report {
  input:
    cluster_name=cluster_name,
    treefile=treefile,
    roary_plot=select_first([roary_plot, plot_roary.plot_roary_png]),
    
  }

  output {
    File    report = plot_roary_waphl.plot_roary_png
  }
}

