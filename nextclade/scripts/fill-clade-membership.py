#!/usr/bin/env python3

import csv
import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description="If clade_membership is empty, fill with MuV_genotype value",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--input-metadata",
        type=str,
        required=True,
        help="Path to input metadata TSV file",
    )
    parser.add_argument(
        "--output-metadata",
        type=str,
        required=True,
        help="Path to output metadata TSV file",
    )
    parser.add_argument(
        "--clade-membership-column",
        type=str,
        default="clade_membership",
        help="Name of the column to fill if empty",
    )
    parser.add_argument(
        "--genotype-column",
        type=str,
        default="MuV_genotype",
        help="Name of the column to use as a fallback",
    )
    return parser.parse_args()

def fill_clade_membership(input_path, output_path, clade_membership_col, fill_col):
    with open(input_path, newline='', encoding='utf-8') as infile, \
         open(output_path, 'w', newline='', encoding='utf-8') as outfile:

        reader = csv.DictReader(infile, delimiter='\t')
        fieldnames = reader.fieldnames

        if clade_membership_col not in fieldnames or fill_col not in fieldnames:
            raise ValueError(f"Input file must contain '{clade_membership_col}' and '{fill_col}' columns")

        writer = csv.DictWriter(outfile, fieldnames=fieldnames, delimiter='\t')
        writer.writeheader()

        for row in reader:
            if row.get(clade_membership_col, '').strip() == '':
                fill_val = row.get(fill_col, '').strip()
                if fill_val and fill_val.split(' ', 1)[0] != "Could":
                    # only keep substring before first space
                    row[clade_membership_col] = fill_val.split(' ', 1)[0]
            writer.writerow(row)

def main():
    args = parse_args()
    fill_clade_membership(
        args.input_metadata,
        args.output_metadata,
        args.clade_membership_column,
        args.genotype_column
    )

if __name__ == '__main__':
    main()
