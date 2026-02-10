# reference/

Reference tables and lookup data for payment message validation.

## Purpose

This directory contains authoritative reference data used throughout the payment message processing pipeline for validation, formatting, and enrichment.

## Reference Data Files

- **currencies.json** — ISO 4217 currency codes with decimal precision
- **countries.json** — ISO 3166-1 country codes with EU membership flags
- **iban_formats.json** — Per-country IBAN structure definitions
- **bic_spec.json** — BIC/SWIFT code format specification
- **swift_charsets.json** — SWIFT character set definitions (X, Y, Z)

## File Formats

All reference files are JSON with accompanying JSON Schema files (`.schema.json`) for validation.

### currencies.json

```json
{
  "currencies": [
    {
      "code": "USD",
      "name": "US Dollar",
      "numeric_code": "840",
      "decimal_places": 2,
      "is_active": true
    },
    {
      "code": "JPY",
      "name": "Japanese Yen",
      "numeric_code": "392",
      "decimal_places": 0,
      "is_active": true
    }
  ]
}
```

**Key Points**:
- Most currencies use 2 decimal places (USD, EUR, GBP)
- Zero-decimal currencies: JPY, KRW, VND, etc.
- Three-decimal currencies: BHD, KWD, OMR, JOD

### countries.json

```json
{
  "countries": [
    {
      "alpha2": "DE",
      "alpha3": "DEU",
      "numeric": "276",
      "name": "Germany",
      "is_eu_member": true
    }
  ]
}
```

**Key Points**:
- 249 officially assigned ISO 3166-1 alpha-2 codes
- EU membership flags used for regulatory validation rules
- 27 EU members as of 2025

### iban_formats.json

```json
{
  "formats": [
    {
      "country_code": "DE",
      "length": 22,
      "bban_format": "^[0-9]{18}$",
      "example": "DE89370400440532013000",
      "bank_id_position": {
        "start": 0,
        "end": 8
      }
    }
  ]
}
```

**Key Points**:
- All example IBANs have valid Mod-97 check digits
- BBAN format varies significantly by country
- Bank identifier position needed for routing

### bic_spec.json

```json
{
  "structure": {
    "institution_code": {
      "position": "1-4",
      "length": 4,
      "charset": "A-Z",
      "description": "Bank or institution code"
    },
    ...
  },
  "examples_valid": [
    {
      "bic": "DEUTDEFF",
      "description": "Deutsche Bank, Germany, Frankfurt"
    }
  ],
  "examples_invalid": [
    {
      "bic": "DEUT",
      "reason": "Too short (minimum 8 characters)"
    }
  ]
}
```

**Key Points**:
- 8 or 11 characters: AAAA BB CC [DDD]
- Institution(4) + Country(2) + Location(2) + Branch(3, optional)
- 'XXX' branch code indicates head office

### swift_charsets.json

```json
{
  "charsets": {
    "X": {
      "name": "SWIFT X - Alphanumeric",
      "description": "Uppercase letters, digits, and space",
      "characters": "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
    },
    ...
  },
  "conversion_table": [
    {
      "utf8": "é",
      "swift": "e",
      "description": "Accented e becomes plain e"
    }
  ]
}
```

**Key Points**:
- SWIFT X: uppercase alphanumeric + space
- SWIFT Y: extended with some punctuation
- SWIFT Z: includes CRLF and special control characters
- UTF-8 → SWIFT conversion needed for MT messages

## Usage

Applications should load these reference files to:

1. Validate currency codes and determine decimal precision for amounts
2. Validate country codes in BICs, IBANs, and addresses
3. Validate IBAN structure beyond basic check digit validation
4. Validate BIC/SWIFT code format
5. Convert between UTF-8 and SWIFT character sets for MT messages

## Data Sources

- **ISO 4217**: International Organization for Standardization (currency codes)
- **ISO 3166-1**: International Organization for Standardization (country codes)
- **SWIFT IBAN Registry**: Official IBAN structure specifications per country
- **SWIFT Standards**: BIC structure and character set definitions

## Maintenance

These reference files should be updated when:

- New currencies are introduced or deprecated (check ISO 4217 amendments)
- Countries join or leave the EU (update `is_eu_member` flags)
- IBAN formats change for specific countries (check SWIFT IBAN Registry)
- SWIFT updates character set or BIC specifications
