# Observability Contract Architecture

## High-Level Design
The Observability Contract replaces disparate `<logger>` components scattered throughout an integration with a unified, centrally managed Mule sub-flow suite.

### Core Principles
1. **Never Log the Literal Message**: Our generic subflows do not map `<logger message="Some string">`. Instead, they pass contextual variables into a master DataWeave lookup function.
2. **Centralized Normalization**: A single DataWeave script (`canonical-log-formatter.dwl`) constructs the JSON payload. If the organization decides to rename `correlationId` to `traceId`, it happens in exactly one place.
3. **The Gated Two-Mode File Size Model**:
   - **INFO mode**: Emits strict routing metrics. Payloads are stripped of content and replaced with `payloadSummary` (byte size, array counts).
   - **DEBUG mode**: Safely renders dense diagnostic trees conditionally based on the `obs.debug.enabled` property.

## Sequence of Execution
When a developer calls `<flow-ref name="obs-log-outbound-request"/>`:
1. The subflow captures the active Mule Payload.
2. The subflow constructs an internal `logParams` map (setting `eventType: OUTBOUND_REQUEST`).
3. The subflow invokes the `canonical-log-formatter.dwl` passing the map.
4. The formatter invokes `masking-rules.dwl` to conditionally summarize or redact the payload.
5. The formatter returns a finalized JSON String to the generic async Mule logger.

## Performance Impact Minimization
The `log4j2.xml` uses asynchronous loggers. This means the DataWeave evaluation happens, the string is generated, and the log is handed to a background RingBuffer thread, instantly freeing the Mule Event worker to continue the integration flow.
