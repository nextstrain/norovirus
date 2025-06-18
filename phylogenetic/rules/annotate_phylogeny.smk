"""
This part of the workflow creates additonal annotations for the phylogenetic tree.

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta
    tree                = results/tree.nwk

OUTPUTS:

    node_data = results/*.json

    There are no required outputs for this part of the workflow as it depends
    on which annotations are created. All outputs are expected to be node data
    JSON files that can be fed into `augur export`.

    See Nextstrain's data format docs for more details on node data JSONs:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur traits
    - augur ancestral
    - augur translate
    - augur clades

See Augur's usage docs for these commands for more details.

Custom node data files can also be produced by build-specific scripts in addition
to the ones produced by Augur commands.
"""

rule ancestral:
    """Reconstructing ancestral sequences and mutations"""
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        alignment = "results/{group}/{gene}/aligned.fasta"
    output:
        node_data = "results/{group}/{gene}/nt_muts.json"
    benchmark:
        "benchmarks/{group}/{gene}/ancestral.txt",
    log:
        "logs/{group}/{gene}/ancestral.txt",
    params:
        inference = "joint"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    """Translating amino acid sequences"""
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        node_data = "results/{group}/{gene}/nt_muts.json",
        reference = "results/defaults/norovirus_reference_{group}_{gene}.gb"
    output:
        node_data = "results/{group}/{gene}/aa_muts.json"
    benchmark:
        "benchmarks/{group}/{gene}/translate.txt",
    log:
        "logs/{group}/{gene}/translate.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output-node-data {output.node_data}
        """

rule traits:
    """
    Inferring ancestral traits for {params.columns!s}
      - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
    """
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        metadata = "results/{group}/{gene}/metadata.tsv",
    output:
        node_data = "results/{group}/{gene}/traits.json",
    log:
        "logs/{group}/{gene}/traits.txt",
    benchmark:
        "benchmarks/{group}/{gene}/traits.txt",
    params:
        columns = lambda wildcards: config['traits'].get(wildcards.group, {}).get(wildcards.gene, config['traits']['default']),
        sampling_bias_correction = config["traits"]["sampling_bias_correction"],
        strain_id = config.get("strain_id_field", "strain"),
    shell:
        r"""
        exec &> >(tee {log:q})

        augur traits \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output {output.node_data:q} \
            --columns {params.columns} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction:q}
        """