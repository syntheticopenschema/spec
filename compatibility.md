# Compatibility

This document defines forward and backward compatibility guarantees for Synthetic Open Schema.

---

## Compatibility Principles

### Backward Compatibility

**Definition**: Checks written for an older version of the specification MUST work with implementations supporting a newer version within the same major version.

**Example**: A check written for `v1.0` MUST work with a runner implementing `v1.5`.

### Forward Compatibility

**Definition**: Implementations SHOULD handle checks that include unknown fields gracefully, either by ignoring them or providing clear error messages.

**Example**: A `v1.0` implementation encountering a `v1.5` check with new optional fields SHOULD either:
1. Ignore the unknown fields and execute the check
2. Provide a clear error indicating unsupported fields

---

## Version Compatibility Matrix

### Within Stable Major Versions

| Check Version | Runner Version | Compatibility | Notes |
|---------------|----------------|---------------|-------|
| v1.0 | v1.0 | ✅ Full | Exact match |
| v1.0 | v1.5 | ✅ Full | Backward compatible |
| v1.5 | v1.0 | ⚠️ Partial | Unknown fields may be ignored |
| v1 | v2 | ❌ None | Major version breaking change |

### Beta/Alpha Versions

Beta and alpha versions have NO compatibility guarantees across versions:

| Check Version | Runner Version | Compatibility |
|---------------|----------------|---------------|
| v1beta1 | v1beta2 | ❌ None |
| v1alpha1 | v1alpha2 | ❌ None |
| v1beta1 | v1 | ❌ None (migration required) |

---

## Field Evolution Rules

### Adding Fields

New **optional** fields MAY be added in minor versions:

```yaml
# v1.0
spec:
  url: https://example.com
  timeout: 5s

# v1.1 adds optional field
spec:
  url: https://example.com
  timeout: 5s
  maxRedirects: 3  # New in v1.1, optional
```

New **required** fields MUST NOT be added within a major version.

### Deprecating Fields

Fields may be deprecated but MUST remain functional:

```yaml
# Deprecated in v1.5, removed in v2.0
spec:
  url: https://example.com
  retries: 3  # Deprecated, use retryPolicy instead
  retryPolicy:  # New field replacing retries
    maxAttempts: 3
```

### Changing Defaults

Default values MUST NOT change within a major version, as this changes behavior.

---

## Check Kind Compatibility

### Adding Check Kinds

New check kinds MAY be added at any time:
- HttpCheck, TcpCheck (v1.0)
- DnsCheck, SslCheck (v1.1) ← Allowed
- BrowserCheck (v1.2) ← Allowed

### Removing Check Kinds

Check kinds MUST NOT be removed within a major version:
- Deprecation warnings in v1.x
- Removal only in v2.0

---

## Assertion Compatibility

### Adding Assertions

New assertion types MAY be added:

```yaml
# v1.0
checks:
  - type: statusCode
    operator: equals
    value: 200

# v1.1 adds new assertion type
checks:
  - type: statusCode
    operator: equals
    value: 200
  - type: responseTime  # New in v1.1
    operator: lessThan
    value: 500ms
```

### Adding Operators

New operators MAY be added for existing assertions:

```yaml
# v1.0: equals, notEquals, contains
operator: equals

# v1.1: adds regex operator
operator: regex  # New in v1.1
```

---

## Implementation Requirements

### Conformance Levels

Implementations SHOULD declare their conformance level:

**Full Conformance**: Supports all required features of the declared version
**Partial Conformance**: Supports subset of features (must document which)

Example:
```
This runner supports Synthetic Open Schema v1.2 with full conformance.
Supported check kinds: HttpCheck, TcpCheck, DnsCheck, SslCheck
```

### Unknown Field Handling

Implementations MUST either:
1. **Strict Mode**: Reject checks with unknown fields (recommended for validation tools)
2. **Permissive Mode**: Ignore unknown fields and execute check (recommended for runners)

The mode SHOULD be configurable.

---

## Migration Guides

When major versions introduce breaking changes, migration guides MUST be provided documenting:
1. What changed
2. Why it changed
3. How to migrate existing checks
4. Automated migration tools (if available)

---

## Guarantees Summary

| Guarantee | Within Major Version | Across Major Versions |
|-----------|---------------------|----------------------|
| Backward Compatibility | ✅ Required | ❌ Not guaranteed |
| Forward Compatibility | ⚠️ Best effort | ❌ Not guaranteed |
| Field additions | ✅ Allowed (optional) | ✅ Allowed |
| Field removals | ❌ Prohibited | ✅ Allowed |
| Default changes | ❌ Prohibited | ✅ Allowed |
| Check kind additions | ✅ Allowed | ✅ Allowed |
| Check kind removals | ❌ Prohibited | ✅ Allowed (with deprecation) |
