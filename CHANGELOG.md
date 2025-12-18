# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes,
and config value changes that may affect both the usage of the workflows and
the outputs of the workflows.

## 2025

* 18 December 2025: phylogenetic - drop separate "VP1 Genotype (Nextclade)" and "RdRp Genotype (Nextclade)" coloring options since we already have [VP1|RdRp] group, type, and variant coloring ([#45][])
* 29 October 2025: phylogenetic and nextclade - use Snakemake threads for `align` and `tree` rules ([#41][])
  The default is set to 1 thread for `align` and `tree` because this was faster
  on GitHub Actions with 4 cores. If you are running the workflow on a larger machine
  and want to increase the number of threads, use `--set-threads` to override the default.

* 22 October 2025: phylogenetic - Update alignment reference to RefSeq ([#37][])
  * GII.4 reference used for the all builds had a truncated VP2
  * Update builds to the RefSeq references instead where possible

* 15 October 2025: phylogenetic and nextclade - Update to color handling ([#34][])
  * phylogenetic colors - generate one colors.tsv to be used with all builds for consistency
  * nextclade colors - generate separate colors.tsv files per dataset since clade_membership may be different

* 15 October 2025: phylogenetic and nextclade - Major update to the definition of inputs. ([#34][])
  * Switch to use shared/vendor scripts in workflows where possible

The configuration has been updated from top level keys:

```yaml
sequences_url: "https://data.nextstrain.org/files/workflows/norovirus/sequences.fasta.zst"
metadata_url: "https://data.nextstrain.org/files/workflows/norovirus/metadata.tsv.zst"
```

to named dictionary key of multiple inputs:

```yaml
inputs:
  - name: ncbi
    metadata: "https://data.nextstrain.org/files/workflows/norovirus/metadata.tsv.zst"
    sequences: "https://data.nextstrain.org/files/workflows/norovirus/sequences.fasta.zst"
```

[#34]: https://github.com/nextstrain/norovirus/pull/34
[#37]: https://github.com/nextstrain/norovirus/pull/37
[#41]: https://github.com/nextstrain/norovirus/pull/41
[#45]: https://github.com/nextstrain/norovirus/pull/45
