#!/usr/bin/env bash

# validate.sh
# Quality validation script for paymsg-specs repository
# Checks all spec files for internal consistency and correctness
#
# Usage: bash validate.sh
# Exit code: 0 if all checks pass, non-zero otherwise

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Output functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if required tools are available
check_dependencies() {
    info "Checking dependencies..."

    if ! command -v jq &> /dev/null; then
        error "jq is not installed. Please install jq to run validation."
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        error "python3 is not installed. Please install Python 3 to run validation."
        exit 1
    fi

    success "All dependencies available (jq, python3)"
}

# Check 1: Validate all JSON files are valid JSON
check_json_validity() {
    info "Checking JSON validity for all .json files..."

    local invalid_files=()

    while IFS= read -r -d '' json_file; do
        if ! jq . "$json_file" > /dev/null 2>&1; then
            invalid_files+=("$json_file")
        fi
    done < <(find . -name "*.json" -type f -print0)

    if [ ${#invalid_files[@]} -eq 0 ]; then
        success "All JSON files are valid"
    else
        error "Invalid JSON files found:"
        for file in "${invalid_files[@]}"; do
            echo "  - $file"
        done
    fi
}

# Check 2: Validate JSON files against their schemas
check_json_schema_validation() {
    info "Checking JSON Schema validation..."

    local validation_errors=()

    # Create a Python script to validate JSON against schema
    python3 - <<'PYEOF'
import json
import sys
import os
from pathlib import Path

try:
    import jsonschema
    from jsonschema import validate, ValidationError
except ImportError:
    print("jsonschema module not available - skipping schema validation")
    print("To enable: pip3 install jsonschema")
    sys.exit(0)

def find_schema_for_file(json_file):
    """Find the corresponding schema file for a JSON file."""
    path = Path(json_file)

    # If the file itself is a schema, skip it
    if path.name.endswith('.schema.json'):
        return None

    # Look for a schema file with the same name
    schema_file = path.parent / f"{path.stem}.schema.json"
    if schema_file.exists():
        return str(schema_file)

    # Look for a schema file with a generic name in the same directory
    # For example, mt103.json should use mt103.schema.json (already checked above)

    return None

errors = []

# Find all JSON files that should be validated
for root, dirs, files in os.walk('.'):
    # Skip hidden directories
    dirs[:] = [d for d in dirs if not d.startswith('.')]

    for file in files:
        if not file.endswith('.json') or file.endswith('.schema.json'):
            continue

        json_path = os.path.join(root, file)
        schema_path = find_schema_for_file(json_path)

        if not schema_path:
            continue

        try:
            with open(json_path, 'r') as f:
                data = json.load(f)
            with open(schema_path, 'r') as f:
                schema = json.load(f)

            validate(instance=data, schema=schema)

        except ValidationError as e:
            errors.append(f"{json_path}: {str(e.message)}")
        except Exception as e:
            errors.append(f"{json_path}: Failed to validate - {str(e)}")

if errors:
    print("VALIDATION_ERRORS")
    for err in errors:
        print(err)
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
PYEOF

    local result=$?
    if [ $result -eq 0 ]; then
        success "All JSON files validate against their schemas"
    else
        error "JSON Schema validation errors found"
    fi
}

# Check 3: Verify all test data files have companion .meta.json files
check_meta_json_files() {
    info "Checking for companion .meta.json files..."

    local missing_meta=()

    # Check .mt files (excluding translation_pairs which use pair.meta.json)
    while IFS= read -r -d '' mt_file; do
        # Skip translation pairs - they use a single pair.meta.json
        if [[ "$mt_file" =~ translation_pairs ]]; then
            continue
        fi

        meta_file="${mt_file}.meta.json"
        if [ ! -f "$meta_file" ]; then
            missing_meta+=("$mt_file")
        fi
    done < <(find testdata -name "*.mt" -type f -print0)

    # Check .xml files (excluding translation_pairs which use pair.meta.json)
    while IFS= read -r -d '' xml_file; do
        # Skip translation pairs - they use a single pair.meta.json
        if [[ "$xml_file" =~ translation_pairs ]]; then
            continue
        fi

        meta_file="${xml_file}.meta.json"
        if [ ! -f "$meta_file" ]; then
            missing_meta+=("$xml_file")
        fi
    done < <(find testdata -name "*.xml" -type f -print0)

    # Check that each translation_pairs subdirectory has at least one pair.meta.json
    while IFS= read -r -d '' pair_dir; do
        if [ ! -f "$pair_dir"/*.pair.meta.json ] 2>/dev/null; then
            missing_meta+=("$pair_dir (missing *.pair.meta.json)")
        fi
    done < <(find testdata/translation_pairs -mindepth 1 -maxdepth 1 -type d -print0)

    if [ ${#missing_meta[@]} -eq 0 ]; then
        success "All test data files have companion .meta.json files"
    else
        error "Missing .meta.json files for:"
        for file in "${missing_meta[@]}"; do
            echo "  - $file"
        done
    fi
}

# Check 4: Validate IBAN check digits using Mod-97
check_iban_validation() {
    info "Checking IBAN Mod-97 check digit validation..."

    python3 - <<'PYEOF'
import json
import sys

def validate_iban_mod97(iban):
    """Validate IBAN using Mod-97 algorithm (ISO 7064)."""
    # Remove spaces and convert to uppercase
    iban = iban.replace(' ', '').upper()

    # Move first 4 characters to end
    rearranged = iban[4:] + iban[:4]

    # Replace letters with numbers (A=10, B=11, ..., Z=35)
    numeric = ''
    for char in rearranged:
        if char.isdigit():
            numeric += char
        else:
            numeric += str(ord(char) - ord('A') + 10)

    # Check if mod 97 equals 1
    return int(numeric) % 97 == 1

# Load IBAN formats file
try:
    with open('reference/iban_formats.json', 'r') as f:
        iban_data = json.load(f)
except FileNotFoundError:
    print("reference/iban_formats.json not found - skipping IBAN validation")
    sys.exit(0)

errors = []

for entry in iban_data:
    country_code = entry.get('country_code', 'UNKNOWN')
    example = entry.get('example', '')

    if not example:
        errors.append(f"{country_code}: No example IBAN provided")
        continue

    if not validate_iban_mod97(example):
        errors.append(f"{country_code}: Example IBAN '{example}' fails Mod-97 validation")

if errors:
    print("IBAN_ERRORS")
    for err in errors:
        print(err)
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
PYEOF

    local result=$?
    if [ $result -eq 0 ]; then
        success "All example IBANs pass Mod-97 check digit validation"
    else
        error "IBAN validation errors found"
    fi
}

# Check 5: Verify no duplicate rule IDs across all rule files
check_duplicate_rule_ids() {
    info "Checking for duplicate rule IDs..."

    python3 - <<'PYEOF'
import json
import sys
import os
from collections import defaultdict

rule_ids = defaultdict(list)

# Find all rule files
for root, dirs, files in os.walk('rules'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]

    for file in files:
        if file.endswith('_rules.json'):
            rule_file = os.path.join(root, file)

            try:
                with open(rule_file, 'r') as f:
                    data = json.load(f)

                rules = data.get('rules', [])
                for rule in rules:
                    rule_id = rule.get('id', '')
                    if rule_id:
                        rule_ids[rule_id].append(rule_file)
            except Exception as e:
                print(f"Error reading {rule_file}: {e}")

# Check for duplicates
duplicates = {rid: files for rid, files in rule_ids.items() if len(files) > 1}

if duplicates:
    print("DUPLICATE_RULE_IDS")
    for rule_id, files in duplicates.items():
        print(f"Rule ID '{rule_id}' found in:")
        for f in files:
            print(f"  - {f}")
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
PYEOF

    local result=$?
    if [ $result -eq 0 ]; then
        success "No duplicate rule IDs found"
    else
        error "Duplicate rule IDs found"
    fi
}

# Check 6: Verify mapping files reference valid MT tags
check_mapping_mt_tags() {
    info "Checking mapping files reference valid MT tags..."

    python3 - <<'PYEOF'
import json
import sys
import os
from collections import defaultdict

# Load all valid MT field tags from mt-specs
mt_specs = {}

for root, dirs, files in os.walk('mt-specs'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]

    for file in files:
        if file.startswith('mt') and file.endswith('.json') and not file.endswith('.schema.json'):
            mt_type = file.replace('.json', '').upper()
            spec_file = os.path.join(root, file)

            try:
                with open(spec_file, 'r') as f:
                    data = json.load(f)

                # Extract valid field tags (Block 4)
                tags = set()
                fields = data.get('fields', [])
                for field in fields:
                    tag = field.get('tag', '')
                    if tag:
                        tags.add(tag)

                mt_specs[mt_type] = tags
            except Exception as e:
                print(f"Error reading {spec_file}: {e}")

# Load valid Block 3 header tags from block_structure.json
block3_tags = set()
try:
    with open('mt-specs/block_structure.json', 'r') as f:
        block_data = json.load(f)
        blocks = block_data.get('blocks', [])
        for block in blocks:
            if block.get('block_id') == '3':
                common_tags = block.get('common_tags', [])
                for tag_info in common_tags:
                    tag = tag_info.get('tag', '')
                    if tag:
                        block3_tags.add(tag)
except Exception as e:
    print(f"Warning: Could not load Block 3 tags from block_structure.json: {e}")

# Check mapping files
errors = []

for root, dirs, files in os.walk('mappings'):
    dirs[:] = [d for d in dirs if not d.startswith('.')]

    for file in files:
        if file.endswith('.json') and not file.endswith('.schema.json'):
            mapping_file = os.path.join(root, file)

            try:
                with open(mapping_file, 'r') as f:
                    data = json.load(f)

                mt_type = data.get('mt_type', '').upper()
                if mt_type not in mt_specs:
                    # Can't validate if we don't have the spec
                    continue

                valid_field_tags = mt_specs[mt_type]
                mappings = data.get('mappings', [])

                for mapping in mappings:
                    mt_tag = mapping.get('mt_tag', '')
                    if not mt_tag:
                        continue

                    # Check if it's a valid field tag (Block 4) or header tag (Block 3)
                    if mt_tag not in valid_field_tags and mt_tag not in block3_tags:
                        errors.append(f"{mapping_file}: MT tag '{mt_tag}' not found in {mt_type} field specification or Block 3 header tags")

            except Exception as e:
                print(f"Error reading {mapping_file}: {e}")

if errors:
    print("MT_TAG_ERRORS")
    for err in errors:
        print(err)
    sys.exit(1)
else:
    print("OK")
    sys.exit(0)
PYEOF

    local result=$?
    if [ $result -eq 0 ]; then
        success "All mapping files reference valid MT tags"
    else
        error "Invalid MT tag references found in mapping files"
    fi
}

# Main validation flow
main() {
    echo ""
    echo "=========================================="
    echo "  paymsg-specs Validation Suite"
    echo "=========================================="
    echo ""

    check_dependencies
    echo ""

    check_json_validity
    check_json_schema_validation
    check_meta_json_files
    check_iban_validation
    check_duplicate_rule_ids
    check_mapping_mt_tags

    echo ""
    echo "=========================================="
    echo "  Validation Summary"
    echo "=========================================="
    echo "Total checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✓ All validation checks passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some validation checks failed.${NC}"
        exit 1
    fi
}

main "$@"
