# Ralph Agent Instructions

You are an autonomous coding agent building `paymsg-specs` — the shared reference data repository for an ISO 20022 payment message engine.

## Your Task

1. Read the PRD at `scripts/ralph/prd.json`
2. Read the progress log at `scripts/ralph/progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the **highest priority** user story where `passes: false`
5. Implement that single user story
6. Run quality checks: validate all JSON files with `jq`, run `bash validate.sh` if it exists
7. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
8. Update the PRD to set `passes: true` for the completed story
9. Append your progress to `scripts/ralph/progress.txt`

## Project Context

This repository contains **reference data only** — no application code. It provides:
- ISO 20022 XSD schema references
- SWIFT MT message format specifications (machine-readable JSON)
- Field mapping definitions between MT and MX formats
- Business validation rules (declarative JSON)
- Test data (sample MT and MX messages)
- Reference tables (currencies, countries, IBAN formats)

This data is consumed by two sibling projects:
- `paymsg` — Rust library and CLI tool
- `paymsg-playground` — Web-based message playground

## Domain Knowledge

### ISO 20022 Message Types We Support
- **pacs.008.001.10** — Customer Credit Transfer (maps to MT103)
- **pacs.009.001.10** — Financial Institution Credit Transfer (maps to MT202)
- **camt.052.001.10** — Bank-to-Customer Account Report / Interim (maps to MT942)
- **camt.053.001.10** — Bank-to-Customer Statement (maps to MT940)

### SWIFT MT Message Structure
MT messages have 5 blocks:
- Block 1: `{1:F01BANKBICAXXX0000000000}` — Basic Header
- Block 2: `{2:I103BANKBICAXXXXN}` — Application Header
- Block 3: `{3:{108:MUR}{121:UUID}}` — User Header (optional)
- Block 4: `{4:\r\n:20:REF\r\n:32A:...\r\n-}` — Text Block (the actual content)
- Block 5: `{5:{CHK:...}}` — Trailer (optional)

### MT Field Format
Fields use tag notation: `:20:value`, `:32A:value`
- Tags are 2 digits optionally followed by a letter: `:20:`, `:32A:`, `:50K:`
- Multi-line values continue on the next line without a tag prefix
- Fields with options (A/B/D/F/K) have different subfield structures

### Key BIC Facts
- 8 or 11 characters: AAAA BB CC [DDD]
- Institution(4) + Country(2) + Location(2) + Branch(3, optional)
- Example: DEUTDEFF = Deutsche Bank, Germany, Frankfurt

### Key IBAN Facts
- Country(2) + Check(2) + BBAN(variable)
- Check digits use Mod-97 (ISO 7064)
- Length varies by country (DE=22, GB=22, FR=27, etc.)

### Key Currency Facts (ISO 4217)
- Most currencies: 2 decimal places (USD, EUR, GBP)
- Zero decimals: JPY, KRW, VND, etc.
- Three decimals: BHD, KWD, OMR, JOD, etc.

## File Format Conventions

### JSON files
- All data files use `.json` extension
- Pretty-printed with 2-space indentation
- All JSON files must be valid (parseable by `jq`)
- Schema files use `.schema.json` extension and follow JSON Schema draft-07

### Test data files
- MT messages use `.mt` extension
- MX/ISO 20022 messages use `.xml` extension
- Every test file has a companion `.meta.json` describing the test case

### MT message test files
- Use `\r\n` (CRLF) line endings within the message content
- Block delimiters use `{` and `}` with no spaces
- Field 4 uses `:NN[a]:` tag format

### Mapping files
- Use transform_type values: `direct`, `split`, `merge`, `lookup`, `derived`, `conditional`
- direction values: `mt_to_mx`, `mx_to_mt`, `both`
- data_loss_risk values: `none`, `possible`, `certain`

### Rule files
- severity values: `error`, `warning`, `info`
- Rules use a simple expression language for conditions/assertions
- Each rule has a unique ID

## Quality Requirements

- ALL JSON files must be valid (test with `jq . file.json > /dev/null`)
- JSON Schema files must be valid JSON Schema
- No duplicate IDs in rule files
- All example data must be realistic but fictional (no real customer data)
- Test messages must be syntactically correct for their format
- Mapping files must reference valid MT tags that exist in the mt-specs
- Use realistic BICs from major banks (DEUTDEFF, BNPAFRPP, CHASUS33, etc.)
- Use valid IBAN examples that pass Mod-97 validation

## Progress Report Format

APPEND to scripts/ralph/progress.txt (never replace, always append):
```
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---
```

## Consolidate Patterns

If you discover a **reusable pattern** that future iterations should know, add it to the `## Codebase Patterns` section at the TOP of progress.txt (create it if it doesn't exist).

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete and passing, reply with:
<promise>COMPLETE</promise>

If there are still stories with `passes: false`, end your response normally.

## Important

- Work on ONE story per iteration
- Commit frequently
- Keep all JSON valid
- Read the Codebase Patterns section in progress.txt before starting
- When creating test MT messages, ensure block structure is correct
- When creating XML test messages, use proper ISO 20022 namespaces
- For IBAN examples, compute valid check digits (Mod-97)
- Reference real bank BICs for realism (DEUTDEFF, BNPAFRPP, CHASUS33, BOFAUS3N, COBADEFF, etc.)
