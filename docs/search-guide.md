# Search & Troubleshooting Guide

Because every Mule API adheres strictly to the `mulesoft-observability-contract` JSON schema, support engineers and architects can rely on universal Splunk/ELK queries across the entire enterprise.

## Foundational Splunk Queries

### 1. Tracing a Single Transaction
Finding all logs belonging to a specific request journey (even if it spans from the Experience API to Process API to System API):
```spl
index="mulesoft-prod" trace.correlationId="d4e1b8a..."
| sort _time
| table _time, application.apiLayer, application.apiName, eventType, message
```

### 2. Identifying Failing Downstream Systems
Finding which target platforms are currently rejecting our API calls:
```spl
index="mulesoft-prod" eventType="OUTBOUND_RESPONSE"
| search targetMetadata.httpStatus>=400
| stats count by targetMetadata.targetSystem, targetMetadata.httpStatus
```

### 3. Measuring API Performance
Calculating the average elapsed milliseconds of all successfully processed API requests, grouped by the API Name:
```spl
index="mulesoft-prod" eventType="FLOW_END"
| stats avg(executionContext.elapsedMs) as avgDuration p90(executionContext.elapsedMs) as p90Duration by application.apiName
| sort - p90Duration
```

### 4. Grouping by Business Identifier
Extracting logs matching a specific Customer Order, regardless of the API processing it:
```spl
index="mulesoft-prod" businessContext.businessId="ORD-29910"
| sort _time
```

## How to Handle an active Incident
1. **Find the Error**: Search for `level="ERROR"` or `eventType="UNEXPECTED_ERROR"` in the timeframe.
2. **Grab the Correlation ID**: Copy `trace.correlationId`.
3. **Follow the Breadcrumbs**: Search for the Correlation ID. You will see the exact `STEP_START` and `OUTBOUND_REQUEST` events leading up to the crash.
4. **Enable Deep Diagnostics (If needed)**: If the summary payloads aren't enough to discern root cause, flip the `obs.debug.enabled=true` property in the Control Plane / Runtime Manager for that specific API. The framework will immediately begin dumping dense `diagnostics.before` payloads to help you see exactly what attributes triggered the fault.
