"""
This part of the workflow preprocesses any data and files related to the
lineages/clades designations of the pathogen.

REQUIRED INPUTS:

    None

OUTPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta

    There will be many pathogen specific outputs from this part of the workflow
    due to the many ways lineages and/or clades are maintained and defined.

This part of the workflow usually includes steps to download and curate the required files.
"""

rule merge_clade_membership:
    input:
        metadata="results/metadata.tsv",
        clade_membership=config['clade_membership']['metadata'],
    output:
        merged_metadata=temp("data/{gene}/metadata_merged_raw.tsv"),
    log:
        "logs/{gene}/merge_clade_membership.txt",
    benchmark:
        "benchmarks/{gene}/merge_clade_membership.txt",
    params:
        metadata_id=config.get("strain_id_field", "strain"),
        clade_membership_id=config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur merge \
        --metadata a={input.metadata:q} b={input.clade_membership:q} \
        --metadata-id-columns a={params.metadata_id:q} b={params.clade_membership_id:q} \
        --output-metadata {output.merged_metadata:q}
        """


rule fill_in_clade_membership:
    input:
        merged_metadata="data/{gene}/metadata_merged_raw.tsv",
    output:
        merged_metadata="data/{gene}/metadata_merged.tsv",
    log:
        "logs/{gene}/fill_in_clade_membership.txt",
    benchmark:
        "benchmarks/{gene}/fill_in_clade_membership.txt",
    params:
        clade_membership_column="clade_membership",
        # ORF1_type for RdRp gene region, ORF2_type for VP1 gene region
        genotype_column=lambda w: f"ORF1_type" if w.gene == "RdRp" else f"ORF2_type"
    shell:
        r"""
        exec &> >(tee {log:q})

        python scripts/fill-clade-membership.py \
          --input-metadata {input.merged_metadata:q} \
          --output-metadata {output.merged_metadata:q} \
          --clade-membership-column {params.clade_membership_column:q} \
          --genotype-column {params.genotype_column:q}
        """