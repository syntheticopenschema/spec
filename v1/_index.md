# Synthetic Open Schema v1

**API Version**: `v1`
**Status**: Stable
**Release Date**: 2026-02-07

---

## Overview

This directory contains the normative specification for Synthetic Open Schema version 1.

Version 1 represents the first stable release of the specification, graduating from the v1beta1 beta release.

---

## What's New in v1

### Stable API Version
- `apiVersion: v1` - Production-ready, stable specification
- Simplified versioning without vendor prefix

### New Check Types
- **DomainCheck**: Domain registration and WHOIS monitoring
  - Monitor expiration dates, nameservers, registrar, EPP status, DNSSEC

### Enhanced Features
- **TLS/SSL Dual Naming**: Both `TlsCheck` and `SslCheck` supported (aliases)
- **Custom CA Support**: TLS checks can use custom certificate authorities
- **Time to First Byte**: HTTP checks support TTFB assertion
- **Certificate Validation**: TLS checks include certificate validity assertion
- **List Assertions**: Support for list-based assertions (nameservers, status codes)

---

## Specification Documents

This version specification is organized as follows:

### Core Documents

- **[common.md](common.md)**: Shared types, fields, and concepts used across all check kinds
- **[check.md](check.md)**: Base resource model (Resource, Metadata, CheckSpec)

### Check Kind Specifications

Each check kind has its own specification document:

- **[http.md](http.md)**: HTTP/HTTPS endpoint checks
- **[tcp.md](tcp.md)**: TCP port connectivity checks
- **[tls.md](tls.md)**: TLS/SSL certificate checks
- **[dns.md](dns.md)**: DNS resolution checks
- **[domain.md](domain.md)**: Domain registration and WHOIS monitoring

**Note**: Browser checks are documented separately under `browser/v1` API version. See `../browser/v1/` directory.

---

## Supported Check Kinds (v1 API)

| Kind | Description | Status |
|------|-------------|--------|
| HttpCheck | HTTP/HTTPS endpoint monitoring | ✅ Stable |
| TcpCheck | TCP port connectivity | ✅ Stable |
| TlsCheck | TLS/SSL certificate validation | ✅ Stable |
| DnsCheck | DNS resolution | ✅ Stable |
| DomainCheck | Domain registration and WHOIS | ✅ Stable |

**Note**: `SslCheck` is an alias for `TlsCheck` (both names are supported).

**Note**: Browser checks (`LoadCheck`, `ScriptedCheck`) use separate `apiVersion: browser/v1`. See `../browser/v1/` for documentation.

---

## Resource Structure

All checks follow this structure:

```yaml
apiVersion: v1
kind: {CheckKind}
metadata:
  name: check-name
  labels:
    key: value
spec:
  # Check-specific fields
  # Common fields (interval, timeout, locations, etc.)
  # Assertions (checks)
```

---

## Common Fields

All check kinds share these fields in their `spec`:

- `interval` or `cron`: Scheduling (mutually exclusive, one required)
- `timeout`: Maximum execution time
- `retries`: Number of retry attempts
- `locations`: List of execution locations
- `channels`: Notification destinations
- `checks`: List of assertions to evaluate

See [common.md](common.md) for detailed specifications.

---

## Examples

Example configurations for all check kinds can be found in the reference implementation's `examples/` directory:

**v1 Check Examples**:
- `http-check.yaml` - HTTP/HTTPS endpoint monitoring
- `tcp-check.yaml` - TCP port connectivity
- `tls-check.yaml` - TLS certificate validation (HTTPS)
- `tls-smtp.yaml` - TLS certificate validation (SMTP)
- `ssl-check.yaml` - SSL/TLS (using SslCheck alias)
- `dns-check.yaml` - DNS resolution
- `domain-check.yaml` - Domain registration monitoring

**browser/v1 Check Examples**:
- `load-check.yaml` - Browser page load monitoring
- `scripted-check.yaml` - Browser automation scripts
- `scripted-check-with-file.yaml` - External script files

---

## JSON Schema

JSON Schema definitions for v1 are published at: https://github.com/syntheticopenschema/schemas

These schemas are generated from the reference Python implementation and can be used for validation and tooling integration.

---

## Conformance

An implementation claiming compatibility with Synthetic Open Schema v1 MUST:

1. Implement the base Resource model as defined in [check.md](check.md)
2. Support at least one check kind fully
3. Reject configurations that violate normative constraints
4. Clearly document which check kinds and features are supported
5. Handle scheduling (interval or cron) as specified
6. Evaluate assertions according to the specification

Implementations SHOULD:
- Support all stable check kinds
- Provide clear error messages for validation failures
- Support multiple execution locations
- Implement retry logic

---

## Contributing

To propose changes to this specification:
1. Open an issue describing the proposed change
2. Submit a pull request with specification updates
3. Update examples and schemas accordingly
4. Ensure backward compatibility (or document breaking change)

See [CONTRIBUTING.md](../CONTRIBUTING.md) for full guidelines.
