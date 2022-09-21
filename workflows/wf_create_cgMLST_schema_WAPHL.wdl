version 1.0

import "../tasks/phylogenetic_inference/task_chewbbaca.wdl" as chewbbaca
import "../tasks/task_versioning.wdl" as versioning


workflow cgMLST_WAPHL {
  meta {
    description: "cgMLST"
  }
  input {
    String cluster_name
    Array[File] assembly_fastas
    File prodigal_file
    # by default do not call ANI task, but user has ability to enable this task if working with enteric pathogens or supply their own high-quality reference genome

  }

  call versioning.version_capture{
    input:
  }

  call chewbbaca.create_cgmlst_schema {
    input:
      assembly_fastas = assembly_fastas,
      prodigal_file = prodigal_file,
      cluster_name = cluster_name
  }

  output {
    #Version Captures
    String cgMLST_waphl_version = version_capture.phbg_version
    String cgMLST_waphl_date = version_capture.date
    File chewbbaca_test = create_cgmlst_schema.chewbbaca_test
    File cgmlst_schema_zip = create_cgmlst_schema.schema_zip
    File cgmlst_schema_txt = create_cgmlst_schema.schema_txt

    #Read Metadata
}
}
