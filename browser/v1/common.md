# Browser Common Types

**API Version**: `browser/v1`
**Status**: Stable

---

## Overview

This document defines common types and configurations shared across all browser check kinds in the `browser/v1` API version.

---

## Table of Contents

- [BrowserEngine](#browserengine)
- [Viewport](#viewport)
- [BrowserConfig](#browserconfig)
- [Design Rationale](#design-rationale)
- [Examples](#examples)

---

## BrowserEngine

Browser engine for check execution.

### Type

`BrowserEngine` is an enumeration string with the following valid values:

| Value | Description | Underlying Technology |
|-------|-------------|----------------------|
| `chromium` | Chromium-based browser | Chromium/Chrome |
| `firefox` | Mozilla Firefox browser | Gecko |
| `webkit` | WebKit-based browser | WebKit (Safari) |

### Semantics

- The browser engine determines which browser implementation is used for check execution
- Each engine has different rendering behavior, JavaScript engine, and capabilities
- Cross-browser testing requires executing checks with multiple engines
- Runner implementations MUST support at least one engine
- Runner implementations SHOULD document which engines are supported

### Conformance Requirements

Runners claiming support for `browser/v1` MUST:
- Support at least one value from the `BrowserEngine` enumeration
- Document which engines are supported
- Return clear errors if an unsupported engine is requested
- Use the specified engine consistently across check executions

### Implementation Notes

The browser automation library/orchestrator used is **implementation-specific**. The specification does not prescribe Playwright, Puppeteer, Selenium, or any other specific library.

Implementations MUST document which automation libraries they support and how `BrowserEngine` values map to actual browser binaries.

**Example mappings** (implementation-dependent):

**Playwright** (example):
- `chromium` → Chromium (typically Chrome)
- `firefox` → Mozilla Firefox
- `webkit` → WebKit (Safari Technology Preview on macOS)

**Puppeteer** (example):
- `chromium` → Chromium/Chrome only
- `firefox` and `webkit` → Not supported

**Selenium WebDriver** (example):
- `chromium` → ChromeDriver
- `firefox` → GeckoDriver
- `webkit` → WebKitDriver (limited support)

**Custom implementations** may:
- Use headless Chrome/Firefox directly
- Integrate with cloud browser services (BrowserStack, Sauce Labs)
- Implement custom browser automation protocols

---

## Viewport

Browser viewport dimensions in pixels.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `width` | `integer` | REQUIRED | Viewport width in pixels |
| `height` | `integer` | REQUIRED | Viewport height in pixels |

### Constraints

- `width` MUST be a positive integer (> 0)
- `height` MUST be a positive integer (> 0)
- Common viewport sizes:
  - Desktop: 1920x1080, 1366x768, 1440x900
  - Tablet: 768x1024, 1024x768
  - Mobile: 375x667 (iPhone), 360x640 (Android)

### Semantics

The viewport defines the visible browser window size:
- Affects responsive design behavior (media queries)
- Determines element visibility and layout
- Does not include browser chrome (toolbars, address bar)
- Combined with `deviceScaleFactor` for mobile emulation

### Example

```yaml
viewport:
  width: 1920
  height: 1080
```

---

## BrowserConfig

Complete browser configuration for check execution.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `engine` | [`BrowserEngine`](#browserengine) | REQUIRED | — | Browser engine to use |
| `viewport` | [`Viewport`](#viewport) | REQUIRED | — | Viewport dimensions |
| `deviceScaleFactor` | `float` | OPTIONAL | `1.0` | Device pixel ratio |
| `userAgent` | `string` | OPTIONAL | engine default | Custom user agent string |
| `locale` | `string` | OPTIONAL | `en-US` | Browser locale (language/region) |
| `timezone` | `string` | OPTIONAL | runner default | IANA timezone identifier |

### Field Details

#### `engine`
- **Type**: [`BrowserEngine`](#browserengine)
- **Required**: REQUIRED
- **Description**: Specifies which browser engine to use for execution

#### `viewport`
- **Type**: [`Viewport`](#viewport)
- **Required**: REQUIRED
- **Description**: Defines the browser window size in pixels

#### `deviceScaleFactor`
- **Type**: `float`
- **Required**: OPTIONAL
- **Default**: `1.0`
- **Description**: Device pixel ratio for mobile/retina emulation
- **Common values**:
  - `1.0` - Standard desktop display
  - `2.0` - Retina/HiDPI displays, modern iPhones
  - `3.0` - High-density Android devices
- **Constraints**: MUST be > 0, typically between 1.0 and 4.0

#### `userAgent`
- **Type**: `string`
- **Required**: OPTIONAL
- **Default**: Browser engine's default user agent
- **Description**: Custom user agent string for browser identification
- **Use cases**:
  - Mobile device emulation
  - Testing user-agent specific behavior
  - Bypassing bot detection (controversial)
- **Security**: Changing user agent does not provide true anonymity

#### `locale`
- **Type**: `string`
- **Required**: OPTIONAL
- **Default**: `en-US`
- **Description**: Browser locale in BCP 47 format (e.g., `en-US`, `fr-FR`, `ja-JP`)
- **Affects**:
  - Date/time formatting
  - Number formatting
  - Language-specific text rendering
  - Accept-Language HTTP header
- **Format**: ISO 639-1 language code + ISO 3166-1 country code

#### `timezone`
- **Type**: `string`
- **Required**: OPTIONAL
- **Default**: Runner's system timezone
- **Description**: IANA timezone identifier (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`)
- **Affects**:
  - JavaScript `Date` object behavior
  - Timezone-sensitive rendering
  - Scheduled events in web applications
- **Format**: IANA Time Zone Database names

### Validation Rules

1. **Extra fields forbidden**: Additional fields beyond those defined MUST NOT be present
2. **Engine support**: Runner MUST validate engine is supported before execution
3. **Viewport range**: Both width and height MUST be positive integers
4. **Locale format**: If provided, locale SHOULD be valid BCP 47 format
5. **Timezone format**: If provided, timezone SHOULD be valid IANA identifier

### Example

```yaml
browser:
  engine: chromium
  viewport:
    width: 1920
    height: 1080
  deviceScaleFactor: 1.0
  userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
  locale: en-US
  timezone: America/Los_Angeles
```

---

## Design Rationale

### Why Separate BrowserConfig?

1. **Reusability**: Same browser configuration shared across LoadCheck and ScriptedCheck
2. **Consistency**: Ensures uniform browser behavior across check types
3. **Testability**: Standardized configuration makes check behavior predictable
4. **Mobile Emulation**: Viewport + deviceScaleFactor + userAgent enable mobile testing

### Why Required Viewport?

Unlike real browser usage, synthetic checks require deterministic, repeatable behavior:
- Responsive designs change based on viewport size
- Element visibility depends on viewport dimensions
- Performance metrics vary by viewport (larger = more rendering work)
- Requiring explicit viewport prevents non-deterministic behavior

### Timezone and Locale

Web applications often have timezone and locale-specific behavior:
- E-commerce sites show region-specific pricing
- Booking systems display times in user timezone
- Content sites show localized text
- Explicit configuration ensures checks validate correct behavior

---

## Common Use Cases

### Desktop Browser Testing
```yaml
browser:
  engine: chromium
  viewport:
    width: 1920
    height: 1080
  deviceScaleFactor: 1.0
```

### Mobile Device Emulation (iPhone 14)
```yaml
browser:
  engine: webkit
  viewport:
    width: 390
    height: 844
  deviceScaleFactor: 3.0
  userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)"
```

### Mobile Device Emulation (Android)
```yaml
browser:
  engine: chromium
  viewport:
    width: 360
    height: 640
  deviceScaleFactor: 2.0
  userAgent: "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36"
```

### Tablet Testing (iPad)
```yaml
browser:
  engine: webkit
  viewport:
    width: 768
    height: 1024
  deviceScaleFactor: 2.0
```

### Cross-Browser Testing
Execute same check with different engines:

```yaml
# Chromium variant
browser:
  engine: chromium
  viewport:
    width: 1366
    height: 768
```

```yaml
# Firefox variant
browser:
  engine: firefox
  viewport:
    width: 1366
    height: 768
```

```yaml
# WebKit variant
browser:
  engine: webkit
  viewport:
    width: 1366
    height: 768
```

### Localized Testing
```yaml
browser:
  engine: chromium
  viewport:
    width: 1920
    height: 1080
  locale: ja-JP
  timezone: Asia/Tokyo
```

---

## Security Considerations

### User Agent Spoofing

Changing `userAgent` allows impersonating different browsers:
- **Legitimate use**: Testing responsive behavior, mobile emulation
- **Problematic use**: Bypassing user-agent based security controls
- **Recommendation**: Document why custom user agents are used

### Bot Detection

Some websites use browser fingerprinting to detect automation:
- Changing user agent alone is insufficient to bypass detection
- Browsers launched via automation have detectable characteristics
- Consider using stealth mode or authenticated sessions for monitoring production sites

### Data Privacy

Browser checks may:
- Store cookies and local storage
- Execute third-party scripts
- Transmit data to external services

Ensure compliance with data privacy regulations (GDPR, CCPA) when monitoring production sites.

---

## Conformance

Implementations claiming support for `browser/v1` common types MUST:
1. Support the `BrowserConfig` structure exactly as defined
2. Forbid extra fields (strict validation)
3. Support at least one `BrowserEngine` value
4. Honor `viewport` settings precisely
5. Apply `deviceScaleFactor` if provided
6. Apply `userAgent`, `locale`, and `timezone` if provided
7. Return clear errors for unsupported engines or invalid configurations

Implementations MAY:
- Support additional browser engines via custom values
- Provide defaults for optional fields
- Add validation warnings for unusual configurations

---

## Related Documents

- [browser/v1/_index.md](./_index.md) - Browser check overview
- [browser/v1/load_check.md](./load_check.md) - LoadCheck specification
- [browser/v1/scripted_check.md](./scripted_check.md) - ScriptedCheck specification
- [v1/common.md](../../v1/common.md) - Core v1 common types

---

**Status**: Stable
**Last Updated**: 2026-02-07
