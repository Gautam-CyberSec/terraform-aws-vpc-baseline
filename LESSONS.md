# Engineering Decisions &amp; Lessons Learned

Mistakes made while building this module and what each one changed. Every entry
below actually happened during development; none are illustrative.

Each lesson records **Problem**, **Cause**, **Discovery**, **Fix** and the
**Engineering Principle** that now prevents it.

---

## 1. A documented security control that did not work

**Problem**
`README.md` and `SECURITY.md` both stated that `readable_s3_bucket_arns` rejects
wildcards. It did not. `arn:aws:s3:::*` passed validation, which would have
granted the EC2 instance role read access to **every bucket in the account** —
the exact outcome the variable exists to prevent.

**Cause**
The validation matched only the ARN *prefix*:

```hcl
can(regex("^arn:aws[a-z-]*:s3:::", a))
```

It confirmed the string looked like an S3 ARN and never checked that it named one
bucket. Prefix matching resembles validation closely enough to pass review.

**Discovery**
Found during a self-directed review pass, by choosing to execute the claim rather
than re-read it:

```
$ echo 'can(regex("^arn:aws[a-z-]*:s3:::", "arn:aws:s3:::*"))' | terraform console
true
```

No linter, test or CI job flagged this. `tflint` reported zero findings and
`terraform validate` passed throughout — the configuration was valid, it just did
not do what the documentation said.

**Fix**
Match the bucket name against S3's own naming rules, which a bare `*` cannot
satisfy. Both the wildcard rejection and a legitimate ARN were confirmed in
`terraform console` before the change was committed (`f34ffda`).

**Engineering Principle**
*A security control described in documentation must be exercised with a hostile
input.* A control that is only asserted is worse than an absent one: it buys
confidence without providing protection, and the documentation hides the gap from
the next reader.

---

## 2. A drift check that failed on the commit that introduced it

**Problem**
The `terraform-docs` CI job was added to stop the generated variable tables
falling behind the code. It failed immediately — on its own commit and every
commit after — with `Uncommitted change(s) has been found!`, while `make docs`
produced no diff locally.

**Cause**
`terraform-docs/gh-actions` runs its own container image at a different version
and passes CLI flags that override `.terraform-docs.yml`. The tables it generated
could never match the ones committed from the local config, so the check reported
drift permanently.

**Discovery**
The CI run on `main` went red. Reading the job log showed the action invoking
`terraform-docs` with its own `--output-format`, `--template` and `--indention`
arguments, none of which came from the committed config.

**Fix**
Removed the action. CI now installs a pinned `terraform-docs` binary and runs the
same `make docs-check` target a developer runs, so both produce identical output.

**Engineering Principle**
*Prefer a pinned binary over a third-party action wrapping the same tool, and
make CI run the exact command a developer runs.* If `make check` passes locally
and CI disagrees, CI is measuring something else. A check that always fails gets
ignored, then deleted — worse than never adding it.

---

## 3. Pinning a version is not the same as being able to install it

**Problem**
`brew install terraform` failed while setting up the toolchain. `brew install
tflint` failed too, with Homebrew suggesting `flint` instead.

**Cause**
Both tools moved to vendor-managed taps after HashiCorp's licence change —
`hashicorp/tap/terraform` and `terraform-linters/tap/tflint`. The package names
were unchanged; the distribution channel was not.

**Discovery**
Immediate local failure during environment setup, before any code was written.

**Fix**
Install from the vendor taps, and pin `terraform_version: "1.15.8"` in CI so the
toolchain is explicit rather than whatever the runner happens to ship.

**Engineering Principle**
*Record where a tool comes from, not only which version.* A version number is not
a working install instruction once distribution changes underneath it.

---

## 4. The repository tried to be a root configuration and a reusable module at once

**Problem**
The root module declares a `provider "aws"` block so it can be applied directly,
while the README told consumers to use
`source = "github.com/Gautam-CyberSec/terraform-aws-vpc-baseline"`. Terraform
permits a provider block inside a child module but strongly discourages it: the
caller cannot pass `providers = {}`, and `count` or `for_each` on the module
become errors.

**Cause**
Two goals were served by one artefact without deciding which it was. Being
directly runnable requires a provider block; being a reusable module requires
its absence.

**Discovery**
Found during a self-directed senior-engineer review of the finished repository.
No tool reported it — `terraform validate`, `tflint` and `fmt` were all clean,
because the configuration is legal. It only fails for a *consumer*, at their plan
time, not for this repository.

**Fix**
The README now points module consumers at `modules/network` and `modules/iam`,
neither of which carries provider configuration. The root remains a runnable
reference for anyone who wants to apply it as-is.

**Engineering Principle**
*Decide whether an artefact is a root configuration or a reusable component, and
say which in the documentation.* Serving both without saying so hands the caller
a constraint they discover only when their own build breaks.

---

## What this repository does differently as a result

- Variable validation is exercised with a hostile input in `terraform console`
  rather than reasoned about.
- CI installs pinned binaries and runs the same `make` targets a developer runs,
  so local and CI cannot disagree about what passing means.
- Module documentation is generated and drift-checked, so the variable tables
  cannot fall behind the code.
- Consumers are directed at the child modules, which carry no provider block.
