# DomainCheck Specification

**API Version**: `v1`
**Kind**: `DomainCheck`
**Status**: Stable

---

## Overview

DomainCheck monitors domain registration status, expiration, and configuration to prevent domain loss and detect unauthorized changes.

**Use Cases**:
- Domain expiration monitoring (prevent accidental loss)
- DNS hijacking detection (nameserver changes)
- Unauthorized transfer detection (registrar changes)
- Domain lock verification (EPP status codes)
- DNSSEC compliance monitoring

**Different from**:
- **DnsCheck**: Validates DNS resolution (A, MX, TXT records)
- **TlsCheck**: Validates SSL/TLS certificates
- **DomainCheck**: Validates domain registration and ownership

---

## Table of Contents

- [Resource Structure](#resource-structure)
- [DomainCheckSpec](#domainregistrationcheckspec)
- [Assertion Types](#assertion-types)
  - [ExpirationTimeAssertion](#expirationtimeassertion)
  - [NameserversAssertion](#nameserversassertion)
  - [RegistrarAssertion](#registrarassertion)
  - [StatusAssertion](#statusassertion)
  - [DnssecAssertion](#dnssecassertion)
- [Examples](#examples)
- [Implementation Notes](#implementation-notes)
- [Security Considerations](#security-considerations)
- [Conformance](#conformance)

---

## Resource Structure

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: example-com-registration
  title: "Example.com Domain Monitoring"
  labels:
    domain: example.com
    registrar: namecheap
spec:
  domain: example.com

  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d

    - type: nameservers
      operator: contains
      value:
        - ns1.cloudflare.com
        - ns2.cloudflare.com

    - type: registrar
      operator: equals
      value: "Namecheap Inc"

    - type: status
      operator: contains
      value: clientTransferProhibited

    - type: dnssec
      operator: equals
      value: signed

  interval: 1d
  timeout: 30s
  retries: 2
```

---

## DomainCheckSpec

Specification for domain registration monitoring.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `domain` | `DNSHostname` | REQUIRED | — | Domain to monitor |
| `checks` | [`DomainRegistrationAssertion[]`](#assertion-types) | OPTIONAL | `[]` | Assertions to validate |
| `interval` | `Time` | CONDITIONAL | — | Scheduling interval (mutually exclusive with `cron`) |
| `cron` | `Crontab` | CONDITIONAL | — | Cron schedule (mutually exclusive with `interval`) |
| `timeout` | `Time` | OPTIONAL | `30s` | Maximum execution time |
| `retries` | `integer` | OPTIONAL | `1` | Number of retry attempts |
| `locations` | `string[]` | OPTIONAL | `[]` | Execution locations |
| `channels` | `NotificationChannel[]` | OPTIONAL | `[]` | Notification destinations |

### Field Details

#### `domain`
- **Type**: `DNSHostname`
- **Required**: REQUIRED
- **Description**: Domain name to monitor
- **Constraints**:
  - MUST be valid DNS format
  - MUST contain at least one dot (e.g., `example.com`)
  - Bare TLDs not allowed (e.g., `com` is invalid)
  - Automatically converted to lowercase
- **Examples**:
  - `example.com` ✅
  - `subdomain.example.com` ✅
  - `example-site.org` ✅
  - `com` ❌ (bare TLD)

#### `checks`
- **Type**: Array of [`DomainRegistrationAssertion`](#assertion-types)
- **Required**: OPTIONAL
- **Default**: `[]` (empty array)
- **Description**: Assertions to validate against domain registration data
- **Note**: Empty checks array is valid (monitoring-only mode, no assertions)

#### Common Fields

DomainCheck inherits common scheduling and execution fields from base `CheckSpec`:
- See [v1/check.md](./check.md) for `interval`, `cron`, `timeout`, `retries`, `locations`, `channels`

### Scheduling Recommendation

**Recommended**: `interval: 1d` (check daily)

**Rationale**:
- WHOIS servers have aggressive rate limits (typically 1-10 queries/minute)
- Domain data changes infrequently (days/weeks, not hours)
- Daily checks provide sufficient detection time for most threats
- More frequent checks may result in IP blocking

---

## Assertion Types

DomainCheck supports five assertion types for validating domain registration data.

All assertions extend base assertion types defined in [v1/common.md](./common.md).

---

### ExpirationTimeAssertion

Assert on days until domain expiration.

**Extends**: [`TimebasedAssertion`](./common.md#timebasedassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"expirationTime"` | REQUIRED | Assertion type discriminator |
| `operator` | `NumericOperator` | REQUIRED | Comparison operator |
| `value` | `StrictTime` | REQUIRED | Time threshold with unit |

#### Supported Operators

- `equals` - Exact time match (rarely useful)
- `notEquals` - Not equal (rarely useful)
- `greaterThan` - Greater than (most common)
- `greaterThanOrEquals` - Greater than or equal
- `lessThan` - Less than
- `lessThanOrEquals` - Less than or equal

#### Semantics

- Measures time from current date to domain expiration date
- Uses calendar-based calculation for units like `mo` (months) and `y` (years)
- Most common: `operator: greaterThan` (alert if less than threshold)

#### Common Thresholds

| Threshold | Use Case |
|-----------|----------|
| `30d` | Standard warning (1 month) |
| `60d` | Early warning (2 months) |
| `90d` | Very early warning (3 months) |
| `1y` | Annual renewal reminder |

#### Examples

```yaml
# Alert if domain expires in less than 30 days
- type: expirationTime
  operator: greaterThan
  value: 30d

# Alert if domain expires in less than 90 days
- type: expirationTime
  operator: greaterThan
  value: 90d

# Alert if domain expires in less than 1 year
- type: expirationTime
  operator: greaterThan
  value: 1y
```

---

### NameserversAssertion

Assert on authoritative nameservers for the domain.

**Extends**: [`ListAssertion`](./common.md#listassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"nameservers"` | REQUIRED | Assertion type discriminator |
| `operator` | `ListOperator` | REQUIRED | Comparison operator |
| `value` | `string \| string[]` | REQUIRED | Nameserver(s) to check |

#### Supported Operators

- `equals` - Exact nameserver list match (order-independent)
- `contains` - All specified nameservers present (most common)
- `notContains` - No specified nameservers present

#### Semantics

- Checks authoritative nameservers returned by WHOIS/RDAP
- Comparison is case-insensitive (`ns1.example.com` == `NS1.EXAMPLE.COM`)
- Order is not significant
- Trailing dots are normalized (removed)

#### Value Format

**Single nameserver** (string):
```yaml
value: ns1.cloudflare.com
```

**Multiple nameservers** (list):
```yaml
value:
  - ns1.cloudflare.com
  - ns2.cloudflare.com
```

#### Examples

```yaml
# Verify at least one Cloudflare nameserver is present
- type: nameservers
  operator: contains
  value: ns1.cloudflare.com

# Verify both Cloudflare nameservers are present
- type: nameservers
  operator: contains
  value:
    - hope.ns.cloudflare.com
    - jeff.ns.cloudflare.com

# Exact nameserver list match
- type: nameservers
  operator: equals
  value:
    - ns1.example.com
    - ns2.example.com

# Alert if old provider nameservers are still present
- type: nameservers
  operator: notContains
  value:
    - ns1.oldprovider.net
    - ns2.oldprovider.net

# Ensure specific nameserver is NOT present (security)
- type: nameservers
  operator: notContains
  value: ns1.malicious.example
```

---

### RegistrarAssertion

Assert on domain registrar.

**Extends**: [`StringAssertion`](./common.md#stringassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"registrar"` | REQUIRED | Assertion type discriminator |
| `operator` | `StringOperator` | REQUIRED | Comparison operator |
| `value` | `string` | REQUIRED | Registrar name or pattern |

#### Supported Operators

- `equals` - Exact registrar name match (most common)
- `notEquals` - Not equal to registrar
- `contains` - Contains substring (flexible matching)
- `notContains` - Does not contain substring

#### Semantics

- Checks the registrar name returned by WHOIS/RDAP
- Registrar names may vary slightly by data source
- Case-sensitive by default (use `contains` for flexible matching)

#### Registrar Name Variations

Registrar names may include suffixes like:
- `"Namecheap Inc"`
- `"NAMECHEAP INC"`
- `"Namecheap, Inc."`

Use `contains` operator for flexible matching.

#### Examples

```yaml
# Exact registrar match
- type: registrar
  operator: equals
  value: "Namecheap Inc"

# Flexible matching (case variations)
- type: registrar
  operator: contains
  value: "Namecheap"

# Alert if registrar changes
- type: registrar
  operator: notEquals
  value: "Unknown Registrar LLC"

# Ensure domain is NOT with specific registrar
- type: registrar
  operator: notContains
  value: "BadRegistrar"
```

---

### StatusAssertion

Assert on EPP status codes (domain lock status, transfer status, etc.).

**Extends**: [`ListAssertion`](./common.md#listassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"status"` | REQUIRED | Assertion type discriminator |
| `operator` | `ListOperator` | REQUIRED | Comparison operator |
| `value` | `string \| string[]` | REQUIRED | EPP status code(s) |

#### Supported Operators

- `equals` - Exact status list match
- `contains` - All specified statuses present (most common)
- `notContains` - No specified statuses present

#### Semantics

- Checks EPP (Extensible Provisioning Protocol) status codes
- Status codes indicate domain state (locked, transferring, redemption, etc.)
- Implementations MUST normalize status codes (strip URLs and whitespace)

#### Status Code Normalization

WHOIS returns status codes with URLs:
```
Input:  "clientTransferProhibited https://icann.org/epp#clientTransferProhibited"
Output: "clientTransferProhibited"
```

Implementations MUST:
1. Strip URLs (everything after first space)
2. Trim whitespace
3. Compare normalized values

#### Common EPP Status Codes

| Status Code | Description | Security Level |
|-------------|-------------|----------------|
| `ok` | No restrictions | Normal |
| `clientTransferProhibited` | Transfer locked | 🔒 Secure |
| `clientUpdateProhibited` | Update locked | 🔒 Secure |
| `clientDeleteProhibited` | Delete locked | 🔒 Secure |
| `serverTransferProhibited` | Registrar transfer lock | 🔒 Secure |
| `serverUpdateProhibited` | Registrar update lock | 🔒 Secure |
| `serverDeleteProhibited` | Registrar delete lock | 🔒 Secure |
| `addPeriod` | Recently registered (grace period) | ℹ️ Info |
| `autoRenewPeriod` | Auto-renewal period | ℹ️ Info |
| `renewPeriod` | Recently renewed (grace period) | ℹ️ Info |
| `transferPeriod` | Recently transferred (grace period) | ℹ️ Info |
| `redemptionPeriod` | Deleted, can be restored | ⚠️ CRITICAL |
| `pendingDelete` | About to be permanently deleted | ⚠️ CRITICAL |
| `pendingTransfer` | Transfer in progress | ℹ️ Info |

#### Value Format

**Single status** (string):
```yaml
value: clientTransferProhibited
```

**Multiple statuses** (list):
```yaml
value:
  - clientTransferProhibited
  - clientUpdateProhibited
  - clientDeleteProhibited
```

#### Examples

```yaml
# Verify domain is locked against transfers
- type: status
  operator: contains
  value: clientTransferProhibited

# Verify domain has all locks
- type: status
  operator: contains
  value:
    - clientTransferProhibited
    - clientUpdateProhibited
    - clientDeleteProhibited

# CRITICAL: Alert if domain enters redemption period
- type: status
  operator: notContains
  value: redemptionPeriod

# CRITICAL: Alert if domain pending deletion
- type: status
  operator: notContains
  value: pendingDelete

# Alert if domain is being transferred
- type: status
  operator: notContains
  value: pendingTransfer

# Verify domain is in normal state
- type: status
  operator: contains
  value: ok
```

---

### DnssecAssertion

Assert on DNSSEC (Domain Name System Security Extensions) status.

**Extends**: [`StringAssertion`](./common.md#stringassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"dnssec"` | REQUIRED | Assertion type discriminator |
| `operator` | `StringOperator` | REQUIRED | Comparison operator |
| `value` | `string` | REQUIRED | DNSSEC status value |

#### Supported Operators

- `equals` - Exact status match (most common)
- `notEquals` - Not equal to status

#### Semantics

- Checks DNSSEC signing status returned by WHOIS/RDAP
- DNSSEC provides cryptographic authentication for DNS responses
- Enabling DNSSEC is a security best practice

#### DNSSEC Status Values

| Value | Description |
|-------|-------------|
| `unsigned` | DNSSEC not enabled (most common) |
| `signed` | DNSSEC enabled |
| `signedDelegation` | DNSSEC signed delegation |

**Note**: Some registrars/TLDs may return different values. Check implementation documentation.

#### Examples

```yaml
# Ensure DNSSEC is enabled
- type: dnssec
  operator: equals
  value: signed

# Ensure DNSSEC is NOT disabled
- type: dnssec
  operator: notEquals
  value: unsigned

# Alert if DNSSEC becomes unsigned
- type: dnssec
  operator: equals
  value: signed
```

---

## Examples

### Example 1: Basic Domain Expiration Monitoring

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: example-com-basic
  title: "Example.com Basic Monitoring"
spec:
  domain: example.com

  checks:
    # Alert if domain expires in less than 30 days
    - type: expirationTime
      operator: greaterThan
      value: 30d

  interval: 1d
  timeout: 30s

  channels:
    - channel: email-alerts
      severity: Critical
```

---

### Example 2: Comprehensive Domain Security

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: syntheticopenschema-org
  title: "SyntheticOpenSchema.org Domain Security"
  labels:
    domain: syntheticopenschema.org
    registrar: namecheap
    criticality: high
spec:
  domain: syntheticopenschema.org

  checks:
    # Expiration: Alert if less than 30 days
    - type: expirationTime
      operator: greaterThan
      value: 30d

    # Nameservers: Verify Cloudflare DNS
    - type: nameservers
      operator: contains
      value:
        - hope.ns.cloudflare.com
        - jeff.ns.cloudflare.com

    # Registrar: Verify still with Namecheap
    - type: registrar
      operator: contains
      value: "NAMECHEAP"

    # Security: Verify domain is locked
    - type: status
      operator: contains
      value: clientTransferProhibited

    # Security: Alert if entering redemption
    - type: status
      operator: notContains
      value: redemptionPeriod

    # Best practice: Verify DNSSEC enabled
    - type: dnssec
      operator: equals
      value: signed

  interval: 1d
  timeout: 30s
  retries: 2

  locations:
    - us-east-1

  channels:
    - channel: pagerduty-infrastructure
      severity: Critical
    - channel: slack-infrastructure
      severity: High
```

---

### Example 3: Detect Unauthorized Changes

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: company-com-security
  title: "Company.com Unauthorized Change Detection"
spec:
  domain: company.com

  checks:
    # Detect nameserver hijacking
    - type: nameservers
      operator: equals
      value:
        - ns1.company-dns.com
        - ns2.company-dns.com

    # Detect unauthorized transfer
    - type: registrar
      operator: equals
      value: "GoDaddy LLC"

    # Verify domain remains locked
    - type: status
      operator: contains
      value:
        - clientTransferProhibited
        - clientUpdateProhibited
        - clientDeleteProhibited

  interval: 1d

  channels:
    - channel: security-alerts
      severity: Critical
```

---

### Example 4: Multi-Domain Fleet Monitoring

```yaml
# Check 1: Primary domain
apiVersion: v1
kind: DomainCheck
metadata:
  name: example-com
  labels:
    fleet: production
    priority: critical
spec:
  domain: example.com
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d
    - type: status
      operator: contains
      value: clientTransferProhibited
  interval: 1d
  channels:
    - channel: ops-critical
      severity: Critical

---

# Check 2: API domain
apiVersion: v1
kind: DomainCheck
metadata:
  name: api-example-com
  labels:
    fleet: production
    priority: high
spec:
  domain: api.example.com
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d
    - type: nameservers
      operator: contains
      value:
        - ns1.cloudflare.com
  interval: 1d
  channels:
    - channel: ops-high
      severity: High

---

# Check 3: Staging domain
apiVersion: v1
kind: DomainCheck
metadata:
  name: staging-example-com
  labels:
    fleet: staging
    priority: medium
spec:
  domain: staging.example.com
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 14d
  interval: 1d
  channels:
    - channel: ops-medium
      severity: Medium
```

---

### Example 5: Redemption Period Emergency Detection

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: critical-domain-emergency
  title: "Critical Domain Emergency Monitoring"
spec:
  domain: critical-business.com

  checks:
    # CRITICAL: Alert immediately if domain enters redemption
    - type: status
      operator: notContains
      value: redemptionPeriod

    # CRITICAL: Alert if domain pending deletion
    - type: status
      operator: notContains
      value: pendingDelete

    # Standard: Check expiration
    - type: expirationTime
      operator: greaterThan
      value: 60d

  interval: 1d
  timeout: 30s
  retries: 3

  locations:
    - us-east-1
    - us-west-2

  channels:
    - channel: pagerduty-critical
      severity: Critical
    - channel: sms-ceo
      severity: Critical
```

---

### Example 6: DNSSEC Compliance Monitoring

```yaml
apiVersion: v1
kind: DomainCheck
metadata:
  name: secure-domain-dnssec
  title: "Secure Domain DNSSEC Compliance"
  labels:
    compliance: pci-dss
    security: high
spec:
  domain: secure.example.com

  checks:
    # Compliance: Ensure DNSSEC is enabled
    - type: dnssec
      operator: equals
      value: signed

    # Security: Verify locks
    - type: status
      operator: contains
      value:
        - clientTransferProhibited
        - serverTransferProhibited

    # Operational: Check expiration
    - type: expirationTime
      operator: greaterThan
      value: 90d

  interval: 1d

  channels:
    - channel: compliance-alerts
      severity: High
```

---

## Implementation Notes

### Data Sources

Implementations may obtain domain registration data from:

**WHOIS (RFC 3912)** - Traditional protocol
- Pros: Universal support, simple text-based
- Cons: Inconsistent formats, aggressive rate limiting, parsing complexity
- Libraries: `python-whois`, `whois` (Ruby), `whoiser` (Node.js)

**RDAP (RFC 7480)** - Modern alternative
- Pros: Structured JSON, standardized format, better rate limits, authentication support
- Cons: Not universally adopted yet, requires per-TLD RDAP server discovery
- Libraries: `rdap` (Python), `rdap-client` (Node.js)

**Registrar APIs** - Direct access
- Pros: Most accurate, highest rate limits, authenticated access, real-time data
- Cons: Implementation-specific, requires credentials, not portable
- Examples: Namecheap API, Cloudflare API, GoDaddy API

**Recommendations**:
1. Prefer RDAP when available (modern, structured)
2. Fall back to WHOIS for unsupported TLDs
3. Document which data source is used
4. Implement caching to reduce query load

### Data Normalization

#### Expiration Date
- WHOIS may return multiple date values (duplicates with varying precision)
- Implementations SHOULD use the first value or most precise value
- Handle timezone information appropriately
- Parse formats: ISO 8601, RFC 3339, locale-specific formats

#### Nameservers
- WHOIS returns nameservers as list of strings
- Comparison MUST be case-insensitive
- Remove trailing dots if present (`ns1.example.com.` → `ns1.example.com`)
- Order is not significant (set comparison)

#### Registrar
- Registrar names vary by source (case, punctuation, suffixes)
- Consider using `contains` operator for flexible matching
- Examples: `"Namecheap Inc"`, `"NAMECHEAP INC"`, `"Namecheap, Inc."`

#### EPP Status Codes
- WHOIS appends URLs to status codes
- **MUST normalize**: Strip everything after first space
- **Input**: `"clientTransferProhibited https://icann.org/epp#clientTransferProhibited"`
- **Output**: `"clientTransferProhibited"`
- Case-sensitive comparison

#### DNSSEC
- Common values: `"signed"`, `"unsigned"`, `"signedDelegation"`
- Case-sensitive comparison
- Some TLDs may not return DNSSEC information

### Privacy Protection

Many domains use privacy/proxy services:
- Personal information (name, email, address) is redacted
- Example: `"Redacted for Privacy"`, `"WHOIS Privacy Protection Service"`
- **Available data**: expiration date, nameservers, registrar, status, DNSSEC
- **Unavailable data**: registrant name, contact emails, physical address

This is why DomainCheck focuses on public, non-personal data.

### Rate Limiting

WHOIS servers impose strict rate limits:
- **Typical**: 1-10 queries per minute per IP address
- **Violation**: Temporary IP blocking (minutes to hours)
- **RDAP**: Generally higher limits, varies by registry
- **Registrar APIs**: Highest limits, token-based

**Recommendations**:
1. **Minimum interval**: `1d` (24 hours) to respect rate limits
2. **Implement caching**: Cache results for at least 23 hours
3. **Exponential backoff**: On rate limit errors, back off exponentially
4. **Distributed checking**: Use multiple source IPs if checking many domains
5. **Document limits**: Clearly document rate limit behavior

### WHOIS Data Freshness

WHOIS data propagation:
- Registrar updates may take 24-48 hours to propagate
- WHOIS servers cache data (TTLs vary)
- Recent changes may not appear immediately

**Recommendations**:
1. Don't alert on single-check anomalies
2. Consider grace periods before alerting (2-3 checks)
3. Document expected propagation delays

### Error Handling

Common errors:
- **Rate limit exceeded**: Back off, retry later
- **Domain not found**: Domain may be deleted or invalid
- **WHOIS server timeout**: Retry with backoff
- **Parse error**: WHOIS format variation, log for debugging
- **Network error**: Transient, retry with backoff

Implementations SHOULD:
- Return clear error messages
- Distinguish transient errors (retry) from permanent errors (fail)
- Log raw WHOIS responses for debugging

---

## Security Considerations

### Domain Hijacking Detection

DomainCheck helps detect domain hijacking through:

**Nameserver hijacking**:
- Attacker changes nameservers to redirect traffic
- Monitor: `nameservers` assertion
- Impact: Complete DNS control, phishing, data theft

**Registrar transfer**:
- Attacker transfers domain to different registrar
- Monitor: `registrar` assertion
- Impact: Loss of domain control, potential theft

**Lock bypass**:
- Attacker removes transfer locks
- Monitor: `status` assertion (clientTransferProhibited)
- Impact: Domain vulnerable to transfer

**Redemption period**:
- Domain expires and enters grace period
- Monitor: `status` assertion (redemptionPeriod, pendingDelete)
- Impact: Domain may be lost permanently

### Domain Expiration Risks

**Timeline after expiration**:
1. **Day 0**: Domain expires, enters grace period
2. **Day 0-40**: Grace period (varies by registrar)
3. **Day 41-70**: Redemption period (expensive recovery)
4. **Day 71+**: Pending delete (5 days)
5. **Day 76+**: Domain released, anyone can register

**Monitoring strategy**:
- **90 days**: Early warning (plenty of time)
- **60 days**: Standard warning (safe buffer)
- **30 days**: Urgent warning (act now)
- **14 days**: Critical warning (emergency)

### False Positives

Be aware of legitimate changes:

**Intentional changes** (not hijacking):
- Registrar transfers (corporate acquisitions, consolidation)
- Nameserver migrations (DNS provider changes)
- Domain renewals (expiration date extends)
- EPP status changes (lock changes during transfers)

**Recommendations**:
1. Document planned changes in advance
2. Use maintenance windows to suppress alerts
3. Configure alerts appropriately (severity levels)
4. Implement alert correlation (multiple checks fail = more serious)

### WHOIS Query Privacy

WHOIS queries are logged:
- Registrars log all WHOIS queries
- May reveal monitoring strategy
- Queries are public record

**Implications**:
- Attackers may monitor WHOIS query patterns
- Consider privacy when naming checks
- Don't include sensitive information in check metadata

### DNSSEC Benefits

DNSSEC provides:
- **Authentication**: Cryptographically verify DNS responses
- **Integrity**: Detect DNS spoofing and cache poisoning
- **Non-repudiation**: Prove DNS records are authentic

**Limitations**:
- Does not provide confidentiality (DNS responses still public)
- Requires resolver support (not all ISPs/DNS resolvers validate DNSSEC)
- Adds complexity to DNS operations

---

## Conformance

Implementations claiming support for `DomainCheck` MUST:

1. **Support domain field**: Accept valid DNS hostnames
2. **Query registration data**: Obtain domain registration information from WHOIS, RDAP, or registrar API
3. **Support all assertion types**:
   - `expirationTime` - Domain expiration monitoring
   - `nameservers` - Authoritative nameserver validation
   - `registrar` - Registrar verification
   - `status` - EPP status code validation
   - `dnssec` - DNSSEC status validation
4. **Normalize status codes**: Strip URLs from EPP status codes
5. **Case-insensitive nameservers**: Nameserver comparison ignores case
6. **Evaluate assertions**: Run all `checks` assertions against obtained data
7. **Report results**: Return pass/fail status with detailed error messages
8. **Honor timeout**: Abort check if `timeout` is exceeded
9. **Retry logic**: Retry failed checks up to `retries` count
10. **Document data source**: Clearly specify which data source is used (WHOIS, RDAP, API)
11. **Document rate limits**: Specify rate limit behavior and recommendations

Implementations SHOULD:
- Cache registration data for at least 23 hours (reduce query load)
- Implement exponential backoff on rate limit errors
- Support both WHOIS and RDAP data sources
- Provide clear error messages for rate limiting, parsing failures, and network errors
- Log raw WHOIS/RDAP responses for debugging

Implementations MAY:
- Support additional data sources (registrar APIs, custom sources)
- Collect additional metrics (query time, data freshness, cache hit rate)
- Provide additional assertion types (creation date, registrant, etc.)
- Implement intelligent caching strategies

---

## Related Documents

- [v1/_index.md](./_index.md) - V1 API overview
- [v1/common.md](./common.md) - Common types (ListAssertion, TimebasedAssertion, StringAssertion)
- [v1/check.md](./check.md) - Base Check resource
- [v1/dns.md](./dns.md) - DNS resolution checks (different from domain registration)
- [v1/tls.md](./tls.md) - TLS certificate checks (different from domain registration)

---

**Status**: Stable
**Last Updated**: 2026-02-07
