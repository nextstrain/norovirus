"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta
    reference   = ../shared/reference.fasta

OUTPUTS:

    prepared_sequences = results/prepared_sequences.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - augur align
    - augur mask

See Augur's usage docs for these commands for more details.
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
        query = f"({query}) & (VP1_nextclade == '{wildcards.group}')"

    return query

rule filter:
    """
    Filtering to
      - various criteria based on the auspice JSON target
    """
    input:
        sequences = "results/sequences.fasta",
        metadata = "results/metadata.tsv",
        exclude = lambda wildcards: config['filter']['exclude'].get(wildcards.group, config['filter']['exclude']['default']),
    output:
        sequences = "results/{group}/{gene}/filtered.fasta",
        metadata = "results/{group}/{gene}/filtered.tsv",
    benchmark:
        "benchmarks/{group}/{gene}/filter.txt",
    log:
        "logs/{group}/{gene}/filter.txt",
    params:
        id_field = config['strain_id_field'],
        filter_params = config['filter']['filter_params'],
        query_params = lambda wildcards: _query_params(wildcards)
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.id_field:q} \
            {params.filter_params} \
            --query {params.query_params:q} \
            --exclude {input.exclude:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q}
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

        python scripts/reference_parsing.py \
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
    threads: 1
    shell:
        r"""
        exec &> >(tee {log:q})

        augur align \
            --sequences {input.sequences:q} \
            --reference-sequence {input.reference:q} \
            --output {output.alignment:q} \
            --fill-gaps \
            --nthreads {threads} \
            --remove-reference
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

        python scripts/gene_parsing.py \
          --alignment {input.alignment:q} \
          --reference {input.reference:q} \
          --gene {wildcards.gene} \
          --output {output.output:q} \
          --percentage {params.percentage:q}
        """
