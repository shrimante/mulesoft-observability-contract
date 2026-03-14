%dw 2.0
/**
 * Observability Contract: Canonical Log Formatter
 * This script forces every Mule logger event into the strict enterprise JSON schema.
 */
import dwl::maskingRules

// Input parameters populated by the Observability subflows
var logParams = payload default {}

// Execution Context
var flowName = logParams.flowName default flow.name
var correlationId = correlationId default uuid()
var elapsedMs = logParams.elapsedMs default 0

// Verbosity & Mode Strategy
// Defaults to SUMMARY to protect memory footprint
var loggingMode = p('obs.logging.mode') default "SUMMARY"
var isDebugEnabled = (p('obs.debug.enabled') default "false") == "true"

// -------------------------------------------------------------
// The Strict Enterprise Schema
// -------------------------------------------------------------
output application/json
---
{
    // 1. Core Metadata
    "timestamp": now() as String {format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"},
    "level": logParams.level default "INFO",
    "eventCode": logParams.eventCode default "OBS-1001",
    "eventType": logParams.eventType default "FLOW_START",
    "message": logParams.message default "Executing flow",
    "description": logParams.description default "",

    // 2. Application Identity
    "application": {
        "applicationName": app.name,
        "apiName": p('api.name') default "Unknown API",
        "apiLayer": p('api.layer') default "Unknown",
        "environment": p('mule.env') default "local",
        "version": p('api.version') default "v1"
    },

    // 3. Traceability
    "trace": {
        "correlationId": correlationId,
        "spanId": logParams.spanId default uuid(),
        "transactionId": vars.transactionId,
        "messageId": attributes.headers.'message-id' default null
    },

    // 4. Business Context (Extracted from vars if populated)
    "businessContext": {
        "businessObject": vars.businessObject default null,
        "businessId": vars.businessId default null,
        "customerId": vars.customerId default null
    } filterObject ((value) -> value != null),

    // 5. Execution Coordinates
    "executionContext": {
        "flowName": flowName,
        "stepName": logParams.stepName,
        "elapsedMs": elapsedMs
    } filterObject ((value) -> value != null),

    // 6. External Call Metadata (Only populates on OUTBOUND events)
    ("targetMetadata": {
        "targetSystem": logParams.targetSystem,
        "targetOperation": logParams.targetOperation,
        "endpoint": logParams.endpoint,
        "method": logParams.method,
        "httpStatus": logParams.httpStatus
    }) if (logParams.targetSystem != null),

    // 7. Error Metadata (Only populates on ERROR events)
    ("error": {
        "errorCategory": logParams.errorCategory default "UNKNOWN",
        "errorCode": logParams.errorCode,
        "errorType": error.errorType.identifier default "APP:UNKNOWN",
        "muleErrorType": error.errorType.namespace default "MULE",
        "rootCauseMessage": error.detailedDescription default error.description
    }) if (logParams.level == "ERROR" or logParams.level == "WARN"),

    // 8. Payload State (INFO Mode gets SUMMARY, DEBUG gets REDACTED_DETAIL)
    ("payloadSummary": maskingRules::evaluatePayload(logParams.currentPayload, "SUMMARY")) 
        if (!isDebugEnabled and logParams.currentPayload != null),

    // 9. Deep Diagnostics (EXCLUSIVE TO DEBUG MODE)
    ("diagnostics": {
        ("before": {
            "payload": maskingRules::evaluatePayload(logParams.beforePayload, loggingMode)
        }) if (logParams.beforePayload != null),
        
        ("after": {
            "payload": maskingRules::evaluatePayload(logParams.afterPayload, loggingMode)
        }) if (logParams.afterPayload != null),

        ("query": {
            "statement": logParams.queryStatement,
            "parameters": maskingRules::evaluatePayload(logParams.queryParameters, loggingMode)
        }) if (logParams.queryStatement != null),

        ("request": {
            "headers": maskingRules::evaluatePayload(logParams.requestHeaders, "SUMMARY")
        }) if (logParams.requestHeaders != null)

    }) if (isDebugEnabled)
}
