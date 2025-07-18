"""
This part of the workflow pulls genotype data from Genomic Detective and VIPR, cleans the data, and joins it together.
"""

rule prepare_genotype_metadata:
    input:
        metadata = expand("../data/genomicdetective_results{i}.csv", i = [1,2,3])
    output:
        result = "data/metadata_genomicdetective.tsv"
    params:
        fields = "strain,ORF2_type,ORF1_type"
    shell:
        """
        csvtk concat {input.metadata} \
            | csvtk rename -f "ORF2 type" -n "ORF2_type" \
            | csvtk rename -f "ORF1 type" -n "ORF1_type" \
            | csvtk cut -f {params.fields} \
            | csvtk --out-tabs replace -f "strain" -p "\|.*$" -r "" > {output.result}
        """
