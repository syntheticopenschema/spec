# Glossary

This document defines terminology used throughout the Synthetic Open Schema specification.

---

## RFC 2119 Keywords

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

---

## Terms

### Check
A declarative definition of a synthetic monitoring test, including what to monitor, how to evaluate it, and when to run it.

### Check Kind
The type of check (e.g., HttpCheck, TcpCheck, DnsCheck). Determines the fields available in the spec and the execution semantics.

### Resource
The base model for all check definitions, containing `apiVersion`, `kind`, `metadata`, and `spec` fields.

### Assertion
A condition that must be evaluated to determine if a check passes or fails. Multiple assertions can be defined per check.

### Runner
An implementation that executes checks according to this specification. Runners are responsible for performing the check and evaluating assertions.

### Spec
The `spec` field in a check definition, containing check-specific configuration (URL, timeout, assertions, etc.).

### Metadata
The `metadata` field in a check definition, containing identifying information like name and labels.

### API Version
The version of the schema specification a check conforms to (e.g., `v1`, `v1beta1`).

### Interval
A time duration specifying how frequently a check should be executed (e.g., `1m`, `30s`).

### Cron
A cron expression specifying when a check should be executed, using standard cron syntax.

### Location
A geographic region or execution environment where a check should run (e.g., `us-east-1`, `eu-west-1`).

### Channel
A notification destination for check results (e.g., webhook, email, Slack).

### Timeout
The maximum duration allowed for a check to complete before it is considered failed.

### Retry
The number of times a failed check should be re-attempted before marking it as definitively failed.

### Operator
A comparison operation used in assertions (e.g., `equals`, `contains`, `greaterThan`).

---

## Normative vs. Informative

- **Normative**: Requirements that implementations MUST follow to claim conformance
- **Informative**: Explanatory material, examples, and recommendations that are not requirements

Unless explicitly marked as informative, all content in this specification is normative.
