"""
This part of the workflow handles automatic deployments of the mumps build.

Uploads the build defined as the default output of the workflow through
the `all` rule from Snakefille
"""

# Copied from: https://github.com/nextstrain/ncov/blob/60d4bca0932a379bb88c493f88b7b3249edc581e/workflow/snakemake_rules/export_for_nextstrain.smk#L332C1-L354C62
#
# We limit the number of concurrent `nextstrain deploy` jobs by using a custom
# resource, concurrent_deploys, for the rule deploy_single (below).  This is
# because each `nextstrain deploy` to production currently performs a
# CloudFront wildcard invalidation, and these invalidations have a concurrency
# limit of 15 per CloudFront distribution.¹
#
# Set a default for concurrent_deploys so workflow invocations don't have to
# specify it with --resources or profile config.  This is particularly
# important because using --resources (or the equivalent profile config)
# conflicts with `nextstrain build`'s automatic passing thru of allocated
# memory to Snakemake.²
#
# The default is a very conservative 2 because `nextstrain deploy` does not
# always wait for invalidation completion before exiting, and thus
# invalidations may still be running even though the Snakemake job that started
# it is not.  We also typically have multiple workflow runs occurring
# simultaneously (e.g. GISAID and Open), and the limit of 15 is effectively
# shared between them.
#   -trs, 1 Feb 2023
#
# ¹ <https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html#limits-invalidations>
# ² <https://github.com/nextstrain/cli/blob/017c5380/nextstrain/cli/command/build.py#L149-L166>
workflow.global_resources.setdefault("concurrent_deploys", 2)

rule deploy_single:
    input:
        auspice_json="auspice/norovirus_{group}_{gene}.json",
        tip_frequencies_json= "auspice/norovirus_{group}_{gene}_tip-frequencies.json",
    output:
        success_flag=touch("auspice/{group}_{gene}.deployed"),
    params:
        deploy_url = config["deploy_url"]
    resources:
        concurrent_deploys = 1
    shell:
        """
        nextstrain remote upload {params.deploy_url} {input}
        """

rule deploy_all:
    input: expand("auspice/{group}_{gene}.deployed", group=GROUPS, gene=GENES),
    output: touch("results/deploy_all.done")
