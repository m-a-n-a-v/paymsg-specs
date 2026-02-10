# rules/

Declarative business validation rules for payment messages.

## Purpose

This directory contains business validation rules that go beyond basic schema validation. These rules encode domain knowledge about payment message requirements, regulatory constraints, and cross-field consistency checks.

## Rule Files

- `pacs008_rules.json` — Business rules for pacs.008.001.10 (Customer Credit Transfer)
- `pacs009_rules.json` — Business rules for pacs.009.001.10 (FI Credit Transfer)
- `camt052_rules.json` — Business rules for camt.052.001.10 (Interim Account Report)
- `camt053_rules.json` — Business rules for camt.053.001.10 (Customer Statement)

## File Format

Each rule file contains an array of validation rules following this structure:

```json
{
  "id": "PACS008-AM01",
  "message_type": "pacs.008.001.10",
  "description": "Settlement amount must be positive",
  "severity": "error",
  "condition": "IntrBkSttlmAmt exists",
  "assertion": "IntrBkSttlmAmt > 0",
  "field_paths": ["CdtTrfTxInf/IntrBkSttlmAmt"],
  "suggestion": "Ensure the settlement amount is greater than zero"
}
```

### Rule Properties

- **id**: Unique rule identifier (format: `MSGTYPE-CATNN` where CAT is 2-letter category, NN is number)
- **message_type**: Which message type this rule applies to
- **description**: Human-readable description of what the rule checks
- **severity**: `error` (must pass), `warning` (should pass), or `info` (informational)
- **condition**: When this rule applies (expression syntax)
- **assertion**: What must be true (expression syntax)
- **field_paths**: XPath-like paths to the fields involved
- **suggestion**: Helpful message explaining how to fix violations

### Rule Categories

Common rule ID prefixes by category:

- **AM** — Amount validation (positivity, precision, limits)
- **DT** — Date/time validation (past/future, formats, consistency)
- **ID** — Identifier validation (BIC, IBAN, reference numbers)
- **PT** — Party validation (debtor/creditor completeness)
- **CR** — Cross-field consistency (currency matching, balance checks)
- **RG** — Regulatory requirements (EU reporting, thresholds)

### Severity Levels

- **error**: Message MUST NOT be processed if this rule fails
- **warning**: Message CAN be processed but may have issues
- **info**: Informational only, does not affect processing

## Expression Language

Rules use a simple expression language for conditions and assertions:

- Field references: `FieldName`, `Parent/Child`
- Operators: `=`, `!=`, `>`, `<`, `>=`, `<=`
- Logical: `AND`, `OR`, `NOT`
- Functions: `exists()`, `length()`, `matches()`, `in()`
- Examples:
  - `IntrBkSttlmAmt > 0`
  - `DbtrAcct/Id/IBAN exists AND matches(IBAN_PATTERN)`
  - `Ccy = IntrBkSttlmAmt/@Ccy`
  - `length(EndToEndId) <= 35`

## Usage

Validation engines should:

1. Load the appropriate rule file for the message type
2. Evaluate each rule's `condition` against the message
3. If condition is true, evaluate the `assertion`
4. If assertion fails, report a violation with the given `severity` and `suggestion`
5. Aggregate all violations and determine if the message is valid

## Examples

### Amount Rule
```json
{
  "id": "PACS008-AM01",
  "description": "Settlement amount must be positive",
  "assertion": "IntrBkSttlmAmt > 0"
}
```

### Cross-Field Rule
```json
{
  "id": "PACS008-CR02",
  "description": "Instructed amount currency must match settlement amount currency",
  "assertion": "InstdAmt/@Ccy = IntrBkSttlmAmt/@Ccy"
}
```

### Conditional Rule
```json
{
  "id": "PACS008-RG01",
  "description": "EU payments require regulatory reporting",
  "condition": "DbtrAgt/FinInstnId/BIC[1:2] IN EU_COUNTRIES",
  "assertion": "RgltryRptg exists"
}
```

See `rules.schema.json` for the complete rule schema definition.
