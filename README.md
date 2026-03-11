## 1. The Observability Problem
Integrations are the nervous system of an enterprise. But when logs are noisy, unstructured, unstructured, or missing critical correlation, support teams spend expensive hours "grep-ing" through disparate systems to find the root cause of an outage.

Standard `logger` components allow developers to log *anything*, which results in chaos.

## 2. Our Solution: A Strict Observability Contract
`mulesoft-observability-contract` is a fundamental release engineering asset. It replaces the default Mule `<logger>` with a set of standardized, highly opinionated observability subflows. 

**This is a contract, not a utility.** It forces all APIs in the enterprise to speak the exact same structured JSON dialect. 

### Why a Shared Component?
By abstracting logging logic into this reusable Maven dependency, we achieve:
1. **Zero Configuration Drift**: A change to the logging schema here instantly benefits all 100+ integrations on the next build.
2. **Simplified Business Logic**: Developers no longer write complex DataWeave to construct log payloads.
3. **Advanced Masking**: Sensitive PCI/PII data is redacted centrally before ever hitting the log aggregator.

## 3. The INFO vs DEBUG Philosophy
This framework optimizes for **"faster diagnosis with fewer logs."**

*   **INFO Mode (Lean & Fast):** Used for >99% of production volume. It logs only major milestones (Flow Start, Downstream Call, Flow End, Error). Payloads are **summarized** (size, array length, key names), never serialized fully. Footprint is near zero.
*   **DEBUG Mode (Dense & Diagnostic):** Safe, explicitly gated diagnostics. When enabled via property flags (e.g., `obs.debug.enabled=true`), the framework captures dense `diagnostics.before` and `diagnostics.after` snapshots of payloads, headers, and variables. 

## 4. How to Adopt
Add this repository exclusively as a `mule-plugin` classifier to your Mule API's `pom.xml`.

```xml
<dependency>
    <groupId>com.enterprise.architecture</groupId>
    <artifactId>mulesoft-observability-contract</artifactId>
    <version>1.0.0</version>
    <classifier>mule-plugin</classifier>
</dependency>
```

In your Mule flows, simply `import` the `observability-contract.xml` and invoke the semantic subflows:
```xml
<flow-ref doc:name="Log Flow Start" name="obs-log-flow-start"/>
<flow-ref doc:name="Log Step Start" name="obs-log-step-start"/>
<flow-ref doc:name="Log Outbound Request" name="obs-log-outbound-request"/>
```
