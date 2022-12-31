import pandas as pd

'''Takes snp_distance_matrix.tsv as input and returns txt file with list
of '''
input = "core_snp_dists_WA_isolates_2018_masked_aln_snp_distance_matrix.tsv"
output = "output.txt"
cluster_dist = 150 #SNP ingdistance determines cluster

df =pd.read_csv(input, sep='\t', header=0)

seqs=df[df.columns[0]].tolist()
df = df.replace("-",0)

done_list=[]
seq_list =[]
for i in seqs:
  snp_dist=df[i].tolist()
  res = [idx for idx, val in enumerate(snp_dist) if int(val) <= cluster_dist]

  ids=[]
  for j in res:
    val=df.iloc[j].loc[df.columns[0]]
    ids.append(val)
  
  if res not in done_list:
    done_list.append(res)
    seq_list.append(ids)

count=0
with open(output, 'w') as fp:
    for item in seq_list:
        count+=1
        print(item, count)
        # write each item on a new line
        fp.write("%s\n" % item)
    print('Done')

  
