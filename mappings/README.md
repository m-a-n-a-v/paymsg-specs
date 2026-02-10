# mappings/

Field mapping definitions between SWIFT MT and ISO 20022 MX message formats.

## Purpose

These files define how to translate payment messages between the legacy SWIFT MT format and the modern ISO 20022 XML format. Each mapping file provides bidirectional translation rules for a specific MT/MX message pair.

## Mapping Files

- `mt103_pacs008.json` — MT103 ↔ pacs.008.001.10
- `mt202_pacs009.json` — MT202 ↔ pacs.009.001.10
- `mt940_camt053.json` — MT940 ↔ camt.053.001.10
- `mt942_camt052.json` — MT942 ↔ camt.052.001.10

## File Format

Each mapping file contains an array of field mapping entries following this structure:

```json
{
  "mt_tag": "32A",
  "mt_field_name": "Value Date, Currency Code, Amount",
  "mt_option": null,
  "mx_path": "CdtTrfTxInf/IntrBkSttlmAmt + IntrBkSttlmDt",
  "transform_type": "split",
  "transform_details": "Date -> IntrBkSttlmDt, Currency+Amount -> IntrBkSttlmAmt",
  "direction": "both",
  "data_loss_risk": "none",
  "notes": "Single MT field splits into two MX elements"
}
```

### Transform Types

- **direct**: 1:1 field mapping with no transformation
- **split**: One MT field splits into multiple MX elements
- **merge**: Multiple MT fields combine into one MX element
- **lookup**: Value translation using a lookup table (e.g., charge codes)
- **derived**: MX field is computed/derived from MT fields
- **conditional**: Mapping depends on other field values

### Direction

- **mt_to_mx**: Mapping only applies when translating MT → MX
- **mx_to_mt**: Mapping only applies when translating MX → MT
- **both**: Bidirectional mapping

### Data Loss Risk

- **none**: No data loss in translation
- **possible**: Data may be lost depending on field length or precision
- **certain**: Data will definitely be lost (e.g., MT-only fields with no MX equivalent)

## Usage

Translation engines should use these mapping files to:

1. Identify corresponding fields between MT and MX formats
2. Apply appropriate transformations (split, merge, lookup)
3. Handle data loss scenarios (truncation warnings, default values)
4. Validate completeness of translated messages

## Important Notes

- **Truncation**: When translating MX → MT, some MX text fields may exceed MT field length limits and require truncation
- **Defaults**: Some MX-only mandatory fields have no MT equivalent and must be populated with sensible defaults
- **Character Sets**: SWIFT MT uses restricted character sets (X, Y, Z), while MX allows full UTF-8. Character conversion may be required.

See `mapping.schema.json` for the complete mapping file schema definition.
