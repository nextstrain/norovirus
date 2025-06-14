"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

REQUIRED INPUTS:

    metadata        = data/metadata.tsv
    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json
    node_data       = results/*.json

OUTPUTS:

    auspice_json = auspice/${build_name}.json

    There are optional sidecar JSON files that can be exported as part of the dataset.
    See Nextstrain's data format docs for more details on sidecar files:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur export v2
    - augur frequencies

See Augur's usage docs for these commands for more details.
"""

rule export:
    """Exporting data files for for auspice"""
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        metadata = "results/{group}/{gene}/metadata.tsv",
        branch_lengths = "results/{group}/{gene}/branch_lengths.json",
        nt_muts = "results/{group}/{gene}/nt_muts.json",
        aa_muts = "results/{group}/{gene}/aa_muts.json",
        auspice_config = config['export']['auspice_config']
    output:
        auspice_json = "auspice/norovirus_{group}_{gene}.json",
    benchmark:
        "benchmarks/{group}/{gene}/export.txt",
    log:
        "logs/{group}/{gene}/export.txt",
    params:
        title = "Norovirus {group} {gene} Build",
        id_field = config['strain_id_field']
    shell:
        r"""
        exec &> >(tee {log:q})

        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_field} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} \
            --auspice-config {input.auspice_config} \
            --output {output.auspice_json} \
            --title "{params.title}"
        """
