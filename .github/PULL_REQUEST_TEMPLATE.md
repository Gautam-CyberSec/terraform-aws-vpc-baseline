## What changed

<!-- One or two sentences. What does this do that main does not? -->

## Why

<!-- The problem being solved. Link an issue if there is one. -->

## Checks

- [ ] `terraform fmt -recursive` produces no diff
- [ ] `terraform validate` passes at the root
- [ ] `terraform validate` passes in both examples
- [ ] `tflint --recursive` is clean
- [ ] New or changed variables have descriptions
- [ ] No credentials, account IDs, real bucket names or internal hostnames

## Cost impact

<!-- Does this create anything that bills? If so, is it off by default? -->

- [ ] No new billable resources, or new billable resources default to disabled

## Plan output

<!-- Optional but helpful: the relevant part of `terraform plan`, redacted. -->

```
```
