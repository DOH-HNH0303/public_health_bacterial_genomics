version 1.0

import "../tasks/phylogenetic_inference/task_chewbbaca.wdl" as chewbbaca
import "../tasks/task_versioning.wdl" as versioning


workflow prep_bigdb_cgmlst {
  meta {
    description: "cgMLST"
  }
  input {
    File locus_list
  }

  call versioning.version_capture{
    input:
  }

  call chewbbaca.prepare_cgmlst_schema {
    input:
      locus_list = locus_list
  }

  output {
    #Version Captures
    String cgMLST_waphl_version = version_capture.phbg_version
    String cgMLST_waphl_date = version_capture.date
    File cgmlst_zip = prep_cgMLST_schema_WAPHL.cgmlst_zip
    #Read Metadata
}
}
