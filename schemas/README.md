# schemas/

ISO 20022 XSD schema files for message validation.

## Directory Structure

```
schemas/
└── iso20022/
    ├── pacs/   # Payment clearing and settlement messages
    └── camt/   # Cash management messages
```

## Contents

This directory contains XML Schema Definition (XSD) files from the ISO 20022 standard for the payment message types supported by paymsg.

### Supported Message Types

**pacs** (Payment Clearing and Settlement):
- `pacs.008.001.10` — FIToFICustomerCreditTransfer
- `pacs.009.001.10` — FinancialInstitutionCreditTransfer

**camt** (Cash Management):
- `camt.052.001.10` — BankToCustomerAccountReport (Interim)
- `camt.053.001.10` — BankToCustomerStatement

## Usage

These XSD files are the authoritative source for XML schema validation. Applications should use standard XML validators to check ISO 20022 messages against these schemas.

## Source

XSD files are obtained from the official ISO 20022 website and SWIFT's standards repository. Version numbers in filenames indicate the exact schema revision.
