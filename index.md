# Synthetic Open Schema — Overview

**Status**: Stable Specification
**Version**: v1
**Last Updated**: 2026-02-07

---

## Abstract

Synthetic Open Schema (SOS) is an open, vendor-neutral specification for defining portable, deterministic synthetic monitoring checks. This specification defines a common contract that allows synthetic checks to be defined once and executed consistently across different runners, platforms, and environments.

---

## Scope

This specification defines:

1. **Resource Model**: The base structure for all check types (apiVersion, kind, metadata, spec)
2. **Check Types**: Standard check kinds and their semantics
3. **Validation Rules**: Constraints and requirements for valid check definitions
4. **Execution Model**: Expected behavior for check execution
5. **Assertion Model**: How checks evaluate success/failure conditions
6. **Versioning**: API version semantics and compatibility guarantees

---

## Out of Scope

This specification does NOT define:

- Implementation details for runners or execution engines
- Storage, persistence, or state management
- UI, dashboards, or visualization
- Alerting or notification delivery mechanisms
- Authentication or authorization for check execution
- Multi-tenancy or access control

These concerns are left to implementations.

---

## Design Principles

1. **Vendor Neutrality**: No vendor-specific extensions in the core spec
2. **Platform Agnostic**: Runnable on any platform that supports the check types
3. **Declarative**: Checks are defined, not programmed
4. **Versioned**: Clear API versioning with compatibility guarantees
5. **Extensible**: Companies can add custom check types under their own namespace
6. **Human Readable**: YAML-based for ease of authoring and review

---

## Conformance

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

An implementation claiming conformance with Synthetic Open Schema MUST implement all REQUIRED features defined in this specification for the declared API version.

---

## Document Structure

- [Glossary](glossary.md): Terminology and definitions
- [Versioning](versioning.md): API versioning rules
- [Compatibility](compatibility.md): Compatibility guarantees
- [v1 Specification](v1/_index.md): Version 1 specification

---

## Status

This specification has reached **stable** status. API version `v1` is production-ready, having graduated from `v1beta1`.

---

## Copyright

Copyright 2024-2026 Ideatives Inc.

This specification is licensed under the Apache License, Version 2.0.
