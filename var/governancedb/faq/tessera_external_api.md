# TESSERA External API, Ansible, and Script Engine Reference

## Governance contract

The external API is a command intake surface. It is not a direct database mutation API.
External CMDB and MELT create/update requests are staged, reviewed, released through ticket actions,
recorded as ticket and object activity articles, and reverted through compensating ticket actions.
Delete is not supported. GovernanceDB is query-only.

## API identities and permissions

API identities are API-only CustomerUsers because the authoritative
`ZTSMSupportAssignment-UserAccount` field references CustomerUser. Authentication uses a TESSERA API
key, not the CustomerUser password. Effective access requires all of:

1. an active API key and active CustomerUser;
2. membership in `tessera-api` and the object capability customer group;
3. a SupportAssignment using `CMDBAPI`, `MELTAPI`, or `GovernanceAPI`;
4. a matching SupportProfile and ContractEntitlement.

CMDB access uses `ZTAM-ContractEntitlement`. MELT Risk access uses the exact exported
`MELT-AccessPermission` field, which references one or more ContractEntitlement objects.

## Key lifecycle

Create a key:

```text
bin/otobo.Console.pl Admin::TESSERA::APIKey --action create --customer-user ansible_cmdb_prod --name production --expires-in-days 90
```

Renew with a 24-hour overlap:

```text
bin/otobo.Console.pl Admin::TESSERA::APIKey --action renew --key-id 12 --name production-rotated --expires-in-days 90 --overlap-hours 24
```

Revoke immediately:

```text
bin/otobo.Console.pl Admin::TESSERA::APIKey --action revoke --key-id 12
```

The plaintext key is shown once. Store it in Ansible Vault. Renewal creates a different secret; it
never reveals or reuses the old key. Requests use `Authorization: Bearer <api-key>`.

## Staging request

Only `Create` and `Update` are accepted. Update requires `TargetID` and `ExpectedVersionID`.
Field names must exactly match the current exported class definition. CMDB payloads must include
`ZTAM-ContractEntitlement`; MELT Risk payloads must include `MELT-AccessPermission`.

```json
{
  "Source": "ansible",
  "IdempotencyKey": "server-123-change-42",
  "ObjectType": "CMDB",
  "ObjectClass": "Computer",
  "Operation": "Update",
  "TargetID": 123,
  "ExpectedVersionID": 456,
  "SchemaHash": "authoritative-schema-hash",
  "Payload": {
    "Name": "server-01",
    "ZTAM-ContractEntitlement": [789]
  }
}
```

Retries must reuse the same Source and IdempotencyKey. TESSERA returns the existing staging request
instead of creating a duplicate.

## Ansible pattern

Keep the API key in Ansible Vault and send it only in the Bearer header. Ansible maps source-system
properties to exact TESSERA exported field names. TESSERA remains the final schema, permission,
entitlement, approval, version-conflict, and release boundary.

## TESSERA Script Engine language

The Script Engine is an English YAML language. It is configuration, not Perl, SQL, shell, or a route to
arbitrary runtime modules. Use `VERSION: 1`; unknown versions, statements, object types, operators,
missing context, ambiguous results, and structured values in scalar expressions fail closed as
`UNKNOWN`.

### Search and typed return

`SEARCH` supports `GovernanceObject` and `ITSMConfigItem`. A positive `LIMIT` is mandatory and the
engine rejects values above its safety maximum. `WHERE` supports `EQUALS` and `CONTAINS`. Context values
may use `CURRENT OBJECT` or paths such as `TICKET.ZTicket-Application`. Use exact exported field names.

```yaml
---
SCRIPT: Resolve Dynamic Governance Role
VERSION: 1
SEARCH:
  FOR: GovernanceObject
  CLASS: SupportAssignment
  AS: Matching Assignments
  WHERE:
    ZTSMSupportAssignment-Role:
      EQUALS: CURRENT OBJECT
    ZTSMSupportAssignment-Application:
      EQUALS: TICKET.ZTicket-Application
  LIMIT: 2
REQUIRE:
  Matching Assignments:
    HAS EXACTLY: 1
  OTHERWISE: GovernanceRole and Application must resolve to exactly one SupportAssignment.
RETURN:
  FROM: EXACTLY ONE Matching Assignments
  FIELD: ZTSMSupportAssignment-SupportProfile
  AS: GovernanceObject.SupportProfile
```

`FIRST <collection>` is available where the first bounded result is intentionally sufficient.
`EXACTLY ONE <collection>` should be used for governance resolution. `RETURN AS` declares the result
contract. Supported runtime consumers also use `CustomerUser` and `Collection<SupportAssignment>`.

### Conditional returns

A return may select between typed branches with `RETURN IF`, `THEN`, and `ELSE`. Field paths can
traverse hydrated ticket and CustomerUser context. A missing path is unknown; it never becomes a broad
or default permission.

```yaml
---
SCRIPT: Resolve Requester
VERSION: 1
RETURN:
  IF: TICKET.CustomerUser.ZUser-SupportProfile IS NOT EMPTY
  THEN:
    VALUE: TICKET.CustomerUser.ZUser-SupportProfile
    AS: GovernanceObject.SupportProfile
  ELSE:
    VALUE: TICKET.CustomerUser
    AS: CustomerUser
```

### Conditions and values

Policy and `EXPECT` conditions accept `EQUALS`, `DOES NOT EQUAL`, `CONTAINS`, `STARTS WITH`, `ENDS
WITH`, `IS EMPTY`, `IS NOT EMPTY`, `IS GREATER THAN`, `IS LESS THAN`, `IS AT LEAST`, `IS AT MOST`,
`IS ON OR AFTER`, and `IS ON OR BEFORE`. Join lines with `AND` or `OR`.

Scalar expressions support quoted strings, numbers, `TRUE`, `FALSE`, `EMPTY`, `NOW`, relative time such
as `30 DAYS AGO`, conversion with `NUMBER(...)`, `STRING(...)`, `DATE(...)`, and `DATETIME(...)`, numeric
`*` and `/`, and `PRODUCT OF [value, value]`. Object paths use roots such as `@TICKET` and
`@CONTROLOBJECTIVE`; Dynamic Field paths use their exact exported names. Multiple or structured values
cannot be silently reduced to a scalar.

### ControlObjective risk field assignments

The individual ConfigItem `Control` reports Pass or Fail. Its parent `ControlObjective` owns the
instruction for what a failure creates and how fields are populated. `ZRM-FieldAssignment` contains a
typed Script Engine return. `THIS` is the failing Control ID.

```yaml
---
SCRIPT: Create Risk From Failed Control
VERSION: 1
RETURN:
  AS: MELTObject.Risk
  FIELD ASSIGNMENTS:
    MELT-Control: THIS
    MELT-RMF: "@CONTROLOBJECTIVE.ZRM-RMF"
    MELT-EventSeverity: "@CONTROL.ZRM-Severity"
```

The `AS` target must exactly match the requested object type and class. Every field name is validated,
each value must resolve, and one program cannot target several classes. The older line form remains
accepted for existing configurations:

```text
SET @MELTObject.Risk.MELT-Control THIS
SET @MELTObject.Risk.MELT-RMF @CONTROLOBJECTIVE.ZRM-RMF
```

Prefer the YAML form for new configuration.

### Attestation ticket programs

The bounded program form can request `NEW @TICKET`, set ticket properties, populate exact Dynamic
Fields, define Attestation rows, evaluate an `EXPECT` block, and `SUBMIT`. A new ticket request without
`SUBMIT`, or an Attestation program without a non-empty `EXPECT`, is rejected. Results are `Pass`,
`Fail`, `N/A`, or `UNKNOWN`; unknown input never becomes Pass.

### External connector integration

Script Engine `CALL` is reserved for declarative, registered, allowlisted connectors. It is not enabled
as an arbitrary HTTP instruction. A connector manifest must define typed request and response schemas,
an authentication reference, permission scope, timeout, retry and idempotency rules, secret redaction,
and audit evidence. Scripts cannot provide arbitrary URLs, credentials, Perl, SQL, shell commands, or
runtime module names. API keys are resolved from protected configuration and must never appear in
authored YAML, ticket articles, activity payloads, or logs.

Until a connector is registered and the `CALL` grammar is released, Ansible or another orchestrator
must call the staged TESSERA API directly. This keeps Script Engine programs deterministic and prevents
an authored governance object from bypassing API authentication, entitlement, review, or ticket
evidence.
