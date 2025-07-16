#! /usr/bin/env python
import argparse
import pandas as pd

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
      "--chunksize",
      type=int,
      default=1000,
      help="Chunk size for reading TSV"
    )
    parser.add_argument(
      "--output",
      default="coverages.tsv",
      help="Output TSV filename where gene_coverage columns are appended to input TSV file"
    )
    return parser.parse_args()


def parse_coverage_field(field_value, genes, round_digits=None):
    """Convert a coverage string like '3CLpro:1,NTPase:0.99' into a dict for selected genes."""
    gene_dict = {}

    # Set gene order and default to 0.0
    for gene in genes:
        gene_dict[f"{gene}_coverage"] = float(0.0)

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
                gene_dict[f"{gene}_coverage"] = value
            except ValueError:
                gene_dict[f"{gene}_coverage"] = None

    return gene_dict

def process_chunk(chunk, cds_coverage_col, genes, round_digits=None):
    """For each row, parse gene coverages and append as new columns."""
    coverage_dicts = []

    for _, row in chunk.iterrows():
        field_val = row.get(cds_coverage_col, "")
        if pd.notna(field_val):
            parsed = parse_coverage_field(str(field_val), genes, round_digits)
        else:
            parsed = {f"{gene}_coverage": None for gene in genes}
        coverage_dicts.append(parsed)

    coverage_df = pd.DataFrame(coverage_dicts, index=chunk.index)
    return pd.concat([chunk, coverage_df], axis=1)

def main():
    args = parse_args()

    genes = args.genes.split(",")
    output_file = args.output

    with open(output_file, "w", encoding="utf-8") as f_out:
        first_chunk = True
        for chunk in pd.read_csv(args.metadata, sep="\t", chunksize=args.chunksize):
            processed_chunk = process_chunk(chunk, args.cdsCoverage, genes, round_digits=args.round)
            processed_chunk.to_csv(f_out, sep="\t", index=False, header=first_chunk, mode="a")
            first_chunk = False

    print(f"Done. Output written to: {output_file}")

if __name__ == "__main__":
    main()
