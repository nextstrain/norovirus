"""
This part of the workflow handles running Nextclade on the curated metadata
and sequences.

REQUIRED INPUTS:

    metadata    = data/subset_metadata.tsv
    sequences   = results/sequences.fasta

OUTPUTS:

    metadata        = results/metadata.tsv
    nextclade       = results/nextclade.tsv
    alignment       = results/alignment.fasta
    translations    = results/translations.zip

See Nextclade docs for more details on usage, inputs, and outputs if you would
like to customize the rules:
https://docs.nextstrain.org/projects/nextclade/page/user/nextclade-cli.html
"""

rule run_gene_coverage:
    input:
        input_ref=config['gene_coverage']['dataset_reference'],
        input_annotation=config['gene_coverage']['dataset_gff'],
        sequences="results/sequences.fasta",
    output:
        nextclade="results/gene_coverage/nextclade.tsv",
        alignment="results/gene_coverage/alignment.fasta",
    params:
        # The lambda is used to deactivate automatic wildcard expansion.
        # https://github.com/snakemake/snakemake/blob/384d0066c512b0429719085f2cf886fdb97fd80a/snakemake/rules.py#L997-L1000
        translations=lambda w: "results/gene_coverage/translations/{cds}.fasta",
        min_seed_cover=0.05 # Smallest gene based on GFF/Genome length (398/7500)
    shell:
        """
        nextclade3 run \
            {input.sequences} \
            --input-ref {input.input_ref} \
            --input-annotation {input.input_annotation} \
            --output-tsv {output.nextclade} \
            --output-fasta {output.alignment} \
            --min-seed-cover {params.min_seed_cover} \
            --alignment-preset high-diversity \
            --allowed-mismatches 20 \
            --penalty-gap-extend 1 \
            --min-length 390 \
            --silent
        """


rule gene_coverage_metadata:
    input:
        nextclade="results/gene_coverage/nextclade.tsv",
    output:
        nextclade_metadata=temp("results/gene_coverage/nextclade_metadata.tsv"),
    params:
        nextclade_id_field=config["gene_coverage"]["id_field"],
        nextclade_field_map=[f"{old}={new}" for old, new in config["gene_coverage"]["field_map"].items()],
        nextclade_fields=",".join(config["gene_coverage"]["field_map"].values()),
    shell:
        r"""
        augur curate rename \
            --metadata {input.nextclade:q} \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata - \
        | tsv-select --header --fields {params.nextclade_fields:q} \
        > {output.nextclade_metadata:q}
        """

rule split_cdsCoverage_columns:
    input:
        metadata = "results/gene_coverage/nextclade_metadata.tsv"
    output:
        metadata = "results/gene_coverage.tsv"
    params:
        cdsCoverage=config['gene_coverage']['coverage']['cdsCoverage_field'],
        genes=config['gene_coverage']['coverage']['genes'],
        round_digits=config['gene_coverage']['coverage']['round_digits'],
    shell:
        r"""
        python ./scripts/split-cdsCoverage-columns.py \
          --metadata {input.metadata} \
          --cdsCoverage {params.cdsCoverage} \
          --genes {params.genes} \
          --round {params.round_digits} \
          --output {output.metadata}
        """

DATASET_NAMES = config["nextclade"]["dataset_name"]

wildcard_constraints:
    DATASET_NAME = "|".join(DATASET_NAMES)

rule run_nextclade:
    input:
        dataset=lambda wildcards: directory(f"../nextclade_data/{wildcards.DATASET_NAME}/"),
        sequences="results/sequences.fasta",
    output:
        nextclade="results/{DATASET_NAME}/nextclade.tsv",
        alignment="results/{DATASET_NAME}/alignment.fasta",
    log:
        "logs/{DATASET_NAME}/run_nextclade.txt",
    benchmark:
        "benchmarks/{DATASET_NAME}/run_nextclade.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        nextclade3 run \
            {input.sequences} \
            --input-dataset {input.dataset:q} \
            --output-tsv {output.nextclade:q} \
            --output-fasta {output.alignment:q} \
            --alignment-preset high-diversity \
            --min-length 1224 \
            --silent
        """

rule nextclade_metadata:
    input:
        nextclade="results/{DATASET_NAME}/nextclade.tsv",
    output:
        nextclade_metadata=temp("results/{DATASET_NAME}/nextclade_metadata.tsv"),
    log:
        "logs/{DATASET_NAME}/nextclade_metadata.txt",
    benchmark:
        "benchmarks/{DATASET_NAME}/nextclade_metadata.txt",
    params:
        nextclade_id_field=config["nextclade"]["id_field"],
        nextclade_field_map=lambda wildcard: [f"{old}={new}" for old, new in config["nextclade"][wildcard.DATASET_NAME]["field_map"].items()],
        nextclade_fields=lambda wildcard: ",".join(config["nextclade"][wildcard.DATASET_NAME]["field_map"].values()),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur curate rename \
            --metadata {input.nextclade:q} \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata - \
        | csvtk cut -t --fields {params.nextclade_fields:q} \
        > {output.nextclade_metadata:q}

        """

rule join_metadata_and_nextclade:
    input:
        metadata="data/subset_metadata.tsv",
        gene_coverage="results/gene_coverage.tsv",
        genomicdetective_metadata = "data/metadata_genomicdetective.tsv",
        VP1="results/VP1/nextclade_metadata.tsv",
        RdRp="results/RdRp/nextclade_metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        metadata_id_field=config["curate"]["output_id_field"],
        genomicdetective_id_field = "strain",
        nextclade_id_field=config["gene_coverage"]["id_field"],
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                gene_coverage={input.gene_coverage:q} \
                genomicdetective={input.genomicdetective_metadata:q} \
                VP1={input.VP1:q} \
                RdRp={input.RdRp:q} \
            --metadata-id-columns \
                metadata={params.metadata_id_field:q} \
                gene_coverage={params.nextclade_id_field:q} \
                genomicdetective={params.genomicdetective_id_field:q} \
                VP1={params.nextclade_id_field:q} \
                RdRp={params.nextclade_id_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns
        """
