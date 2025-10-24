"""
This part of the workflow collects the phylogenetic tree and annotations to
export a reference tree and create the Nextclade dataset.

REQUIRED INPUTS:

    augur export:
        metadata            = data/metadata.tsv
        tree                = results/tree.nwk
        branch_lengths      = results/branch_lengths.json
        nt_muts             = results/nt_muts.json
        aa_muts             = results/aa_muts.json
        clades              = results/clades.json

    Nextclade dataset files:
        reference           = ../shared/reference.fasta
        pathogen            = config/pathogen.json
        genome_annotation   = config/genome_annotation.gff3
        readme              = config/README.md
        changelog           = config/CHANGELOG.md
        example_sequences   = config/sequence.fasta

OUTPUTS:

    nextclade_dataset = datasets/${build_name}/*

    See Nextclade docs on expected naming conventions of dataset files
    https://docs.nextstrain.org/projects/nextclade/page/user/datasets.html

This part of the workflow usually includes the following steps:

    - augur export v2
    - cp Nextclade datasets files to new datasets directory

See Augur's usage docs for these commands for more details.
"""


import json

rule colors:
    """Generate color pallete for color by metadata in auspice"""
    input:
        color_schemes = config['colors']['color_schemes'],
        color_orderings = config['colors']['color_orderings'],
        # Generate colors per Nextclade dataset to account for differences in clade nomenclature
        metadata = "results/{group}/{gene}/filtered.tsv",
    output:
        colors = "results/{group}/{gene}/colors.tsv"
    log:
        "logs/{group}/{gene}/colors.txt",
    benchmark:
        "benchmarks/{group}/{gene}/colors.txt"
    shell:
        r"""
        python3 {workflow.basedir}/../shared/vendored/scripts/assign-colors \
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
        title = "Nextclade scaffold tree for Norovirus {group} {gene} virus evolution",
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
                "key": "clade_membership",
                "title": "Clade Membership",
                "type": "categorical"
              },
              {
                "key": "genogroup",
                "title": "Genogroup",
                "type": "categorical"
              },
              {
                "key": "genotype",
                "title": "Genotype",
                "type": "categorical"
              },
              {
                "key": "variant",
                "title": "Variant",
                "type": "categorical"
              },
              {
                "key": "ORF2_type",
                "title": "Vp1 Genotype",
                "type": "categorical"
              },
              {
                "key": "ORF1_type",
                "title": "RdRp Genotype",
                "type": "categorical"
              },
              {
                "key": "host",
                "title": "Host",
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
              },
              {
                "key": "literature_source",
                "title": "Literature source",
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
               "entropy"
            ],
            "display_defaults": {
              "map_triplicate": True,
              "color_by": "clade_membership"
            },
            "metadata_columns": [
              "strain",
              "host",
              "RdRp_coverage",
              "VP1_coverage",
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
                    "name": "genogroup",
                    "displayName": "Genogroup",
                    "description": "Norovirus Genogroup (based on current tree)"
                  },
                  {
                    "name": "genotype",
                    "displayName": "Genotype",
                    "description": "Norovirus Genotype (based on current tree)"
                  },
                  {
                    "name": "variant",
                    "displayName": "Variant",
                    "description": "Norovirus Variant (based on current tree)"
                  }
                ]
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

rule assemble_dataset:
    input:
        reference=config["assemble_dataset"]["reference"],
        tree="auspice/norovirus_all_{gene}.json",
        pathogen_json=config["assemble_dataset"]["pathogen_json"],
        sequences=config["assemble_dataset"]["sequences"],
        annotation=config["assemble_dataset"]["annotation"],
        readme=config["assemble_dataset"]["readme"],
        changelog=config["assemble_dataset"]["changelog"],
    output:
        reference="datasets/{gene}/reference.fasta",
        tree="datasets/{gene}/tree.json",
        pathogen_json="datasets/{gene}/pathogen.json",
        sequences="datasets/{gene}/sequences.fasta",
        annotation="datasets/{gene}/genome_annotation.gff3",
        readme="datasets/{gene}/README.md",
        changelog="datasets/{gene}/CHANGELOG.md",
    benchmark:
        "benchmarks/{gene}/assemble_dataset.txt",
    shell:
        """
        cp {input.reference} {output.reference}
        cp {input.tree} {output.tree}
        cp {input.pathogen_json} {output.pathogen_json}
        cp {input.annotation} {output.annotation}
        cp {input.readme} {output.readme}
        cp {input.changelog} {output.changelog}
        cp {input.sequences} {output.sequences}
        """

rule test_dataset:
    input:
        tree="datasets/{gene}/tree.json",
        pathogen_json="datasets/{gene}/pathogen.json",
        sequences=config["assemble_dataset"]["sequences"],
        annotation="datasets/{gene}/genome_annotation.gff3",
        readme="datasets/{gene}/README.md",
        changelog="datasets/{gene}/CHANGELOG.md",
    output:
        outdir=directory("test_output/{gene}"),
    log:
        "logs/{gene}/test_dataset.txt",
    benchmark:
        "benchmarks/{gene}/test_dataset.txt",
    params:
        dataset_dir="datasets/{gene}",
    shell:
        """
        exec &> >(tee {log:q})

        nextclade run \
          --input-dataset {params.dataset_dir} \
          --output-all {output.outdir} \
          --silent \
          {input.sequences}
        """