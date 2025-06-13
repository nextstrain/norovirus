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

rule filter:
    """
    Filtering to
      - various criteria based on the auspice JSON target
      - from {params.min_date} onwards
      - excluding strains in {input.exclude}
      - including strains in {input.include}
      - minimum genome length of {params.min_length} (67% of Norovirus virus genome)
    """
    input:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv",
        exclude = config['filter']['exclude']
    output:
        sequences = "results/{group}/{gene}/filtered.fasta",
        metadata = "results/{group}/{gene}/metadata.tsv",
    benchmark:
        "benchmarks/{group}/{gene}/filter.txt",
    log:
        "logs/{group}/{gene}/filter.txt",
    params:
        id_field = config['strain_id_field'],
        min_length = config['filter']['min_length'],
        filter_params = config['filter']['filter_params'],
        query = lambda wildcards: f"ORF2_type == '{wildcards.group}'" if wildcards.group != 'all' else "ORF2_type in ['GII.6', 'GII.4', 'GII.2', 'GII.3', 'GII.17']"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.id_field:q} \
            --query "{params.query}" \
            {params.filter_params} \
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

        python scripts/gene_parsing.py \
          --alignment {input.alignment:q} \
          --reference {input.reference:q} \
          --gene {wildcards.gene} \
          --output {output.output:q} \
          --percentage {params.percentage:q}
        """
