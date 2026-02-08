# HTTP Check

**Version**: v1
**Kind**: `HttpCheck`
**Status**: Stable

---

## Overview

The HTTP Check validates HTTP/HTTPS endpoints by making requests and evaluating response characteristics including status codes, headers, body content, response time, and size.

**Common Use Cases:**
- API health monitoring
- Website availability checks
- Response time SLA validation
- Content verification
- Header validation (security headers, caching, etc.)
- SSL/TLS-enabled endpoints (HTTPS)
- RESTful API testing

---

## Resource Structure

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: {check-name}
  labels:
    key: value
spec:
  url: https://api.example.com/health
  method: GET  # optional, default: GET
  headers:     # optional
    Authorization: Bearer token
    User-Agent: SyntheticMonitor/1.0

  # Scheduling (REQUIRED - one of)
  interval: 1m
  # OR
  cron: "*/5 * * * *"

  # Common fields (OPTIONAL)
  timeout: 10s
  retries: 3
  locations:
    - us-east-1
  channels:
    - channel: alerts
      severity: High

  # Assertions (REQUIRED)
  checks:
    - type: statusCode
      operator: equals
      value: 200
    - type: duration
      operator: lessThan
      value: 500ms
```

---

## Spec Fields

### url

**Type**: `HttpUrl`
**REQUIRED**

**Description**: The HTTP/HTTPS URL to check.

**Examples**:
```yaml
url: https://example.com
url: https://api.example.com/v1/health
url: http://localhost:8080/status
url: https://example.com:8443/metrics
```

**Validation**:
- MUST be valid HTTP or HTTPS URL
- MUST include scheme (`http://` or `https://`)
- MAY include port number
- MAY include path, query parameters, and fragment

**URL Components**:
- **Scheme**: `http` or `https` (REQUIRED)
- **Host**: Domain name or IP address (REQUIRED)
- **Port**: Custom port (OPTIONAL, defaults: 80 for HTTP, 443 for HTTPS)
- **Path**: URL path (OPTIONAL, defaults to `/`)
- **Query**: Query parameters (OPTIONAL)
- **Fragment**: URL fragment (OPTIONAL)

---

### method

**Type**: `string`
**OPTIONAL**
**Default**: `"GET"`

**Description**: HTTP method to use for the request.

**Supported Methods**:
- `GET` (default) - Retrieve resource
- `POST` - Create resource
- `PUT` - Update resource
- `PATCH` - Partial update
- `DELETE` - Delete resource
- `HEAD` - Get headers only (no body)
- `OPTIONS` - Get supported methods

**Examples**:
```yaml
# GET request (default)
method: GET

# POST request for create operations
method: POST

# HEAD request for lightweight checks
method: HEAD
```

**Notes**:
- Method names are case-sensitive (UPPERCASE recommended)
- `HEAD` requests are useful for checking endpoint availability without downloading the response body
- `OPTIONS` requests can verify CORS configuration

---

### headers

**Type**: `dict[str, str]`
**OPTIONAL**
**Default**: `{}`

**Description**: HTTP headers to include in the request.

**Common Headers**:
- `Authorization` - Authentication credentials
- `User-Agent` - Client identification
- `Accept` - Acceptable response content types
- `Content-Type` - Request body content type (for POST/PUT)
- `Cache-Control` - Caching directives
- `X-Custom-Header` - Custom application headers

**Examples**:
```yaml
# Bearer token authentication
headers:
  Authorization: Bearer eyJhbGc...

# API key authentication
headers:
  X-API-Key: secret-api-key

# Content negotiation
headers:
  Accept: application/json
  User-Agent: SyntheticMonitor/1.0

# Multiple headers
headers:
  Authorization: Bearer token
  Accept: application/json
  X-Request-ID: check-12345
```

**Security Considerations**:
- Credentials in headers are stored in plain text
- Consider using environment variable substitution
- Avoid committing secrets to version control
- Use secure channels for check definition storage

---

### checks

**Type**: `array[HttpAssertion]`
**REQUIRED**

**Description**: List of assertions to evaluate against the HTTP response.

**Supported Assertion Types**:
1. `statusCode` - HTTP status code (200, 404, 500, etc.)
2. `duration` - Total request/response latency
3. `ttfb` - Time to first byte (server response time)
4. `size` - Response body size in bytes
5. `body` - Response body content matching
6. `header` - Response header validation

See [Assertions](#assertions) section for details.

---

## Assertions

All HTTP assertions validate properties of the HTTP response.

### statusCode

**Type**: `NumericAssertion`

**Description**: Assert on HTTP response status code.

**Fields**:
- `type`: `"statusCode"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `integer` (REQUIRED)
  - Valid range: 100-599

**Examples**:

Assert successful response:
```yaml
- type: statusCode
  operator: equals
  value: 200
```

Assert any 2xx success:
```yaml
- type: statusCode
  operator: greaterThan
  value: 199
- type: statusCode
  operator: lessThan
  value: 300
```

Assert not a server error:
```yaml
- type: statusCode
  operator: lessThan
  value: 500
```

Assert specific status code:
```yaml
- type: statusCode
  operator: equals
  value: 201  # Created
```

**Common Status Codes**:
- **2xx Success**: 200 OK, 201 Created, 204 No Content
- **3xx Redirect**: 301 Moved Permanently, 302 Found, 304 Not Modified
- **4xx Client Error**: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 429 Too Many Requests
- **5xx Server Error**: 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout

**Semantics**:
- Check PASSES if status code assertion evaluates to true
- Check FAILS if status code assertion evaluates to false
- Redirect responses (3xx) are followed by default unless implementation specifies otherwise

---

### duration

**Type**: `TimebasedAssertion`

**Description**: Assert on total request/response latency (time from request start to response complete).

**Fields**:
- `type`: `"duration"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `StrictTime` (REQUIRED)
  - MUST include unit suffix: `"500ms"`, `"5s"`, `"1m"`, etc.
  - Bare integers are NOT allowed

**Examples**:

Assert response within 500ms (SLA):
```yaml
- type: duration
  operator: lessThan
  value: 500ms
```

Assert response within 5 seconds:
```yaml
- type: duration
  operator: lessThan
  value: 5s
```

Assert response within 200ms (strict performance):
```yaml
- type: duration
  operator: lessThan
  value: 200ms
```

Using seconds:
```yaml
- type: duration
  operator: lessThan
  value: 2s
```

**Invalid - bare integers rejected**:
```yaml
- type: duration
  operator: lessThan
  value: 500  # ❌ ERROR: unit suffix required
```

**Semantics**:
- Duration includes full request/response cycle:
  - DNS resolution time (if applicable)
  - TCP connection time
  - TLS handshake time (for HTTPS)
  - Time to first byte (TTFB)
  - Response body download time
- Check PASSES if duration assertion evaluates to true
- Check FAILS if duration assertion evaluates to false
- Unit suffix REQUIRED to avoid ambiguity

**Performance Guidance**:
- **Excellent**: < 200ms
- **Good**: 200ms - 500ms
- **Acceptable**: 500ms - 1000ms
- **Slow**: > 1000ms

---

### ttfb

**Type**: `TimebasedAssertion`

**Description**: Assert on Time to First Byte (TTFB) - the time from request sent to receiving the first response byte.

**Fields**:
- `type`: `"ttfb"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `StrictTime` (REQUIRED)
  - MUST include unit suffix: `"100ms"`, `"1s"`, etc.
  - Bare integers are NOT allowed

**Examples**:

Assert TTFB within 100ms (excellent server performance):
```yaml
- type: ttfb
  operator: lessThan
  value: 100ms
```

Assert TTFB within 300ms (acceptable):
```yaml
- type: ttfb
  operator: lessThan
  value: 300ms
```

Assert TTFB within 1 second:
```yaml
- type: ttfb
  operator: lessThan
  value: 1s
```

**Invalid - bare integers rejected**:
```yaml
- type: ttfb
  operator: lessThan
  value: 100  # ❌ ERROR: unit suffix required
```

**Semantics**:
- TTFB measures **server response time** only
- Includes: DNS + Connect + TLS + Server Processing
- Does NOT include: Response body download time
- TTFB < Total Duration (duration includes download)
- Check PASSES if TTFB assertion evaluates to true
- Check FAILS if TTFB assertion evaluates to false
- Unit suffix REQUIRED to avoid ambiguity

**TTFB vs Duration**:
```
duration = DNS + Connect + TLS + TTFB + Download
ttfb = DNS + Connect + TLS + Server Processing
```

**Performance Guidance**:
- **Excellent**: < 100ms
- **Good**: 100ms - 300ms
- **Acceptable**: 300ms - 600ms
- **Slow**: > 600ms

**Use Cases**:
- Monitor backend server performance
- Separate network latency from server processing
- Identify slow database queries or API calls
- Validate server-side SLA (independent of response size)

---

### size

**Type**: `NumericAssertion`

**Description**: Assert on response body size in bytes.

**Fields**:
- `type`: `"size"` (REQUIRED)
- `operator`: `NumericOperator` (REQUIRED)
  - `equals`, `notEquals`, `greaterThan`, `lessThan`
- `value`: `integer` (REQUIRED)
  - Response body size in bytes

**Examples**:

Assert non-empty response:
```yaml
- type: size
  operator: greaterThan
  value: 0
```

Assert response smaller than 1MB:
```yaml
- type: size
  operator: lessThan
  value: 1048576  # 1MB in bytes
```

Assert exact response size:
```yaml
- type: size
  operator: equals
  value: 512
```

Assert response at least 100 bytes:
```yaml
- type: size
  operator: greaterThan
  value: 99
```

**Common Size Limits**:
- 1 KB = 1,024 bytes
- 1 MB = 1,048,576 bytes
- 1 GB = 1,073,741,824 bytes

**Semantics**:
- Size represents decompressed response body length in bytes
- Check PASSES if size assertion evaluates to true
- Check FAILS if size assertion evaluates to false
- Empty responses have size 0

**Use Cases**:
- Verify response is not empty
- Detect unexpectedly large responses
- Validate payload size for bandwidth monitoring
- Ensure consistent response sizes

---

### body

**Type**: `StringAssertion`

**Description**: Assert on response body content.

**Fields**:
- `type`: `"body"` (REQUIRED)
- `operator`: `StringOperator` (REQUIRED)
  - `equals`, `notEquals`, `contains`, `notContains`
- `value`: `string` (REQUIRED)

**Examples**:

Assert body contains expected text:
```yaml
- type: body
  operator: contains
  value: "OK"
```

Assert JSON response contains field:
```yaml
- type: body
  operator: contains
  value: '"status":"healthy"'
```

Assert body equals specific content:
```yaml
- type: body
  operator: equals
  value: '{"status":"ok"}'
```

Assert body does not contain error:
```yaml
- type: body
  operator: notContains
  value: "error"
```

Assert health check response:
```yaml
- type: body
  operator: contains
  value: "healthy"
```

**Semantics**:
- Matching is case-sensitive by default
- `contains` searches anywhere in response body
- `equals` requires exact match (including whitespace)
- Check PASSES if body assertion evaluates to true
- Check FAILS if body assertion evaluates to false

**Best Practices**:
- Use `contains` for flexible matching (recommended for JSON/HTML)
- Use `equals` for exact text responses
- Prefer specific strings over generic ones
- Be aware of whitespace sensitivity with `equals`

**Limitations**:
- No regex support (use `contains` for substring matching)
- No JSON path support (implementation-specific extension)
- Full body loaded into memory (consider size limits)

---

### header

**Type**: `KeyValueAssertion`

**Description**: Assert on response headers.

**Modes**:
1. **Without `name`**: Operations against header names (keys)
2. **With `name`**: Operations against specific header value

**Fields**:
- `type`: `"header"` (REQUIRED)
- `operator`: `StringOperator` (REQUIRED)
  - `equals`, `notEquals`, `contains`, `notContains`
- `name`: `string` (OPTIONAL)
  - Header name to check (e.g., `"Content-Type"`)
- `value`: `string` (REQUIRED)
  - Expected value or substring

**Examples - Header Name Assertions** (without `name`):

Assert Content-Type header exists:
```yaml
- type: header
  operator: contains
  value: "Content-Type"
```

Assert security header exists:
```yaml
- type: header
  operator: contains
  value: "Strict-Transport-Security"
```

**Examples - Header Value Assertions** (with `name`):

Assert JSON content type:
```yaml
- type: header
  name: Content-Type
  operator: contains
  value: "application/json"
```

Assert exact content type:
```yaml
- type: header
  name: Content-Type
  operator: equals
  value: "application/json; charset=utf-8"
```

Assert cache control:
```yaml
- type: header
  name: Cache-Control
  operator: contains
  value: "max-age"
```

Assert HSTS enabled:
```yaml
- type: header
  name: Strict-Transport-Security
  operator: contains
  value: "max-age"
```

Assert CORS header:
```yaml
- type: header
  name: Access-Control-Allow-Origin
  operator: equals
  value: "*"
```

**Common Security Headers**:
- `Strict-Transport-Security` - HSTS (force HTTPS)
- `Content-Security-Policy` - CSP (XSS protection)
- `X-Frame-Options` - Clickjacking protection
- `X-Content-Type-Options` - MIME sniffing protection
- `Permissions-Policy` - Feature permissions

**Common Headers to Validate**:
- `Content-Type` - Response content type
- `Cache-Control` - Caching behavior
- `ETag` - Resource versioning
- `Last-Modified` - Resource modification time
- `Server` - Server identification
- `X-RateLimit-*` - Rate limiting info

**Semantics**:
- Header names are case-insensitive (per HTTP spec)
- Header values are case-sensitive
- Check PASSES if header assertion evaluates to true
- Check FAILS if header assertion evaluates to false

---

## Examples

### Basic API Health Check

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: api-health
  title: "API Health Endpoint"
  labels:
    environment: production
    service: api
spec:
  url: https://api.example.com/health
  method: GET
  interval: 1m
  timeout: 5s
  retries: 2
  checks:
    - type: statusCode
      operator: equals
      value: 200
    - type: body
      operator: contains
      value: "healthy"
    - type: duration
      operator: lessThan
      value: 500ms
  locations:
    - us-east-1
    - eu-west-1
  channels:
    - channel: api-alerts
      severity: Critical
```

### Authenticated API Check

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: authenticated-api
  title: "Authenticated API Endpoint"
  labels:
    environment: production
spec:
  url: https://api.example.com/v1/users/me
  method: GET
  headers:
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    Accept: application/json
  interval: 5m
  timeout: 10s
  checks:
    - type: statusCode
      operator: equals
      value: 200
    - type: header
      name: Content-Type
      operator: contains
      value: "application/json"
    - type: body
      operator: contains
      value: '"email"'
    - type: duration
      operator: lessThan
      value: 1s
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: High
```

### POST Request Check

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: create-user-endpoint
  title: "POST /users Endpoint Test"
spec:
  url: https://api.example.com/v1/users
  method: POST
  headers:
    Authorization: Bearer test-token
    Content-Type: application/json
  interval: 10m
  timeout: 5s
  checks:
    - type: statusCode
      operator: equals
      value: 201  # Created
    - type: header
      name: Location
      operator: contains
      value: "/users/"
    - type: duration
      operator: lessThan
      value: 2s
  locations:
    - us-east-1
```

### Performance SLA Validation

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: homepage-performance
  title: "Homepage Performance SLA"
  labels:
    environment: production
    team: frontend
spec:
  url: https://example.com
  method: GET
  interval: 1m
  timeout: 10s
  retries: 3
  checks:
    - type: statusCode
      operator: equals
      value: 200
    # SLA: 95th percentile < 1s
    - type: duration
      operator: lessThan
      value: 1s
    # Ensure response is not empty
    - type: size
      operator: greaterThan
      value: 0
    # Verify page title present
    - type: body
      operator: contains
      value: "<title>"
  locations:
    - us-east-1
    - us-west-2
    - eu-west-1
  channels:
    - channel: frontend-alerts
      severity: High
```

### Security Headers Validation

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: security-headers
  title: "Security Headers Compliance"
  labels:
    environment: production
    security: true
spec:
  url: https://example.com
  method: HEAD  # Lightweight, headers only
  interval: 1h
  timeout: 5s
  checks:
    - type: statusCode
      operator: equals
      value: 200
    # HSTS enabled
    - type: header
      name: Strict-Transport-Security
      operator: contains
      value: "max-age"
    # CSP present
    - type: header
      name: Content-Security-Policy
      operator: contains
      value: "default-src"
    # X-Frame-Options set
    - type: header
      operator: contains
      value: "X-Frame-Options"
    # X-Content-Type-Options set
    - type: header
      name: X-Content-Type-Options
      operator: equals
      value: "nosniff"
  locations:
    - us-east-1
  channels:
    - channel: security-alerts
      severity: Critical
```

### JSON API Validation

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: json-api-structure
  title: "JSON API Structure Validation"
spec:
  url: https://api.example.com/v1/status
  method: GET
  headers:
    Accept: application/json
  interval: 2m
  timeout: 5s
  checks:
    - type: statusCode
      operator: equals
      value: 200
    - type: header
      name: Content-Type
      operator: contains
      value: "application/json"
    # Validate JSON structure
    - type: body
      operator: contains
      value: '"version"'
    - type: body
      operator: contains
      value: '"status"'
    - type: body
      operator: contains
      value: '"timestamp"'
    # Performance requirement
    - type: duration
      operator: lessThan
      value: 300ms
  locations:
    - us-east-1
```

### Redirect Validation

```yaml
apiVersion: v1
kind: HttpCheck
metadata:
  name: http-to-https-redirect
  title: "HTTP to HTTPS Redirect"
spec:
  url: http://example.com  # Note: HTTP not HTTPS
  method: GET
  interval: 6h
  timeout: 5s
  checks:
    # Expect redirect
    - type: statusCode
      operator: equals
      value: 301  # Moved Permanently
    # Verify Location header
    - type: header
      name: Location
      operator: contains
      value: "https://"
  locations:
    - us-east-1
```

---

## Validation Rules

### Required Fields

- `apiVersion` MUST be `"v1"`
- `kind` MUST be `"HttpCheck"`
- `metadata.name` MUST be valid `CaseInsensitiveKey`
- `spec.url` MUST be valid `HttpUrl`
- `spec.checks` MUST be non-empty array
- One of `spec.interval` or `spec.cron` MUST be specified

### Optional Fields

- `spec.method` defaults to `"GET"`
- `spec.headers` defaults to `{}`
- `spec.timeout` defaults to `10s`
- `spec.retries` defaults to `1`
- `spec.locations` defaults to `[]`
- `spec.channels` defaults to `[]`

### Extra Fields

- Extra fields are FORBIDDEN (`extra="forbid"`)
- Unknown fields MUST cause validation errors

---

## Execution Semantics

### Request Behavior

1. Runner resolves `url` hostname via DNS
2. Runner establishes TCP connection to target (port 80 or 443)
3. Runner initiates TLS handshake (HTTPS only)
4. Runner sends HTTP request with `method` and `headers`
5. Runner receives response (status, headers, body)
6. Runner evaluates all assertions in `checks` array
7. Check PASSES if all assertions pass
8. Check FAILS if any assertion fails

### Redirect Handling

- Implementations SHOULD follow redirects (3xx status codes) by default
- Implementations MAY provide configuration to disable redirect following
- Final response after redirects is used for assertions
- Status code assertions can validate redirect behavior

### Timeout Behavior

- Timeout applies to total execution time (DNS + TCP + TLS + HTTP)
- If timeout exceeded, check FAILS with timeout error
- Partial responses are discarded on timeout

### Error Conditions

Check FAILS if:
- DNS resolution fails
- Cannot establish TCP connection
- TLS handshake fails (HTTPS)
- HTTP request fails
- Any assertion evaluates to false
- Timeout exceeded
- Network error occurs

### Retry Behavior

- Failed checks are retried up to `retries` times
- Retries occur immediately after failure
- If ANY attempt succeeds, check is considered successful
- Timeout applies to total execution time including retries

---

## Conformance

Implementations claiming HttpCheck conformance MUST:

1. **Support HTTP/HTTPS**: Accept both `http://` and `https://` URLs
2. **Support common methods**: Implement GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
3. **Support headers**: Send custom headers specified in `spec.headers`
4. **Support all assertions**: Implement statusCode, duration, size, body, header
5. **Evaluate all checks**: Execute all assertions in `checks` array
6. **Fail on any assertion failure**: Check fails if ANY assertion fails
7. **Handle timeouts**: Respect `timeout` field
8. **Retry on failure**: Implement retry logic according to `retries` field
9. **Follow redirects**: Follow HTTP redirects by default (MAY be configurable)

Implementations SHOULD:
- Capture timing breakdown (DNS, connect, TLS, TTFB, download)
- Capture response size
- Support multiple locations
- Send notifications to configured channels
- Provide detailed error messages for validation failures
- Report full HTTP metrics in results

---

## Security Considerations

### Credential Management

- Headers MAY contain sensitive credentials (API keys, tokens)
- Implementations SHOULD support secure credential storage
- Implementations SHOULD NOT log headers containing credentials
- Consider environment variable substitution for secrets

### TLS/SSL Validation

- HTTPS requests SHOULD validate server certificates
- Implementations SHOULD verify certificate chain
- Implementations SHOULD check certificate expiration
- Implementations MAY allow custom CA certificates
- Invalid certificates SHOULD cause check failure

### Request Safety

- Implementations SHOULD limit request body size
- Implementations SHOULD limit response body size
- Implementations SHOULD handle malformed responses safely
- Implementations SHOULD sanitize URLs before execution

### Rate Limiting

- Frequent checks MAY trigger rate limiting
- Implementations SHOULD respect HTTP 429 (Too Many Requests)
- Implementations SHOULD provide configurable retry backoff

---

## Performance Considerations

### Response Time Thresholds

**Recommended thresholds** for `duration` assertions:

- **API endpoints**: < 500ms
- **Web pages**: < 1s
- **Complex queries**: < 5s
- **TTFB**: < 100ms (excellent), < 300ms (acceptable)

### Body Size Limits

- Implementations MAY limit response body size
- Typical limit: 10MB
- Consider memory usage for body assertions
- Use `HEAD` method for lightweight checks

### Connection Reuse

- Implementations MAY reuse connections for repeated checks
- Connection pooling can improve performance
- Consider DNS caching for frequent checks

---

## Implementation Notes

### Timing Measurements

**Total Response Time** = DNS + Connect + TLS + TTFB + Download

- **DNS Time**: Hostname resolution
- **Connect Time**: TCP connection establishment
- **TLS Time**: TLS handshake (HTTPS only, 0 for HTTP)
- **TTFB**: Time from request sent to first response byte
- **Download Time**: Time to receive full response body

### Header Matching

- Header names are case-insensitive per HTTP specification
- Header values are case-sensitive
- `contains` operator searches entire header value
- Multiple headers with same name: implementation-defined behavior

### Body Encoding

- Response body decoded based on Content-Type charset
- Default: UTF-8
- Binary responses: implementation-defined handling
- Large responses: MAY be truncated (with warning)

---

## Related

- [Base Check Definition](check.md) - Common check structure
- [Common Types](common.md) - Shared types and operators
- [TlsCheck](tls.md) - TLS/SSL certificate validation
- [TcpCheck](tcp.md) - TCP connection testing

---

## Changelog

### v1 (Current)
- Initial stable release
- Six assertion types: statusCode, duration, ttfb, size, body, header
- StrictTime for duration and ttfb assertions (unit suffix required)
- Support for GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- Custom headers support
- Multi-location execution
- TTFB (Time to First Byte) assertion for server performance monitoring
