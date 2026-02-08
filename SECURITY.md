# Security Policy

**Synthetic Open Schema** is an open specification stewarded by **Ideatives Inc.**

This document outlines the security policy for the specification and reference implementations.

---

## Reporting Security Issues

### Scope

Security issues may include:
- Specification ambiguities that could lead to security vulnerabilities
- Issues in reference implementations (Python model/runner)
- Documentation gaps affecting secure usage
- Validation bypass opportunities

### How to Report

**DO NOT** open public GitHub issues for security vulnerabilities.

Instead, report security issues privately:

1. **Email**: Open a private security advisory via GitHub
   - Go to https://github.com/syntheticopenschema/spec/security/advisories/new
   - Fill in the advisory template

2. **Alternative**: Create a private GitHub issue
   - Mark as security-sensitive
   - Include detailed description

### Information to Include

- Description of the vulnerability
- Affected spec version(s) or implementation(s)
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

---

## Response Timeline

We aim to respond to security reports within:

- **Initial Response**: 3 business days
  - Acknowledge receipt
  - Confirm scope (spec vs implementation)
  - Provide initial assessment

- **Status Update**: 7 days
  - Investigation progress
  - Estimated fix timeline
  - Coordinated disclosure date (if applicable)

- **Resolution**: 30 days (target)
  - Specification clarification or
  - Implementation fix or
  - Documentation update

---

## Disclosure Policy

### Coordinated Disclosure

We follow responsible disclosure practices:

1. **Private Resolution**: Fix developed privately
2. **Implementer Notification**: Alert known implementations
3. **Grace Period**: 14-day advance notice for implementers
4. **Public Disclosure**: Coordinated public announcement

### Security Advisories

Public security advisories will include:
- Affected versions
- Description of vulnerability
- Impact assessment
- Mitigation steps
- Fixed versions
- Credit to reporter (if desired)

---

## Security Considerations in Spec

The specification includes security guidance for:

### Credential Management
- How to handle sensitive data in check definitions
- Environment variable substitution
- Secrets storage recommendations

### TLS/SSL Validation
- Certificate validation requirements
- Custom CA trust stores
- `insecureSkipVerify` warnings (development only)

### Input Validation
- Field validation rules
- Type constraints
- Regex patterns for safety

### Injection Prevention
- Safe handling of user-provided values
- Script execution sandboxing (browser checks)
- Command injection risks

See individual check specifications for detailed security considerations.

---

## Implementation Security

### Reference Implementation

The Python reference implementation follows security best practices:
- Pydantic strict validation
- No `eval()` or dynamic code execution
- Dependency security scanning
- Regular security updates

### Community Implementations

Implementers should:
- Validate all inputs strictly
- Sandbox script execution (browser checks)
- Implement timeout protections
- Follow principle of least privilege
- Document security assumptions
- Provide security contact

---

## CVE Process

### When CVEs Apply

CVEs (Common Vulnerabilities and Exposures) may be issued for:
- Critical security flaws in reference implementations
- Specification ambiguities exploited in the wild
- Widespread implementation vulnerabilities

### CVE Assignment

- CVEs assigned through GitHub Security Advisories
- Coordinated with affected parties
- Published after fix availability

---

## Security Updates

### Specification Updates

Security-relevant specification clarifications:
- Issued as minor version updates
- Backward compatible
- Documented in changelog
- Announced via GitHub releases

### Implementation Updates

Reference implementation security updates:
- Published as patch releases
- Security advisory on GitHub
- Notification to known users
- Documented in release notes

---

## Supported Versions

### Specification

| Version | Security Support |
|---------|------------------|
| v1      | ✅ Fully supported |
| v1beta1 | ⚠️ Best effort (deprecated) |

### Python Reference Implementation

| Version | Security Support |
|---------|------------------|
| Latest  | ✅ Fully supported |
| Previous minor | ⚠️ Critical fixes only (90 days) |
| Older | ❌ Not supported |

---

## Security Best Practices

### For Check Definitions

1. **Credentials**: Use environment variables, not hardcoded secrets
2. **URLs**: Validate and sanitize user-provided URLs
3. **Scripts**: Sandbox browser script execution
4. **Timeouts**: Always set reasonable timeouts
5. **Validation**: Use strict validation (extra="forbid")

### For Implementations

1. **Input Validation**: Validate all YAML/JSON strictly
2. **Resource Limits**: Enforce memory and CPU limits
3. **Network Security**: Use TLS where appropriate
4. **Logging**: Don't log sensitive data
5. **Dependencies**: Keep dependencies updated
6. **Isolation**: Run checks in isolated environments

### For Operators

1. **Access Control**: Restrict who can define checks
2. **Code Review**: Review check definitions before deployment
3. **Monitoring**: Monitor for suspicious check behavior
4. **Auditing**: Log check creation and modifications
5. **Rotation**: Rotate credentials regularly

---

## Security Contacts

- **Maintainer**: @dmonroy
- **GitHub Security Advisories**: https://github.com/syntheticopenschema/spec/security/advisories
- **Issues**: https://github.com/syntheticopenschema/spec/issues (non-security)

---

## Acknowledgments

We appreciate responsible disclosure from the security community. Security researchers who report valid vulnerabilities will be credited in:
- GitHub Security Advisories
- Release notes
- Hall of Fame (if established)

---

**Last Updated**: 2026-02-07
**Version**: 1.0
