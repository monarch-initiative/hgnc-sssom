#!/usr/bin/env python3

import csv
import dataclasses
import sys

import click
import yaml
from koza.app import KozaApp
from koza.model.config.source_config import PrimaryFileConfig
from koza.model.source import Source
from sssom.sssom_datamodel import Mapping


@click.command()
@click.argument("input", required=True, type=click.Path())
@click.option(
    "-o",
    "--output",
    help="Output file, e.g. a SSSOM tsv file.",
    type=click.File(mode="w"),
    default=sys.stdout,
)
def main(input, output):

    with open(input, 'r') as source_fh:
        source_config = PrimaryFileConfig(**yaml.safe_load(source_fh))
        if not source_config.name:
            source_config.name = 'hgnc'

    koza_source = Source(source_config)
    koza_app = KozaApp(source=koza_source)

    writer = csv.DictWriter(
        output,
        delimiter='\t',
        fieldnames=[field.name for field in dataclasses.fields(Mapping)],
    )
    writer.writeheader()

    for row in koza_app.source:
        for uniprot_id in row['uniprot_ids'].split("|"):
            if not uniprot_id:
                continue
            mapping = Mapping(
                subject_id=row['hgnc_id'],
                subject_label=row['symbol'],
                object_id=f"UniProtKB:{uniprot_id}",
                subject_source='infores:hgnc',
                object_source='infores:uniprot',
            )
            writer.writerow(dataclasses.asdict(mapping))


if __name__ == '__main__':
    main()
