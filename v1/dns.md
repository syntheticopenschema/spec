# DNS Check

**Version**: v1
**Kind**: `DnsCheck`
**Status**: Stable

---

## Overview

The DNS Check validates DNS resolution by querying DNS records for hostnames. It monitors record existence, values, and DNS resolution performance.

**Common Use Cases:**
- Domain DNS resolution monitoring
- DNS propagation verification
- DNS record value validation (IP addresses, MX records, TXT records)
- DNS resolver health checks
- SPF/DKIM/DMARC validation
- Service discovery (SRV records)
- Reverse DNS validation (PTR records)
- DNS failover validation

---

## Resource Structure

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: {check-name}
  labels:
    key: value
spec:
  hostname: example.com
  recordType: A
  resolver:  # optional custom DNS servers
    - 8.8.8.8
    - 1.1.1.1

  # Scheduling (REQUIRED - one of)
  interval: 5m
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
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "192.0.2.1"
```

---

## Spec Fields

### hostname

**Type**: `DNSHostname`
**REQUIRED**

**Description**: The hostname to query DNS records for.

**Examples**:
```yaml
hostname: example.com
hostname: www.example.com
hostname: api.example.com
hostname: mail.example.com
hostname: _service._tcp.example.com  # SRV record
```

**Validation**:
- MUST be valid DNS hostname
- Automatically converted to lowercase
- Maximum length: 253 characters
- Labels separated by dots
- Each label: 1-63 characters
- Supports internationalized domain names (IDN)

---

### recordType

**Type**: `DnsRecordType` (enum)
**REQUIRED**

**Description**: The type of DNS record to query.

**Supported Record Types** (14 types):

| Type | Description | Example Value |
|------|-------------|---------------|
| `A` | IPv4 address | `192.0.2.1` |
| `AAAA` | IPv6 address | `2001:db8::1` |
| `CNAME` | Canonical name | `www.example.com.` |
| `ALIAS` | Alias record | `example.com.` |
| `MX` | Mail exchange | `10 mail.example.com.` |
| `NS` | Name server | `ns1.example.com.` |
| `PTR` | Pointer (reverse DNS) | `example.com.` |
| `SOA` | Start of authority | `ns1.example.com. admin.example.com. ...` |
| `SRV` | Service record | `0 5 5060 sipserver.example.com.` |
| `NAPTR` | Naming authority pointer | Complex format |
| `TXT` | Text record | `"v=spf1 include:_spf.example.com ~all"` |
| `SPF` | Sender Policy Framework | `"v=spf1 mx ~all"` |
| `HINFO` | Host information | `"PC-Intel-Core" "Linux"` |
| `CAA` | Certificate authority authorization | `0 issue "letsencrypt.org"` |

**Examples**:
```yaml
# IPv4 address
recordType: A

# IPv6 address
recordType: AAAA

# Mail server
recordType: MX

# Text record (SPF, DKIM, etc.)
recordType: TXT

# Name server
recordType: NS

# Service discovery
recordType: SRV

# Certificate authority authorization
recordType: CAA
```

**Record Type Details**:

**A (Address)**: IPv4 address
```
example.com.  3600  IN  A  192.0.2.1
```

**AAAA (IPv6 Address)**: IPv6 address
```
example.com.  3600  IN  AAAA  2001:db8::1
```

**CNAME (Canonical Name)**: Alias to another domain
```
www.example.com.  3600  IN  CNAME  example.com.
```

**MX (Mail Exchange)**: Mail server with priority
```
example.com.  3600  IN  MX  10 mail.example.com.
example.com.  3600  IN  MX  20 mail2.example.com.
```

**NS (Name Server)**: Authoritative name servers
```
example.com.  3600  IN  NS  ns1.example.com.
example.com.  3600  IN  NS  ns2.example.com.
```

**TXT (Text)**: Arbitrary text data (SPF, DKIM, DMARC, domain verification)
```
example.com.  3600  IN  TXT  "v=spf1 include:_spf.google.com ~all"
example.com.  3600  IN  TXT  "google-site-verification=..."
```

**SRV (Service)**: Service location
```
_sip._tcp.example.com.  3600  IN  SRV  0 5 5060 sipserver.example.com.
Format: priority weight port target
```

**CAA (Certificate Authority Authorization)**: Specify allowed CAs
```
example.com.  3600  IN  CAA  0 issue "letsencrypt.org"
example.com.  3600  IN  CAA  0 issuewild ";"
```

---

### resolver

**Type**: `array[IPvAnyAddress]`
**OPTIONAL**
**Default**: System default nameservers

**Description**: Custom DNS servers to use for resolution. If not specified, uses system's default DNS resolvers.

**Examples**:
```yaml
# Google Public DNS
resolver:
  - 8.8.8.8
  - 8.8.4.4

# Cloudflare DNS
resolver:
  - 1.1.1.1
  - 1.0.0.1

# Quad9 DNS
resolver:
  - 9.9.9.9

# Custom internal DNS
resolver:
  - 10.0.0.53

# IPv6 resolvers
resolver:
  - 2001:4860:4860::8888  # Google
  - 2606:4700:4700::1111  # Cloudflare
```

**Common Public DNS Servers**:
- **Google**: `8.8.8.8`, `8.8.4.4`
- **Cloudflare**: `1.1.1.1`, `1.0.0.1`
- **Quad9**: `9.9.9.9`, `149.112.112.112`
- **OpenDNS**: `208.67.222.222`, `208.67.220.220`
- **AdGuard**: `94.140.14.14`, `94.140.15.15`

**Use Cases**:
- Verify DNS propagation across different resolvers
- Test authoritative nameservers directly
- Validate internal DNS servers
- Check DNS filtering/blocking
- Test DNS failover

---

### checks

**Type**: `array[DnsAssertion]`
**REQUIRED**

**Description**: List of assertions to evaluate against DNS query results.

**Supported Assertion Types**:
1. `recordExists` - Whether DNS records were found
2. `recordValue` - DNS record value matching

See [Assertions](#assertions) section for details.

---

## Assertions

All DNS assertions validate properties of DNS query results.

### recordExists

**Type**: `BooleanAssertion`

**Description**: Assert on whether DNS records exist for the queried hostname and record type.

**Fields**:
- `type`: `"recordExists"` (REQUIRED)
- `operator`: `BooleanOperator` (REQUIRED)
  - `is`, `isNot`
- `value`: `boolean` (REQUIRED)
  - `true` - Records should exist
  - `false` - Records should not exist

**Examples**:

Assert records exist:
```yaml
- type: recordExists
  operator: is
  value: true
```

Verify domain has A record:
```yaml
- type: recordExists
  operator: isNot
  value: false  # Expect records to exist
```

Assert no records (negative check):
```yaml
- type: recordExists
  operator: is
  value: false  # Expect NXDOMAIN or empty result
```

**Semantics**:
- `true` means at least one DNS record was returned
- `false` means no DNS records found (NXDOMAIN or empty result)
- Check PASSES if assertion evaluates to true
- Check FAILS if assertion evaluates to false

**Use Cases**:
- **Positive check** (`value: true`): Verify domain resolves
- **Negative check** (`value: false`): Verify domain doesn't exist (expired, removed)
- **Availability monitoring**: Ensure DNS is working

---

### recordValue

**Type**: `StringAssertion`

**Description**: Assert on DNS record value content.

**Fields**:
- `type`: `"recordValue"` (REQUIRED)
- `operator`: `StringOperator` (REQUIRED)
  - `equals`, `notEquals`, `contains`, `notContains`
- `value`: `string` (REQUIRED)

**Examples**:

Assert specific IP address:
```yaml
- type: recordValue
  operator: equals
  value: "192.0.2.1"
```

Assert IP in range (subnet):
```yaml
- type: recordValue
  operator: contains
  value: "192.0.2."
```

Assert mail server:
```yaml
- type: recordValue
  operator: contains
  value: "mail.example.com"
```

Assert SPF record includes Google:
```yaml
- type: recordValue
  operator: contains
  value: "include:_spf.google.com"
```

Verify CAA allows Let's Encrypt:
```yaml
- type: recordValue
  operator: contains
  value: "letsencrypt.org"
```

Assert NOT using old IP:
```yaml
- type: recordValue
  operator: notContains
  value: "203.0.113.1"  # Old IP
```

**Semantics**:
- Matching is case-sensitive by default
- `contains` searches in ANY returned record
- `equals` requires exact match with at least ONE record
- Multiple records: assertion passes if ANY record matches
- Check PASSES if record value assertion evaluates to true
- Check FAILS if record value assertion evaluates to false

**Multi-Record Behavior**:

If DNS query returns multiple records:
```
example.com.  IN  A  192.0.2.1
example.com.  IN  A  192.0.2.2
example.com.  IN  A  192.0.2.3
```

Then:
- `contains: "192.0.2.1"` - PASSES (found in first record)
- `contains: "192.0.2"` - PASSES (found in all records)
- `equals: "192.0.2.1"` - PASSES (exact match with first record)
- `notContains: "192.0.2.4"` - PASSES (not in any record)

**Record Format Examples**:

**A/AAAA**: IP address only
```
192.0.2.1
2001:db8::1
```

**MX**: Priority + mail server
```
10 mail.example.com.
20 mail2.example.com.
```

**TXT**: Quoted text
```
"v=spf1 include:_spf.example.com ~all"
"google-site-verification=abc123..."
```

**SRV**: Priority + weight + port + target
```
0 5 5060 sipserver.example.com.
```

**CNAME**: Target domain
```
www.example.com.
```

---

## Examples

### Basic A Record Check

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: domain-a-record
  title: "Domain A Record Validation"
  labels:
    environment: production
spec:
  hostname: example.com
  recordType: A
  interval: 5m
  timeout: 5s
  retries: 2
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "192.0.2."  # Validate IP subnet
  locations:
    - us-east-1
    - eu-west-1
  channels:
    - channel: dns-alerts
      severity: Critical
```

### MX Record Validation

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: mail-server-mx
  title: "Mail Server MX Records"
  labels:
    environment: production
    service: email
spec:
  hostname: example.com
  recordType: MX
  interval: 1h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "mail.example.com"
  locations:
    - us-east-1
  channels:
    - channel: email-alerts
      severity: High
```

### SPF Record Validation

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: spf-record
  title: "SPF Record Validation"
  labels:
    environment: production
    security: true
spec:
  hostname: example.com
  recordType: TXT
  interval: 6h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "v=spf1"
    - type: recordValue
      operator: contains
      value: "include:_spf.google.com"
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: Medium
```

### DNS Propagation Check (Multiple Resolvers)

```yaml
# Check Google DNS
apiVersion: v1
kind: DnsCheck
metadata:
  name: dns-propagation-google
  title: "DNS Propagation - Google DNS"
spec:
  hostname: example.com
  recordType: A
  resolver:
    - 8.8.8.8
  interval: 5m
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: equals
      value: "192.0.2.1"  # New IP
---
# Check Cloudflare DNS
apiVersion: v1
kind: DnsCheck
metadata:
  name: dns-propagation-cloudflare
  title: "DNS Propagation - Cloudflare DNS"
spec:
  hostname: example.com
  recordType: A
  resolver:
    - 1.1.1.1
  interval: 5m
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: equals
      value: "192.0.2.1"  # New IP
```

### CAA Record Validation

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: caa-letsencrypt
  title: "CAA Record - Let's Encrypt Authorization"
  labels:
    environment: production
    security: true
spec:
  hostname: example.com
  recordType: CAA
  interval: 24h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "letsencrypt.org"
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: High
```

### SRV Record Check (Service Discovery)

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: sip-service
  title: "SIP Service SRV Record"
spec:
  hostname: _sip._tcp.example.com
  recordType: SRV
  interval: 10m
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "sipserver.example.com"
  locations:
    - us-east-1
```

### IPv6 (AAAA) Record Check

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: ipv6-address
  title: "IPv6 AAAA Record"
  labels:
    environment: production
spec:
  hostname: www.example.com
  recordType: AAAA
  interval: 5m
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "2001:db8:"
  locations:
    - us-east-1
```

### CNAME Record Validation

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: www-cname
  title: "WWW CNAME Record"
spec:
  hostname: www.example.com
  recordType: CNAME
  interval: 1h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "example.com"
  locations:
    - us-east-1
```

### NS Record Check

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: nameserver-records
  title: "Authoritative Nameservers"
spec:
  hostname: example.com
  recordType: NS
  interval: 12h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "ns1.example.com"
    - type: recordValue
      operator: contains
      value: "ns2.example.com"
  locations:
    - us-east-1
```

### Domain Verification TXT Record

```yaml
apiVersion: v1
kind: DnsCheck
metadata:
  name: google-verification
  title: "Google Domain Verification"
spec:
  hostname: example.com
  recordType: TXT
  interval: 24h
  timeout: 5s
  checks:
    - type: recordExists
      operator: is
      value: true
    - type: recordValue
      operator: contains
      value: "google-site-verification="
  locations:
    - us-east-1
```

---

## Validation Rules

### Required Fields

- `apiVersion` MUST be `"v1"`
- `kind` MUST be `"DnsCheck"`
- `metadata.name` MUST be valid `CaseInsensitiveKey`
- `spec.hostname` MUST be valid `DNSHostname`
- `spec.recordType` MUST be valid `DnsRecordType`
- `spec.checks` MUST be non-empty array
- One of `spec.interval` or `spec.cron` MUST be specified

### Optional Fields

- `spec.resolver` defaults to system nameservers
- `spec.timeout` defaults to `10s`
- `spec.retries` defaults to `1`
- `spec.locations` defaults to `[]`
- `spec.channels` defaults to `[]`

### Extra Fields

- Extra fields are FORBIDDEN (`extra="forbid"`)
- Unknown fields MUST cause validation errors

---

## Execution Semantics

### Query Behavior

1. Runner selects nameserver (custom resolver or system default)
2. Runner sends DNS query for `hostname` with `recordType`
3. Runner waits for DNS response
4. Runner parses returned records
5. Runner evaluates all assertions in `checks` array
6. Check PASSES if all assertions pass
7. Check FAILS if any assertion fails

### Resolver Selection

- If `resolver` specified: Use first responsive resolver from list
- If `resolver` not specified: Use system's default nameservers
- Fallback to next resolver if first fails (implementation-defined)

### Timeout Behavior

- Timeout applies to total query execution time
- DNS query timeout: `timeout` value
- If timeout exceeded, check FAILS with timeout error

### Error Conditions

Check FAILS if:
- DNS query timeout
- NXDOMAIN (domain does not exist)
- SERVFAIL (server failure)
- REFUSED (query refused)
- No nameservers responsive
- Any assertion evaluates to false
- Network error occurs

**Common DNS Errors**:
- **NXDOMAIN**: Domain does not exist
- **SERVFAIL**: DNS server encountered an error
- **TIMEOUT**: No response within timeout period
- **REFUSED**: Server refused the query
- **NODATA**: Domain exists but no records of requested type

### Retry Behavior

- Failed checks are retried up to `retries` times
- Retries occur immediately after failure
- If ANY attempt succeeds, check is considered successful
- Timeout applies to each individual attempt

---

## Conformance

Implementations claiming DnsCheck conformance MUST:

1. **Support all record types**: Implement all 14 DnsRecordType values
2. **Support custom resolvers**: Accept `resolver` parameter with IPv4/IPv6 addresses
3. **Support all assertions**: Implement recordExists and recordValue
4. **Evaluate all checks**: Execute all assertions in `checks` array
5. **Fail on any assertion failure**: Check fails if ANY assertion fails
6. **Handle timeouts**: Respect `timeout` field
7. **Retry on failure**: Implement retry logic according to `retries` field
8. **Parse DNS responses**: Correctly parse all supported record types

Implementations SHOULD:
- Support multiple locations
- Send notifications to configured channels
- Provide detailed error messages (RCODE, error type)
- Report TTL values
- Report authoritative flag
- Report which resolver was used
- Cache DNS results appropriately

---

## Security Considerations

### DNS Cache Poisoning

- Use secure DNS resolvers (DNSSEC-enabled)
- Validate DNS responses
- Consider using DNS-over-HTTPS (DoH) or DNS-over-TLS (DoT)

### DNS Privacy

- DNS queries may reveal monitoring targets
- Consider privacy implications of DNS queries
- Use encrypted DNS protocols when appropriate

### DNSSEC

- Implementations SHOULD support DNSSEC validation
- Report DNSSEC validation status
- Fail checks on DNSSEC validation errors (configurable)

### DNS Amplification

- Frequent DNS queries MAY be flagged as abuse
- Configure appropriate check frequency
- Document check sources for DNS operators

---

## Performance Considerations

### Query Latency

**Typical DNS resolution times**:
- **Cached**: < 1ms
- **Local network**: 1-10ms
- **ISP DNS**: 10-50ms
- **Public DNS**: 10-100ms
- **Authoritative query**: 50-200ms

### TTL (Time to Live)

- DNS records have TTL values (cache duration)
- Low TTL: More queries, higher load, faster updates
- High TTL: Fewer queries, lower load, slower updates
- Consider TTL when setting check frequency

### Check Frequency

- **Critical domains**: 1m - 5m
- **Standard domains**: 5m - 1h
- **Non-critical domains**: 1h - 24h
- Consider DNS server load

### Resolver Performance

**Public DNS Latency** (approximate):
- **Cloudflare** (1.1.1.1): 10-30ms
- **Google** (8.8.8.8): 15-40ms
- **Quad9** (9.9.9.9): 20-50ms

---

## Implementation Notes

### Record Parsing

**A/AAAA**: Simple IP address string
```python
"192.0.2.1"
"2001:db8::1"
```

**MX**: Priority + hostname
```python
"10 mail.example.com."
```

**TXT**: Quoted strings (may have multiple)
```python
"v=spf1 include:_spf.example.com ~all"
```

**SRV**: Priority + weight + port + target
```python
"0 5 5060 sipserver.example.com."
```

### Multiple Records

- DNS queries often return multiple records
- Store all records in results
- Assertions evaluated against ALL records
- ANY record match = assertion passes

### DNS Libraries

Recommended libraries:
- **Python**: `dnspython`
- **Go**: `net` package, `miekg/dns`
- **Node.js**: `dns` module, `dns-packet`
- **Java**: `dnsjava`

---

## Related

- [Base Check Definition](check.md) - Common check structure
- [Common Types](common.md) - Shared types and operators
- [TcpCheck](tcp.md) - TCP connection testing
- [HttpCheck](http.md) - HTTP endpoint checks

---

## Changelog

### v1 (Current)
- Initial stable release
- 14 DNS record types supported
- Two assertion types: recordExists, recordValue
- Custom resolver support (IPv4/IPv6)
- Multi-location execution
