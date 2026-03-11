# Observability JSON Schema

The output of the Centralized Logger will always conform to the following schema structure. Extraneous keys injected by developers to `currentPayload` will be organized under the `payloadSummary` or `diagnostics` blocks, never polluting the root object.

## Example INFO Output
```json
{
  "timestamp": "2026-03-12T10:15:30.123Z",
  "level": "INFO",
  "eventCode": "OBS-1002",
  "eventType": "FLOW_END",
  "message": "Flow Execution Completed",
  "description": "",
  "application": {
    "applicationName": "customer-sync-sys-api",
    "apiName": "System API",
    "apiLayer": "System",
    "environment": "dev",
    "version": "v1"
  },
  "trace": {
    "correlationId": "8b9cad0e-1f20-4a81-ac16-abcd12345",
    "spanId": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
  },
  "businessContext": {
    "businessId": "CUST-88910"
  },
  "executionContext": {
    "flowName": "sample-app-flow",
    "elapsedMs": 412
  },
  "payloadSummary": {
    "type": "Object",
    "attributeCount": 3,
    "topLevelKeys": ["sapId", "status", "sensitiveToken"]
  }
}
```

## Example DEBUG Output (Dense Diagnostics)
If `obs.debug.enabled=true` and the event is an HTTP outbound call:
```json
{
  ...
  "level": "DEBUG",
  "targetMetadata": {
    "targetSystem": "SAP ERP",
    "targetOperation": "POST_CUSTOMER",
    "httpStatus": 201
  },
  "diagnostics": {
    "before": {
      "payload": {
         "customerId": "CUST-88910",
         "name": "Jane Doe",
         "email": "*** REDACTED ***"
      }
    },
    "after": {
      "payload": {
         "sapId": "SAP-00123",
         "status": "CREATED",
         "sensitiveToken": "*** REDACTED ***"
      }
    }
  }
}
```
