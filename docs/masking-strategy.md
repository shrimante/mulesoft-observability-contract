# Masking Strategy

Data security cannot be left to individual developers building hundreds of HTTP integrations. The Observability Contract mandates a centralized masking architecture to protect PII, PHI, and credentials.

## 1. Zero-Trust Keys
The `masking-rules.dwl` engine maintains a universal dictionary of keys that are **always redacted**, regardless of the payload's location or depth.

```json
"sensitiveKeys": [
    "password", "secret", "token", "access_token", "authorization",
    "apikey", "apisecret", "email", "phone", "ssn", "cvv", "cardnumber"
]
```

## 2. Modes of Operation

### SUMMARY Mode (Default for INFO)
Emits `payloadSummary`. It computes the structural footprint rather than serializing data.
*   **Safety Level**: Absolute. No strings, numbers, or objects are logged.
*   **Result**: 
    ```json
    "payloadSummary": {
      "type": "Array",
      "recordCount": 215,
      "sampleSize": 8
    }
    ```

### REDACTED_DETAIL Mode (Default for DEBUG)
Recursively searches every node. If a key matches the `sensitiveKeys` dictionary, the value is overwritten with `*** REDACTED ***`.
*   **Array Truncation Guard**: Massive arrays crashing memory during serialization is a common MuleSoft operational issue. If an array exceeds `maxArraySize` (default: 5), it is aggressively sliced:
    ```json
    "__truncationWarning": "Array truncated at 5 items. Total items: 400"
    ```
*   **String Truncation Guard**: Base64 documents often pollute Splunk indices. Strings exceeding 500 characters are safely clipped: `"...[TRUNCATED]"`
