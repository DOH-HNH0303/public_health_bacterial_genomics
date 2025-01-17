version 1.0

import "../tasks/utilities/task_summarize_table_waphl.wdl" as summarize
import "../tasks/utilities/task_report_waphl.wdl" as report

workflow waphl_report {

  input {
    String cluster_name
    File treefile
    Array[File] mlst_tsvs
    Array[String] samplenames
    String terra_table
    String terra_workspace
    String terra_project
    String organism="corynebacterium"
  }
  call summarize.summarize_string_data as summarize_strings  {
  input:
    samplenames = samplenames,
    terra_table = terra_table,
    terra_workspace = terra_workspace,
    terra_project = terra_project
    
}

  call report.cdip_report as cdip_report {
  input:
    cluster_name=cluster_name,
    treefile=treefile,
    assembly_tsv = summarize_strings.summarized_data,
    mlst_tsvs = mlst_tsvs
    
  }

  output {
    File    report = cdip_report.report
  }
}

