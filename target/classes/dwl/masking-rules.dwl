%dw 2.0
/**
 * Observability Contract: Masking and Summarization Engine
 * This script ensures sensitive fields are never logged, while conditionally 
 * generating metadata or redacted payloads based on the verbosity mode.
 */

var sensitiveKeys = [
    "password", "secret", "token", "access_token", "authorization",
    "apikey", "apisecret", "email", "phone", "ssn", "cvv", "cardnumber"
]

// -------------------------------------------------------------
// Core Masker (Recursive Redaction)
// -------------------------------------------------------------
fun maskData(data: Any): Any =
    data match {
        // Obfuscate sensitive strings entirely
        case obj is Object -> 
            obj mapObject ((value, key, index) -> 
                (key): if (sensitiveKeys contains lower(key as String)) 
                           "*** REDACTED ***" 
                       else maskData(value)
            )
        // Iterate through arrays
        case arr is Array -> arr map maskData($)
        // Pass through non-sensitive primitives
        else -> data
    }

// -------------------------------------------------------------
// Mode 1: Summary (INFO Mode Default)
// Returns footprint, keys, but ZERO content.
// -------------------------------------------------------------
fun summarizePayload(payload: Any): Object =
    if (payload == null) { status: "empty" }
    else payload match {
        case obj is Object -> {
            type: "Object",
            attributeCount: sizeOf(obj),
            topLevelKeys: namesOf(obj)
        }
        case arr is Array -> {
            type: "Array",
            recordCount: sizeOf(arr),
            sampleSize: if (sizeOf(arr) > 0) sizeOf(arr[0] pluck $$) else 0
        }
        case str is String -> {
            type: "String",
            lengthBytes: sizeOf(str)
        }
        case bin is Binary -> {
            type: "Binary",
            sizeBytes: sizeOf(bin)
        }
        else -> { type: typeOf(payload) }
    }

// -------------------------------------------------------------
// Mode 2: Redacted Detail (DEBUG Mode Default)
// Truncates massively large collections, masks secrets.
// -------------------------------------------------------------
fun extractRedactedDetail(payload: Any, maxArraySize: Number = 5): Any =
    if (payload == null) null
    else payload match {
        case arr is Array -> 
            if (sizeOf(arr) > maxArraySize) 
                maskData(arr[0 to (maxArraySize - 1)]) << { "__truncationWarning": "Array truncated at $(maxArraySize) items. Total items: $(sizeOf(arr))" }
            else maskData(arr)
        case str is String ->
             if(sizeOf(str) > 500) (str[0 to 500] ++ "...[TRUNCATED]") else str
        else -> maskData(payload)
    }

// -------------------------------------------------------------
// Master Evaluation function called by Logger
// -------------------------------------------------------------
fun evaluatePayload(payload: Any, mode: String = "SUMMARY") =
    if (mode == "NONE" or payload == null) null
    else if (mode == "REDACTED_DETAIL") extractRedactedDetail(payload)
    else summarizePayload(payload)
