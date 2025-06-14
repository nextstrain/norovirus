GENES = ['3CLpro', 'NTPase', 'p22', 'p48', 'rdrp', 'VP1', 'VP2', 'VPg', 'genome']
# rdrp = ['GII.P4', 'GII.P16', 'GII.P31 (GII.Pe)', 'GII.P17', 'GII.P21 (GII.Pb)', 'GII.P7']
GROUP = ['GII.6', 'GII.4', 'GII.2', 'GII.3', 'GII.17', 'all']

rule all:
    input:
        expand("auspice/norovirus_{group}_{gene}.json", gene=GENES, group=GROUP),
auspice_config = "config/auspice_config.json"

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        metadata = "results/{group}/{gene}/filtered_metadata.tsv",
        branch_lengths = "results/{group}/{gene}/branch_lengths.json",
        nt_muts = "results/{group}/{gene}/nt_muts.json",
        aa_muts = "results/{group}/{gene}/aa_muts.json",
        auspice_config = auspice_config
    output:
        auspice_json = "auspice/norovirus_{group}_{gene}.json",
    params:
        title = "Norovirus {group} {gene} Build"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} \
            --auspice-config {input.auspice_config} \
            --output {output.auspice_json} \
            --title "{params.title}"
        """
