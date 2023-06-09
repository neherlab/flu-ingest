"""
This part of the workflow handles fetching sequences from various sources.
Uses `config.sources` to determine which sequences to include in final output.

Currently only fetches sequences from GenBank, but other sources can be
defined in the config. If adding other sources, add a new rule upstream
of rule `fetch_all_sequences` to create the file `data/{source}.ndjson` or the
file must exist as a static file in the repo.

Produces final output as

    sequences_ndjson = "data/sequences.ndjson"

"""


rule fetch_from_genbank:
    output:
        genbank_ndjson="data/genbank_{lineage}_{segment}.ndjson",
    params:
        lineage = lambda w: w.lineage,
        segment = lambda w: w.segment,
    shell:
        """
        ./bin/fetch-from-genbank {params.lineage} {params.segment} > {output.genbank_ndjson}
        """


def _get_all_sources(wildcards):
    return [f"data/{source}_{wildcards.lineage}_{wildcards.segment}.ndjson" for source in config["sources"]]


rule fetch_all_sequences:
    input:
        all_sources=_get_all_sources,
    output:
        sequences_ndjson="data/sequences_{lineage}_{segment}.ndjson",
    shell:
        """
        cat {input.all_sources} > {output.sequences_ndjson}
        """
