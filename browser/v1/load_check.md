# LoadCheck Specification

**API Version**: `browser/v1`
**Kind**: `LoadCheck`
**Status**: Stable

---

## Overview

LoadCheck validates page load behavior and collects performance metrics using passive browser automation. Unlike ScriptedCheck (active automation), LoadCheck simply loads a URL and validates the resulting page state.

**Use Cases**:
- Page load performance monitoring
- Core Web Vitals tracking
- Uptime monitoring with browser validation
- Content availability checks
- Frontend performance regression detection

---

## Table of Contents

- [Resource Structure](#resource-structure)
- [LoadCheckSpec](#loadcheckspec)
- [CollectionConfig](#collectionconfig)
- [Assertion Types](#assertion-types)
- [Examples](#examples)
- [Implementation Notes](#implementation-notes)
- [Security Considerations](#security-considerations)
- [Conformance](#conformance)

---

## Resource Structure

```yaml
apiVersion: browser/v1
kind: LoadCheck
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
  collect:
    performance: true
    webVitals: true
    resources: false
  checks:
    - type: status
      operator: equals
      value: 200
    - type: loadTime
      operator: lessThan
      value: 3000
  interval: 5m
```

---

## LoadCheckSpec

Specification for passive page load check.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `url` | `URL` | REQUIRED | — | Target URL to load |
| `browser` | [`BrowserConfig`](./common.md#browserconfig) | REQUIRED | — | Browser configuration |
| `collect` | [`CollectionConfig`](#collectionconfig) | OPTIONAL | see below | Performance data collection |
| `checks` | [`LoadCheckAssertion[]`](#assertion-types) | OPTIONAL | `[]` | Assertions to validate |
| `interval` | `Time` | CONDITIONAL | — | Scheduling interval (mutually exclusive with `cron`) |
| `cron` | `Crontab` | CONDITIONAL | — | Cron schedule (mutually exclusive with `interval`) |
| `timeout` | `Time` | OPTIONAL | `30s` | Maximum execution time |
| `retries` | `integer` | OPTIONAL | `1` | Number of retry attempts |
| `locations` | `string[]` | OPTIONAL | `[]` | Execution locations |
| `channels` | `NotificationChannel[]` | OPTIONAL | `[]` | Notification destinations |

### Field Details

#### `url`
- **Type**: `URL` (RFC 3986 compliant URL string)
- **Required**: REQUIRED
- **Description**: Target URL to load in the browser
- **Constraints**:
  - MUST use `http://` or `https://` scheme
  - MUST be a valid, absolute URL
  - Fragment identifiers (`#hash`) are allowed
  - Query parameters are allowed
- **Examples**:
  - `https://example.com`
  - `https://app.example.com/login`
  - `https://shop.example.com/products?category=electronics`

#### `browser`
- **Type**: [`BrowserConfig`](./common.md#browserconfig)
- **Required**: REQUIRED
- **Description**: Browser engine, viewport, and emulation settings
- **See**: [common.md#browserconfig](./common.md#browserconfig) for full specification

#### `collect`
- **Type**: [`CollectionConfig`](#collectionconfig)
- **Required**: OPTIONAL
- **Default**: `CollectionConfig()` with defaults (performance: true, webVitals: true, resources: false)
- **Description**: Configures which performance metrics to collect during page load

#### `checks`
- **Type**: Array of [`LoadCheckAssertion`](#assertion-types)
- **Required**: OPTIONAL
- **Default**: `[]` (empty array)
- **Description**: Assertions to validate against page load results
- **Note**: Empty checks array is valid (collect-only mode)

#### Common Fields

LoadCheck inherits common scheduling and execution fields from base `CheckSpec`:
- See [v1/check.md](../../v1/check.md) for `interval`, `cron`, `timeout`, `retries`, `locations`, `channels`

---

## CollectionConfig

Configures performance data collection during page load.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `performance` | `boolean` | OPTIONAL | `true` | Collect Navigation Timing API metrics |
| `webVitals` | `boolean` | OPTIONAL | `true` | Collect Core Web Vitals (LCP, FID, CLS) |
| `resources` | `boolean` | OPTIONAL | `false` | Collect individual resource timing data |

### Field Details

#### `performance`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Collect Navigation Timing API metrics
- **Metrics collected** (implementation-specific):
  - DNS lookup time
  - TCP connection time
  - TLS handshake time
  - Time to first byte (TTFB)
  - DOM content loaded time
  - Page load complete time
  - Total page size
- **Standard**: [W3C Navigation Timing Level 2](https://www.w3.org/TR/navigation-timing-2/)

#### `webVitals`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Collect Core Web Vitals metrics
- **Metrics collected** (implementation-specific):
  - **LCP** (Largest Contentful Paint) - Loading performance
  - **FID** (First Input Delay) - Interactivity (replaced by INP in 2024)
  - **CLS** (Cumulative Layout Shift) - Visual stability
  - **INP** (Interaction to Next Paint) - Responsiveness
  - **TTFB** (Time to First Byte) - Server response time
  - **FCP** (First Contentful Paint) - Initial rendering
- **Standard**: [Web Vitals Initiative](https://web.dev/vitals/)
- **Note**: Implementations SHOULD collect metrics using web-vitals library or equivalent

#### `resources`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Collect detailed timing for each resource (scripts, stylesheets, images, etc.)
- **Warning**: Enabling this can generate large amounts of data
- **Use cases**:
  - Identifying slow third-party scripts
  - Analyzing resource waterfall
  - Debugging performance issues
- **Standard**: [Resource Timing Level 2](https://www.w3.org/TR/resource-timing-2/)

### Semantics

- Setting all flags to `false` is valid but provides minimal observability
- Metrics are collected but not automatically asserted against
- Assertions use `checks` field to validate performance thresholds
- Collection happens regardless of assertion pass/fail
- Resource collection can significantly increase result payload size

### Example

```yaml
collect:
  performance: true   # Collect navigation timing
  webVitals: true     # Collect Core Web Vitals
  resources: false    # Skip individual resource timing
```

---

## Assertion Types

LoadCheck supports four assertion types for validating page load results.

All assertions extend base assertion types defined in [v1/common.md](../../v1/common.md).

---

### StatusAssertion

Assert on HTTP response status code.

**Extends**: [`NumericAssertion`](../../v1/common.md#numericassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"status"` | REQUIRED | Assertion type discriminator |
| `operator` | `NumericOperator` | REQUIRED | Comparison operator |
| `value` | `integer` | REQUIRED | Expected status code |

#### Supported Operators

- `equals` - Exact match
- `notEquals` - Not equal
- `greaterThan` - Greater than
- `greaterThanOrEquals` - Greater than or equal
- `lessThan` - Less than
- `lessThanOrEquals` - Less than or equal

#### Semantics

- Validates the HTTP status code of the initial page load response
- Does not validate redirect intermediate status codes (only final response)
- Most common: `operator: equals, value: 200`

#### Examples

```yaml
# Exact status code match
- type: status
  operator: equals
  value: 200

# Success range (2xx)
- type: status
  operator: greaterThanOrEquals
  value: 200
- type: status
  operator: lessThan
  value: 300

# Not an error
- type: status
  operator: lessThan
  value: 400
```

---

### LoadTimeAssertion

Assert on total page load time in milliseconds.

**Extends**: [`NumericAssertion`](../../v1/common.md#numericassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"loadTime"` | REQUIRED | Assertion type discriminator |
| `operator` | `NumericOperator` | REQUIRED | Comparison operator |
| `value` | `integer` | REQUIRED | Time threshold in milliseconds |

#### Supported Operators

- `equals` - Exact match (rarely useful)
- `notEquals` - Not equal (rarely useful)
- `greaterThan` - Greater than
- `greaterThanOrEquals` - Greater than or equal
- `lessThan` - Less than (most common)
- `lessThanOrEquals` - Less than or equal

#### Semantics

- Measures time from navigation start to `load` event completion
- Includes all network requests, rendering, and script execution
- Corresponds to `loadEventEnd - navigationStart` in Navigation Timing API
- Values are in milliseconds (not seconds)

#### Performance Guidance

| Load Time | Classification | User Experience |
|-----------|---------------|-----------------|
| < 1000ms | Excellent | Near-instantaneous |
| 1000-3000ms | Good | Acceptable for most users |
| 3000-5000ms | Fair | Noticeable delay |
| > 5000ms | Poor | Users likely to abandon |

#### Examples

```yaml
# Load within 3 seconds
- type: loadTime
  operator: lessThan
  value: 3000

# Load within 5 seconds
- type: loadTime
  operator: lessThanOrEquals
  value: 5000
```

---

### ElementPresentAssertion

Assert on element presence in the DOM.

**Extends**: [`BooleanAssertion`](../../v1/common.md#booleanassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"elementPresent"` | REQUIRED | Assertion type discriminator |
| `selector` | `string` | REQUIRED | CSS selector for element |
| `operator` | `BooleanOperator` | REQUIRED | Comparison operator |
| `value` | `boolean` | REQUIRED | Expected presence state |

#### Supported Operators

- `equals` - Element presence matches expected value
- `is` - Alias for `equals`

#### Semantics

- Checks whether element exists in DOM (not whether it's visible)
- Uses CSS selector syntax (same as `document.querySelector()`)
- Element found → `true`, element not found → `false`
- Does NOT wait for element (evaluated after page load complete)
- Visibility is not checked (use ScriptedCheck's `elementVisible` for that)

#### Selector Syntax

Supports full CSS selector syntax:
- Tag: `div`, `h1`, `button`
- ID: `#header`, `#login-form`
- Class: `.nav-item`, `.btn-primary`
- Attribute: `[data-test="submit"]`, `[aria-label="Close"]`
- Combinators: `nav > ul > li`, `.container .card`
- Pseudo-classes: `:first-child`, `:nth-of-type(2)`

#### Examples

```yaml
# Element should be present
- type: elementPresent
  selector: "h1"
  operator: equals
  value: true

# Element should NOT be present
- type: elementPresent
  selector: ".error-banner"
  operator: equals
  value: false

# Specific element by ID
- type: elementPresent
  selector: "#checkout-button"
  operator: is
  value: true

# Data attribute selector
- type: elementPresent
  selector: "[data-test='success-message']"
  operator: equals
  value: true
```

---

### TextContainsAssertion

Assert on page text content.

**Extends**: [`StringAssertion`](../../v1/common.md#stringassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"textContains"` | REQUIRED | Assertion type discriminator |
| `operator` | `StringOperator` | REQUIRED | Comparison operator |
| `value` | `string` | REQUIRED | Text to search for or match |

#### Supported Operators

- `equals` - Exact match (case-sensitive)
- `notEquals` - Not equal
- `contains` - Contains substring (case-sensitive, most common)
- `notContains` - Does not contain substring
- `startsWith` - Starts with prefix
- `endsWith` - Ends with suffix
- `matches` - Regular expression match

#### Semantics

- Searches full page text content (all visible text)
- Uses `document.body.innerText` or equivalent
- Case-sensitive by default
- Does NOT search HTML source (only rendered text)
- Does NOT search hidden elements

#### Examples

```yaml
# Page contains specific text
- type: textContains
  operator: contains
  value: "Welcome to our site"

# Page does NOT contain error message
- type: textContains
  operator: notContains
  value: "Error:"

# Exact title match
- type: textContains
  operator: equals
  value: "Example Domain"

# Regex match for dynamic content
- type: textContains
  operator: matches
  value: "Order #[0-9]{6} confirmed"
```

---

## Complete Examples

### Example 1: Basic Page Load Check

```yaml
apiVersion: browser/v1
kind: LoadCheck
metadata:
  name: homepage-load
  title: "Homepage Load Performance"
spec:
  url: https://example.com

  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080

  checks:
    - type: status
      operator: equals
      value: 200

    - type: loadTime
      operator: lessThan
      value: 3000

    - type: elementPresent
      selector: "h1"
      operator: equals
      value: true

  interval: 5m
```

---

### Example 2: Performance Monitoring with Web Vitals

```yaml
apiVersion: browser/v1
kind: LoadCheck
metadata:
  name: app-performance
  title: "Application Performance Monitoring"
  labels:
    team: frontend
    criticality: high
spec:
  url: https://app.example.com/dashboard

  browser:
    engine: chromium
    viewport:
      width: 1366
      height: 768
    locale: en-US
    timezone: America/New_York

  collect:
    performance: true
    webVitals: true
    resources: false

  checks:
    - type: status
      operator: equals
      value: 200

    - type: loadTime
      operator: lessThan
      value: 2000

    - type: textContains
      operator: contains
      value: "Dashboard"

  interval: 3m
  timeout: 30s
  retries: 2
  locations:
    - us-east-1
    - eu-west-1
```

---

### Example 3: Mobile Performance Check

```yaml
apiVersion: browser/v1
kind: LoadCheck
metadata:
  name: mobile-performance
  title: "Mobile Page Performance (iPhone)"
spec:
  url: https://m.example.com

  browser:
    engine: webkit
    viewport:
      width: 390
      height: 844
    deviceScaleFactor: 3.0
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)"

  collect:
    performance: true
    webVitals: true
    resources: true  # Collect detailed resource timing

  checks:
    - type: status
      operator: equals
      value: 200

    - type: loadTime
      operator: lessThan
      value: 5000  # Mobile networks are slower

    - type: elementPresent
      selector: ".mobile-nav"
      operator: equals
      value: true

  interval: 10m
```

---

### Example 4: Content Availability Check

```yaml
apiVersion: browser/v1
kind: LoadCheck
metadata:
  name: product-page-check
  title: "Product Page Content Validation"
spec:
  url: https://shop.example.com/products/widget

  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080

  collect:
    performance: false
    webVitals: false
    resources: false

  checks:
    - type: status
      operator: equals
      value: 200

    - type: elementPresent
      selector: ".product-title"
      operator: equals
      value: true

    - type: elementPresent
      selector: ".price"
      operator: equals
      value: true

    - type: elementPresent
      selector: ".add-to-cart"
      operator: equals
      value: true

    - type: textContains
      operator: contains
      value: "In Stock"

    - type: textContains
      operator: notContains
      value: "Out of Stock"

  interval: 5m
```

---

### Example 5: Multi-Region Performance

```yaml
apiVersion: browser/v1
kind: LoadCheck
metadata:
  name: global-performance
  title: "Global CDN Performance Check"
  labels:
    environment: production
spec:
  url: https://cdn.example.com/landing

  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080

  collect:
    performance: true
    webVitals: true
    resources: false

  checks:
    - type: status
      operator: equals
      value: 200

    - type: loadTime
      operator: lessThan
      value: 2000

  interval: 5m
  locations:
    - us-east-1
    - us-west-2
    - eu-west-1
    - eu-central-1
    - ap-southeast-1
    - ap-northeast-1

  channels:
    - channel: slack-cdn-alerts
      severity: High
```

---

## Implementation Notes

### Browser Automation Library

The browser automation library/orchestrator used is **implementation-specific**. This specification does not prescribe Playwright, Puppeteer, Selenium, or any other specific library.

Implementations MUST:
- Document which automation libraries are supported
- Provide code examples for their chosen orchestrator(s)
- Clearly document API surface provided to users (if extensible)

### Page Load Semantics

LoadCheck follows standard browser page load behavior:

1. **Navigation**: Navigate to `url` using chosen orchestrator
2. **Network**: Complete all network requests
3. **Parsing**: Parse HTML, CSS, JavaScript
4. **Execution**: Execute scripts
5. **Rendering**: Render page
6. **Load Event**: Fire `window.onload` event
7. **Collection**: Collect performance metrics
8. **Assertion**: Evaluate all `checks`

### Timing Measurement

**Load Time** measurement using standard browser APIs:

```javascript
// Navigation Timing API
const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;

// Or using Performance Timeline API
const [navigation] = performance.getEntriesByType('navigation');
const loadTime = navigation.loadEventEnd;
```

Implementations MAY use orchestrator-specific APIs if they provide equivalent measurements.

### Performance Collection

Implementations SHOULD collect metrics using standard browser APIs:
- **Navigation Timing API**: `performance.timing` or `performance.getEntriesByType('navigation')`
- **Resource Timing API**: `performance.getEntriesByType('resource')`
- **Web Vitals**: `web-vitals` library or equivalent

Orchestrator-specific APIs are acceptable if they provide equivalent data.

### Element Selectors

Element presence checked using CSS selectors:
```javascript
const element = document.querySelector(selector);
const isPresent = element !== null;
```

### Text Content

Text content extraction:
```javascript
const text = document.body.innerText; // or textContent
```

### Browser Context Isolation

Each check execution SHOULD use a fresh browser context:
- No cookies from previous runs
- No local storage or session storage
- No service workers
- Clean cache (unless explicitly configured otherwise)

This ensures deterministic, repeatable behavior across all orchestrator implementations.

---

## Security Considerations

### Third-Party Content

Loading pages executes third-party scripts:
- Scripts can make external requests
- Scripts can set cookies
- Scripts can fingerprint the browser

**Mitigation**: Run checks in isolated browser contexts, rotate user agents if needed.

### Authentication

LoadCheck does NOT support authenticated checks out of the box:
- No cookie injection
- No HTTP authentication
- No programmatic login

**Workaround**: Use ScriptedCheck for authenticated workflows.

### Data Privacy

Collecting performance metrics may include:
- Full URL with query parameters (may contain PII)
- Resource URLs (third-party tracking scripts)
- Text content (may contain sensitive data)

**Recommendation**: Ensure compliance with data privacy regulations (GDPR, CCPA).

---

## Conformance

Implementations claiming support for `LoadCheck` MUST:

1. **Load URL**: Navigate to specified URL in configured browser
2. **Wait for Load**: Wait for `window.onload` event
3. **Collect Metrics**: Collect performance data based on `collect` configuration
4. **Evaluate Assertions**: Evaluate all `checks` assertions
5. **Report Results**: Return pass/fail status and collected metrics
6. **Honor Browser Config**: Apply all `BrowserConfig` settings
7. **Timeout Handling**: Abort check if `timeout` is exceeded
8. **Retry Logic**: Retry failed checks up to `retries` count

Implementations MAY:
- Collect additional metrics beyond those specified
- Provide screenshot capture on failure
- Support custom collection configuration
- Cache browser instances for performance

---

## Related Documents

- [browser/v1/_index.md](./_index.md) - Browser check overview
- [browser/v1/common.md](./common.md) - BrowserConfig, BrowserEngine, Viewport
- [browser/v1/scripted_check.md](./scripted_check.md) - ScriptedCheck (active automation)
- [v1/common.md](../../v1/common.md) - Core v1 common types
- [v1/check.md](../../v1/check.md) - Base Check resource

---

**Status**: Stable
**Last Updated**: 2026-02-07
