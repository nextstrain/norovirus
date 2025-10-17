# Genome Detective

Genome metadata annotation files were feteched from the genomic detective norovirus typing tool.

Steps for creating genomic detective annotation files:
1. Break sequences.fasta file into multiple files (<1000 sequences each) using *`seqkit split sequences_vipr.fasta -n (total number of sequences/number of files)`
      * Ex. for 1981 sequences, n = 703 for 703,703, 575 sequences in 3 output files
2. Put all output files into [norovirus typing tool](https://www.genomedetective.com/app/typingtool/nov/). **Be aware that this step might take a very long time to process, depending on how many sequences you pass in**. For example, ~2000 sequences took 24 hours for the tool to fully annotate.
3. Place resulting csv files in the data folder, naming them genomicdetective_results1...2...3, etc for however many output files you have