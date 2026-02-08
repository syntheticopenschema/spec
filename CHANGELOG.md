# Changelog

All notable changes to the Synthetic Open Schema specification will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-02-07

### 🎉 v1 Stable Release

First stable release of Synthetic Open Schema, graduating from v1beta1 beta version.

### Added

#### Core API (`apiVersion: v1`)

- **HttpCheck**: HTTP/HTTPS endpoint monitoring
  - Status code assertions
  - Response time (duration) assertions
  - Time to first byte (TTFB) assertions
  - Header validation
  - Body content matching
  - Custom HTTP methods, headers, and body
  - TLS certificate validation
  - Redirect handling

- **TcpCheck**: TCP port connectivity checks
  - Connection establishment validation
  - Duration assertions
  - Optional response content validation

- **DnsCheck**: DNS resolution validation
  - A, AAAA, CNAME, MX, TXT, NS, PTR record types
  - IP address validation
  - Record value assertions
  - Resolution time monitoring

- **TlsCheck** (alias: **SslCheck**): TLS/SSL certificate monitoring
  - Certificate expiration validation
  - Certificate validity assertions
  - Issuer validation
  - Subject name validation
  - Custom CA certificate support
  - Support for HTTPS and STARTTLS protocols (SMTP, IMAP, etc.)

- **DomainCheck**: Domain registration and WHOIS monitoring
  - Domain expiration tracking
  - Nameserver validation
  - Registrar monitoring
  - EPP status code validation
  - DNSSEC status validation

#### Browser API (`apiVersion: browser/v1`)

- **LoadCheck**: Browser page load monitoring
  - Real browser rendering (Chromium, Firefox, WebKit)
  - Performance metrics (FCP, LCP, DOM load, page load)
  - Network timing
  - Resource counts
  - Console message capture
  - Screenshot capture
  - Custom viewport and user agent
  - Cookie injection
  - Basic authentication

- **ScriptedCheck**: Browser automation with custom scripts
  - Playwright-based scripting
  - Inline or external script files
  - Custom script parameters
  - Hybrid validation (scripts + assertions)
  - Console output capture
  - Screenshot capture
  - Same browser configuration as LoadCheck

#### Base Specification

- **Resource Model**: Kubernetes-style structure (`apiVersion`, `kind`, `metadata`, `spec`)
- **Metadata**: Names, titles, labels for organization
- **Scheduling**: Interval-based (`1m`, `5s`) or cron expressions
- **Locations**: Multi-location execution support
- **Channels**: Notification destination references
- **Retries**: Configurable retry logic with delays
- **Timeouts**: Per-check execution timeouts

#### Assertion Types

- **Numeric Assertions**: `equals`, `notEquals`, `greaterThan`, `lessThan`, `greaterThanOrEqual`, `lessThanOrEqual`
- **String Assertions**: `equals`, `notEquals`, `contains`, `notContains`, `matches` (regex)
- **Boolean Assertions**: `equals`, `notEquals`
- **Time-based Assertions**: Duration/timeout validation
- **List Assertions**: `contains`, `notContains`, `containsAny`, `containsAll`
- **KeyValue Assertions**: Header/metadata validation

#### Documentation

- **Specification Documents**: 21 comprehensive markdown files
  - Base model definition (`check.md`)
  - Common types and fields (`common.md`)
  - Per-check-kind specifications (8 files)
  - Versioning and compatibility docs

- **Governance Documents**:
  - `GOVERNANCE.md`: Decision-making process, RFC workflow
  - `SECURITY.md`: Security disclosure policy
  - `CONTRIBUTING.md`: Contribution guidelines
  - `CODE_OF_CONDUCT.md`: Community standards

- **Policy Documents**:
  - `versioning.md`: API versioning strategy
  - `compatibility.md`: Backward/forward compatibility guarantees
  - `glossary.md`: Terminology definitions

### Changed

#### Breaking Changes from v1beta1

- **API Version**: Changed from `apiVersion: checks.dev/v1beta1` to `apiVersion: v1` for core checks
- **Browser Check API**: Separate namespace `apiVersion: browser/v1` (previously in v1beta1)
- **Field Naming**: Standardized field names across all check types
  - Assertions field: `checks` (consistent across all types)
  - Notification field: `channels` (consistent)

#### Non-Breaking Changes

- **Status**: All specifications marked as "Stable" (previously "Draft")
- **Organization**: Moved from `checksdev` to `syntheticopenschema` GitHub organization
- **Stewardship**: Formally documented as stewarded by Ideatives Inc.
- **License**: Confirmed Apache License 2.0 with proper NOTICE file

### Deprecated

- **v1beta1 API Version**: Marked as deprecated with best-effort support
  - Users should migrate to `v1` for core checks
  - Users should migrate to `browser/v1` for browser checks
  - Migration path documented in specification

---

## [v1beta1] - 2024-2025

### Beta Release (Historical)

Initial beta release under `checks.dev/v1beta1` API version.

#### Included Check Types
- HttpCheck (beta)
- TcpCheck (beta)
- DnsCheck (beta)
- SslCheck (beta)
- PlaywrightCheck (beta - later split into LoadCheck and ScriptedCheck)

#### Status
- **Deprecated**: Use v1 stable release instead
- **Support**: Best-effort basis, no new features
- **Migration**: Required to move to v1 or browser/v1

---

## Migration Guide

### From v1beta1 to v1

**Core Checks** (Http, Tcp, Dns, Tls, Domain):

1. Update `apiVersion`:
   ```yaml
   # Before
   apiVersion: checks.dev/v1beta1

   # After
   apiVersion: v1
   ```

2. Verify field names:
   - Ensure `checks:` is used for assertions (not `assertions:`)
   - Ensure `channels:` is used for notifications (not `notifications:`)

**Browser Checks** (Load, Scripted):

1. Update `apiVersion`:
   ```yaml
   # Before
   apiVersion: checks.dev/v1beta1
   kind: PlaywrightCheck

   # After
   apiVersion: browser/v1
   kind: LoadCheck  # or ScriptedCheck
   ```

2. Update `kind`:
   - `PlaywrightCheck` → `LoadCheck` (for page load monitoring)
   - `PlaywrightCheck` with scripts → `ScriptedCheck`

---

## Future Releases

### Planned Features

See [GOVERNANCE.md](GOVERNANCE.md) for the RFC process to propose new check types or features.

Potential future additions:
- Additional check types (gRPC, WebSocket, GraphQL)
- Enhanced assertion capabilities
- Extended browser automation features

---

## Support Policy

### Version Support

| Version | Status | Support Level | End of Life |
|---------|--------|---------------|-------------|
| v1 | ✅ Stable | Full support | TBD |
| v1beta1 | ⚠️ Deprecated | Best effort | 2026-08-07 (6 months) |

### Compatibility Guarantees

- **v1 Minor Releases** (v1.x): Backward compatible, no breaking changes
- **v1 Patch Releases** (v1.x.y): Bug fixes and clarifications only
- **v2 Major Release**: Breaking changes allowed with migration guide

See [compatibility.md](compatibility.md) for full details.

---

## Links

- **Specification**: https://github.com/syntheticopenschema/spec
- **Python Model**: https://github.com/syntheticopenschema/model
- **Python Runner**: https://github.com/syntheticopenschema/runner
- **JSON Schemas**: https://github.com/syntheticopenschema/schemas
- **Website**: https://syntheticopenschema.org
- **Issues**: https://github.com/syntheticopenschema/spec/issues

---

**Maintained by**: Ideatives Inc.
**Created by**: @dmonroy
**License**: Apache License 2.0
