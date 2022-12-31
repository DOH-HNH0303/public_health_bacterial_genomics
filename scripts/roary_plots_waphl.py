#!/usr/bin/env python
# Copyright (C) <2015> EMBL-European Bioinformatics Institute

# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# Neither the institution name nor the name roary_plots
# can be used to endorse or promote products derived from
# this software without prior written permission.
# For written permission, please contact <marco@ebi.ac.uk>.

# Products derived from this software may not be called roary_plots
# nor may roary_plots appear in their names without prior written
# permission of the developers. You should have received a copy
# of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

__author__ = "Marco Galardini, Holly Halstead"
__version__ = '0.2.0-WAPHL'

def get_options():
    import argparse

    # create the top-level parser
    description = "Create plots from roary outputs"
    parser = argparse.ArgumentParser(description = description,
                                     prog = 'roary_plots_waphl.py')

    parser.add_argument('tree', action='store',
                        help='Newick Tree file', default='accessory_binary_genes.fa.newick')
    parser.add_argument('spreadsheet', action='store',
                        help='Roary gene presence/absence spreadsheet', default='gene_presence_absence.csv')
    parser.add_argument('alignment', action='store',
                        help='Pangenome Alignment', default='pirate_pangenome_alignment.gff')
    parser.add_argument('recombinants', action='store',
                        help='Gubbins Recombination GFF', default='pirate.recombination_predictions.gff')

    parser.add_argument('--labels', action='store_true',
                        default=False,
                        help='Add node labels to the tree (up to 10 chars)')
    parser.add_argument('--format',
                        choices=('png',
                                 'tiff',
                                 'pdf',
                                 'svg'),
                        default='png',
                        help='Output format [Default: png]')
    parser.add_argument('-N', '--skipped-columns', action='store',
                        type=int,
                        default=14,
                        help='First N columns of Roary\'s output to exclude [Default: 14]')
    
    parser.add_argument('--version', action='version',
                         version='%(prog)s '+__version__)

    return parser.parse_args()

def flatten(l):
    return [item for sublist in l for item in sublist]

if __name__ == "__main__":
    options = get_options()

    import matplotlib
    matplotlib.use('Agg')

    import matplotlib.pyplot as plt
    import seaborn as sns

    sns.set_style('white')

    import os
    import pandas as pd
    import numpy as np
    from Bio import Phylo
    from bisect import bisect




    ##########################################################

  

    t = Phylo.read(options.tree, 'newick')

    # Max distance to create better plots
    print(t.get_terminals())
    mdist = max([t.distance(t.root, x) for x in t.get_terminals()])

    # Load roary
    roary = pd.read_csv(options.spreadsheet, low_memory=False)
#############################################################
    roary = roary.fillna(np.nan)
    print("test1")
    print(roary)
    roary_cp = roary.copy()
    selected_rows = roary_cp[roary_cp.isnull().any(axis=1)]
    #print(selected_rows)
    genes = selected_rows["Gene"]
    new_genes = []
    for gene in genes:
      gene_pre = gene.split("_")[0]
      if not gene.split("_")[1].startswith("0"):
    
        version = gene.split("_")[1]
        gene_pre=gene_pre+"_"+version
      #print(gene_pre)
      new_genes.append(gene_pre)
    
    selected_rows['Gene'] = new_genes
    
    roary = selected_rows

    # Use pangenome gff to add gene locations to recombination gff
    cds_dict = {}

    
    
    with open(options.alignment) as f:
        lines = f.readlines()
        count = 1
        for line in lines:     
          if count > 2:
            line=line.split('\t')
            gene_id = line[8].split(';')[0][3:]
            start = line[3]
            stop = line[4]
            cds_dict[gene_id] = [start, stop]
            count+=1
          else:
            count+=1


    gff = pd.DataFrame.from_dict(cds_dict, orient='index',columns=['start','stop'])
    gff = gff.reset_index(names=['Gene'])
    print(gff)
    print("test")
    print(roary)

    starts = list(map(int, gff['start'].tolist()))
    stops = list(map(int, gff['stop'].tolist()))

  
    recomb_dict = {}
    recomb_genes = []
    genes_dict = {}
    
    with open(options.recombinants) as f:
        lines = f.readlines()
        count = 1
        for line in lines: 
          
          if count > 2:
            print("new recomb")
            print(line)
            line=line.split('\t')
            #print(line)
            gene_id = line[8].split(';')[0][3:]
            #print("gene id", gene_id)
            start = int(line[3])
            stop = int(line[4])
            isolates = list(filter(None , line[8].split(";")[2][6:-1].strip().split(' ')))
            #print(isolates)
            recomb_dict[gene_id] = [start, stop, isolates]
            count+=1
            # Get Genes at recombination location
            idx_start = bisect(starts, start)
            idx_stop = bisect(stops, stop)+1
            # print(idx_start, idx_stop)
            ref_start = gff.loc[gff.index[idx_start], 'start']
            ref_stop = gff.loc[gff.index[idx_stop], 'stop']
            # print(ref_start, start)
            # print(ref_stop, stop)
            #generate index list for genes effected
            effected_genes_idx = list(range(idx_start, idx_stop+1))
            effected_genes = []
            for i in effected_genes_idx:         
              effected_gene = gff.loc[i, 'Gene']
              effected_genes.append(effected_gene)
              recomb_genes.append(effected_gene)
              if effected_gene not in genes_dict.keys():
                genes_dict[effected_gene] = [isolates]
              else:
                test = print(genes_dict[effected_gene]+[isolates])
                genes_dict[effected_gene] = genes_dict[effected_gene]+[isolates]
            
          else:
            count+=1

    #,columns=['start','stop' 'seqs'])
    #flat_list = [item for sublist in regular_list for item in sublist]
  #print(recomb_df)



  ####################################################################
    # Set index (group name)


    roary.set_index('Gene', inplace=True)
    # Drop the other info columns
    roary.drop(list(roary.columns[:options.skipped_columns-1]), axis=1, inplace=True)

    # Transform it in a presence/absence matrix (1/0)
  #####################################################
    #print(roary.columns)
    #print(roary.Index.tolist())
    
    roary.replace('.{2,100}', 1, regex=True, inplace=True)
    roary.replace(np.nan, 0, regex=True, inplace=True)

    ### r =
    replace_coords = []
    for gene in genes_dict.keys():
      print()
      print(gene, genes_dict[gene])
    
      if len(genes_dict[gene]) == 1:
        # Only one recomb event on this gene
        if len(genes_dict[gene][0]) > 1:
          # Recombination is NOT terminal and is the only recombination event on gene in dataset
          # blue
          print("line 231", genes_dict[gene][0])
          for i in genes_dict[gene][0]:
            idx = genes_dict[gene][0].index(i)
            print("[gene, (genes_dict[gene][0][idx], 3]", [gene, genes_dict[gene][0][idx], "4"])
            print
            replace_coords.append([gene, genes_dict[gene][0][idx], "4"])
        else:
          # Recombination is unique and is the only one on the gene in dataset
          # Yellow
          print("else len(genes_dict[gene][0]", len(genes_dict[gene][0]))
          replace_coords.append([gene, genes_dict[gene][0][0], "2"])
      else:
        # Multiple recombination events on this gene
        occurences = flatten(genes_dict[gene])
        multi_occur = list(set([i for i in occurences if occurences.count(i) > 1]))
        single_occur = list(set(occurences) - set(multi_occur))
        
        for i in genes_dict[gene]:
          idx = genes_dict[gene].index(i)
          if len(genes_dict[gene][idx]) > 1:
            for instance in genes_dict[gene][idx]:             
            # Recombination is NOT unique but is NOT the only one on gene in dataset
              print("its here", gene, instance, "non-terminal")
              replace_coords.append([gene, instance, "non-terminal"])
          else:
            # Recombination is unique but is NOT the only one on the gene in dataset
            replace_coords.append([gene, instance, "3"])
            print([gene, instance, "3"])
            
      
  
    print(roary)
    #print(roary.index)
##############################################################
    # Sort the matrix by the sum of strains presence
    idx = roary.sum(axis=1).sort_values(ascending=False).index
    roary_sorted = roary.loc[idx]


    # Sort the matrix according to tip labels in the tree
    roary_sorted = roary_sorted[[x.name for x in t.get_terminals()]]

    # Plot presence/absence matrix against the tree
    with sns.axes_style('whitegrid'):
        plt.rc('lines', linewidth=0.2)
        fig = plt.figure()  
        
        fig.set_size_inches(8, roary.shape[1]*0.2)#figure(figsize=(17, 10))
        #fig.set_size_inches(8, roary.shape[1]*0.25)

        ax1=plt.subplot2grid((1,40), (0, 12), colspan=30)
        a=ax1.matshow(roary_sorted.T, cmap=plt.cm.Blues,
                   vmin=0, vmax=1,
                   aspect='auto',
                   interpolation='none',
                    )
        ax1.set_yticks([])
        ax1.set_xticks([])
        ax1.axis('off')

        ax = fig.add_subplot(1,2,1)
        # matplotlib v1/2 workaround
        try:
            ax=plt.subplot2grid((1,60), (0, 0), colspan=10, facecolor='white')
        except AttributeError:
            ax=plt.subplot2grid((1,60), (0, 0), colspan=10, axisbg='white')

        fig.subplots_adjust(wspace=0, hspace=0)

        ax1.set_title('Gene Presence/Absence Matrix\n(%d genes shown)'%roary.shape[0])

        if options.labels:
            fsize = 10
            print(fsize)
            with plt.rc_context({'font.size': fsize}):
                Phylo.draw(t, axes=ax, 
                           show_confidence=False,
                           label_func=lambda x: str(x)[:11],
                           xticks=([],), yticks=([],),
                           ylabel=('',), xlabel=('',),
                           xlim=(-mdist*0.1,mdist+mdist*0.45-mdist*roary.shape[1]*0.001),
                           axis=('off',),
                           title=('Tree\n(%d strains)'%roary.shape[1],), 
                           do_show=False,
                          )
        else:
            Phylo.draw(t, axes=ax, 
                       #show_confidence=False,
                       #label_func=lambda x: None,
                       xticks=([],), yticks=([],),
                       ylabel=('',), xlabel=('',),
                       xlim=(-mdist*0.1,mdist+mdist*0.1),
                       axis=('off',),
                       title=('Tree\n(%d strains)'%roary.shape[1],),
                       do_show=False,
                      )
        
        plt.savefig('pangenome_matrix.%s'%options.format, dpi=300, bbox_inches='tight')
        plt.clf()


    
    