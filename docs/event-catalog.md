# Event Catalog

To ensure high traceability, the Observability Contract relies on semantic event codes rather than arbitrary strings.

## Standard Events

| Event Code | Event Type | Description | Verbosity |
| :--- | :--- | :--- | :--- |
| `OBS-1001` | `FLOW_START` | Initial ingress of the API framework. Generates correlation ID. | INFO |
| `OBS-1002` | `FLOW_END` | Successful egress of the API. Calculates `elapsedMs`. | INFO |
| `OBS-2001` | `STEP_START` | Milestone marker for a major internal processing phase. | INFO |
| `OBS-3001` | `OUTBOUND_REQUEST` | The integration is reaching out to a downstream Target System. | INFO |
| `OBS-3002` | `OUTBOUND_RESPONSE` | The integration received a payload or timeout from the Target System. | INFO |
| `OBS-5001` | `ERROR_HANDLED` | An exception was securely recovered by the Error Framework. | ERROR |
| `OBS-9001` | `UNEXPECTED_ERROR` | An unhandled exception crashed the executing thread. | FATAL |

### Why semantic codes?
Searching Splunk for `eventCode="OBS-3001" AND targetSystem="SAP ERP" ` is magnitudes faster and more reliable than searching for `message="Calling SAP..."` because the message string is prone to change, while the cataloged Contract code is strictly immutable.
