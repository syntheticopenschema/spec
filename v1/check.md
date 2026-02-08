# Base Check Definition

**Version**: v1
**Status**: Stable

---

## Overview

This document defines the base `Resource` model that all check types in Synthetic Open Schema v1 extend.

All checks follow a Kubernetes-style resource structure with `apiVersion`, `kind`, `metadata`, and `spec` fields.

---

## Resource Structure

Every check MUST conform to this base structure:

```yaml
apiVersion: v1
kind: {CheckKind}
metadata:
  name: {check-name}
  title: {optional-title}
  labels:
    key: value
spec:
  # Check-specific fields
  # Common fields (interval, timeout, etc.)
```

---

## Fields

### apiVersion

**Type**: `string`
**REQUIRED**

**Description**: The API version of the schema.

**Value**: `v1`

**Example**:
```yaml
apiVersion: v1
```

**Validation**:
- MUST be exactly `v1` for this specification version
- MUST be a literal value (not computed)

**Custom Extensions**:
Companies implementing custom check kinds MAY use their own namespace:
```yaml
apiVersion: company.com/v1
kind: CustomCheck
```

---

### kind

**Type**: `string`
**REQUIRED**

**Description**: The type of check being defined.

**Standard Values** (for `apiVersion: v1`):
- `HttpCheck`
- `TcpCheck`
- `SslCheck`
- `DnsCheck`
- `DomainCheck` (planned)

**Note**: Browser checks use `apiVersion: browser/v1` and have their own check kinds:
- `LoadCheck` - Passive page load monitoring
- `ScriptedCheck` - Active browser automation

**Example**:
```yaml
kind: HttpCheck
```

**Validation**:
- MUST be a valid check kind
- MUST match one of the supported kinds for the implementation
- Case-sensitive

**Custom Extensions**:
Companies MAY define custom check kinds under their own namespace (see `apiVersion`).

---

### metadata

**Type**: `Metadata` object
**REQUIRED**

**Description**: Identifying information for the check.

**Fields**:
- `name`: Identifier for the check (REQUIRED)
- `title`: Human-readable title (OPTIONAL)
- `labels`: Key-value labels for organization (OPTIONAL)

**Example**:
```yaml
metadata:
  name: api-health-check
  title: "Production API Health Check"
  labels:
    environment: production
    service: api
    team: platform
```

---

## Metadata Fields

### metadata.name

**Type**: `CaseInsensitiveKey`
**REQUIRED**

**Description**: Unique identifier for the check within its scope.

**Format**: `^[A-Za-z0-9\-]+$`

**Constraints**:
- MUST contain at least one character
- MUST contain only alphanumeric characters and hyphens
- MUST NOT start or end with a hyphen
- Automatically converted to lowercase
- MUST follow DNS subdomain naming conventions

**Examples**:
```yaml
name: api-health-check
name: checkout-flow-monitor
name: prod-database-connectivity
```

**Uniqueness**:
The combination of `apiVersion`, `kind`, and `metadata.name` forms a unique key for the check:
```
v1:HttpCheck:api-health-check
```

---

### metadata.title

**Type**: `string`
**OPTIONAL**
**Default**: `null`

**Description**: Human-readable title for the check.

**Example**:
```yaml
title: "Production API Health Check"
```

**Usage**:
- For display in UIs
- For reporting
- Documentation purposes
- Can contain spaces and special characters

---

### metadata.labels

**Type**: `object` (key-value pairs)
**OPTIONAL**
**Default**: `{}`

**Description**: Arbitrary key-value labels for organizing and filtering checks.

**Example**:
```yaml
labels:
  environment: production
  service: api
  team: platform
  region: us-east-1
  criticality: high
```

**Constraints**:
- Keys and values MUST be strings
- Labels are for organization only
- Do not affect check execution
- Implementation-specific usage (filtering, grouping, etc.)

**Validation**:
- MUST be a dictionary/map
- Keys and values MUST be strings
- Empty labels object is valid

---

## spec

**Type**: Check-specific object
**REQUIRED**

**Description**: The specification for the check, containing both check-specific fields and common fields.

**Structure**:
```yaml
spec:
  # Scheduling (REQUIRED - one of):
  interval: 1m     # OR
  cron: "*/5 * * * *"

  # Common fields (OPTIONAL):
  timeout: 5s
  retries: 3
  locations:
    - us-east-1
    - eu-west-1
  channels:
    - channel: alerts
      severity: High

  # Check-specific fields:
  # (defined by each check kind)
```

---

## Base CheckSpec

All check kinds extend the base `CheckSpec` with these common fields:

### Scheduling Fields

**REQUIRED**: Exactly ONE of `interval` or `cron` MUST be specified.

#### interval

**Type**: `Time`
**REQUIRED** (if `cron` not specified)

**Description**: Execute check at regular intervals.

**Example**:
```yaml
interval: 1m
```

See [common.md](common.md#time-format) for Time format specification.

#### cron

**Type**: `string` (cron expression)
**REQUIRED** (if `interval` not specified)

**Description**: Execute check based on cron schedule.

**Format**: Standard cron (5 or 6 fields)

**Example**:
```yaml
cron: "*/5 * * * *"  # Every 5 minutes
cron: "0 0 * * *"    # Daily at midnight
```

**Validation**:
- MUST be valid cron expression
- Validated using croniter semantics

**Mutual Exclusion**:
```yaml
# VALID: Only interval
spec:
  interval: 1m

# VALID: Only cron
spec:
  cron: "*/5 * * * *"

# INVALID: Both specified
spec:
  interval: 1m
  cron: "*/5 * * * *"  # ERROR!

# INVALID: Neither specified
spec:
  timeout: 5s  # ERROR! Missing interval or cron
```

---

### Common Optional Fields

#### timeout

**Type**: `Time`
**OPTIONAL**
**Default**: `1s`

**Description**: Maximum duration allowed for check execution.

**Example**:
```yaml
timeout: 5s
```

**Behavior**:
- Check MUST be terminated if execution exceeds timeout
- Timeout includes all retry attempts
- Timed-out checks are considered failures

---

#### retries

**Type**: `integer`
**OPTIONAL**
**Default**: `1`

**Description**: Number of retry attempts on check failure.

**Example**:
```yaml
retries: 3
```

**Constraints**:
- MUST be positive integer
- Value of `1` means no retries (execute once)
- Value of `3` means execute up to 3 times (initial + 2 retries)

**Behavior**:
- Retries occur immediately after failure
- If any attempt succeeds, check is considered successful
- Timeout applies to total execution time including all retries

---

#### locations

**Type**: `array[string]`
**OPTIONAL**
**Default**: `[]`

**Description**: Geographic locations or execution environments where check should run.

**Example**:
```yaml
locations:
  - us-east-1
  - eu-west-1
  - ap-southeast-1
```

**Behavior**:
- Empty list means run in default location
- Check executes independently in each location
- Location identifiers are implementation-specific
- Results are reported separately per location

---

#### channels

**Type**: `array[object]`
**OPTIONAL**
**Default**: `[]`

**Description**: Notification destinations for check results.

**Example**:
```yaml
channels:
  - channel: webhook-alerts
    severity: Critical
  - channel: slack-team-channel
    severity: High
```

**Fields**:
- `channel`: Identifier for notification channel (string)
- `severity`: Severity level (implementation-specific)
- Additional fields MAY be implementation-specific

**Behavior**:
- Empty list means no notifications
- Channel configuration is implementation-specific
- Notifications are sent based on check results and severity

---

## Check-Specific Fields

Each check kind defines its own fields in the `spec` section:

**Core Checks (apiVersion: v1)**:
- **HttpCheck**: `url`, `method`, `headers`, `checks`
- **TcpCheck**: `host`, `port`, `checks`
- **SslCheck**: `hostname`, `port`, `checks`
- **DnsCheck**: `hostname`, `recordType`, `resolver`, `checks`
- **DomainCheck**: `domain`, `checks` (planned)

**Browser Checks (apiVersion: browser/v1)**:
- **LoadCheck**: `url`, `browser`, `collect`, `checks`
- **ScriptedCheck**: `url`, `browser`, `script`, `checks`

See individual check kind specifications for details.

---

## Resource Key

Each resource has a unique key formed by combining:
```
{apiVersion}:{kind}:{metadata.name}
```

**Example**:
```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: api-health

# Key: v1:HttpCheck:api-health
```

This key is used for:
- Identifying resources
- Preventing duplicates
- Referencing in logs and results

---

## Validation Rules

### Required Fields

The following fields MUST be present:
- `apiVersion`
- `kind`
- `metadata`
- `metadata.name`
- `spec`
- One of `spec.interval` or `spec.cron`

### Extra Fields

- Extra fields at the resource level are FORBIDDEN
- Unknown fields MUST cause validation errors
- Each check kind MAY allow additional fields in its `spec`

### Type Constraints

- `apiVersion` MUST be `v1` (literal string)
- `kind` MUST be valid check kind (string)
- `metadata.name` MUST be valid `CaseInsensitiveKey`
- `metadata.labels` MUST be string-to-string map
- All Time fields MUST match Time format

---

## Examples

### Minimal Check

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: minimal-check
spec:
  url: https://example.com
  interval: 1m
  checks: []
```

### Complete Check with All Common Fields

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: complete-check
  title: "Production API Health Monitor"
  labels:
    environment: production
    service: api
    team: platform
spec:
  # Scheduling
  interval: 30s

  # Common fields
  timeout: 10s
  retries: 3
  locations:
    - us-east-1
    - eu-west-1
    - ap-southeast-1
  channels:
    - channel: pagerduty-oncall
      severity: Critical
    - channel: slack-monitoring
      severity: High

  # Check-specific fields
  url: https://api.example.com/health
  method: GET
  checks:
    - type: statusCode
      operator: equals
      value: 200
```

### Check with Labels

```yaml
apiVersion: v1
kind: TcpCheck
metadata:
  name: database-connectivity
  title: "Production Database Connectivity"
  labels:
    environment: production
    component: database
    criticality: high
    team: data
spec:
  host: db.example.com
  port: 5432
  interval: 1m
  timeout: 5s
  checks:
    - type: reachable
      operator: is
      value: true
```

---

## Conformance

Implementations claiming conformance with Synthetic Open Schema v1 MUST:

1. **Validate resource structure** according to this specification
2. **Require all mandatory fields** (apiVersion, kind, metadata, spec)
3. **Enforce mutual exclusion** of interval/cron
4. **Apply default values** for optional fields
5. **Reject extra fields** at resource level
6. **Validate metadata.name** as CaseInsensitiveKey
7. **Support common spec fields** (timeout, retries, locations, channels)

Implementations SHOULD:
- Provide clear validation error messages
- Generate unique resource keys
- Support all standard check kinds
- Document supported check kinds and features
