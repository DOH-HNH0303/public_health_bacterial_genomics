version 1.0

task ts_mlst {
  meta {
    description: "Torsten Seeman's (TS) automatic MLST calling from assembled contigs"
  }
  input {
    File assembly
    String samplename
    String docker = "staphb/mlst:2.22.0"
    Int? cpu = 4
    # Parameters
    # --nopath          Strip filename paths from FILE column (default OFF)
    # --scheme [X]      Don't autodetect, force this scheme on all inputs (default '')
    # --minid [n.n]     DNA %identity of full allelle to consider 'similar' [~] (default '95')
    # --mincov [n.n]    DNA %cov to report partial allele at all [?] (default '10')
    # --minscore [n.n]  Minumum score out of 100 to match a scheme (when auto --scheme) (default '50')
    Boolean nopath = true
    String? scheme
    Float? minid
    Float? mincov
    Float? minscore
  }
  command <<<
    echo $(mlst --version 2>&1) | sed 's/mlst //' | tee VERSION

    #create output header
    echo -e "Filename\tPubMLST_Scheme_name\tSequence_Type_(ST)\tAllele_IDs" > ~{samplename}_ts_mlst.tsv

    mlst \
      --threads ~{cpu} \
      ~{true="--nopath" false="" nopath} \
      ~{'--scheme ' + scheme} \
      ~{'--minid ' + minid} \
      ~{'--mincov ' + mincov} \
      ~{'--minscore ' + minscore} \
      ~{assembly} \
      >> ~{samplename}_ts_mlst.tsv

    # parse ts mlst tsv for relevant outputs
    if [ $(wc -l ~{samplename}_ts_mlst.tsv | awk '{ print $1 }') -eq 1 ]; then
      predicted_mlst="No ST predicted"
      pubmlst_scheme="NA"
    else
      pubmlst_scheme="$(cut -f2 ~{samplename}_ts_mlst.tsv | tail -n 1)"
      predicted_mlst="ST$(cut -f3 ~{samplename}_ts_mlst.tsv | tail -n 1)"
        if [ "$pubmlst_scheme" == "-" ]; then
          predicted_mlst="No ST predicted"
          pubmlst_scheme="NA"
        else
          if [ "$predicted_mlst" == "ST-" ]; then
          predicted_mlst="No ST predicted"
          fi
        fi
    fi

    echo $predicted_mlst | tee PREDICTED_MLST
    echo $pubmlst_scheme | tee PUBMLST_SCHEME
  >>>
  output {
    File ts_mlst_results = "~{samplename}_ts_mlst.tsv"
    String ts_mlst_predicted_st = read_string("PREDICTED_MLST")
    String ts_mlst_pubmlst_scheme = read_string("PUBMLST_SCHEME")
    String ts_mlst_version = read_string("VERSION")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}

task srst2 {
  input {
    File read1_cleaned
    File read2_cleaned
    String samplename
    String docker = "hnh0303/srst2:0.2.0"
    Int? cpu = 4
    # Parameters
    # --nopath          Strip filename paths from FILE column (default OFF)
    # --scheme [X]      Don't autodetect, force this scheme on all inputs (default '')
    # --minid [n.n]     DNA %identity of full allelle to consider 'similar' [~] (default '95')
    # --mincov [n.n]    DNA %cov to report partial allele at all [?] (default '10')
    # --minscore [n.n]  Minumum score out of 100 to match a scheme (when auto --scheme) (default '50')
    Boolean nopath = true
    String? scheme = 'Corynebacterium diphtheriae'
  }
  command <<<

    getmlst.py --species "~{scheme}"

    srst2 --output "~{samplename}_srst2" --input_pe ~{read1_cleaned} ~{read2_cleaned} --mlst_db Corynebacterium_diphtheriae.fasta --mlst_definitions profiles_csv --mlst_delimiter '_'

    ls

    echo " ~{samplename} in srst2 is finished"

    tree
    echo ""
    tree /data
  >>>
  output {
    File srst2_result = glob("*~{samplename}_srst2*")[0]
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}
