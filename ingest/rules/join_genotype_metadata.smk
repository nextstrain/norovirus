"""
This part of the workflow pulls genotype data from Genomic Detective and VIPR, cleans the data, and joins it together.
"""
ruleorder: join_metadata > create_final_metadata
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

rule join_metadata:
    input:
        metadata = "data/subset_metadata.tsv",
        genomicdetective_metadata = "data/metadata_genomicdetective.tsv",
    output:
        metadata = "results/metadata.tsv",
    params:
        metadata_id_field = "accession",
        genomicdetective_id_field = "strain",
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                genomicdetective={input.genomicdetective_metadata:q} \
            --metadata-id-columns \
                metadata={params.metadata_id_field:q} \
                genomicdetective={params.genomicdetective_id_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns
        """