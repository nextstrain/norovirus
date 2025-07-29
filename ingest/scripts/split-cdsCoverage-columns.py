#! /usr/bin/env python
import argparse
import csv

def parse_args():
    parser = argparse.ArgumentParser(
        description="Split up the aggregated cdsCoverage column from nextclade.tsv into gene_coverage columns",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--metadata",
        required=True,
        help="Path to the metadata.tsv or nextclade.tsv file"
    )
    parser.add_argument(
      "--genes",
      required=True,
      help="Comma-separated list of genes (e.g., '3CLpro,NTPase') to convert to coverage"
    )
    parser.add_argument(
      "--suffix",
      default="_coverage",
      help="Suffix to append to the gene name to create the new column name (e.g. 'gene'+'_coverage')."
    )
    parser.add_argument(
      "--cdsCoverage",
      default="cdsCoverage",
      help="Column with gene coverage string"
    )
    parser.add_argument(
      "--round",
      type=int,
      default=None,
      help="If defined, round to this number of decimal places"
    )
    parser.add_argument(
      "--output",
      default="coverages.tsv",
      help="Output TSV filename where gene_coverage columns are appended to input TSV file"
    )
    return parser.parse_args()


def parse_coverage_field(field_value, genes, round_digits=None, suffix="_coverage"):
    """Convert a coverage string like '3CLpro:1,NTPase:0.99' into a dict for selected genes."""
    gene_dict = {
        f"{gene}{suffix}": float(0.0)
        for gene in genes
    }

    for item in field_value.split(","):
        if ":" not in item:
            continue
        gene, val = item.split(":")
        # Set recognized genes to value
        if gene in genes:
            try:
                value = float(val)

                # Optionally round the value, especially for excell which may auto convert long float values to text
                if round_digits is not None:
                    value = round(value, round_digits)

                # Add original or rounded value to dictionary
                gene_dict[f"{gene}{suffix}"] = value
            except ValueError as e:
                raise ValueError(f'ERROR: Value "{val}" is not a number in "{gene}:{val}". Check if the column is correctly formatted.') from e

    return gene_dict


def main():
    args = parse_args()

    genes = args.genes.split(",")
    output_file = args.output

    with open(args.metadata, "r", encoding="utf-8", newline="") as infile, open(args.output, "w", encoding="utf-8", newline='') as outfile:
        reader = csv.DictReader(infile, delimiter="\t")
        # If --cdsCoverage column doesn't exist, exit early
        if args.cdsCoverage not in reader.fieldnames:
            raise ValueError(f"The column '{args.cdsCoverage}' does not exist in the metadata '{args.metadata}'")

        # Defer defining the writer until we process the first row, to avoid fieldname mismatch
        writer = None

        # Parse gene_coverage values
        for row in reader:
            field_val = row.get(args.cdsCoverage, "")
            gene_coverage_dict = parse_coverage_field(field_val, genes, args.round, args.suffix)
            row.update(gene_coverage_dict)

            # Only initialize writer and print header on first iteration
            if writer is None:
                writer = csv.DictWriter(outfile, fieldnames=list(row), delimiter="\t")
                writer.writeheader()

            # Write row on every iteration
            writer.writerow(row)

    print(f"Done. Output written to: {output_file}")

if __name__ == "__main__":
    main()
