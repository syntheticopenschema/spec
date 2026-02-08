# TLS Certificate Check

**Version**: v1
**Kind**: `TlsCheck`
**Alias**: `SslCheck` (for backward compatibility)
**Status**: Stable

---

## Overview

The TLS Certificate Check validates TLS/SSL certificates for any TCP service, not just HTTPS. It monitors certificate validity, expiration, and issuer information.

**Common Use Cases:**
- HTTPS servers (port 443)
- SMTP with STARTTLS (port 587) or SMTPS (port 465)
- IMAP with SSL/TLS (port 993)
- POP3 with SSL/TLS (port 995)
- PostgreSQL with TLS (port 5432)
- MySQL with TLS (port 3306)
- LDAPS (port 636)
- Any TCP service using TLS

---

## Naming: TlsCheck vs SslCheck

**Primary Name**: `TlsCheck` (technically correct, protocol-agnostic)
**Alias**: `SslCheck` (widely recognized, user-friendly)

Both names are accepted in YAML definitions and resolve to the same implementation:

```yaml
# Canonical (technically correct)
kind: TlsCheck

# Alias (familiar name)
kind: SslCheck
```

**Rationale:**
- TLS is the modern protocol (SSL is deprecated since 2015)
- "SSL" terminology remains widely used in industry
- Supporting both names provides technical accuracy AND user familiarity
- TlsCheck is protocol-agnostic (not web-specific like "SSL certificate")

---

## Resource Structure

```yaml
apiVersion: v1
kind: TlsCheck  # or SslCheck
metadata:
  name: {check-name}
  labels:
    key: value
spec:
  hostname: example.com
  port: 443  # optional, default: 443

  # Custom CA trust (OPTIONAL - for internal PKI)
  trustedCAs:
    - |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKJ...
      -----END CERTIFICATE-----

  # OR skip verification (OPTIONAL - development only!)
  # insecureSkipVerify: true

  # Scheduling (REQUIRED - one of)
  interval: 1h
  # OR
  cron: "0 */6 * * *"

  # Common fields (OPTIONAL)
  timeout: 10s
  retries: 3
  locations:
    - us-east-1
  channels:
    - channel: alerts
      severity: High

  # Assertions (REQUIRED)
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d
```

---

## Spec Fields

### hostname

**Type**: `DNSHostname`
**REQUIRED**

**Description**: The hostname of the server whose certificate to validate.

**Examples**:
```yaml
hostname: example.com
hostname: smtp.example.com
hostname: db.example.com
```

**Validation**:
- MUST be valid DNS hostname
- Automatically converted to lowercase
- Maximum length: 253 characters

---

### port

**Type**: `integer`
**OPTIONAL**
**Default**: `443`

**Description**: The TCP port where the TLS service is running.

**Common Ports**:
- `443` - HTTPS (default)
- `465` - SMTPS (SMTP over SSL)
- `587` - SMTP with STARTTLS
- `993` - IMAPS (IMAP over SSL)
- `995` - POP3S (POP3 over SSL)
- `636` - LDAPS (LDAP over SSL)
- `5432` - PostgreSQL with TLS
- `3306` - MySQL with TLS

**Examples**:
```yaml
# HTTPS (default)
port: 443

# SMTP with STARTTLS
port: 587

# PostgreSQL with TLS
port: 5432
```

**Validation**:
- MUST be integer between 1 and 65535

---

### trustedCAs

**Type**: `array[string]`
**OPTIONAL**
**Default**: `null` (use system trust store)

**Description**: Custom CA certificates to trust for certificate validation. If specified, replaces the system trust store.

**Format**: Array of PEM-encoded X.509 certificates (string format).

**Examples**:

Single internal CA:
```yaml
trustedCAs:
  - |
    -----BEGIN CERTIFICATE-----
    MIIDXTCCAkWgAwIBAgIJAKJ...
    -----END CERTIFICATE-----
```

Multiple CAs (internal PKI hierarchy):
```yaml
trustedCAs:
  - |
    -----BEGIN CERTIFICATE-----
    ... Root CA ...
    -----END CERTIFICATE-----
  - |
    -----BEGIN CERTIFICATE-----
    ... Intermediate CA ...
    -----END CERTIFICATE-----
```

**Semantics**:
- If NOT specified: Use system trust store (default behavior)
- If specified: Use ONLY these CAs (system trust store is ignored)
- Validates certificate chain against provided CAs
- Still checks: expiration, hostname match, revocation (if enabled)

**Use Cases**:
- **Internal networks**: Services with internal CA-issued certificates
- **Private PKI**: Enterprise infrastructure with private certificate authorities
- **Air-gapped environments**: No access to public CA infrastructure
- **Testing**: Validate against test CAs without modifying system trust store

**Security Considerations**:
- ⚠️ **Validate CA certificates** before adding to `trustedCAs`
- ⚠️ **Store securely**: CAs are sensitive (control what you trust)
- ⚠️ **Audit regularly**: Review which checks use custom CAs
- ⚠️ **Rotate CAs**: Update when CAs expire or are compromised
- ✅ **Prefer proper PKI**: Better than self-signed certificates

**Validation**:
- Each CA MUST be valid PEM-encoded X.509 certificate
- Mutually exclusive with `insecureSkipVerify`

**Best Practices**:
- Use for production internal services with proper PKI
- Document why custom CAs are needed
- Maintain CA certificate lifecycle (expiration, rotation)
- Store CA certificates in secrets management system
- Don't commit CA certificates to public repositories

---

### insecureSkipVerify

**Type**: `boolean`
**OPTIONAL**
**Default**: `false`

**Description**: Skip ALL certificate validation. ⚠️ **DEVELOPMENT/TESTING ONLY** - disables trust verification.

**Examples**:

Development with self-signed certificate:
```yaml
insecureSkipVerify: true  # WARNING: Development only!
```

**Semantics**:
- If `false` (default): Perform full certificate validation
- If `true`: Skip certificate validation entirely
  - No expiration check
  - No trust chain validation
  - No hostname verification
  - No revocation check
- Still performs TLS handshake (connection is encrypted)
- Incompatible with `valid` assertion (validation disabled)
- Can still use: `expirationTime`, `certificateIssuer`, `certificateSubject`

**Use Cases**:
- ⚠️ **Development**: Local testing with self-signed certificates
- ⚠️ **Debugging**: Investigate TLS issues
- ⚠️ **Migration**: Temporary workaround during certificate migration
- ❌ **Production**: NEVER use in production environments

**Security Warnings**:
```yaml
# ⚠️⚠️⚠️ SECURITY WARNING ⚠️⚠️⚠️
# insecureSkipVerify disables ALL certificate validation
#
# This makes you vulnerable to:
# - Man-in-the-middle attacks
# - Impersonation attacks
# - Expired certificate usage
# - Untrusted certificate acceptance
#
# Use ONLY for development/testing
# NEVER use in production
insecureSkipVerify: true
```

**Validation**:
- Mutually exclusive with `trustedCAs`
- Incompatible with `valid` assertion type
- If `true` and `checks` contains `valid`, validation FAILS

**Examples of Invalid Usage**:

```yaml
# ❌ INVALID: Cannot validate when verification skipped
spec:
  hostname: localhost
  insecureSkipVerify: true
  checks:
    - type: valid  # ERROR: incompatible
      operator: is
      value: true
```

```yaml
# ❌ INVALID: Mutually exclusive with trustedCAs
spec:
  hostname: example.com
  trustedCAs: [...]
  insecureSkipVerify: true  # ERROR: conflicting
```

**Valid Development Usage**:

```yaml
# ✅ VALID: Can check expiration even without trust validation
spec:
  hostname: localhost
  port: 8443
  insecureSkipVerify: true
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 7d
```

**Alternatives**:
- **Production**: Use `trustedCAs` with proper internal CA
- **Development**: Set up local CA and use `trustedCAs`
- **Testing**: Use mkcert or similar tools for trusted local certificates

---

### checks

**Type**: `array[TlsAssertion]`
**REQUIRED**

**Description**: List of assertions to evaluate against the TLS certificate.

**Supported Assertion Types**:
1. `expirationTime` - Time until certificate expiration
2. `certificateIssuer` - Certificate issuer organization
3. `certificateSubject` - Certificate subject/CN
4. `valid` - Certificate validity (not expired, trusted, hostname match)

See [Assertions](#assertions) section for details.

---

## Assertions

All TLS assertions validate properties of the TLS certificate.

### expirationTime

**Type**: `TimebasedAssertion`

**Description**: Assert on time until certificate expiration.

**Fields**:
- `type`: `"expirationTime"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `StrictTime` (REQUIRED)
  - MUST include unit suffix: `"30d"`, `"7d"`, `"720h"`, etc.
  - Bare integers are NOT allowed

**Examples**:

Alert if certificate expires in less than 30 days:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 30d
```

Alert if certificate expires in less than 7 days:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 7d
```

Using hours instead of days:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 720h  # 30 days in hours
```

Using weeks:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 4w  # approximately 30 days
```

Using calendar-based months (recommended for certificates):
```yaml
- type: expirationTime
  operator: greaterThan
  value: 3mo  # 3 calendar months (Jan 7 → April 7)
```

Using calendar-based years:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 1y  # 1 calendar year (handles leap years)
```

**Invalid - bare integers rejected**:
```yaml
- type: expirationTime
  operator: greaterThan
  value: 30  # ❌ ERROR: unit suffix required
```

**Semantics**:
- Value represents duration UNTIL expiration
- Check FAILS if certificate expires within the specified time
- `greaterThan` typically used to ensure sufficient validity remaining
- Unit suffix REQUIRED to avoid ambiguity (days vs seconds vs hours)

---

### certificateIssuer

**Type**: `StringAssertion`

**Description**: Assert on the certificate issuer (CA) organization name.

**Fields**:
- `type`: `"certificateIssuer"` (REQUIRED)
- `operator`: `StringOperator` (REQUIRED)
  - `equals`, `notEquals`, `contains`, `notContains`
- `value`: `string` (REQUIRED)

**Examples**:

Verify certificate issued by Let's Encrypt:
```yaml
- type: certificateIssuer
  operator: contains
  value: "Let's Encrypt"
```

Verify certificate issued by specific CA:
```yaml
- type: certificateIssuer
  operator: equals
  value: "DigiCert Inc"
```

Ensure certificate NOT issued by untrusted CA:
```yaml
- type: certificateIssuer
  operator: notContains
  value: "UnknownCA"
```

**Common Issuers**:
- `"Let's Encrypt"`
- `"DigiCert Inc"`
- `"Google Trust Services"`
- `"Amazon"`
- `"Cloudflare"`
- `"GlobalSign"`

---

### certificateSubject

**Type**: `StringAssertion`

**Description**: Assert on the certificate subject (Common Name or Subject Alternative Names).

**Fields**:
- `type`: `"certificateSubject"` (REQUIRED)
- `operator`: `StringOperator` (REQUIRED)
  - `equals`, `notEquals`, `contains`, `notContains`
- `value`: `string` (REQUIRED)

**Examples**:

Verify certificate subject contains domain:
```yaml
- type: certificateSubject
  operator: contains
  value: "CN=example.com"
```

Verify exact subject match:
```yaml
- type: certificateSubject
  operator: equals
  value: "CN=*.example.com, O=Example Inc, L=San Francisco, ST=California, C=US"
```

Verify wildcard certificate:
```yaml
- type: certificateSubject
  operator: contains
  value: "*.example.com"
```

**Common Patterns**:
- `"CN=example.com"` - Single domain
- `"CN=*.example.com"` - Wildcard certificate
- `"O=Example Inc"` - Organization
- `"C=US"` - Country

---

### valid

**Type**: `BooleanAssertion`

**Description**: Assert on overall certificate validity.

**Fields**:
- `type`: `"valid"` (REQUIRED)
- `operator`: `BooleanOperator` (REQUIRED)
  - `is`, `isNot`
- `value`: `boolean` (REQUIRED)
  - `true` - Certificate should be valid
  - `false` - Certificate should be invalid

**Examples**:

Assert certificate is valid:
```yaml
- type: valid
  operator: is
  value: true
```

Verify certificate is trusted:
```yaml
- type: valid
  operator: isNot
  value: false  # Certificate must be valid
```

**Semantics**:
- `true` means certificate passed all validation checks:
  - Not expired (current time between notBefore and notAfter)
  - Trusted certificate chain (signed by trusted CA)
  - Hostname matches (certificate subject/SAN matches spec.hostname)
  - Not revoked (implementation-dependent, may check OCSP/CRL)
- `false` means certificate failed validation
- Check PASSES if assertion evaluates to true
- Check FAILS if assertion evaluates to false

**Validation Checks** (implementation performs):
1. **Expiration**: Certificate not expired
2. **Trust Chain**: Certificate chain validates to trusted root CA
3. **Hostname**: Certificate subject/SAN matches `spec.hostname`
4. **Revocation**: Certificate not revoked (optional, implementation-dependent)

**Use Cases**:
- **Security compliance**: Ensure certificates are properly validated
- **Trust validation**: Verify certificates signed by trusted CAs
- **Hostname verification**: Confirm certificate matches expected hostname
- **General health**: Single assertion for overall certificate validity

**Comparison with expirationTime**:
- `valid` checks multiple criteria (expiration + trust + hostname)
- `expirationTime` only checks expiration date
- Use `valid` for general security compliance
- Use `expirationTime` for specific expiration monitoring/alerting

**Examples**:

Basic validity check:
```yaml
- type: valid
  operator: is
  value: true
```

Combined with expiration monitoring:
```yaml
# General validity (security)
- type: valid
  operator: is
  value: true

# Specific expiration alert (30 day warning)
- type: expirationTime
  operator: greaterThan
  value: 30d
```

---

## Examples

### Basic HTTPS Certificate Check

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: web-tls-monitor
  title: "HTTPS Certificate Monitor"
  labels:
    environment: production
spec:
  hostname: example.com
  port: 443
  interval: 6h
  timeout: 10s
  retries: 2
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d
    - type: certificateIssuer
      operator: contains
      value: "Let's Encrypt"
  locations:
    - us-east-1
    - eu-west-1
  channels:
    - channel: security-alerts
      severity: Critical
```

### SMTP TLS Certificate Check

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: smtp-tls-certificate
  title: "SMTP Server TLS Monitor"
  labels:
    environment: production
    service: email
spec:
  hostname: smtp.example.com
  port: 587  # SMTP with STARTTLS
  interval: 6h
  timeout: 5s
  retries: 2
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 7d
    - type: certificateIssuer
      operator: contains
      value: "DigiCert"
  locations:
    - us-east-1
  channels:
    - channel: email-alerts
      severity: High
```

### Database TLS Certificate Check

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: postgres-tls-certificate
  title: "PostgreSQL TLS Certificate Monitor"
  labels:
    environment: production
    service: database
spec:
  hostname: db.example.com
  port: 5432
  interval: 12h
  timeout: 5s
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 14d
    - type: certificateSubject
      operator: contains
      value: "CN=db.example.com"
  locations:
    - us-east-1
  channels:
    - channel: database-alerts
      severity: Critical
```

### Using SslCheck Alias

```yaml
apiVersion: v1
kind: SslCheck  # Alias for TlsCheck
metadata:
  name: ssl-cert-monitor
  title: "SSL Certificate Monitor"
spec:
  hostname: example.com
  interval: 1h
  checks:
    - type: expirationTime
      operator: greaterThan
      value: 30d
```

### Comprehensive Certificate Validation

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: comprehensive-tls-check
  title: "Comprehensive TLS Validation"
  labels:
    environment: production
    criticality: high
spec:
  hostname: api.example.com
  port: 443
  interval: 6h
  timeout: 10s
  retries: 3
  checks:
    # Overall validity check
    - type: valid
      operator: is
      value: true

    # Ensure at least 30 days until expiration
    - type: expirationTime
      operator: greaterThan
      value: 30d

    # Verify trusted CA
    - type: certificateIssuer
      operator: contains
      value: "Let's Encrypt"

    # Verify certificate subject
    - type: certificateSubject
      operator: contains
      value: "CN=api.example.com"

    # Ensure not using wildcard (if desired)
    - type: certificateSubject
      operator: notContains
      value: "*"

  locations:
    - us-east-1
    - eu-west-1
    - ap-southeast-1

  channels:
    - channel: pagerduty-security
      severity: Critical
    - channel: slack-security
      severity: High
```

### Internal Service with Custom CA

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: internal-api-tls
  title: "Internal API TLS (Custom CA)"
  labels:
    environment: production
    network: internal
spec:
  hostname: internal-api.corp.example.com
  port: 443
  interval: 6h
  timeout: 10s

  # Custom internal CA certificate
  trustedCAs:
    - |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKJ8FqEVUvKCMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
      BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMSEwHwYDVQQKDBhJbnRlcm5hbCBD
      QSAtIEV4YW1wbGUgSW5jMB4XDTI0MDEwMTAwMDAwMFoXDTM0MDEwMTAwMDAwMFow
      RTELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExITAfBgNVBAoMGElu
      dGVybmFsIENBIC0gRXhhbXBsZSBJbmMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
      ggEKAoIBAQC...
      -----END CERTIFICATE-----

  checks:
    # Validate against internal CA
    - type: valid
      operator: is
      value: true

    # Monitor expiration (30 day warning)
    - type: expirationTime
      operator: greaterThan
      value: 30d

    # Verify internal CA
    - type: certificateIssuer
      operator: contains
      value: "Internal CA - Example Inc"

  locations:
    - internal-dc-1

  channels:
    - channel: internal-alerts
      severity: High
```

### Internal Service with Multiple CAs (PKI Hierarchy)

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: internal-db-tls
  title: "Internal Database TLS (PKI Hierarchy)"
spec:
  hostname: db.internal.example.com
  port: 5432
  interval: 12h
  timeout: 5s

  # Internal PKI - Root + Intermediate CAs
  trustedCAs:
    # Root CA
    - |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKJ8FqEVUvKCMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
      ... Root CA Certificate ...
      -----END CERTIFICATE-----

    # Intermediate CA
    - |
      -----BEGIN CERTIFICATE-----
      MIIDXTCCAkWgAwIBAgIJAKJ8FqEVUvKDMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
      ... Intermediate CA Certificate ...
      -----END CERTIFICATE-----

  checks:
    - type: valid
      operator: is
      value: true

    - type: expirationTime
      operator: greaterThan
      value: 14d

  locations:
    - internal-dc-1

  channels:
    - channel: database-alerts
      severity: Critical
```

### Development with Self-Signed Certificate

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: dev-localhost-tls
  title: "Development Localhost TLS"
  labels:
    environment: development
spec:
  hostname: localhost
  port: 8443
  interval: 5m
  timeout: 5s

  # ⚠️ WARNING: Development only - disables validation
  insecureSkipVerify: true

  checks:
    # Can still check expiration without trust validation
    - type: expirationTime
      operator: greaterThan
      value: 7d

    # Can check issuer/subject
    - type: certificateSubject
      operator: contains
      value: "localhost"

  locations:
    - local
```

### Testing Environment with Self-Signed (Better Approach)

```yaml
apiVersion: v1
kind: TlsCheck
metadata:
  name: staging-api-tls
  title: "Staging API TLS (Test CA)"
  labels:
    environment: staging
spec:
  hostname: api.staging.example.com
  port: 443
  interval: 1h
  timeout: 10s

  # Better than insecureSkipVerify: Use test CA
  trustedCAs:
    - |
      -----BEGIN CERTIFICATE-----
      ... Test/Staging CA Certificate ...
      -----END CERTIFICATE-----

  checks:
    - type: valid
      operator: is
      value: true

    - type: expirationTime
      operator: greaterThan
      value: 30d

  locations:
    - staging-us-east-1
```

---

## Validation Rules

### Required Fields

- `apiVersion` MUST be `"v1"`
- `kind` MUST be `"TlsCheck"` or `"SslCheck"`
- `metadata.name` MUST be valid `CaseInsensitiveKey`
- `spec.hostname` MUST be valid `DNSHostname`
- `spec.checks` MUST be non-empty array
- One of `spec.interval` or `spec.cron` MUST be specified

### Optional Fields

- `spec.port` defaults to `443`
- `spec.trustedCAs` defaults to `null` (use system trust store)
- `spec.insecureSkipVerify` defaults to `false`
- `spec.timeout` defaults to `1s`
- `spec.retries` defaults to `1`
- `spec.locations` defaults to `[]`
- `spec.channels` defaults to `[]`

### Field Constraints

- `spec.trustedCAs` and `spec.insecureSkipVerify` are mutually exclusive
- If `spec.insecureSkipVerify` is `true`, `checks` MUST NOT contain `valid` assertion
- Each CA in `spec.trustedCAs` MUST be valid PEM-encoded X.509 certificate

### Extra Fields

- Extra fields are FORBIDDEN (`extra="forbid"`)
- Unknown fields MUST cause validation errors

---

## Execution Semantics

### Connection Behavior

1. Runner connects to `hostname:port` via TCP
2. Runner initiates TLS handshake
3. Runner retrieves server certificate
4. Runner evaluates all assertions against certificate
5. Check PASSES if all assertions pass
6. Check FAILS if any assertion fails

### Error Conditions

Check FAILS if:
- Cannot connect to `hostname:port`
- TLS handshake fails
- No certificate presented
- Certificate is invalid or expired
- Any assertion evaluates to false
- Timeout exceeded

### Retry Behavior

- Failed checks are retried up to `retries` times
- Retries occur immediately after failure
- If ANY attempt succeeds, check is considered successful
- Timeout applies to total execution time including retries

---

## Conformance

Implementations claiming TlsCheck conformance MUST:

1. **Support both names**: Accept `TlsCheck` and `SslCheck` as valid kinds
2. **Validate hostname**: Enforce `DNSHostname` constraints
3. **Support all assertions**: Implement `expirationTime`, `certificateIssuer`, `certificateSubject`
4. **Default port**: Use `443` when port is not specified
5. **Evaluate all checks**: Execute all assertions in `checks` array
6. **Fail on any assertion failure**: Check fails if ANY assertion fails
7. **Handle timeouts**: Respect `timeout` field
8. **Retry on failure**: Implement retry logic according to `retries` field

Implementations SHOULD:
- Support multiple locations
- Send notifications to configured channels
- Provide detailed error messages for validation failures
- Report certificate details in results (issuer, subject, expiration date)

---

## Security Considerations

### Certificate Validation

- Implementations SHOULD validate entire certificate chain
- Implementations SHOULD verify certificate against system trust store
- Implementations MAY allow custom CA certificates
- Implementations SHOULD report certificate chain issues

### Hostname Verification

- Implementations SHOULD verify certificate hostname matches `spec.hostname`
- Implementations SHOULD support wildcards and Subject Alternative Names (SANs)
- Implementations SHOULD report hostname mismatch as check failure

### Timing Attacks

- Implementations SHOULD NOT leak timing information that could aid attackers
- Certificate validation SHOULD use constant-time operations where possible

---

## Implementation Notes

### Certificate Parsing

- Extract certificate expiration date
- Parse issuer Distinguished Name (DN)
- Parse subject Distinguished Name (DN)
- Handle certificate chain traversal

### Expiration Calculation

- Calculate days until expiration: `(expiration_date - current_date).days`
- Use system clock or NTP-synchronized time
- Consider timezone differences

### String Matching

- Certificate issuer/subject matching is case-sensitive by default
- Implementations MAY support case-insensitive matching
- `contains` operator searches anywhere in the DN string

### Custom CA Trust Store

**Check-Level Configuration** (via `trustedCAs`):
- Specified in check definition
- Portable across runners
- Self-contained
- Per-check granularity

**Runner-Level Configuration** (alternative approach):

Implementations MAY support runner-level CA configuration via:

**Environment Variables**:
```bash
# Set custom CA bundle for all TLS checks
export CUSTOM_CA_BUNDLE=/etc/ssl/certs/internal-ca-bundle.pem
synthetic-runner start

# Or for multiple CAs
export CUSTOM_CA_PATH=/etc/ssl/certs/internal-cas/
synthetic-runner start
```

**Configuration File**:
```yaml
# runner-config.yaml
tls:
  customCABundle: /etc/ssl/certs/internal-ca-bundle.pem
  # OR
  customCAPath: /etc/ssl/certs/internal-cas/
  # OR
  trustedCAs:
    - /etc/ssl/certs/ca1.pem
    - /etc/ssl/certs/ca2.pem
```

**System Trust Store Updates**:
```bash
# Add CA to system trust store (Linux)
sudo cp internal-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Add CA to system trust store (macOS)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain internal-ca.crt
```

**Precedence** (when both check-level and runner-level configured):
1. Check-level `trustedCAs` (highest priority)
2. Check-level `insecureSkipVerify`
3. Runner-level CA configuration
4. System trust store (default)

**Trade-offs**:

| Approach | Pros | Cons |
|----------|------|------|
| Check-level (`trustedCAs`) | Portable, explicit, auditable | Large YAML, duplication |
| Runner-level (env/config) | Shared across checks, smaller YAML | Implicit, runner-specific |
| System trust store | Standard approach, no config | Global impact, requires admin |

**Recommendation**:
- **Production**: Check-level `trustedCAs` (explicit, auditable)
- **Development**: Runner-level or system trust store (convenience)
- **CI/CD**: Runner-level via environment variables (flexibility)

---

## Related

- [Base Check Definition](check.md) - Common check structure
- [Common Types](common.md) - Shared types and operators
- [HttpCheck](http.md) - HTTP endpoint checks (uses TLS on port 443)

---

## Changelog

### v1 (Current)
- Renamed from `SslCheck` to `TlsCheck` (canonical name)
- Added `SslCheck` as backward-compatible alias
- Four assertion types: expirationTime, certificateIssuer, certificateSubject, valid
- Added `valid` assertion for overall certificate validity checking
- Added `trustedCAs` field for custom CA certificates (internal PKI support)
- Added `insecureSkipVerify` field for development/testing (disables validation)
- Clarified support for non-web protocols (SMTP, databases, etc.)
- Added port examples for common TLS services
- Documented both `TlsCheck` and `SslCheck` as valid kinds
- Documented runner-level CA configuration options
- StrictTime for expirationTime assertions (unit suffix required)
