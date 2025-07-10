from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.SeqFeature import SeqFeature, FeatureLocation
from sys import stderr, stdin
import os
import argparse
import shutil

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--reference", metavar="GB", default="config/reference.gb",
        help="The reference genbank file")
    parser.add_argument('--gene', metavar='N',nargs='+', default='all_genes',
                    help='gene sequenced')
    parser.add_argument('--output', metavar='N',nargs='+', default='result.fasta',
                    help='output file to store sequence')
    args = parser.parse_args()

if 'genome' != args.gene[0].lower():
    for seq_record in SeqIO.parse(args.reference, "genbank"):
        for feature in seq_record.features:
            if feature.type == 'CDS':
                if 'gene' in feature.qualifiers.keys() and feature.qualifiers['gene'][0].lower() == args.gene[0].lower():
                    #get name of gene
                    gene_name = feature.qualifiers['gene'][0]
                    #extract gene sequence from whole genome
                    gene_seq = feature.location.extract(seq_record.seq)
                    #initialize a SeqRecord for the genbank file
                    gene_record = SeqRecord(gene_seq, id= seq_record.id,
                                            name= gene_name)
                    #make the source feature
                    source_feature = SeqFeature(FeatureLocation(0, len(gene_seq)), type='source',
                                        qualifiers={"mol_type":"genomic RNA","gene":gene_name})
                    gene_record.features.append(source_feature)
                    #make the gene feature
                    gene_feature = SeqFeature(FeatureLocation(0, len(gene_seq)), type='CDS',
                                        qualifiers={"mol_type":"genomic RNA","gene":gene_name})
                    gene_record.features.append(gene_feature)

                    #make the cds feature, with translation
                    cds_feature = SeqFeature(FeatureLocation(0, len(gene_seq)), type='CDS', qualifiers={'translation':gene_seq.translate()})
                    gene_record.features.append(cds_feature)

                    #add molecular type
                    gene_record.annotations["molecule_type"] = "RNA"

                    #write gene-specific reference file
                    outfile_name = args.output[0]
                    SeqIO.write(gene_record, outfile_name, 'genbank')
else:
    shutil.copyfile(args.reference ,args.output[0])
