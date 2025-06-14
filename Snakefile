GENES = ['3CLpro', 'NTPase', 'p22', 'p48', 'rdrp', 'VP1', 'VP2', 'VPg', 'genome']
# rdrp = ['GII.P4', 'GII.P16', 'GII.P31 (GII.Pe)', 'GII.P17', 'GII.P21 (GII.Pb)', 'GII.P7']
GROUP = ['GII.6', 'GII.4', 'GII.2', 'GII.3', 'GII.17', 'all']

rule all:
    input:
        expand("auspice/norovirus_{group}_{gene}.json", gene=GENES, group=GROUP),
auspice_config = "config/auspice_config.json"
