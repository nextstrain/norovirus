GENES = ['3CLpro', 'NTPase', 'p22', 'p48', 'rdrp', 'VP1', 'VP2', 'VPg', 'genome']
# rdrp = ['GII.P4', 'GII.P16', 'GII.P31 (GII.Pe)', 'GII.P17', 'GII.P21 (GII.Pb)', 'GII.P7']
GROUP = ['GII.6', 'GII.4', 'GII.2', 'GII.3', 'GII.17', 'all']

rule all:
    input:
        expand("auspice/norovirus_{group}_{gene}.json", gene=GENES, group=GROUP),
auspice_config = "config/auspice_config.json"

rule tree:
    message: "Building tree"
    input:
        alignment = "results/{group}/{gene}/aligned.fasta"
    output:
        tree = "results/{group}/{gene}/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads 4
        """

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - estimate {params.date_inference} node dates
          - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
        """
    input:
        tree = "results/{group}/{gene}/tree_raw.nwk",
        alignment = "results/{group}/{gene}/aligned.fasta",
        metadata = "results/{group}/{gene}/filtered_metadata.tsv"
    output:
        tree = "results/{group}/{gene}/tree.nwk",
        node_data = "results/{group}/{gene}/branch_lengths.json"
    params:
        date_inference = "marginal",
        clock_filter_iqd = 4
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --root mid_point \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data}
            #--clock-filter-iqd {params.clock_filter_iqd} \
            #--timetree \
            #--date-confidence \
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        alignment = "results/{group}/{gene}/aligned.fasta"
    output:
        node_data = "results/{group}/{gene}/nt_muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        node_data = "results/{group}/{gene}/nt_muts.json",
        reference = "config/norovirus_reference_{group}_{gene}.gb"
    output:
        node_data = "results/{group}/{gene}/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output-node-data {output.node_data} \
        """

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
