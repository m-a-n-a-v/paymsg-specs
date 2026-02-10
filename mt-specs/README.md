# mt-specs/

Machine-readable SWIFT MT message format specifications.

## Purpose

This directory contains JSON specifications for SWIFT MT (Message Type) messages. Unlike the official SWIFT documentation (which is human-readable PDFs), these files provide structured, machine-readable definitions that can be directly consumed by parsers and validators.

## Supported MT Message Types

- **MT103** — Single Customer Credit Transfer
- **MT202** — General Financial Institution Transfer
- **MT940** — Customer Statement
- **MT942** — Interim Transaction Report

## File Format

Each MT message type has a JSON specification file (e.g., `mt103.json`) following this structure:

```json
{
  "message_type": "MT103",
  "name": "Single Customer Credit Transfer",
  "description": "...",
  "blocks": { ... },
  "fields": [
    {
      "tag": "20",
      "name": "Transaction Reference Number",
      "status": "M",
      "options": [],
      "max_length": 16,
      "format_pattern": "^[A-Za-z0-9/\\-\\?:\\(\\)\\.,'\\+ ]+$",
      "description": "...",
      "subfields": null
    },
    ...
  ]
}
```

### Field Properties

- **tag**: Field tag identifier (e.g., "20", "32A", "50K")
- **name**: Human-readable field name
- **status**: `M` (mandatory) or `O` (optional)
- **options**: Array of option letters for fields with multiple formats (e.g., ["A", "D", "K"] for field 50)
- **max_length**: Maximum character length for the field
- **format_pattern**: Regex pattern defining valid field content
- **description**: Detailed field description
- **subfields**: For composite fields (like 32A), breakdown of date/currency/amount components

## MT Message Block Structure

All MT messages follow the 5-block structure defined in `block_structure.json`:

1. **Block 1**: Basic Header (application ID, service ID, BIC, session/sequence numbers)
2. **Block 2**: Application Header (message type, destination BIC, priority)
3. **Block 3**: User Header (optional tag-value pairs like MUR, UETR)
4. **Block 4**: Text Block (actual message content with tagged fields)
5. **Block 5**: Trailer (optional checksums and system info)

## Usage

Applications should parse these JSON files to understand:
- Which fields are required vs optional
- Field ordering constraints
- Format validation patterns
- Subfield structure for composite fields

These specifications drive the MT parser and validator implementations in the paymsg library.
