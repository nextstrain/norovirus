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

rule download:
    """Downloading sequences and metadata from data.nextstrain.org"""
    output:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst",
    params:
        sequences_url = config["sequences_url"],
        metadata_url = config["metadata_url"],
    benchmark:
        "benchmarks/download.txt",
    log:
        "logs/download.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """

rule decompress:
    """Decompressing sequences and metadata"""
    input:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    output:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv",
    benchmark:
        "benchmarks/decompress.txt",
    log:
        "logs/decompress.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """

rule merge_clade_membership:
    input:
        metadata="data/metadata.tsv",
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

def _query_params(wildcards):
    """
    Generate the query for filtering Norovirus samples based on the combination of wildcards values

    1. wildcards.gene: genetic region (genome, VP1, RdRp, ...)
    2. wildcards.group: genotypes (all, GII.2, ...)

    """
    if wildcards.gene == 'genome':
        query = f'coverage >= {config["filter"]["min_coverage"]} & (length > 5032)'
    else:
        query = f'`{wildcards.gene}_coverage` >= {config["filter"]["min_coverage"]}'

    if wildcards.group != 'all':
        query = f"({query}) & (ORF2_type == '{wildcards.group}')"

    if wildcards.gene == 'RdRp':
        query = f"({query}) & (ORF1_type != '')"

    if wildcards.gene == 'VP1':
        query = f"({query}) & (ORF2_type != '')"

    return query

rule filter:
    """
    Filtering to
      - various criteria based on the auspice JSON target
    """
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/{gene}/metadata_merged.tsv",
        exclude = config['filter']['exclude'],
        include = config['filter']['include'],
    output:
        sequences = "results/{group}/{gene}/filtered.fasta",
        metadata = "results/{group}/{gene}/metadata.tsv",
    benchmark:
        "benchmarks/{group}/{gene}/filter.txt",
    log:
        "logs/{group}/{gene}/filter.txt",
    params:
        id_field = config['strain_id_field'],
        filter_params = config['filter']['filter_params'],
        query_params = lambda wildcards: _query_params(wildcards),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.id_field:q} \
            --include {input.include:q} \
            {params.filter_params} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q}

            # --exclude {input.exclude:q}
            #--query {params.query_params:q}
        """

rule parse_reference:
    """
    parsing gene from reference genbank
    """
    input:
        reference = config['reference']
    output:
        output = "results/defaults/norovirus_reference_{group}_{gene}.gb"
    benchmark:
        "benchmarks/{group}/{gene}/parse_reference.txt",
    log:
        "logs/{group}/{gene}/parse_reference.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        python ../phylogenetic/scripts/reference_parsing.py \
          --reference {input.reference} \
          --gene {wildcards.gene} \
          --output {output.output}
        """

rule align:
    """
    Aligning sequences to {input.reference}
      - filling gaps with N
    """
    input:
        sequences = "results/{group}/{gene}/filtered.fasta",
        reference = "results/defaults/norovirus_reference_{group}_{gene}.gb"
    output:
        alignment = "results/{group}/{gene}/alignment.fasta"
    benchmark:
        "benchmarks/{group}/{gene}/align.txt",
    log:
        "logs/{group}/{gene}/align.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --fill-gaps \
            --nthreads 4
        """

rule parse_gene:
    input:
        reference = "results/defaults/norovirus_reference_{group}_{gene}.gb",
        alignment = "results/{group}/{gene}/alignment.fasta"
    output:
        output = "results/{group}/{gene}/aligned.fasta"
    benchmark:
        "benchmarks/{group}/{gene}/parse_gene.txt",
    log:
        "logs/{group}/{gene}/parse_gene.txt",
    params:
        percentage = 0.8
    shell:
        r"""
        exec &> >(tee {log:q})

        python ../phylogenetic/scripts/gene_parsing.py \
          --alignment {input.alignment:q} \
          --reference {input.reference:q} \
          --gene {wildcards.gene} \
          --output {output.output:q} \
          --percentage {params.percentage:q}
        """
