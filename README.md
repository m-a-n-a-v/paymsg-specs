# paymsg-specs

Shared reference data repository for the **paymsg** ISO 20022 payment message engine.

## Purpose

This repository contains reference data only — no application code. It provides canonical specifications, mapping definitions, validation rules, and test data used by:

- **paymsg** — Rust library and CLI tool for parsing, validating, and translating payment messages
- **paymsg-playground** — Web-based message playground for testing and exploration

## Directory Layout

```
paymsg-specs/
├── schemas/              # ISO 20022 XSD schema files
│   └── iso20022/
│       ├── pacs/        # Payment clearing and settlement (pacs.008, pacs.009)
│       └── camt/        # Cash management (camt.052, camt.053)
├── mt-specs/            # SWIFT MT message format specifications (machine-readable JSON)
├── mappings/            # Field mapping definitions between MT and MX formats
├── rules/               # Business validation rules (declarative JSON)
├── testdata/            # Sample messages and test data
│   ├── mt/             # SWIFT MT test messages (.mt files)
│   └── mx/             # ISO 20022 XML test messages (.xml files)
└── reference/           # Reference tables (currencies, countries, IBAN formats, BIC structure)
```

## Message Types Supported

### ISO 20022 (MX)
- **pacs.008.001.10** — Customer Credit Transfer
- **pacs.009.001.10** — Financial Institution Credit Transfer
- **camt.052.001.10** — Bank-to-Customer Account Report (Interim)
- **camt.053.001.10** — Bank-to-Customer Statement

### SWIFT MT
- **MT103** — Single Customer Credit Transfer
- **MT202** — General Financial Institution Transfer
- **MT940** — Customer Statement
- **MT942** — Interim Transaction Report

## How to Use This Repository

### For Application Developers

This repository is intended to be consumed as a git submodule or by copying specific data files into your project:

```bash
# As a submodule
git submodule add https://github.com/yourorg/paymsg-specs.git

# Or copy specific files
cp paymsg-specs/reference/currencies.json ./data/
cp paymsg-specs/mt-specs/mt103.json ./specs/
```

### File Format Conventions

- **JSON files**: All data files use `.json` extension, pretty-printed with 2-space indentation
- **Schema files**: Use `.schema.json` extension, follow JSON Schema draft-07
- **MT test messages**: Use `.mt` extension with CRLF line endings
- **MX test messages**: Use `.xml` extension with proper ISO 20022 namespaces
- **Test metadata**: Every test file has a companion `.meta.json` describing the test case

### Validation

Before using data from this repository, validate it using the comprehensive validation script:

```bash
# Run all validation checks
bash validate.sh
```

The validation script performs the following checks:

1. **JSON Validity** — Verifies all `.json` files are valid JSON (using `jq`)
2. **JSON Schema Validation** — Validates JSON files against their companion `.schema.json` files
3. **Test Metadata** — Ensures all test data files (`.mt`, `.xml`) have companion `.meta.json` files
4. **IBAN Check Digits** — Validates all example IBANs in `reference/iban_formats.json` using Mod-97 algorithm
5. **Unique Rule IDs** — Checks for duplicate rule IDs across all rule files
6. **MT Tag References** — Verifies mapping files only reference valid MT tags defined in `mt-specs/`

#### Requirements

- `jq` — JSON processor ([installation guide](https://stedolan.github.io/jq/download/))
- `python3` — For advanced validation logic (IBAN Mod-97, cross-file checks)
- Optional: `pip3 install jsonschema` — For JSON Schema validation (will skip if not available)

#### CI/CD Integration

Add validation to your CI pipeline:

```yaml
# Example GitHub Actions workflow
- name: Validate paymsg-specs
  run: |
    cd paymsg-specs
    bash validate.sh
```

The script exits with code 0 if all checks pass, non-zero if any check fails.

See each directory's README for detailed format specifications and usage examples.

## Contributing

Contributions are welcome! When adding or modifying reference data:

1. Ensure all JSON files are valid (test with `jq`)
2. Validate against schemas where applicable
3. Include test cases for new message formats or mappings
4. Run `./validate.sh` before committing
5. Use realistic but fictional data (no real customer information)

## License

MIT License - see LICENSE file for details.
