# testdata/

Sample payment messages and test data for parser validation and translation testing.

## Purpose

This directory contains realistic (but fictional) sample messages in both SWIFT MT and ISO 20022 MX formats. These test messages are used to:

- Validate parser implementations
- Test message translation (MT ↔ MX)
- Demonstrate message format features
- Provide examples for developers

## Directory Structure

```
testdata/
├── mt/                      # SWIFT MT test messages
│   ├── mt103/              # Customer credit transfers
│   ├── mt202/              # Financial institution transfers
│   ├── mt940/              # Customer statements
│   └── mt942/              # Interim transaction reports
├── mx/                      # ISO 20022 XML test messages
│   ├── pacs.008/           # Customer credit transfers
│   ├── pacs.009/           # FI credit transfers
│   ├── camt.052/           # Interim account reports
│   └── camt.053/           # Customer statements
└── translation_pairs/       # Matched MT/MX pairs for round-trip testing
    ├── mt103_pacs008/
    ├── mt202_pacs009/
    ├── mt940_camt053/
    └── mt942_camt052/
```

## File Formats

### MT Test Messages (.mt)

SWIFT MT messages use the `.mt` extension and follow the 5-block structure:

```
{1:F01BANKBICAXXX0000000000}{2:I103BANKBICAXXXXN}{4:
:20:REFERENCE123
:32A:260210EUR1000,00
:50K:/DE89370400440532013000
HANS MUELLER
:59:/GB29NWBK60161331926819
JOHN SMITH
-}
```

- Use CRLF (`\r\n`) line endings within block 4
- Block delimiters: `{` and `}`
- Field tags: `:NN[a]:` format

### MX Test Messages (.xml)

ISO 20022 messages use the `.xml` extension with proper namespaces:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pacs.008.001.10">
  <FIToFICstmrCdtTrf>
    ...
  </FIToFICstmrCdtTrf>
</Document>
```

### Test Metadata (.meta.json)

Every test message has a companion `.meta.json` file describing:

```json
{
  "test_id": "MT103_MINIMAL",
  "description": "Minimal valid MT103 with only mandatory fields",
  "message_type": "MT103",
  "scenario": "minimal_valid",
  "expected_validation": "pass",
  "validation_rules": [],
  "tags": ["minimal", "valid", "mandatory-only"]
}
```

## Test Categories

### Valid Messages
- **minimal_valid**: Only mandatory fields populated
- **full_valid**: All optional fields populated
- **scenario-specific**: Real-world scenarios (SEPA, cross-border, etc.)

### Invalid Messages
- **invalid_missing_mandatory**: Missing required fields
- **invalid_bad_format**: Malformed field values (bad BICs, IBANs, etc.)
- **invalid_business_rule**: Violates business validation rules

## Data Guidelines

All test data MUST be:

- **Realistic but fictional**: Use plausible names, amounts, and references
- **Valid format**: BICs from real banks, IBANs with correct check digits
- **Never real**: No actual customer data or live transaction references
- **Diverse**: Cover multiple countries, currencies, and scenarios

### Example Realistic Data

**BICs**: DEUTDEFF, BNPAFRPP, CHASUS33, BOFAUS3N, COBADEFF  
**IBANs**: DE89370400440532013000, GB29NWBK60161331926819  
**Names**: Hans Mueller, John Smith, ACME Corporation  
**Amounts**: 1000.00, 25000.50, 999.99  
**References**: REF20260210001, TXN-2026-001  

## Translation Pairs

The `translation_pairs/` directory contains matched MT and MX messages representing the same payment. Each pair includes:

- `source.mt` — Original MT message
- `expected.xml` — Expected MX translation
- `source.xml` — Original MX message
- `expected.mt` — Expected MT translation
- `pair.meta.json` — Metadata documenting field mappings and data loss

These pairs are the gold standard for testing translation engine correctness.

## Usage

```bash
# Validate an MT message structure
cat testdata/mt/mt103/minimal_valid.mt

# Validate an MX message against schema
xmllint --schema schemas/iso20022/pacs/pacs.008.001.10.xsd \
  testdata/mx/pacs.008/minimal_valid.xml

# Test translation
paymsg translate testdata/mt/mt103/sepa_credit.mt --to pacs.008 \
  --compare testdata/translation_pairs/mt103_pacs008/pair1/expected.xml
```

## Contributing Test Data

When adding new test messages:

1. Create both the message file (`.mt` or `.xml`) and `.meta.json`
2. Ensure all BICs, IBANs, and other identifiers are valid format
3. Use fictional but realistic names and amounts
4. Document the test scenario in the metadata
5. For translation pairs, ensure semantic equivalence between MT and MX versions
