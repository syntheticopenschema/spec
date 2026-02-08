# TCP Check

**Version**: v1
**Kind**: `TcpCheck`
**Status**: Stable

---

## Overview

The TCP Check validates TCP service availability by establishing TCP connections to specified ports. It monitors connection success, latency, and optionally SSL/TLS handshake completion.

**Common Use Cases:**
- Database server monitoring (PostgreSQL 5432, MySQL 3306, Redis 6379)
- Message queue monitoring (RabbitMQ 5672, Kafka 9092)
- Cache server monitoring (Memcached 11211, Redis 6379)
- Mail server monitoring (SMTP 25/587, IMAP 143/993, POP3 110/995)
- Custom TCP services
- Port availability verification
- Network connectivity testing
- SSL/TLS service validation

---

## Resource Structure

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: {check-name}
  labels:
    key: value
spec:
  host: db.example.com  # or IP address
  port: 5432

  # Scheduling (REQUIRED - one of)
  interval: 1m
  # OR
  cron: "*/5 * * * *"

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
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 100ms
```

---

## Spec Fields

### host

**Type**: `DNSHostname | IPvAnyAddress`
**REQUIRED**

**Description**: The hostname or IP address of the TCP service to check.

**Formats**:
- **DNS Hostname**: Domain name (e.g., `db.example.com`, `localhost`)
- **IPv4 Address**: Dotted decimal notation (e.g., `192.168.1.1`, `10.0.0.5`)
- **IPv6 Address**: Colon-hexadecimal notation (e.g., `2001:db8::1`, `::1`)

**Examples**:
```yaml
# DNS hostname
host: db.example.com

# Localhost
host: localhost

# IPv4 address
host: 192.168.1.100

# IPv6 address
host: 2001:db8::8a2e:370:7334

# IPv6 loopback
host: ::1
```

**Validation**:
- MUST be valid DNS hostname or IP address
- DNS hostnames automatically converted to lowercase
- IPv6 addresses MAY be compressed (::)
- Maximum hostname length: 253 characters

---

### port

**Type**: `integer`
**REQUIRED**

**Description**: The TCP port number to connect to.

**Common Ports**:

**Databases:**
- `5432` - PostgreSQL
- `3306` - MySQL/MariaDB
- `27017` - MongoDB
- `6379` - Redis
- `1433` - Microsoft SQL Server
- `5984` - CouchDB
- `9042` - Cassandra
- `7000` - Cassandra inter-node
- `8529` - ArangoDB

**Message Queues:**
- `5672` - RabbitMQ (AMQP)
- `15672` - RabbitMQ Management
- `9092` - Kafka
- `4222` - NATS
- `5445` - ActiveMQ

**Caching:**
- `6379` - Redis
- `11211` - Memcached

**Mail:**
- `25` - SMTP
- `587` - SMTP (submission)
- `465` - SMTPS
- `143` - IMAP
- `993` - IMAPS
- `110` - POP3
- `995` - POP3S

**Web/Proxy:**
- `80` - HTTP
- `443` - HTTPS
- `8080` - HTTP alternate
- `3128` - Squid proxy
- `9200` - Elasticsearch

**Other:**
- `22` - SSH
- `21` - FTP
- `3389` - RDP (Remote Desktop)
- `5900` - VNC

**Examples**:
```yaml
# PostgreSQL
port: 5432

# MySQL
port: 3306

# Redis
port: 6379

# Custom application
port: 8888
```

**Validation**:
- MUST be integer between 1 and 65535
- Well-known ports: 1-1023 (may require privileges)
- Registered ports: 1024-49151
- Dynamic/private ports: 49152-65535

---

### checks

**Type**: `array[TcpAssertion]`
**REQUIRED**

**Description**: List of assertions to evaluate against the TCP connection.

**Supported Assertion Types**:
1. `reachable` - Whether TCP connection succeeds
2. `latency` - TCP connection establishment time
3. `sslHandshake` - Whether SSL/TLS handshake succeeds (for TLS-enabled services)

See [Assertions](#assertions) section for details.

---

## Assertions

All TCP assertions validate properties of the TCP connection.

### reachable

**Type**: `BooleanAssertion`

**Description**: Assert on TCP connection success/failure.

**Fields**:
- `type`: `"reachable"` (REQUIRED)
- `operator`: `BooleanOperator` (REQUIRED)
  - `is`, `isNot`
- `value`: `boolean` (REQUIRED)
  - `true` - Connection should succeed
  - `false` - Connection should fail

**Examples**:

Assert connection succeeds:
```yaml
- type: reachable
  operator: is
  value: true
```

Assert port is closed (connection fails):
```yaml
- type: reachable
  operator: is
  value: false
```

Verify service is down:
```yaml
- type: reachable
  operator: isNot
  value: true
```

**Semantics**:
- `true` means TCP connection established successfully
- `false` means connection failed (refused, timeout, unreachable)
- Check PASSES if assertion evaluates to true
- Check FAILS if assertion evaluates to false

**Use Cases**:
- **Positive check** (`value: true`): Verify service is running
- **Negative check** (`value: false`): Verify port is closed (security validation)
- **Availability monitoring**: Ensure database/service is reachable

---

### latency

**Type**: `TimebasedAssertion`

**Description**: Assert on TCP connection establishment time (from connection initiation to successful establishment).

**Fields**:
- `type`: `"latency"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `StrictTime` (REQUIRED)
  - MUST include unit suffix: `"100ms"`, `"1s"`, etc.
  - Bare integers are NOT allowed

**Examples**:

Assert connection within 100ms (low latency):
```yaml
- type: latency
  operator: lessThan
  value: 100ms
```

Assert connection within 1 second:
```yaml
- type: latency
  operator: lessThan
  value: 1s
```

Assert connection within 500ms (SLA):
```yaml
- type: latency
  operator: lessThan
  value: 500ms
```

Using seconds:
```yaml
- type: latency
  operator: lessThan
  value: 2s
```

**Invalid - bare integers rejected**:
```yaml
- type: latency
  operator: lessThan
  value: 100  # ❌ ERROR: unit suffix required
```

**Semantics**:
- Latency measures time from connection initiation to successful TCP handshake
- Includes DNS resolution time (if hostname used)
- Does NOT include SSL/TLS handshake time
- Check PASSES if latency assertion evaluates to true
- Check FAILS if latency assertion evaluates to false
- Unit suffix REQUIRED to avoid ambiguity

**Performance Guidance**:
- **Excellent**: < 10ms (local network)
- **Good**: 10ms - 50ms (same region)
- **Acceptable**: 50ms - 100ms (cross-region)
- **Slow**: > 100ms

**Network Latency Context**:
- **Local network**: < 1ms
- **Same datacenter**: 1-5ms
- **Same region**: 10-20ms
- **Cross-region (US)**: 50-80ms
- **Transatlantic**: 80-120ms
- **Transpacific**: 150-200ms

---

### sslHandshake

**Type**: `BooleanAssertion`

**Description**: Assert on SSL/TLS handshake success for TLS-enabled TCP services.

**Fields**:
- `type`: `"sslHandshake"` (REQUIRED)
- `operator`: `BooleanOperator` (REQUIRED)
  - `is`, `isNot`
- `value`: `boolean` (REQUIRED)
  - `true` - TLS handshake should succeed
  - `false` - TLS handshake should fail

**Examples**:

Assert TLS handshake succeeds:
```yaml
- type: sslHandshake
  operator: is
  value: true
```

Verify TLS is enabled:
```yaml
- type: sslHandshake
  operator: isNot
  value: false
```

**Semantics**:
- Only applicable to services that support SSL/TLS
- `true` means TLS handshake completed successfully
- `false` means TLS handshake failed
- Check PASSES if assertion evaluates to true
- Check FAILS if assertion evaluates to false

**Use Cases**:
- Verify database uses SSL/TLS (PostgreSQL, MySQL)
- Validate SMTP STARTTLS support
- Ensure Redis TLS is enabled
- Confirm LDAPS connection

**TLS-Enabled Services**:
- **SMTPS**: port 465
- **IMAPS**: port 993
- **POP3S**: port 995
- **LDAPS**: port 636
- **PostgreSQL with TLS**: port 5432 (optional)
- **MySQL with TLS**: port 3306 (optional)
- **Redis with TLS**: port 6379 (configurable)

**Note**: For comprehensive certificate validation (expiration, issuer, subject), use [TlsCheck](tls.md) instead.

---

## Examples

### Basic Database Connectivity Check

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: postgres-connectivity
  title: "PostgreSQL Database Connectivity"
  labels:
    environment: production
    service: database
spec:
  host: db.example.com
  port: 5432
  interval: 1m
  timeout: 5s
  retries: 2
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 100ms
  locations:
    - us-east-1
  channels:
    - channel: database-alerts
      severity: Critical
```

### Redis Cache Monitoring

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: redis-cache
  title: "Redis Cache Availability"
  labels:
    environment: production
    service: cache
spec:
  host: cache.example.com
  port: 6379
  interval: 30s
  timeout: 3s
  retries: 3
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 50ms
  locations:
    - us-east-1
    - us-west-2
  channels:
    - channel: infrastructure-alerts
      severity: High
```

### MySQL with TLS Validation

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: mysql-tls-check
  title: "MySQL TLS Connectivity"
  labels:
    environment: production
    service: database
    security: true
spec:
  host: mysql.example.com
  port: 3306
  interval: 5m
  timeout: 10s
  checks:
    - type: reachable
      operator: is
      value: true
    - type: sslHandshake
      operator: is
      value: true  # Verify TLS is enabled
    - type: latency
      operator: lessThan
      value: 200ms
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: Critical
```

### SMTP Server Connectivity

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: smtp-server
  title: "SMTP Server Availability"
  labels:
    environment: production
    service: email
spec:
  host: smtp.example.com
  port: 587  # SMTP submission
  interval: 5m
  timeout: 5s
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 500ms
  locations:
    - us-east-1
  channels:
    - channel: email-alerts
      severity: High
```

### IPv4 and IPv6 Dual-Stack Monitoring

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: web-server-ipv4
  title: "Web Server IPv4 Connectivity"
spec:
  host: 203.0.113.42  # IPv4 address
  port: 443
  interval: 1m
  timeout: 5s
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 100ms
---
apiVersion: v1
kind: TcpCheck
metadata:
  name: web-server-ipv6
  title: "Web Server IPv6 Connectivity"
spec:
  host: 2001:db8::1  # IPv6 address
  port: 443
  interval: 1m
  timeout: 5s
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 100ms
```

### Port Security Validation (Negative Check)

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: ftp-port-closed
  title: "Verify FTP Port is Closed (Security)"
  labels:
    environment: production
    security: true
spec:
  host: server.example.com
  port: 21  # FTP (should be disabled)
  interval: 1h
  timeout: 5s
  checks:
    - type: reachable
      operator: is
      value: false  # Expect connection to fail
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: Critical
```

### Message Queue Monitoring

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: rabbitmq-broker
  title: "RabbitMQ Broker Connectivity"
  labels:
    environment: production
    service: messaging
spec:
  host: mq.example.com
  port: 5672  # AMQP
  interval: 1m
  timeout: 5s
  retries: 2
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 100ms
  locations:
    - us-east-1
    - eu-west-1
  channels:
    - channel: messaging-alerts
      severity: Critical
```

### Localhost Service Check

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: local-service
  title: "Local Service Health"
spec:
  host: localhost
  port: 8080
  interval: 30s
  timeout: 2s
  checks:
    - type: reachable
      operator: is
      value: true
    - type: latency
      operator: lessThan
      value: 10ms  # Local should be very fast
  locations:
    - local
```

---

## Validation Rules

### Required Fields

- `apiVersion` MUST be `"v1"`
- `kind` MUST be `"TcpCheck"`
- `metadata.name` MUST be valid `CaseInsensitiveKey`
- `spec.host` MUST be valid `DNSHostname` or `IPvAnyAddress`
- `spec.port` MUST be integer 1-65535
- `spec.checks` MUST be non-empty array
- One of `spec.interval` or `spec.cron` MUST be specified

### Optional Fields

- `spec.timeout` defaults to `10s`
- `spec.retries` defaults to `1`
- `spec.locations` defaults to `[]`
- `spec.channels` defaults to `[]`

### Extra Fields

- Extra fields are FORBIDDEN (`extra="forbid"`)
- Unknown fields MUST cause validation errors

---

## Execution Semantics

### Connection Behavior

1. Runner resolves `host` hostname via DNS (if hostname, not IP)
2. Runner initiates TCP connection to `host:port`
3. Runner performs TCP three-way handshake (SYN, SYN-ACK, ACK)
4. If `sslHandshake` assertion present, runner initiates TLS handshake
5. Runner evaluates all assertions in `checks` array
6. Runner closes connection
7. Check PASSES if all assertions pass
8. Check FAILS if any assertion fails

### TCP Handshake

**Three-way handshake**:
1. Client sends SYN packet
2. Server responds with SYN-ACK packet
3. Client sends ACK packet
4. Connection established

**Latency measurement**: Time from step 1 to step 4 completion.

### TLS Handshake (if sslHandshake checked)

**After TCP established**:
1. Client sends ClientHello
2. Server responds with ServerHello, Certificate, etc.
3. Client verifies certificate, sends key exchange
4. TLS connection established

**Note**: Use [TlsCheck](tls.md) for comprehensive certificate validation.

### Timeout Behavior

- Timeout applies to total execution time (DNS + TCP handshake + TLS handshake)
- If timeout exceeded, check FAILS with timeout error
- Connection is aborted on timeout

### Error Conditions

Check FAILS if:
- DNS resolution fails (hostname)
- Cannot establish TCP connection
- Connection refused (port closed/filtered)
- Connection timeout
- TLS handshake fails (if sslHandshake assertion present)
- Any assertion evaluates to false
- Network error occurs

**Common Error Types**:
- **DNS Error**: Hostname cannot be resolved
- **Connection Refused**: Port is closed or service not listening
- **Timeout**: No response within timeout period
- **Network Unreachable**: Routing failure
- **TLS Error**: TLS handshake failed

### Retry Behavior

- Failed checks are retried up to `retries` times
- Retries occur immediately after failure
- If ANY attempt succeeds, check is considered successful
- Timeout applies to each individual attempt

---

## Conformance

Implementations claiming TcpCheck conformance MUST:

1. **Support DNS hostnames**: Resolve DNS names to IP addresses
2. **Support IP addresses**: Accept both IPv4 and IPv6 addresses
3. **Support all assertions**: Implement reachable, latency, sslHandshake
4. **Evaluate all checks**: Execute all assertions in `checks` array
5. **Fail on any assertion failure**: Check fails if ANY assertion fails
6. **Handle timeouts**: Respect `timeout` field
7. **Retry on failure**: Implement retry logic according to `retries` field
8. **Close connections**: Properly close TCP connections after check

Implementations SHOULD:
- Support multiple locations
- Send notifications to configured channels
- Provide detailed error messages for connection failures
- Report DNS resolution time separately
- Report TLS handshake time separately (if applicable)
- Validate TLS certificates (if sslHandshake used)

---

## Security Considerations

### Firewall and Network Policies

- TCP checks originate from check runner infrastructure
- May require firewall rules to allow connections
- Consider IP allowlisting for production checks
- Private networks may need VPN or bastion access

### Port Scanning

- Frequent TCP checks MAY appear as port scanning
- Configure check frequency appropriately
- Document check sources for security teams
- Avoid checking large port ranges

### TLS Validation

- `sslHandshake` assertion verifies TLS capability only
- For certificate validation, use [TlsCheck](tls.md)
- Implementations SHOULD validate certificates by default
- Invalid certificates SHOULD cause sslHandshake to fail

### Credential-Free

- TCP checks do NOT support authentication
- Only tests network connectivity
- Use application-level checks (HTTP, etc.) for authenticated services

---

## Performance Considerations

### Connection Overhead

- Each check opens and closes a new TCP connection
- No connection pooling/reuse
- Minimal overhead for most services
- Some services MAY rate-limit connection attempts

### Latency Expectations

**By Network Type**:
- **Loopback** (localhost): < 1ms
- **LAN**: 1-10ms
- **Same Region**: 10-50ms
- **Cross-Region**: 50-200ms
- **International**: 100-300ms

**By Service Type**:
- **Databases**: Expect 1-50ms (same region)
- **Caches**: Expect 1-20ms (same region)
- **Message Queues**: Expect 1-50ms (same region)

### Check Frequency

- **Critical services**: 30s - 1m
- **Standard services**: 1m - 5m
- **Non-critical services**: 5m - 15m
- Consider service load and connection limits

---

## Implementation Notes

### DNS Resolution

- DNS resolution time included in latency
- Cache DNS results to reduce latency variation
- Support both IPv4 (A) and IPv6 (AAAA) records
- Prefer IPv6 if available (dual-stack)

### Connection Establishment

- Use operating system's TCP stack
- Respect system socket timeouts
- Handle connection backlog appropriately
- Clean up file descriptors

### TLS Handshake

- Use system's TLS library
- Validate certificates against system trust store
- Support TLS 1.2 and TLS 1.3
- Handle TLS errors gracefully

### Error Handling

- Distinguish connection refused vs. timeout
- Report DNS errors separately
- Provide actionable error messages
- Log connection attempts for debugging

---

## Related

- [Base Check Definition](check.md) - Common check structure
- [Common Types](common.md) - Shared types and operators
- [TlsCheck](tls.md) - Comprehensive TLS/SSL certificate validation
- [HttpCheck](http.md) - HTTP/HTTPS endpoint checks

---

## Changelog

### v1 (Current)
- Initial stable release
- Three assertion types: reachable, latency, sslHandshake
- Support for DNS hostnames, IPv4, and IPv6 addresses
- StrictTime for latency assertions (unit suffix required)
- Dual-stack (IPv4/IPv6) support
- Multi-location execution
