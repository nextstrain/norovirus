# Nextstrain repository for Norovirus

This repository contains workflows for the analysis of Norovirus data:

- [`ingest/`](./ingest) - Download data from GenBank, clean and curate it, append Genomic Detective result columns, and upload it to S3
- [`phylogenetic/`](./phylogenetic) - Filter sequences, align, construct phylogeny and export for visualization
- [`nextclade/`](./nextclade) - Create Nextclade datasets for VP1 and RdRp groups/types/variants

Each workflow directory contains a `README.md` file with more information. The results of running both workflows are publically visible at https://nextstrain.org/staging/norovirus/all/VP1

These workflows have been refactored from an earlier norovirus analysis at https://github.com/blab/norovirus

## Installation

Follow the [standard installation instructions][] for Nextstrain's
suite of software tools.

## Quick start

Run the phylogenetic workflow by executing the following commands in
the repository checkout, after installing `nextstrain` per the above
instructions:

```bash
cd phylogenetic/
nextstrain build .
nextstrain view .
```

Further documentation is available at "[Running a pathogen workflow][]".

## Working on this repository

This repository is configured to use [pre-commit][] to help
automatically catch common coding errors and syntax issues with
changes before they are committed to the repo.


If you will be writing new code or otherwise working within this
repository, please do the following to get started:
7 years ago

1. install `pre-commit`, by running either `python -m pip install
   pre-commit` or `brew install pre-commit`, depending on your
   preferred package management solution
2. install the local git hooks by running `pre-commit install` from
   the root of the repository
3. when problems are detected, correct them in your local working tree
   before committing them.
7 years ago

Note that these pre-commit checks are also run in a GitHub Action when
changes are pushed to GitHub, so correcting issues locally will
prevent extra cycles of correction.
7 years ago

[Running a pathogen workflow]: https://docs.nextstrain.org/en/latest/tutorials/running-a-workflow.html
[pre-commit]: https://pre-commit.com
[standard installation instructions]: https://docs.nextstrain.org/en/latest/install.html

# Phylogenetic Modeling Analysis of Norovirus Reveals Varying Genotype and Gene Adaptive Mutation Rates

Allison Li, John Huddleston, Katie Kistler, Trevor Bedford

University of Washington, Fred Hutchinson Cancer Center (VIDD)

Full analysis in: https://nextstrain.org/staging/norovirus/all/VP1

## Adaptive Evolution
<p align="center">
     <img src="images/all-genes-norovirus-plot.png" alt="norovirus all strains plot" width="300"/>
</p>

<img src="images/norovirus_adaptation_accumulation.png" alt="norovirus all genes plot" width="400"/><img src="images/norovirus_gii4_rates_allgenes_new.png" alt="norovirus comparison plot" width="400"/>

## Analysis

From our analysis, we found that out of all the genotypes in the dataset, GII.4 had the highest rate of adaptive mutations, followed by GII.3. Out of the genes, we found that the VP1 protein had the highest adaptive mutation rate, followed by P22 and VP2. Based on our data, we can hypothesize that VP1, P22, and VP2 are possibly undergoing immune evasion, and could be potential targets for vaccine development. We can also hypothesize that if a vaccine were to be developed for the GII.4 genotype, it would need to be updated rather regularly to match the mutation rate of the virus.

## Further Reading
Relevant papers for further reading:
* [Norwalk Virus Minor Capsid Protein VP2 Associates within the VP1 Shell Domain](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3624303/)
* [Deep Sequencing of Norovirus Genomes Defines Evolutionary Patterns in an Urban Tropical Setting](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4178781/)
