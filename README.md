# Synthetic Open Schema — Specification

![Version](https://img.shields.io/badge/version-v1-blue) ![Status](https://img.shields.io/badge/status-stable-green) ![License](https://img.shields.io/badge/license-Apache%202.0-blue)

Synthetic Open Schema (SOS) is an open, vendor-neutral specification for defining portable, deterministic synthetic checks.

The goal of SOS is to provide a common contract that allows synthetic checks to be defined once and executed consistently across different runners, platforms, and environments.

This repository contains the **normative specification** for Synthetic Open Schema.

---

## What this is

Synthetic Open Schema defines:

* A common object model for synthetic checks
* Supported check kinds and their semantics
* Validation rules and constraints
* Versioning and compatibility guarantees
* Conformance requirements for implementations

The specification is written in human-readable, RFC-style Markdown and is intended to be language- and platform-agnostic.

---

## What this is not

Synthetic Open Schema is **not**:

* A product
* A runner or execution engine
* A monitoring platform
* A UI or dashboard
* A vendor-specific format

Those concerns are intentionally out of scope.

---

## Repository structure

```
spec/
├── README.md          # This file
├── CHANGELOG.md       # Version history and release notes
├── index.md           # Specification overview and scope
├── glossary.md        # Terminology and normative language
├── versioning.md      # Versioning and compatibility rules
├── compatibility.md   # Forward/backward compatibility guarantees
├── v1/
│   ├── _index.md      # Version overview
│   ├── check.md       # Base check definition
│   ├── common.md      # Shared fields and concepts
│   ├── http.md        # HTTP check specification
│   ├── dns.md         # DNS check specification
│   ├── tcp.md         # TCP check specification
│   ├── tls.md         # TLS check specification
│   └── domain.md      # Domain registration check specification
└── browser/
    └── v1/
        ├── _index.md           # Browser checks overview
        ├── load_check.md       # LoadCheck specification
        └── scripted_check.md   # ScriptedCheck specification
```

---

## Supported check kinds

### Core Checks (v1)

Declarative checks with assertion-based validation:

* **HttpCheck** - HTTP/HTTPS endpoint monitoring
* **TcpCheck** - TCP port connectivity
* **DnsCheck** - DNS resolution validation
* **TlsCheck** / **SslCheck** - TLS/SSL certificate monitoring
* **DomainCheck** - Domain registration checks

### Browser Checks (browser/v1)

Programmatic browser automation checks:

* **LoadCheck** - Passive page load and performance monitoring
* **ScriptedCheck** - Active browser automation with custom scripts

Each check kind has a dedicated specification describing its fields, execution model, and assertion semantics.

---

## Conformance

An implementation claiming compatibility with Synthetic Open Schema MUST:

* Implement the base check model as defined in the specification
* Support all required check kinds for the declared version
* Reject configurations that violate normative constraints
* Clearly document which optional features are supported

Conformance requirements are defined per specification version.

---

## Relationship to implementations

This repository defines **what** a Synthetic Open Schema check is.

Reference implementations, runners, tooling, and generated artifacts live in separate repositories and MUST treat this specification as the source of truth.

### Reference Implementations

- **Python Model**: https://github.com/syntheticopenschema/model
- **Python Runner**: https://github.com/syntheticopenschema/runner
- **JSON Schemas**: https://github.com/syntheticopenschema/schemas


---

## Examples

Complete, tested YAML example configurations live in the **model repository** and are validated against the implementation:

**Core Checks (v1):**
- [http-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/http-check.yaml) - HTTP endpoint monitoring
- [tcp-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/tcp-check.yaml) - TCP service monitoring
- [ssl-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/ssl-check.yaml) - TLS/SSL certificate monitoring
- [dns-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/dns-check.yaml) - DNS resolution monitoring

**Browser Checks (browser/v1):**
- [load-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/load-check.yaml) - Page load and performance monitoring
- [scripted-check.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/scripted-check.yaml) - Browser automation with inline script
- [scripted-check-with-file.yaml](https://github.com/syntheticopenschema/model/blob/main/src/examples/scripted-check-with-file.yaml) - Browser automation with external script

> **Why examples are in the model repo:** Examples are unit tested to ensure they remain valid as the implementation evolves. This prevents stale or broken examples in the specification.

---

## Release Notes

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

**Current Version**: v1.0.0 (Stable) - Released 2026-02-07

---

## Governance

Synthetic Open Schema is an open specification stewarded by **Ideatives Inc.**

The project is developed in the open, and contributions are welcome.

Governance, contribution guidelines, and decision-making processes are documented within this repository.

---

## Contributing

We welcome contributions from the community! Check out the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to the Synthetic Open Schema project.

---

## License

This specification is licensed under the **Apache License, Version 2.0**.

See the [LICENSE](LICENSE) file for details.
