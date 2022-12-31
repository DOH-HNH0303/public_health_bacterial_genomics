from Bio import Phylo
import matplotlib.pyplot as plt

# Generates appropriately sized dendrogram pdf
tree_file = "ksnp3_king_county_2018_core.tree"
tree = Phylo.read(tree_file, "newick")
tree.ladderize()

count = 0
for i in tree.get_terminals():
  print(i.name)
  count+=1

print(count)
mdist = max([tree.distance(tree.root, x) for x in tree.get_terminals()])
plt.rc('font', size=7)
plt.rc('lines', linewidth=0.5)
#plt.figure(figsize=(20,70))
#fig = plt.figure(figsize=(20, 40), dpi=300)
fig = plt.figure()
fig.set_size_inches(10, count*0.21)
axes = fig.add_subplot(1, 1, 1)


Phylo.draw(tree, 
           axes=axes,#ax, 
           do_show=False, 
           show_confidence=False,
           xticks=([],), yticks=([],),
           ylabel=('',), xlabel=('',),
           xlim=(-mdist*0.1,mdist+mdist*0.1),
           axis=('off',),)


plt.savefig('tree.pdf', dpi=150, bbox_inches='tight')
