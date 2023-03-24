version 1.0

task version_capture {
  input {
    String? timezone
  }
  meta {
    volatile: true
  }
  command {
    PHBG_Version="PHBG v1.0.0"
    ~{default='' 'export TZ=' + timezone}
    date +"%Y-%m-%d" > TODAY
    echo "$PHBG_Version" > PHBG_VERSION
  }
  output {
    String date = read_string("TODAY")
    String phbg_version = read_string("PHBG_VERSION")
  }
  runtime {
    memory: "1 GB"
    cpu: 1
    docker: "quay.io/theiagen/utility:1.1"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}

task waphl_version_capture {
  input {
    Array[String?] docker_images
    Array[String?] versions
    String = "PHBG-WAPHL v1.0.0-beta"
  }
  meta {
    volatile: true
  }
  command {
    touch input.tsv
    assembly_array="~{sep='\t' docker_images}"
    for item in "${docker_images[@]}"; do
      echo $item>>input.tsv
    done
    for item in "${versions[@]}"; do
      echo $item>>input.tsv
    done
    ~{default='' 'export TZ=' + timezone}
    date +"%Y-%m-%d" > TODAY
    echo "~{PHBG-WAPHL v1.0.0-beta}" > PHBG_WAPHL_VERSION

    python3<<CODE

    import os

    directory = '.'

    with open("input.tsv", "r") as file1, \
     open('versions.tsv', mode='w') as out_file:
        tool_list = ["utilities"]
        version_list = ["1.1"]
        for l in file1:
            l=l.split(":")
            if len(l)>1:
                tool = ''.join(l[:-1]).split("/")[-1]
                version = l[-1]
                if tool.upper().strip("-").strip("_") not in tool_list:
                    tool_list.append(tool.upper().strip("-").strip("_"))
                    version_list.append(version)
        for i in range(len(tool_list)):
          out_file.write(tool_list[i]+"\t"+version_list[i]+)

    file1.close()
    out_file.close()

    CODE
  }
  output {
    String date = read_string("TODAY")
    String phbg_waphl_version = read_string("PHBG_WAPHL_VERSION")
    String docker_tool_versions = "versions.tsv"
  }
  runtime {
    memory: "1 GB"
    cpu: 1
    docker: "quay.io/theiagen/utility:1.1"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}
