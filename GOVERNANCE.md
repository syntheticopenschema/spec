# Governance

**Synthetic Open Schema** is an open specification stewarded by **Ideatives Inc.**

---

## Stewardship

**Stewarded by**: Ideatives Inc.
**Created and maintained by**: @dmonroy
**Repository**: https://github.com/syntheticopenschema/spec

Ideatives Inc. maintains the Synthetic Open Schema specification as an open, vendor-neutral standard for portable synthetic monitoring checks.

---

## Decision-Making Process

### Specification Changes

Proposed changes to the specification follow this process:

1. **Proposal**: Open an issue describing the proposed change
   - Include rationale and use cases
   - Provide examples if applicable
   - Tag with `proposal` label

2. **Discussion**: Community discussion on the issue
   - Gather feedback from implementers and users
   - Refine the proposal based on input
   - Minimum 7-day discussion period for breaking changes

3. **Decision**: Steward makes final decision
   - Consider community feedback
   - Evaluate impact on existing implementations
   - Document decision rationale

4. **Implementation**: Update specification documents
   - Update relevant spec files
   - Add examples
   - Update changelog
   - Tag version if applicable

### New Check Types

Adding new check types follows an RFC (Request for Comments) process:

1. **RFC Document**: Create detailed proposal
   - Check kind name and purpose
   - Spec fields and validation rules
   - Assertion types
   - Examples
   - Implementation considerations

2. **Review Period**: Minimum 14-day community review
   - Feedback from implementers
   - Discussion of technical details
   - Impact assessment

3. **Approval**: Steward approval required
   - Must meet spec quality standards
   - Must not conflict with existing checks
   - Must include comprehensive examples

4. **Documentation**: Add to specification
   - Create spec document
   - Update index
   - Provide reference implementation (optional but encouraged)

---

## API Versioning

### Version Stability

- **v1**: Stable, production-ready
  - Breaking changes require new major version (v2)
  - Non-breaking additions allowed
  - Bug fixes and clarifications welcome

- **browser/v1**: Stable
  - Separate version namespace for browser checks
  - Same stability guarantees as v1

### Deprecation Policy

When deprecating features:
- Minimum 6-month deprecation notice
- Document migration path
- Maintain backward compatibility during deprecation period
- Clearly mark deprecated features in spec

---

## Reference Implementations

### Official Implementations

**Python Reference Implementation**:
- Repository: https://github.com/syntheticopenschema/model
- Maintainer: Ideatives Inc.
- Purpose: Reference for spec interpretation

**Python Runner**:
- Repository: https://github.com/syntheticopenschema/runner
- Maintainer: Ideatives Inc.
- Purpose: Reference execution engine

### Relationship to Spec

- Specification is the source of truth
- Reference implementations demonstrate compliance
- Implementation bugs do not affect spec validity
- Spec clarifications may result from implementation issues

### Community Implementations

Community implementations are welcome and encouraged:
- Must document which check types are supported
- Must specify conformance level
- Should provide examples
- May extend with custom check types (use custom apiVersion)

---

## Trademark Policy

"Synthetic Open Schema" is stewarded by Ideatives Inc.

### Usage Guidelines

**Permitted Uses**:
- Implementing the specification
- Referencing the specification in documentation
- Creating compatible tools and services
- Teaching and educational purposes

**Restrictions**:
- Do not imply official endorsement without permission
- Do not create confusingly similar names
- Clearly mark unofficial implementations as such

### Claiming Compatibility

Implementations may claim compatibility if they:
1. Support the base Resource model
2. Implement at least one check kind completely
3. Pass conformance requirements in spec
4. Document which features are supported

---

## Commercial vs Open Source

### Specification License

The specification is licensed under **Apache License 2.0**:
- Open for anyone to implement
- Commercial and non-commercial use permitted
- No restrictions on proprietary implementations

### Implementation Freedom

Organizations may:
- Build commercial products using the spec
- Create proprietary check types (use custom apiVersion)
- Offer managed services
- Integrate into existing monitoring platforms

### Attribution

Implementations should acknowledge:
```
This product implements the Synthetic Open Schema specification,
stewarded by Ideatives Inc.
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose changes
- Code of conduct
- Submission guidelines
- Development workflow

---

## Security

See [SECURITY.md](SECURITY.md) for:
- Security issue reporting
- Responsible disclosure
- Security update process

---

## Contact

- **Issues & Discussions**: https://github.com/syntheticopenschema/spec/issues
- **Website**: https://syntheticopenschema.org
- **Email**: Contact through GitHub issues

---

**Last Updated**: 2026-02-07
**Version**: v1.0
