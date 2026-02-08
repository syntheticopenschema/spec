# Browser Check Specification

**API Version**: `browser/v1`
**Status**: Stable

---

## Overview

Browser checks use browser automation to validate web applications through real browser interactions. They support both passive monitoring (page loads) and active automation (scripted workflows).

**Key Characteristics**:
- Real browser execution (Chromium, Firefox, WebKit)
- Visual rendering and JavaScript execution
- Performance metrics collection
- Hybrid validation model (scripts + assertions)

---

## Implementation Independence

**IMPORTANT**: This specification does NOT prescribe:
- Which browser automation library to use (Playwright, Puppeteer, Selenium, etc.)
- How to implement browser orchestration
- Specific API surface for scripts

**Vendor Responsibility**: Organizations implementing Synthetic Open Schema MUST:
1. Document which orchestrator(s) they support
2. Provide clear API documentation for script authors
3. Publish code examples for common use cases
4. Advertise which languages and engines are supported

The specification defines **WHAT** to validate (browser config, assertions, check structure).
Implementations choose **HOW** to execute (orchestrator, API surface, runtime).

**Portability**: Scripts written for one implementation (e.g., using Playwright) may NOT be portable to another implementation (e.g., using Puppeteer) unless they share the same orchestrator.

---

## Differences from Core Checks (v1)

| Aspect | Core Checks (v1) | Browser Checks (browser/v1) |
|--------|------------------|----------------------------|
| API Version | `v1` | `browser/v1` |
| Execution | Protocol-level (HTTP, TCP, DNS) | Browser automation |
| Complexity | Simple, declarative | Advanced, may include scripting |
| Dependencies | Minimal | Browser automation library |
| Implementation | All runners | Optional for runners |
| Performance | Fast (milliseconds) | Slower (seconds) |

---

## Supported Check Kinds

### Current

- **[LoadCheck](./load_check.md)** - Passive page load and performance monitoring
- **[ScriptedCheck](./scripted_check.md)** - Active browser automation with custom scripts

### Planned

- **PuppeteerCheck** - Browser automation using Puppeteer
- **SeleniumCheck** - Browser automation using Selenium WebDriver

---

## Resource Structure

Browser checks follow the same base resource structure as core checks:

```yaml
apiVersion: browser/v1
kind: LoadCheck  # or ScriptedCheck
metadata:
  name: check-name
  title: "Human-readable title"
  labels:
    key: value
spec:
  url: https://example.com
  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080
  # Check-specific fields
  # Common fields (interval, timeout, etc.)
```

---

## Common Fields

Browser checks inherit common fields from the base `CheckSpec`:

- `interval` or `cron` - Scheduling (REQUIRED, mutually exclusive)
- `timeout` - Maximum execution time (OPTIONAL, default: `30s` for LoadCheck, `60s` for ScriptedCheck)
- `retries` - Retry attempts (OPTIONAL, default: `1`)
- `locations` - Execution locations (OPTIONAL, default: `[]`)
- `channels` - Notification destinations (OPTIONAL, default: `[]`)

See [v1/check.md](../../v1/check.md) for detailed specifications.

---

## Hybrid Validation Model

Browser checks use a **hybrid model** combining scripts and assertions:

### LoadCheck (Passive)
- **No script**: Simply loads the page
- **Assertions**: Validate page load results (status, load time, elements, text)
- **Example**: Page load performance monitoring

```yaml
spec:
  url: https://example.com
  checks:
    - type: status
      operator: equals
      value: 200
    - type: loadTime
      operator: lessThan
      value: 3000
```

### ScriptedCheck (Active)
- **Script**: Custom automation logic (login, form submission, navigation)
- **Assertions**: Validate final state after script execution
- **Both**: Script can fail (throw error) OR assertions can fail

```yaml
spec:
  url: https://app.example.com/login
  script:
    language: javascript
    entrypoint: validateLogin
    source:
      inline: |
        async function validateLogin(page, context) {
          await page.fill('#username', 'test@example.com');
          await page.click('#submit');
          await page.waitForNavigation();
        }
  checks:
    - type: elementPresent
      selector: ".user-menu"
      operator: equals
      value: true
```

---

## Common Types

Browser checks share common configuration types:

- **[BrowserEngine](./common.md#browserengine)** - Browser engine selection (`chromium`, `firefox`, `webkit`)
- **[Viewport](./common.md#viewport)** - Browser window dimensions
- **[BrowserConfig](./common.md#browserconfig)** - Complete browser configuration

See [common.md](./common.md) for full specifications.

---

## Check Specifications

- **[load_check.md](./load_check.md)** - LoadCheck (passive page load monitoring)
- **[scripted_check.md](./scripted_check.md)** - ScriptedCheck (active browser automation)

---

## Design Rationale

### Why Separate API Version?

1. **Different Execution Model**: Browser automation requires different runtime than protocol-level checks
2. **Heavy Dependencies**: Browser automation libraries (Playwright, Puppeteer) are large (100+ MB)
3. **Optional Implementation**: Not all runners need to support browser checks
4. **Independent Evolution**: Browser check features can evolve without affecting v1
5. **Performance Trade-off**: Browser checks are slower but provide richer validation
6. **Clear Separation**: Distinct API version makes the difference explicit

### Why Hybrid Model (Scripts + Assertions)?

**LoadCheck**: No script needed, pure declarative assertions work well for page loads.

**ScriptedCheck**: Hybrid approach provides flexibility:
- **Script**: Executes complex workflows (login, checkout, multi-step forms)
- **Assertions**: Validates final state in a structured, reportable way
- **Both**: Script errors provide immediate feedback, assertions provide detailed validation

This is more powerful than script-only or assertion-only approaches.

### Why LoadCheck and ScriptedCheck Instead of Single PlaywrightCheck?

Separating passive and active checks:
- **Clarity**: Intent is clear from the check kind
- **Simplicity**: LoadCheck is simpler (no script configuration)
- **Performance**: Runners can optimize passive checks differently
- **Governance**: Different checks may have different approval workflows

---

## Conformance

Implementations claiming support for `browser/v1` MUST:

1. Support the base browser check resource model (`BrowserConfig`, `Viewport`, `BrowserEngine`)
2. Execute at least one browser check kind (LoadCheck or ScriptedCheck)
3. Inherit common scheduling and execution semantics from v1
4. Support at least one browser engine (`chromium`, `firefox`, or `webkit`)
5. Honor browser configuration (viewport, user agent, locale, timezone)
6. Evaluate assertions in the `checks` field
7. Report errors clearly (script errors, assertion failures, browser errors)
8. Implement proper timeouts and retries
9. **Document which browser automation library/orchestrator is used**
10. **Provide code examples for supported script languages and orchestrators**
11. **Clearly specify the API surface provided to scripts (`page`, `context`)**

Implementations MAY:
- Support all browser engines or a subset
- Support multiple script languages
- Support multiple orchestrators (Playwright, Puppeteer, Selenium, custom)
- Provide additional browser-specific features (screenshots, video recording)
- Extend with custom browser check types
- Collect additional performance metrics
- Use cloud browser services or custom browser automation protocols

---

## Relationship to v1

Browser checks (`browser/v1`) extend the same base types as core checks (`v1`):
- Use same `Resource` structure (apiVersion, kind, metadata, spec)
- Inherit `CheckSpec` for common fields (interval, cron, timeout, retries, locations, channels)
- Follow same validation rules (extra fields forbidden, strict typing)
- Use same assertion base types (NumericAssertion, StringAssertion, BooleanAssertion)

**Key differences**:
- **Execution**: Browser automation vs protocol-level requests
- **Performance**: Seconds vs milliseconds
- **Dependencies**: Browser library vs minimal dependencies
- **Validation**: Hybrid (scripts + assertions) vs pure assertions

---

## Examples

Example browser checks are in the model repository [`examples/`](https://github.com/syntheticopenschema/model/tree/main/examples) directory:

- [load-check.yaml](https://github.com/syntheticopenschema/model/blob/main/examples/load-check.yaml) - LoadCheck example
- [scripted-check.yaml](https://github.com/syntheticopenschema/model/blob/main/examples/scripted-check.yaml) - ScriptedCheck with inline script
- [scripted-check-with-file.yaml](https://github.com/syntheticopenschema/model/blob/main/examples/scripted-check-with-file.yaml) - ScriptedCheck with external script

---

## Migration Note

In earlier versions, there was a single `PlaywrightCheck` kind. This has been split into two distinct check kinds:

- **LoadCheck** - For passive page load monitoring (no scripting)
- **ScriptedCheck** - For active browser automation (with scripting)

This separation provides better clarity and allows for simpler configurations when scripting is not needed.
