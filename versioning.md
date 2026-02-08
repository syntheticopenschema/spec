# Versioning

This document describes the versioning strategy for Synthetic Open Schema.

---

## API Versioning

Synthetic Open Schema uses semantic versioning for its API versions:

### Version Format

API versions follow the format: `v{MAJOR}[{STABILITY}]`

Examples:
- `v1` - Major version 1, stable
- `v1beta1` - Major version 1, beta 1
- `v1alpha1` - Major version 1, alpha 1
- `v2` - Major version 2, stable

### Stability Levels

**Alpha** (`v1alpha1`, `v2alpha1`, etc.):
- Early preview, subject to breaking changes
- No backward compatibility guarantees
- May be removed in future versions
- Not recommended for production use

**Beta** (`v1beta1`, `v2beta1`, etc.):
- Feature complete but may have minor changes
- Backward compatibility best effort
- API is relatively stable
- Suitable for testing and feedback

**Stable** (`v1`, `v2`, etc.):
- Production ready
- Strong backward compatibility guarantees
- Breaking changes only in new major versions
- Long-term support

---

## Backward Compatibility

### Within a Major Version

Within a stable major version (e.g., `v1`), changes MUST maintain backward compatibility:

**Allowed Changes**:
- Adding new optional fields
- Adding new check kinds
- Adding new assertion types
- Adding new operator types
- Expanding allowed values for enums
- Clarifying documentation

**Prohibited Changes**:
- Removing fields
- Changing field types
- Making optional fields required
- Changing field semantics
- Removing check kinds
- Removing operators

### Between Major Versions

Major version changes (e.g., `v1` → `v2`) MAY introduce breaking changes:
- Removed or renamed fields
- Changed field types or semantics
- Different validation rules
- Removed check kinds

---

## Version Lifecycle

1. **Alpha**: Experimental, may change significantly
2. **Beta**: Feature complete, minor changes possible
3. **Stable**: Production ready, long-term support
4. **Deprecated**: Marked for removal, still supported
5. **Removed**: No longer supported

### Deprecation Policy

- Deprecation warnings MUST be provided at least one major version before removal
- Deprecated features MUST continue to work during the deprecation period
- Clear migration guides MUST be provided for deprecated features

---

## Custom Extensions

Implementations MAY add custom check kinds under their own namespace:

```yaml
apiVersion: company.com/v1
kind: CustomCheck
```

Custom extensions:
- MUST NOT conflict with standard check kinds
- MUST use a company/organization domain as prefix
- SHOULD follow the same versioning principles
- MAY have different compatibility guarantees

---

## Schema Evolution

JSON schemas are published in a separate repository: https://github.com/syntheticopenschema/schemas

Schemas are versioned alongside the API:
- `v1.json` corresponds to API version `v1`
- `v1beta1.json` corresponds to API version `v1beta1`

Schemas are generated from the reference implementation and published for tooling integration.
