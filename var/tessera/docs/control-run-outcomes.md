# Control run outcomes and empty affected scans

Available in TESSERA-Base 0.0.153. Installation and worker reload are required before adding the new option to live policy.

Execution and assessment are separate outcomes. A completed scan can assess Pass, Fail or N/A. Fail describes a policy violation, not a failure to execute. An execution error leaves the assessment Unknown; it must never be converted to Pass.

For VERSION 1 PolicyEvaluation programs using ON FAIL / DESCENDANTS / AFFECTED, add this sibling of DESCENDANTS and AFFECTED inside ON FAIL:

```yaml
ON FAIL:
  ON NO AFFECTED:
    RETURN: Pass
    REASON: No deployed assets are affected by this Product.
  # Keep the existing DESCENDANTS and AFFECTED mappings here.
```

RETURN accepts exactly Pass or N/A; REASON is optional scalar text. This branch applies only after the complete descendant traversal and all affected-object searches succeed and produce zero findings. It does not skip assets missing Application references, incomplete searches, invalid dates or traversal limit errors. Existing programs without the option retain their behavior. This option is not supported with EMIT FINDING or FOR EACH SELECTED. ON EMPTY remains a separate guard for an empty source field.

Automatic Control execution errors are always recorded in the Control's Activity Articles without requiring YAML opt-in. The article includes attempted UTC time, execution Error, assessment Unknown and bounded error reason. The previous stored result and ZRM-LastRun remain unchanged so the failed attempt does not suppress retries. Successful target evaluations record execution Completed and their assessment result/reason, then advance ZRM-LastRun. Article creation time records when evidence was written. No new Dynamic Fields are introduced.

If evidence storage itself fails, the result reports ErrorArticleRecorded=0 and the system log records the failure. Article delivery cannot be guaranteed when its database is unavailable. Retries can create a separate error article for each actual attempt. Risk effects already committed before an error are not rolled back; existing identity/reuse behavior remains responsible for retry safety.

This release does not change customer-authored GovernanceObjects during upgrades, correct unknown asset Application assignments, or change risk lifecycle catalog entries. Install the runtime first, then add the option to the applicable EOS PolicyEvaluation Set. Control4141's observed missing group reference remains a separate data/hydration issue.
