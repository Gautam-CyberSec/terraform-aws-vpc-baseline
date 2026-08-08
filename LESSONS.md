# Engineering Decisions &amp; Lessons Learned

Mistakes made while building this module, and what each one changed. Every entry
actually happened during development.

---

## 1. A documented security control that did not work

**What happened.** The README and `SECURITY.md` both stated that
`readable_s3_bucket_arns` rejects wildcards. Checking the claim rather than
trusting it:

```
$ echo 'can(regex("^arn:aws[a-z-]*:s3:::", "arn:aws:s3:::*"))' | terraform console
true
```

`arn:aws:s3:::*` passed. The validation would have accepted a value granting the
instance role read access to **every bucket in the account** — the precise
outcome the variable exists to prevent.

**Why.** The rule matched only the ARN *prefix*. It confirmed the string looked
like an S3 ARN and never checked that it named one bucket. Prefix matching feels
like validation and stops well short of it.

**Fix.** Match the bucket name against S3's own naming rules, which a bare `*`
cannot satisfy. Both the wildcard rejection and a legitimate ARN were verified in
`terraform console` before the change shipped.

**Principle.** *A security control stated in documentation must be exercised with
a hostile input.* A control that is only asserted is worse than an absent one: it
buys confidence without providing protection, and the documentation makes the gap
invisible.

---

## 2. A drift check that failed on the commit introducing it

**What happened.** The `terraform-docs` job was added to keep the generated
variable tables honest. It failed immediately — on its own commit, and on every
commit after — with `Uncommitted change(s) has been found!`, even though
`make docs` produced no diff locally.

**Why.** `terraform-docs/gh-actions` runs its own container image at a different
version and passes CLI flags that override `.terraform-docs.yml`. The tables it
generated could never match the ones committed from the local config, so the
check reported drift permanently.

**Fix.** Drop the action. Install a pinned `terraform-docs` binary and run the
same `make docs-check` target a developer runs.

**Principle.** *Prefer a pinned binary over a third-party action wrapping the
same tool, and make CI run the exact command a developer runs.* If `make check`
passes locally and CI disagrees, CI is measuring something else — and a check
that always fails gets ignored, then removed, which is worse than never adding it.

---

## 3. Pinning is not the same as being able to install

**What happened.** The `brew install terraform` used to set up the toolchain
failed: Homebrew no longer carries the formula after HashiCorp's licence change.
`brew install tflint` failed too, suggesting `flint` instead.

**Why.** Both moved to vendor-managed taps — `hashicorp/tap/terraform` and
`terraform-linters/tap/tflint`. The package names had not changed; the
distribution had.

**Fix.** Install from the vendor taps, and pin `terraform_version: "1.15.8"` in
CI so the toolchain is explicit rather than whatever the runner happens to
provide.

**Principle.** *Record the source of a tool, not only its version.* A version
number is not a working install instruction when distribution changes underneath
it.

---

## 4. The repository tried to be a root configuration and a reusable module at once

**What happened.** The root module declares a `provider "aws"` block so it can be
applied directly, and the README originally showed consumers using
`source = "github.com/Gautam-CyberSec/terraform-aws-vpc-baseline"`.

**Why.** Terraform permits a `provider` block inside a child module but strongly
discourages it: the caller cannot pass `providers = {}`, and `count` or
`for_each` on the module become errors. The repository was quietly handing
consumers a module that would fail as soon as they did anything non-trivial with
it.

**Fix.** The README now points module consumers at `modules/network` and
`modules/iam`, which carry no provider configuration. The root remains a runnable
reference for people who want to apply it as-is.

**Principle.** *Decide whether an artefact is a root configuration or a reusable
component, and say which in the documentation.* Trying to be both without saying
so hands the caller a constraint they find out about at plan time.

---

## What this repository does differently as a result

- Variable validation is checked with a hostile input in `terraform console`, not
  reasoned about.
- CI installs pinned binaries and runs the same `make` targets a developer runs,
  so local and CI cannot disagree.
- Module documentation is generated and drift-checked, so the variable tables
  cannot fall behind the code.
- Consumers are pointed at the child modules, which have no provider block.
