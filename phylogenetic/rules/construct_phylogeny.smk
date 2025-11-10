"""
This part of the workflow constructs the phylogenetic tree.

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta

OUTPUTS:

    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json

This part of the workflow usually includes the following steps:

    - augur tree
    - augur refine

See Augur's usage docs for these commands for more details.
"""


rule tree:
    """Building tree"""
    input:
        alignment = "results/{group}/{gene}/aligned.fasta"
    output:
        tree = "results/{group}/{gene}/tree_raw.nwk"
    benchmark:
        "benchmarks/{group}/{gene}/tree.txt",
    log:
        "logs/{group}/{gene}/tree.txt",
    threads: 1
    shell:
        r"""
        exec &> >(tee {log:q})

        augur tree \
            --alignment {input.alignment:q} \
            --output {output.tree:q} \
            --nthreads {threads}
        """

def _clock_rate_params(wildcards):
    """
    Generate the clock rate parameters for Norovirus samples for augur refine based on if wildcard group and gene values are in the config file

    refine:
      clock_rate:
        wildcards.group:
          wildcards.gene: numeric value here

    else leave blank
    """
    clock_rate = config['refine']['clock_rate'].get(wildcards.group, {}).get(wildcards.gene, "")
    if clock_rate !="":
        return f' --clock-rate {clock_rate} '
    else:
        return ""


rule refine:
    """
    Refining tree
    """
    input:
        tree = "results/{group}/{gene}/tree_raw.nwk",
        alignment = "results/{group}/{gene}/aligned.fasta",
        metadata = "results/{group}/{gene}/filtered.tsv"
    output:
        tree = "results/{group}/{gene}/tree.nwk",
        node_data = "results/{group}/{gene}/branch_lengths.json"
    benchmark:
        "benchmarks/{group}/{gene}/refine.txt",
    log:
        "logs/{group}/{gene}/refine.txt",
    params:
        root = lambda wildcards: config['refine']['root'].get(wildcards.group, {}).get(wildcards.gene, config['refine']['root']['default']),
        clock_rate_params = lambda wildcards: _clock_rate_params(wildcards),
        id_field = config['strain_id_field'],
    shell:
        r"""
        exec &> >(tee {log:q})

        augur refine \
            --tree {input.tree:q} \
            --root {params.root} \
            --alignment {input.alignment:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.id_field} \
            --output-tree {output.tree:q} \
            --output-node-data {output.node_data:q} \
            --stochastic-resolve \
            {params.clock_rate_params}
        """
