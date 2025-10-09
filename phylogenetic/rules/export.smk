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

import json

rule colors:
    """Generate color pallete for color by metadata in auspice"""
    input:
        color_schemes = config['colors']['color_schemes'],
        color_orderings = config['colors']['color_orderings'],
        metadata = "results/{group}/{gene}/filtered.tsv",
    output:
        colors = "results/{group}/{gene}/colors.tsv"
    log:
        "logs/{group}/{gene}/colors.txt",
    benchmark:
        "benchmarks/{group}/{gene}/colors.txt"
    shell:
        r"""
        python3 scripts/assign-colors.py \
            --color-schemes {input.color_schemes:q} \
            --ordering {input.color_orderings:q} \
            --metadata {input.metadata:q} \
            --output {output.colors:q} \
            2>&1 | tee {log}
        """

rule prepare_auspice_config:
    """Prepare the auspice config file for each serotypes"""
    output:
        auspice_config="results/defaults/{group}/{gene}/auspice_config.json",
    benchmark:
        "benchmarks/{group}/{gene}/prepare_auspice_config.txt"
    params:
        title = "Real-time tracking of Norovirus {group} {gene} virus evolution",
        default_color_by = lambda wildcard: r"VP1_nextclade" if wildcard.group in ['all'] else r"RdRp_nextclade",
        gene_coverage_coloring = lambda wildcard: {"key": f"{wildcard.gene}_coverage","title": f"{wildcard.gene} coverage","type": "continuous"} if wildcard.gene != "genome" else None
    run:
        data = {
            "title": params.title,
            "maintainers": [
              {"name": "the Nextstrain team", "url": "https://nextstrain.org/team"}
            ],
            "data_provenance": [
              {
                "name": "GenBank",
                "url": "https://www.ncbi.nlm.nih.gov/genbank/"
              }
            ],
            "build_url": "https://github.com/nextstrain/norovirus",
            "colorings": [
              {
                "key": "ORF2_type",
                "title": "Vp1 Genotype (Genome Detective)",
                "type": "categorical"
              },
              {
                "key": "ORF1_type",
                "title": "RdRp Genotype (Genome Detective)",
                "type": "categorical"
              },
              {
                "key": "VP1_nextclade",
                "title": "Vp1 Genotype (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "VP1_group",
                "title": "Vp1 group (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "VP1_type",
                "title": "Vp1 type (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "VP1_variant",
                "title": "Vp1 variant (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "RdRp_nextclade",
                "title": "RdRp Genotype (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "RdRp_group",
                "title": "RdRp group (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "RdRp_type",
                "title": "RdRp type (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "RdRp_variant",
                "title": "RdRp variant (Nextclade)",
                "type": "categorical"
              },
              {
                "key": "host",
                "title": "Host scientific",
                "type": "categorical"
              },
              {
                "key": "host_genus",
                "title": "Host genus",
                "type": "categorical"
              },
              {
                "key": "host_type",
                "title": "Host type",
                "type": "categorical"
              },
              {
                "key": "coverage",
                "title": "Genome coverage",
                "type": "continuous"
              },
              *([params.gene_coverage_coloring] if params.gene_coverage_coloring else []),
              {
                "key": "VP1_coverage",
                "title": "Vp1 coverage",
                "type": "continuous"
              },
              {
                "key": "RdRp_coverage",
                "title": "RdRp coverage",
                "type": "continuous"
              },
              {
                "key": "num_date",
                "title": "Date",
                "type": "continuous"
              },
              {
                "key": "country",
                "title": "Country",
                "type": "categorical"
              }
            ],
            "geo_resolutions": [
              "country",
              "region"
            ],
            "panels": [
               "tree",
               "map",
               "entropy",
               "frequencies"
            ],
            "display_defaults": {
              "map_triplicate": True,
              "color_by": params.default_color_by
            },
            "metadata_columns": [
              "strain",
              "host",
              "is_lab_host",
              "p48_coverage",
              "NTPase_coverage",
              "p22_coverage",
              "VPg_coverage",
              "3CLpro_coverage",
              "RdRp_coverage",
              "VP1_coverage",
              "VP2_coverage",
            ],
            "filters": [
              "country",
              "ORF2_type",
              "ORF1_type",
              "author"
            ],
            "extensions": {
              "nextclade": {
                "clade_node_attrs": [
                  {
                    "name": "ORF2_type",
                    "displayName": "Vp1 Genotype (Genome Detective)",
                    "description": "Norovirus Vp1 Genotype (based on current tree)"
                  },
                  {
                    "name": "ORF1_type",
                    "displayName": "RdRp Genotype (Genome Detective)",
                    "description": "Norovirus RdRp Genotype (based on current tree)"
                  },
                  {
                    "name": "VP1_nextclade",
                    "displayName": "Vp1 Genotype (Nextclade)",
                    "description": "Norovirus Vp1 Genotype (based on current tree)"
                  },
                  {
                    "name": "RdRp_nextclade",
                    "displayName": "RdRp Genotype (Nextclade)",
                    "description": "Norovirus RdRp Genotype (based on current tree)"
                  }
                ],
                "pathogen": {
                  "schemaVersion":"3.0.0",
                  "attributes": {
                    "name": "Norovirus live tree",
                    "reference name": "Reconstructed ancestor",
                    "reference accession": "none"
                  },
                  "alignmentParams": {
                    "alignmentPreset": "high-diversity",
                    "minSeedCover": 0.01
                  }
                }
              }
            }
        }
        with open(output.auspice_config, 'w') as fh:
            json.dump(data, fh, indent=2)

rule export:
    """Exporting data files for for auspice"""
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        metadata = "results/{group}/{gene}/filtered.tsv",
        branch_lengths = "results/{group}/{gene}/branch_lengths.json",
        nt_muts = "results/{group}/{gene}/nt_muts.json",
        aa_muts = "results/{group}/{gene}/aa_muts.json",
        traits = "results/{group}/{gene}/traits.json",
        colors = "results/{group}/{gene}/colors.tsv",
        auspice_config = config['export']['auspice_config'],
        description = config['export']['description'],
    output:
        auspice_json = "auspice/norovirus_{group}_{gene}.json",
    benchmark:
        "benchmarks/{group}/{gene}/export.txt",
    log:
        "logs/{group}/{gene}/export.txt",
    params:
        id_field = config['strain_id_field']
    shell:
        r"""
        exec &> >(tee {log:q})

        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_field} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.traits} \
            --colors {input.colors} \
            --auspice-config {input.auspice_config} \
            --description {input.description} \
            --output {output.auspice_json} \
            --include-root-sequence-inline
        """

rule tip_frequencies:
    """
    Estimating KDE frequencies for tips
    """
    input:
        tree = "results/{group}/{gene}/tree.nwk",
        metadata = "results/{group}/{gene}/filtered.tsv",
    output:
        tip_freq = "auspice/norovirus_{group}_{gene}_tip-frequencies.json"
    benchmark:
        "benchmarks/{group}/{gene}/tip_frequencies.txt",
    log:
        "logs/{group}/{gene}/tip_frequencies.txt",
    params:
        strain_id = config["strain_id_field"],
        min_date = config["tip_frequencies"]["min_date"],
        max_date = config["tip_frequencies"]["max_date"],
        narrow_bandwidth = config["tip_frequencies"]["narrow_bandwidth"],
        proportion_wide = config["tip_frequencies"]["proportion_wide"]
    shell:
        r"""
        exec &> >(tee {log:q})

        augur frequencies \
            --method kde \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --min-date {params.min_date} \
            --max-date {params.max_date} \
            --narrow-bandwidth {params.narrow_bandwidth} \
            --proportion-wide {params.proportion_wide} \
            --output {output.tip_freq}
        """