# Common Types and Fields

**Version**: v1
**Status**: Stable

---

## Overview

This document defines common types, fields, and concepts shared across all check kinds in Synthetic Open Schema v1.

---

## Time Format

**Type**: `Time`

**Format**: `^[0-9]+(ns|ms|s|m|h|d|w|mo|y)?$`

**Description**: A duration value expressed as an integer followed by an optional unit.

**Supported Units**:
- `ns` - Nanoseconds (fixed duration)
- `ms` - Milliseconds (fixed duration)
- `s` - Seconds (default if no unit specified, fixed duration)
- `m` - Minutes (fixed duration)
- `h` - Hours (fixed duration)
- `d` - Days (fixed duration: 24 hours)
- `w` - Weeks (fixed duration: 7 days)
- `mo` - Months (calendar-based: varies 28-31 days)
- `y` - Years (calendar-based: varies 365-366 days)

**Examples**:
```yaml
timeout: 5s
interval: 1m
duration: 500ms
```

**Validation Rules**:
- MUST contain at least one digit
- Unit is OPTIONAL; defaults to seconds
- Value MUST be positive

**Calendar-Based Units** (`mo`, `y`):

Months and years are **calendar-based**, not fixed durations:

- **`mo` (months)**: Computed based on calendar months from reference timestamp
  - Example: January 7 + 3mo = April 7 (regardless of actual days elapsed)
  - Handles month-end gracefully: January 31 + 1mo = February 28/29

- **`y` (years)**: Computed based on calendar years from reference timestamp
  - Example: January 7, 2024 + 1y = January 7, 2025
  - Leap years handled automatically

**Reference Timestamp**: The timestamp used for calendar calculation depends on context:
- **Scheduling** (`interval`): Last execution or result timestamp
- **Assertions** (`expirationTime`): Current time or certificate issue date

**Examples**:
```yaml
# Fixed duration - always 30 days
interval: 30d

# Calendar-based - runs on same day each month
interval: 1mo

# Certificate expires in 3 calendar months
value: 3mo  # Jan 7 → April 7, Mar 31 → June 30
```

**Usage**: Used for fields where defaulting to seconds is intuitive (`timeout`, `interval`).

---

## StrictTime Format

**Type**: `StrictTime`

**Format**: `^[0-9]+(ns|ms|s|m|h|d|w|mo|y)$`

**Description**: A duration value that REQUIRES an explicit unit suffix. Bare integers are NOT allowed.

**Supported Units**:
- `ns` - Nanoseconds (fixed duration)
- `ms` - Milliseconds (fixed duration)
- `s` - Seconds (fixed duration)
- `m` - Minutes (fixed duration)
- `h` - Hours (fixed duration)
- `d` - Days (fixed duration: 24 hours)
- `w` - Weeks (fixed duration: 7 days)
- `mo` - Months (calendar-based: varies 28-31 days)
- `y` - Years (calendar-based: varies 365-366 days)

**Examples**:
```yaml
# Valid
value: 30d
value: 500ms
value: 5s

# Invalid - unit required
value: 30    # ❌ ERROR: unit suffix required
value: 500   # ❌ ERROR: unit suffix required
```

**Validation Rules**:
- MUST contain at least one digit
- Unit suffix is REQUIRED (not optional)
- Value MUST be positive
- Bare integers are REJECTED

**Calendar-Based Units** (`mo`, `y`):

Same calendar semantics as `Time` type:
- `3mo` = 3 calendar months from reference date (e.g., Jan 7 → April 7)
- `1y` = 1 calendar year from reference date (e.g., Jan 7, 2024 → Jan 7, 2025)

**Rationale**: Prevents ambiguity in contexts where defaulting to seconds would be confusing. For example, certificate expiration checks measure days, not seconds, so `value: 30` would be ambiguous without enforcing the unit.

**Usage**: Used for assertion values where the appropriate unit may not be obvious (`expirationTime`, `duration` in assertions).

---

## Identifiers

### CaseInsensitiveKey

**Type**: `CaseInsensitiveKey`

**Format**: `^[A-Za-z0-9\-]+$`

**Description**: An identifier that is case-insensitive and contains only alphanumeric characters and hyphens.

**Constraints**:
- MUST contain at least one character
- MUST match DNS subdomain naming rules
- Automatically converted to lowercase
- MAY contain hyphens
- MUST NOT start or end with hyphen

**Examples**:
```yaml
name: my-check
name: prod-api-health
name: checkout-flow-123
```

### DNSHostname

**Type**: `DNSHostname`

**Format**: `^(([a-zA-Z0-9]+|([a-zA-Z0-9]+-*[a-zA-Z0-9]+))\.)*[a-zA-Z0-9]+$`

**Description**: A valid DNS hostname.

**Constraints**:
- MUST be valid DNS format
- Automatically converted to lowercase
- Minimum length: 1 character
- Maximum length: 253 characters

**Examples**:
```yaml
host: example.com
host: api.example.com
host: localhost
```

---

## Operators

Operators define comparison operations used in assertions.

### NumericOperator

**Used for**: Status codes, sizes, numeric values

**Values**:
- `equals` - Exactly equal to value
- `notEquals` - Not equal to value
- `greaterThan` - Greater than value
- `lessThan` - Less than value

**Example**:
```yaml
- type: statusCode
  operator: equals
  value: 200
```

### StringOperator

**Used for**: Body content, headers, text fields

**Values**:
- `equals` - Exact string match
- `notEquals` - Does not match string
- `contains` - Contains substring
- `notContains` - Does not contain substring

**Example**:
```yaml
- type: body
  operator: contains
  value: "success"
```

### BooleanOperator

**Used for**: Boolean and null comparisons (reachable, valid)

**Values**:
- `is` - Is exactly (true/false)
- `isNot` - Is not (true/false)
- `equals` - Equals (backward compatibility)
- `notEquals` - Not equals (backward compatibility)

**Example**:
```yaml
- type: reachable
  operator: is
  value: true
```

---

### ListOperator

**Used for**: List/array comparisons (nameservers, multiple values)

**Values**:
- `equals` - Exact match (order-independent set equality)
- `contains` - All assertion values present in result (subset check)
- `notContains` - No assertion values present in result

**Semantics**:

**`equals`**: Result list MUST exactly match assertion list (order-independent)
- Assertion: `[a, b]` matches result: `[b, a]` ✅
- Assertion: `[a, b]` matches result: `[a]` ❌ (missing b)
- Assertion: `[a, b]` matches result: `[a, b, c]` ❌ (extra c)

**`contains`**: Result list MUST contain ALL assertion values (may have more)
- Assertion: `[a, b]` matches result: `[a, b]` ✅
- Assertion: `[a, b]` matches result: `[a, b, c]` ✅ (extra values ok)
- Assertion: `[a, b]` matches result: `[a]` ❌ (missing b)

**`notContains`**: Result list MUST NOT contain ANY assertion values
- Assertion: `[a, b]` matches result: `[c, d]` ✅ (neither a nor b present)
- Assertion: `[a, b]` matches result: `[a, c]` ❌ (a is present)

**Examples**:
```yaml
# Single value check (string syntax)
- type: nameservers
  operator: contains
  value: ns1.cloudflare.com

# Multiple values check (list syntax)
- type: nameservers
  operator: contains
  value:
    - ns1.cloudflare.com
    - ns2.cloudflare.com

# Exact match
- type: nameservers
  operator: equals
  value:
    - ns1.cloudflare.com
    - ns2.cloudflare.com

# Must NOT contain (single value)
- type: nameservers
  operator: notContains
  value: ns1.oldprovider.net

# Must NOT contain (multiple values)
- type: nameservers
  operator: notContains
  value:
    - ns1.oldprovider.net
    - ns2.badactor.com
```

---

## Base Assertion Types

All check-specific assertions extend these base types.

### NumericAssertion

**Description**: Base for numeric value assertions.

**Fields**:
- `operator`: `NumericOperator` (REQUIRED)
- `value`: `integer` (REQUIRED)

**Used by**: `statusCode`, `size`, numeric assertions

**Example**:
```yaml
type: statusCode
operator: equals
value: 200
```

**Validation**:
- Value MUST be an integer
- Extra fields are FORBIDDEN

---

### TimebasedAssertion

**Description**: Base for time/duration assertions where unit suffix is required.

**Fields**:
- `operator`: `NumericOperator` (REQUIRED)
- `value`: `StrictTime` (REQUIRED)

**Used by**: `duration`, `latency`, `expirationTime` assertions

**Example**:
```yaml
type: duration
operator: lessThan
value: 500ms
```

```yaml
type: expirationTime
operator: greaterThan
value: 30d
```

**Validation**:
- Value MUST be `StrictTime` (unit suffix required)
- Bare integers are REJECTED (e.g., `value: 30` is invalid)
- MUST include unit: `30d`, `500ms`, `5s`, etc.
- Extra fields are FORBIDDEN

**Rationale**: Using `StrictTime` prevents ambiguity. For example, certificate expiration is measured in days, so `value: 30` would be confusing (30 seconds? 30 days?). Requiring `value: 30d` makes intent clear.

---

### StringAssertion

**Description**: Base for string content assertions.

**Fields**:
- `operator`: `StringOperator` (REQUIRED)
- `value`: `string` (REQUIRED)

**Used by**: `body`, text content assertions

**Example**:
```yaml
type: body
operator: contains
value: "OK"
```

**Validation**:
- Value MUST be a string
- Extra fields are FORBIDDEN

---

### KeyValueAssertion

**Description**: Base for key-value pair assertions (headers, query params).

**Fields**:
- `operator`: `StringOperator` (REQUIRED)
- `name`: `string` (OPTIONAL)
- `value`: `string` (REQUIRED)

**Behavior**:
- If `name` is NOT specified: Operations are against keys
- If `name` IS specified: Operations are against the value of that key

**Used by**: `header` assertions

**Examples**:

Check if header exists:
```yaml
type: header
operator: contains
value: "Content-Type"
```

Check header value:
```yaml
type: header
operator: equals
name: "Content-Type"
value: "application/json"
```

**Validation**:
- Extra fields are FORBIDDEN

---

### BooleanAssertion

**Description**: Base for boolean/null assertions.

**Fields**:
- `operator`: `BooleanOperator` (REQUIRED)
- `value`: `boolean` (REQUIRED)

**Used by**: `reachable`, `valid`, boolean checks

**Example**:
```yaml
type: reachable
operator: is
value: true
```

**Validation**:
- Value MUST be boolean (true/false)
- Extra fields are FORBIDDEN

---

### ListAssertion

**Description**: Base for list/array value assertions.

**Fields**:
- `operator`: `ListOperator` (REQUIRED)
- `value`: `string | array[string]` (REQUIRED)

**Used by**: `nameservers`, multi-value assertions

**Operators**:
- `equals` - Exact list match (order-independent)
- `contains` - All assertion values present in result
- `notContains` - No assertion values present in result

**Value Type Handling**:

If `value` is a **string** (single value):
- Automatically converted to single-element list: `"a"` → `["a"]`
- Syntactic sugar for common single-value checks
- Semantically equivalent to `["a"]`

If `value` is an **array** (multiple values):
- Used as-is for multi-value checks
- MUST NOT be empty

**Examples**:

Single nameserver check (string syntax):
```yaml
type: nameservers
operator: contains
value: ns1.cloudflare.com  # String - checks if this ONE nameserver is present
```

Single nameserver check (list syntax):
```yaml
type: nameservers
operator: contains
value:
  - ns1.cloudflare.com  # Equivalent to above
```

Multiple nameservers check:
```yaml
type: nameservers
operator: contains
value:
  - ns1.cloudflare.com
  - ns2.cloudflare.com  # Checks if BOTH are present
```

Exact nameserver list match:
```yaml
type: nameservers
operator: equals
value:
  - ns1.cloudflare.com
  - ns2.cloudflare.com
```

Nameserver must NOT be present:
```yaml
type: nameservers
operator: notContains
value: ns1.oldprovider.net  # String - checks if this ONE nameserver is absent
```

Multiple nameservers must NOT be present:
```yaml
type: nameservers
operator: notContains
value:
  - ns1.oldprovider.net
  - ns2.badactor.com  # Checks if BOTH are absent
```

**Validation**:
- Value MUST be a string OR an array of strings
- If array, it MUST NOT be empty
- If string, it MUST NOT be empty
- Duplicate values in assertion list are normalized (treated as set)
- Extra fields are FORBIDDEN

**Semantics**:

**String to List Conversion**: If `value` is a string, it is converted to a single-element list before comparison.
- Assertion: `value: "a"` → internally becomes `value: ["a"]`
- This is purely syntactic sugar for convenience

**Order Independence**: List comparison is order-independent. `[a, b]` equals `[b, a]`.

**Comparison Behavior**:
- **`equals`**: Set equality check
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` matches assertion: `[ns2.cloudflare.com, ns1.cloudflare.com]` ✅
  - Result: `[ns1.cloudflare.com]` matches assertion: `ns1.cloudflare.com` ✅ (string converted to `[ns1.cloudflare.com]`)
  - Result: `[ns1.cloudflare.com]` fails assertion: `[ns1.cloudflare.com, ns2.cloudflare.com]` ❌
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com, ns3.cloudflare.com]` fails assertion: `[ns1.cloudflare.com, ns2.cloudflare.com]` ❌

- **`contains`**: Subset check (assertion ⊆ result)
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` matches assertion: `ns1.cloudflare.com` ✅ (single value present)
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` matches assertion: `[ns1.cloudflare.com]` ✅
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com, ns3.cloudflare.com]` matches assertion: `[ns1.cloudflare.com, ns2.cloudflare.com]` ✅
  - Result: `[ns1.cloudflare.com]` fails assertion: `[ns1.cloudflare.com, ns2.cloudflare.com]` ❌ (missing ns2)

- **`notContains`**: Disjoint check (assertion ∩ result = ∅)
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` matches assertion: `ns1.oldprovider.net` ✅ (single value absent)
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` matches assertion: `[ns1.oldprovider.net]` ✅
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` fails assertion: `ns1.cloudflare.com` ❌ (value is present)
  - Result: `[ns1.cloudflare.com, ns2.cloudflare.com]` fails assertion: `[ns1.cloudflare.com, ns3.other.com]` ❌ (ns1.cloudflare.com present)

**Case Sensitivity**: String comparisons are case-sensitive by default. `ns1.cloudflare.com` ≠ `NS1.CLOUDFLARE.COM`.

**Normalization**: Implementations MAY normalize values (e.g., lowercase DNS names) before comparison. If normalization is performed, it MUST be documented.

---

## Scheduling

Checks MUST specify exactly one scheduling method: `interval` OR `cron`.

### Interval

**Type**: `Time`

**Description**: Execute check at regular intervals.

**Example**:
```yaml
interval: 1m
```

**Validation**:
- MUST be valid `Time` format
- MUST NOT be used with `cron`

---

### Cron

**Type**: `string`

**Description**: Execute check based on cron expression.

**Format**: Standard cron format (5 or 6 fields)

**Example**:
```yaml
cron: "*/5 * * * *"  # Every 5 minutes
```

**Validation**:
- MUST be valid cron expression
- MUST NOT be used with `interval`
- Validated using croniter library semantics

---

## Common Spec Fields

These fields appear in the `spec` section of all check kinds.

### timeout

**Type**: `Time`
**Default**: `1s`
**OPTIONAL**

**Description**: Maximum duration for check execution.

**Example**:
```yaml
timeout: 5s
```

---

### retries

**Type**: `integer`
**Default**: `1`
**OPTIONAL**

**Description**: Number of retry attempts on failure.

**Example**:
```yaml
retries: 3
```

**Validation**:
- MUST be positive integer

---

### locations

**Type**: `array[string]`
**Default**: `[]`
**OPTIONAL**

**Description**: List of geographic locations or execution environments where check should run.

**Example**:
```yaml
locations:
  - us-east-1
  - eu-west-1
  - ap-southeast-1
```

**Semantics**:
- Empty list means run in default location
- Location identifiers are implementation-specific
- Check runs independently in each location

---

### channels

**Type**: `array[object]`
**Default**: `[]`
**OPTIONAL**

**Description**: Notification destinations for check results.

**Example**:
```yaml
channels:
  - channel: my-webhook-channel
    severity: Critical
  - channel: slack-alerts
    severity: High
```

**Fields**:
- `channel`: Identifier for notification channel
- `severity`: Severity level (implementation-specific)

**Semantics**:
- Empty list means no notifications
- Channel configuration is implementation-specific

---

## Validation Rules

### Extra Fields

All models in this specification use **strict validation**:
- Extra fields are FORBIDDEN
- Unknown fields MUST cause validation errors
- Implementations SHOULD provide clear error messages

### Required vs Optional

- Fields marked REQUIRED MUST be present
- Fields marked OPTIONAL MAY be omitted
- Default values apply when optional fields are omitted

### Mutually Exclusive

Some fields are mutually exclusive:
- `interval` and `cron` MUST NOT both be specified
- Exactly one MUST be present

**Validation Error**:
```
Only one of interval or cron can be configured.
Either interval or cron must be configured.
```

---

## Conformance

Implementations claiming conformance with Synthetic Open Schema v1 MUST:

1. **Support all common types** defined in this document
2. **Validate Time format** according to specified pattern
3. **Enforce identifier constraints** (CaseInsensitiveKey, DNSHostname)
4. **Implement all operators** for their respective assertion types
5. **Validate mutually exclusive fields** (interval/cron)
6. **Reject extra fields** in strict mode
7. **Apply default values** for optional fields

Implementations SHOULD:
- Provide clear error messages for validation failures
- Support all common spec fields (timeout, retries, locations, channels)
- Document which operators are supported for each assertion type
