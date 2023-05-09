if not config:

    configfile: "config/config.yaml"


send_slack_notifications = config.get("send_slack_notifications", False)


def _get_all_targets(wildcards):
    # Default targets are the metadata TSV and sequences FASTA files
    all_targets = ["data/sequences.fasta", "data/metadata.tsv"]

    # Add additional targets based on upload config
    upload_config = config.get("upload", {})

    for target, params in upload_config.items():
        files_to_upload = params.get("files_to_upload", [])
        remote_file_names = params.get("remote_file_names", [])

        if len(files_to_upload) != len(remote_file_names):
            print(
                f"Skipping file upload for {target!r} because the number of",
                "files to upload does not match the number of remote file names.",
            )
        elif len(remote_file_names) != len(set(remote_file_names)):
            print(
                f"Skipping file upload for {target!r} because there are duplicate remote file names."
            )
        elif not params.get("dst"):
            print(
                f"Skipping file upload for {target!r} because the destintion was not defined."
            )
        else:
            all_targets.extend(
                expand(
                    [
                        f"data/upload/{target}/{{file_to_upload}}-to-{{remote_file_name}}.done"
                    ],
                    zip,
                    file_to_upload=files_to_upload,
                    remote_file_name=remote_file_names,
                )
            )

    # Add additional targets for Nextstrain's internal Slack notifications
    if send_slack_notifications:
        all_targets.extend(
            [
                "data/notify/genbank-record-change.done",
                "data/notify/metadata-diff.done",
            ]
        )

    if config.get("trigger_rebuild"):
        all_targets.append("data/trigger/rebuild.done")

    return all_targets


rule all:
    input:
        _get_all_targets,


include: "workflow/snakemake_rules/fetch_sequences.smk"
include: "workflow/snakemake_rules/transform.smk"
include: "workflow/snakemake_rules/nextclade.smk"


if config.get("upload"):

    include: "workflow/snakemake_rules/upload.smk"


if send_slack_notifications:

    include: "workflow/snakemake_rules/slack_notifications.smk"


if config.get("trigger_rebuild"):

    include: "workflow/snakemake_rules/trigger_rebuild.smk"
