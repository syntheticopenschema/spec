# ScriptedCheck Specification

**API Version**: `browser/v1`
**Kind**: `ScriptedCheck`
**Status**: Stable

---

## Overview

ScriptedCheck executes custom browser automation scripts to validate complex user workflows and application behavior. Unlike LoadCheck (passive monitoring), ScriptedCheck actively interacts with the page using programmatic scripts.

**Use Cases**:
- Multi-step user workflows (login, checkout, form submission)
- Interactive application testing
- Custom validation logic
- Stateful monitoring (sessions, shopping carts)
- Complex assertions requiring DOM manipulation
- Cross-page navigation flows

---

## Table of Contents

- [Resource Structure](#resource-structure)
- [ScriptedCheckSpec](#scriptedcheckspec)
- [ScriptConfig](#scriptconfig)
- [ScriptLanguage](#scriptlanguage)
- [ScriptSource](#scriptsource)
- [Assertion Types](#assertion-types)
- [Script Execution Model](#script-execution-model)
- [Examples](#examples)
- [Implementation Notes](#implementation-notes)
- [Security Considerations](#security-considerations)
- [Conformance](#conformance)

---

## Resource Structure

```yaml
apiVersion: browser/v1
kind: ScriptedCheck
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
  script:
    language: javascript
    entrypoint: myFunction
    source:
      inline: |
        async function myFunction(page, context) {
          // Custom automation logic
          await page.click('#button');
        }
  checks:
    - type: elementPresent
      selector: "#result"
      operator: equals
      value: true
  interval: 5m
```

---

## ScriptedCheckSpec

Specification for scripted browser check.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `url` | `URL` | REQUIRED | — | Initial page URL to load |
| `browser` | [`BrowserConfig`](./common.md#browserconfig) | REQUIRED | — | Browser configuration |
| `script` | [`ScriptConfig`](#scriptconfig) | REQUIRED | — | Script execution configuration |
| `checks` | [`ScriptedCheckAssertion[]`](#assertion-types) | OPTIONAL | `[]` | Assertions to validate |
| `interval` | `Time` | CONDITIONAL | — | Scheduling interval (mutually exclusive with `cron`) |
| `cron` | `Crontab` | CONDITIONAL | — | Cron schedule (mutually exclusive with `interval`) |
| `timeout` | `Time` | OPTIONAL | `60s` | Maximum execution time |
| `retries` | `integer` | OPTIONAL | `1` | Number of retry attempts |
| `locations` | `string[]` | OPTIONAL | `[]` | Execution locations |
| `channels` | `NotificationChannel[]` | OPTIONAL | `[]` | Notification destinations |

### Field Details

#### `url`
- **Type**: `URL` (RFC 3986 compliant URL string)
- **Required**: REQUIRED
- **Description**: Initial page to load before script execution
- **Constraints**:
  - MUST use `http://` or `https://` scheme
  - MUST be a valid, absolute URL
- **Note**: Script can navigate to other pages after initial load

#### `browser`
- **Type**: [`BrowserConfig`](./common.md#browserconfig)
- **Required**: REQUIRED
- **Description**: Browser engine, viewport, and emulation settings
- **See**: [common.md#browserconfig](./common.md#browserconfig) for full specification

#### `script`
- **Type**: [`ScriptConfig`](#scriptconfig)
- **Required**: REQUIRED
- **Description**: Script language, entrypoint function, and source code

#### `checks`
- **Type**: Array of [`ScriptedCheckAssertion`](#assertion-types)
- **Required**: OPTIONAL
- **Default**: `[]` (empty array)
- **Description**: Assertions to validate after script execution
- **Note**: Script can throw errors independently of assertions

#### Common Fields

ScriptedCheck inherits common scheduling and execution fields from base `CheckSpec`:
- See [v1/check.md](../../v1/check.md) for `interval`, `cron`, `timeout`, `retries`, `locations`, `channels`

---

## ScriptConfig

Script execution configuration.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `language` | [`ScriptLanguage`](#scriptlanguage) | REQUIRED | Script programming language |
| `entrypoint` | `string` | REQUIRED | Function name to execute |
| `source` | [`ScriptSource`](#scriptsource) | REQUIRED | Script source code (inline or file) |

### Field Details

#### `language`
- **Type**: [`ScriptLanguage`](#scriptlanguage)
- **Required**: REQUIRED
- **Description**: Programming language of the script
- **Supported values**: `javascript`, `typescript`, `python`

#### `entrypoint`
- **Type**: `string`
- **Required**: REQUIRED
- **Description**: Name of the function to execute
- **Constraints**:
  - MUST be a valid function name in the specified language
  - MUST exist in the script source
  - Function MUST be async (JavaScript/TypeScript) or coroutine (Python)
- **Examples**: `validateLogin`, `testCheckoutFlow`, `run`

#### `source`
- **Type**: [`ScriptSource`](#scriptsource)
- **Required**: REQUIRED
- **Description**: Script source code configuration
- **Validation**: Exactly one of `inline` or `file` MUST be provided

---

## ScriptLanguage

Supported script programming languages.

### Values

| Language | Description | Runtime | Async Support |
|----------|-------------|---------|---------------|
| `javascript` | JavaScript (ES2020+) | Node.js or browser | `async/await` |
| `typescript` | TypeScript (transpiled) | Node.js (compiled to JS) | `async/await` |
| `python` | Python 3.11+ | CPython | `async/await` |

### Semantics

- **JavaScript**: Native browser runtime, fastest execution, widest compatibility
- **TypeScript**: Type safety, compiled to JavaScript before execution
- **Python**: Playwright Python bindings, familiar to QA/DevOps teams

### Implementation Requirements

Runners claiming support for ScriptedCheck MUST support at least one language.
Runners SHOULD document which languages are supported.

---

## ScriptSource

Script source code configuration.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `inline` | `string` | CONDITIONAL | Inline script source code |
| `file` | `string` | CONDITIONAL | Path to external script file |

### Validation Rules

**Mutual Exclusion**: Exactly one of `inline` or `file` MUST be provided.

- If both are provided → Validation error
- If neither is provided → Validation error

### Field Details

#### `inline`
- **Type**: `string`
- **Description**: Full script source code embedded in YAML
- **Use cases**:
  - Short scripts (< 50 lines)
  - Self-contained checks
  - Quick prototyping
- **Advantages**:
  - Single-file configuration
  - Easy to version control
  - Portable across environments
- **Disadvantages**:
  - YAML escaping complexity for large scripts
  - No syntax highlighting in YAML
  - Harder to test independently

#### `file`
- **Type**: `string`
- **Description**: File path to external script (absolute or relative)
- **Use cases**:
  - Complex scripts (> 50 lines)
  - Shared scripts across multiple checks
  - Scripts with external dependencies
- **Advantages**:
  - Full IDE support (syntax highlighting, linting)
  - Easier to test and debug
  - Better for complex logic
- **Disadvantages**:
  - Multi-file configuration
  - Path resolution complexity
- **Path resolution**:
  - Relative paths resolved from check definition location
  - Absolute paths used as-is
  - Implementation-specific resolution rules

---

## Assertion Types

ScriptedCheck supports five assertion types for validating script execution results.

All assertions extend base assertion types defined in [v1/common.md](../../v1/common.md).

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

#### Semantics

- Checks whether element exists in DOM after script execution
- Does NOT check visibility (use `elementVisible` for that)
- Uses CSS selector syntax
- Evaluated on the page as it exists after script completes

#### Examples

```yaml
# Element should be present after script
- type: elementPresent
  selector: "#success-message"
  operator: equals
  value: true

# Element should be removed by script
- type: elementPresent
  selector: ".loading-spinner"
  operator: equals
  value: false
```

---

### ElementVisibleAssertion

Assert on element visibility.

**Extends**: [`BooleanAssertion`](../../v1/common.md#booleanassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"elementVisible"` | REQUIRED | Assertion type discriminator |
| `selector` | `string` | REQUIRED | CSS selector for element |
| `operator` | `BooleanOperator` | REQUIRED | Comparison operator |
| `value` | `boolean` | REQUIRED | Expected visibility state |

#### Semantics

- Checks whether element is visible (not just present in DOM)
- Visibility criteria:
  - Element has non-zero dimensions
  - Element is not `display: none`
  - Element is not `visibility: hidden`
  - Element is not `opacity: 0` (implementation-dependent)
  - Element is not obscured by another element (implementation-dependent)
- More strict than `elementPresent`

#### Examples

```yaml
# User menu should be visible after login
- type: elementVisible
  selector: ".user-menu"
  operator: equals
  value: true

# Modal should be hidden
- type: elementVisible
  selector: "#modal"
  operator: equals
  value: false
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
- `contains` - Contains substring (most common)
- `notContains` - Does not contain substring
- `startsWith` - Starts with prefix
- `endsWith` - Ends with suffix
- `matches` - Regular expression match

#### Semantics

- Searches full page text content after script execution
- Uses `document.body.innerText` or equivalent
- Case-sensitive by default
- Searches visible text only (not HTML source)

#### Examples

```yaml
# Welcome message after login
- type: textContains
  operator: contains
  value: "Welcome back"

# No error messages
- type: textContains
  operator: notContains
  value: "Error"

# Confirmation message
- type: textContains
  operator: matches
  value: "Order #[0-9]+ confirmed"
```

---

### UrlMatchesAssertion

Assert on current page URL.

**Extends**: [`StringAssertion`](../../v1/common.md#stringassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"urlMatches"` | REQUIRED | Assertion type discriminator |
| `operator` | `StringOperator` | REQUIRED | Comparison operator |
| `value` | `string` | REQUIRED | URL pattern to match |

#### Supported Operators

- `equals` - Exact URL match
- `notEquals` - Not equal
- `contains` - URL contains substring (most common)
- `notContains` - URL does not contain substring
- `startsWith` - URL starts with prefix
- `endsWith` - URL ends with suffix
- `matches` - Regular expression match

#### Semantics

- Checks `window.location.href` after script execution
- Useful for validating navigation (redirects, form submissions)
- Full URL including protocol, domain, path, query, and fragment

#### Examples

```yaml
# Redirected to dashboard after login
- type: urlMatches
  operator: contains
  value: "/dashboard"

# On correct domain
- type: urlMatches
  operator: startsWith
  value: "https://app.example.com"

# Order confirmation URL
- type: urlMatches
  operator: matches
  value: "https://shop\\.example\\.com/order/[0-9]+"
```

---

### ConsoleErrorCountAssertion

Assert on browser console error count.

**Extends**: [`NumericAssertion`](../../v1/common.md#numericassertion)

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | `"consoleErrorCount"` | REQUIRED | Assertion type discriminator |
| `operator` | `NumericOperator` | REQUIRED | Comparison operator |
| `value` | `integer` | REQUIRED | Expected error count threshold |

#### Supported Operators

- `equals` - Exact count
- `notEquals` - Not equal
- `greaterThan` - Greater than
- `greaterThanOrEquals` - Greater than or equal
- `lessThan` - Less than (most common)
- `lessThanOrEquals` - Less than or equal

#### Semantics

- Counts JavaScript errors logged to browser console during check execution
- Includes:
  - Uncaught exceptions
  - Network errors (failed resource loads)
  - Syntax errors
  - Runtime errors
- Does NOT include:
  - Console warnings
  - Console info messages
  - Caught exceptions (try/catch)

#### Examples

```yaml
# No JavaScript errors
- type: consoleErrorCount
  operator: equals
  value: 0

# Tolerate up to 1 error (e.g., third-party script)
- type: consoleErrorCount
  operator: lessThan
  value: 2
```

---

## Script Execution Model

### Browser Automation Library

**IMPORTANT**: The browser automation library/orchestrator used is **implementation-specific**. This specification does NOT prescribe:
- Playwright
- Puppeteer
- Selenium WebDriver
- Or any other specific library

Implementations MUST:
1. **Document** which orchestrator(s) they support
2. **Provide** code examples for each supported orchestrator
3. **Define** the exact `page` and `context` API surface
4. **Publish** sample scripts showing common patterns

Organizations implementing Synthetic Open Schema MUST clearly advertise:
- Which scripting languages are supported
- Which browser automation libraries are used
- API documentation for `page` and `context` objects
- Complete working examples for each use case

### Function Signature

Scripts MUST define an async function with the following signature:

#### JavaScript/TypeScript

```javascript
async function entrypointName(page, context) {
  // Script logic using orchestrator-specific API
  // Can return custom metrics (object)
  // Throws error on failure
}
```

**Parameters**:
- `page`: Browser page automation API (implementation-specific)
- `context`: Additional utilities and configuration (implementation-specific)

**Return value**: Optional object with custom metrics (implementation-specific)

#### Python

```python
async def entrypoint_name(page, context):
    # Script logic using orchestrator-specific API
    # Can return custom metrics (dict)
    # Raises exception on failure
```

**Parameters**:
- `page`: Browser page automation API (implementation-specific)
- `context`: Additional utilities and configuration (implementation-specific)

**Return value**: Optional dict with custom metrics (implementation-specific)

---

### Example API Surfaces by Orchestrator

The following examples show how different implementations might expose browser automation APIs. **These are examples only** - actual implementations may vary.

#### Playwright API (Example)

```javascript
async function validateLogin(page, context) {
  // page is Playwright Page object
  await page.goto('https://example.com/login');
  await page.fill('#username', context.env.USERNAME);
  await page.click('button[type="submit"]');
  await page.waitForNavigation();
}
```

#### Puppeteer API (Example)

```javascript
async function validateLogin(page, context) {
  // page is Puppeteer Page object
  await page.goto('https://example.com/login');
  await page.type('#username', context.env.USERNAME);
  await page.click('button[type="submit"]');
  await page.waitForNavigation();
}
```

#### Selenium WebDriver API (Example)

```javascript
async function validateLogin(driver, context) {
  // driver is WebDriver instance
  await driver.get('https://example.com/login');
  const username = await driver.findElement(By.id('username'));
  await username.sendKeys(context.env.USERNAME);
  const submit = await driver.findElement(By.css('button[type="submit"]'));
  await submit.click();
  await driver.wait(until.urlContains('/dashboard'));
}
```

#### Custom Implementation API (Example)

```javascript
async function validateLogin(browser, context) {
  // Custom browser automation API
  const page = await browser.newPage();
  await page.navigate('https://example.com/login');
  await page.input('#username', context.env.USERNAME);
  await page.submit('button[type="submit"]');
  await page.waitForUrl('/dashboard');
}
```

**Note**: Organizations MUST document their specific API surface. Scripts are NOT portable across different implementations unless they use the same orchestrator.

---

### Execution Flow

1. **Initialize**: Create browser context with `BrowserConfig`
2. **Navigate**: Load initial `url`
3. **Execute Script**: Call entrypoint function with `page` and `context`
4. **Collect State**: Capture final page state (URL, DOM, console errors)
5. **Evaluate Assertions**: Run all `checks` assertions
6. **Report Results**: Return pass/fail status, metrics, and errors

---

### Error Handling

Scripts can fail in two ways:

#### 1. Script Throws Error

```javascript
async function validateLogin(page, context) {
  const loginButton = await page.$('#login');
  if (!loginButton) {
    throw new Error('Login button not found');  // Check FAILS
  }
}
```

**Result**: Check fails immediately, assertions not evaluated

#### 2. Assertion Fails

```yaml
checks:
  - type: elementPresent
    selector: "#user-menu"
    operator: equals
    value: true  # If missing, check FAILS
```

**Result**: Check fails after script completes

---

### Script Best Practices

#### Use Explicit Waits

```javascript
// Bad: No wait, may fail due to timing
await page.click('#submit');
const result = await page.$('#result');

// Good: Wait for element
await page.click('#submit');
await page.waitForSelector('#result', { timeout: 5000 });
const result = await page.$('#result');
```

#### Return Custom Metrics

```javascript
async function validateCheckout(page, context) {
  const startTime = Date.now();

  // Execute checkout flow
  await page.click('#checkout');
  await page.waitForNavigation();

  const duration = Date.now() - startTime;

  // Return custom metrics
  return {
    checkoutDuration: duration,
    cartItems: await page.$$eval('.cart-item', items => items.length)
  };
}
```

#### Handle Errors Gracefully

```javascript
async function validateForm(page, context) {
  try {
    await page.fill('#email', 'test@example.com');
    await page.click('#submit');
    await page.waitForSelector('.success', { timeout: 5000 });
  } catch (error) {
    // Add context to errors
    throw new Error(`Form submission failed: ${error.message}`);
  }
}
```

---

## Complete Examples

### Example 1: Login Flow Validation

```yaml
apiVersion: browser/v1
kind: ScriptedCheck
metadata:
  name: login-flow
  title: "User Login Validation"
spec:
  url: https://app.example.com/login

  browser:
    engine: chromium
    viewport:
      width: 1366
      height: 768

  script:
    language: javascript
    entrypoint: validateLogin
    source:
      inline: |
        async function validateLogin(page, context) {
          // Fill login form
          await page.fill('#username', 'test@example.com');
          await page.fill('#password', 'password123');

          // Submit form
          await page.click('button[type="submit"]');

          // Wait for navigation
          await page.waitForNavigation({ timeout: 5000 });

          // Verify logged in
          const userMenu = await page.$('.user-menu');
          if (!userMenu) {
            throw new Error('Login failed: user menu not found');
          }
        }

  checks:
    - type: elementPresent
      selector: ".user-menu"
      operator: equals
      value: true

    - type: elementVisible
      selector: ".user-menu"
      operator: equals
      value: true

    - type: urlMatches
      operator: contains
      value: "/dashboard"

    - type: textContains
      operator: contains
      value: "Welcome"

    - type: consoleErrorCount
      operator: equals
      value: 0

  interval: 10m
  timeout: 60s
  retries: 3
```

---

### Example 2: E-commerce Checkout Flow (External Script)

```yaml
apiVersion: browser/v1
kind: ScriptedCheck
metadata:
  name: checkout-flow
  title: "E-commerce Checkout Validation"
  labels:
    criticality: high
    team: commerce
spec:
  url: https://shop.example.com

  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080
    deviceScaleFactor: 2.0

  script:
    language: typescript
    entrypoint: validateCheckoutFlow
    source:
      file: scripts/checkout-validation.ts

  checks:
    - type: urlMatches
      operator: contains
      value: "/order/"

    - type: elementPresent
      selector: "#order-confirmation"
      operator: equals
      value: true

    - type: textContains
      operator: contains
      value: "Order confirmed"

    - type: consoleErrorCount
      operator: lessThan
      value: 1

  interval: 5m
  timeout: 120s
  retries: 2

  locations:
    - us-east-1
    - eu-west-1

  channels:
    - channel: pagerduty-commerce
      severity: Critical
```

**External script** (`scripts/checkout-validation.ts`):

```typescript
async function validateCheckoutFlow(page: any, context: any) {
  // Add product to cart
  await page.click('[data-test="add-to-cart"]');
  await page.waitForSelector('.cart-badge', { timeout: 3000 });

  // Go to cart
  await page.click('[data-test="cart-icon"]');
  await page.waitForSelector('.cart-items', { timeout: 3000 });

  // Proceed to checkout
  await page.click('[data-test="checkout-button"]');
  await page.waitForNavigation({ timeout: 5000 });

  // Fill shipping information
  await page.fill('#shipping-name', 'Test User');
  await page.fill('#shipping-address', '123 Test St');
  await page.fill('#shipping-city', 'Test City');
  await page.fill('#shipping-zip', '12345');

  // Fill payment information (test mode)
  await page.fill('#card-number', '4242424242424242');
  await page.fill('#card-expiry', '12/25');
  await page.fill('#card-cvc', '123');

  // Submit order
  await page.click('[data-test="place-order"]');
  await page.waitForNavigation({ timeout: 10000 });

  // Return custom metrics
  const orderNumber = await page.textContent('#order-number');
  return {
    orderNumber: orderNumber,
    timestamp: new Date().toISOString()
  };
}
```

---

### Example 3: Multi-Page Form Submission (Python)

```yaml
apiVersion: browser/v1
kind: ScriptedCheck
metadata:
  name: survey-submission
  title: "Multi-Step Survey Validation"
spec:
  url: https://survey.example.com

  browser:
    engine: firefox
    viewport:
      width: 1280
      height: 720

  script:
    language: python
    entrypoint: validate_survey_flow
    source:
      inline: |
        async def validate_survey_flow(page, context):
            # Page 1: Personal info
            await page.fill("#name", "Test User")
            await page.fill("#email", "test@example.com")
            await page.click("button[data-step='next']")
            await page.wait_for_selector("[data-step='2']", timeout=3000)

            # Page 2: Preferences
            await page.click("#option-a")
            await page.click("button[data-step='next']")
            await page.wait_for_selector("[data-step='3']", timeout=3000)

            # Page 3: Submit
            await page.fill("#comments", "Test comment")
            await page.click("button[type='submit']")
            await page.wait_for_navigation(timeout=5000)

            # Verify confirmation
            confirmation = await page.query_selector("#confirmation-code")
            if not confirmation:
                raise Exception("Survey submission failed")

  checks:
    - type: elementPresent
      selector: "#confirmation-code"
      operator: equals
      value: true

    - type: textContains
      operator: contains
      value: "Thank you"

    - type: urlMatches
      operator: contains
      value: "/confirmation"

  interval: 1h
```

---

### Example 4: API Integration Test

```yaml
apiVersion: browser/v1
kind: ScriptedCheck
metadata:
  name: api-integration
  title: "Frontend + API Integration Test"
spec:
  url: https://app.example.com/data

  browser:
    engine: chromium
    viewport:
      width: 1920
      height: 1080

  script:
    language: javascript
    entrypoint: validateApiIntegration
    source:
      inline: |
        async function validateApiIntegration(page, context) {
          // Intercept API requests
          const requests = [];
          page.on('request', req => {
            if (req.url().includes('/api/')) {
              requests.push(req.url());
            }
          });

          // Trigger data load
          await page.click('#load-data');
          await page.waitForSelector('.data-loaded', { timeout: 5000 });

          // Verify API was called
          if (requests.length === 0) {
            throw new Error('No API requests detected');
          }

          // Return metrics
          return {
            apiRequestCount: requests.length,
            apiEndpoints: requests
          };
        }

  checks:
    - type: elementPresent
      selector: ".data-loaded"
      operator: equals
      value: true

    - type: textContains
      operator: notContains
      value: "Loading..."

    - type: consoleErrorCount
      operator: equals
      value: 0

  interval: 5m
```

---

## Implementation Notes

### Browser Automation Library Selection

**Vendor Responsibility**: Organizations implementing Synthetic Open Schema MUST:

1. **Choose Orchestrator(s)**: Select which browser automation library to use
   - Playwright (Node.js, Python, Java, .NET)
   - Puppeteer (Node.js)
   - Selenium WebDriver (multi-language)
   - Custom or proprietary solutions
   - Cloud browser services (BrowserStack, Sauce Labs, etc.)

2. **Document API Surface**: Clearly specify what `page` and `context` provide
   - Method signatures and return types
   - Available automation APIs
   - Error handling behavior
   - Timeout semantics

3. **Provide Code Examples**: Publish sample scripts for common scenarios
   - Login flows
   - Form submissions
   - Multi-page navigation
   - File uploads
   - Dropdown selections
   - Waiting strategies

4. **Advertise Support**: Make it clear which:
   - Languages are supported (javascript, typescript, python)
   - Orchestrators are used
   - Browser engines are available
   - Limitations exist

### Browser Automation API

Implementations provide orchestrator-specific APIs:
- **`page`**: Browser page automation object (varies by orchestrator)
- **`context`**: Additional utilities (logging, metrics, environment variables, secrets)

### Script Isolation

Each check execution SHOULD:
- Use a fresh browser context
- Clear cookies and storage
- Reset browser state
- Use isolated script environment

### Timeout Behavior

- `timeout` applies to entire check execution (navigation + script + assertions)
- Scripts SHOULD implement internal timeouts for individual operations
- Exceeding timeout results in check failure

### Custom Metrics

Scripts can return custom metrics as objects:

```javascript
return {
  loginDuration: 1234,
  cartItems: 5,
  totalPrice: 99.99
};
```

Implementations MAY store and display these metrics separately from assertions.

---

## Script Portability and Vendor Lock-in

### Portability Considerations

**Scripts are NOT portable** across implementations using different orchestrators:
- A script written for Playwright cannot run on Puppeteer without modification
- A script using Selenium WebDriver API is incompatible with Playwright
- Custom orchestrators have unique APIs

**Why?**
- Each orchestrator has different method names and signatures
- Browser interaction patterns vary (e.g., `page.click()` vs `element.click()`)
- Wait strategies differ across libraries
- Return types and error handling vary

### Mitigating Vendor Lock-in

Organizations can reduce vendor lock-in by:

1. **Abstraction Layer**: Provide a common API wrapper
   ```javascript
   // Vendor-provided abstraction
   async function login(page, username, password) {
     // Wraps orchestrator-specific calls
     await page.input('#username', username);
     await page.input('#password', password);
     await page.submit('#login-form');
   }
   ```

2. **Script Templates**: Provide templates for common patterns
   - Form filling patterns
   - Navigation patterns
   - Waiting strategies
   - Error handling

3. **Migration Tools**: Offer tools to convert scripts between orchestrators

4. **Documentation**: Clearly document portability limitations upfront

### Vendor Responsibilities

When implementing ScriptedCheck, vendors SHOULD:

1. **Be Explicit**: Clearly state which orchestrator is used
   - "Uses Playwright for browser automation"
   - "Built on Puppeteer"
   - "Selenium WebDriver compatible"

2. **Provide Examples**: Publish extensive code samples
   - Login flows (simple, multi-factor, SSO)
   - E-commerce workflows (browse, cart, checkout)
   - Form submissions (search, filters, upload)
   - Navigation patterns (multi-page, SPA, tabs)

3. **Document API**: Full API reference for `page` and `context`
   - What methods are available?
   - What do they return?
   - How do errors surface?
   - What are the timeout defaults?

4. **Support Migration**: If changing orchestrators, provide migration guides

5. **Consider Abstraction**: Consider providing orchestrator-agnostic helpers

---

## Security Considerations

### Script Execution

Scripts execute with full browser automation capabilities:
- Can navigate to any URL
- Can submit forms with arbitrary data
- Can execute arbitrary JavaScript in page context
- Can make external HTTP requests

**Mitigation**: Restrict script sources, review scripts before deployment, use separate environments for testing.

### Credential Management

Scripts often require credentials (usernames, passwords, API keys):
- **DO NOT** hardcode credentials in scripts
- **USE** environment variables or secret management
- **INJECT** credentials securely via `context` parameter

Example:
```javascript
async function validateLogin(page, context) {
  // Good: Use context for credentials
  const username = context.env.TEST_USERNAME;
  const password = context.env.TEST_PASSWORD;

  await page.fill('#username', username);
  await page.fill('#password', password);
}
```

### Sensitive Data

Scripts may interact with production data:
- Avoid modifying production state (use test accounts, read-only operations)
- Be cautious with form submissions, purchases, deletions
- Consider using dedicated test environments

### Script Tampering

If loading scripts from `file`:
- Validate script integrity (checksums, signatures)
- Restrict file system access
- Use read-only script directories

---

## Conformance

Implementations claiming support for `ScriptedCheck` MUST:

1. **Load URL**: Navigate to specified `url` in configured browser
2. **Execute Script**: Run script entrypoint function with `page` and `context` parameters
3. **Handle Errors**: Fail check if script throws error
4. **Evaluate Assertions**: Run all `checks` assertions after script completes
5. **Report Results**: Return pass/fail status, script output, and assertion results
6. **Honor Timeout**: Abort check if `timeout` is exceeded
7. **Support Language**: Support at least one `ScriptLanguage`

Implementations MAY:
- Support multiple languages
- Provide additional context utilities
- Capture screenshots on failure
- Record video of execution
- Store custom metrics returned by scripts

---

## Related Documents

- [browser/v1/_index.md](./_index.md) - Browser check overview
- [browser/v1/common.md](./common.md) - BrowserConfig, BrowserEngine, Viewport
- [browser/v1/load_check.md](./load_check.md) - LoadCheck (passive monitoring)
- [v1/common.md](../../v1/common.md) - Core v1 common types
- [v1/check.md](../../v1/check.md) - Base Check resource

---

**Status**: Stable
**Last Updated**: 2026-02-07
