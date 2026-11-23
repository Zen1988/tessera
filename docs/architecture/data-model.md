# Data model

Native Dynamic Fields, class definitions and GeneralCatalog values define exact names, types, Set members and reference targets. Labels do not define names; catalogue IDs do not transfer between sites. Preserve authoritative spellings including Contract-SupportProfie and FieldAsssignment.

GovernanceObject holds Books, applications/platforms, roles, contracts and support assignments. ITSMConfigItem holds assets; MELTObject includes Risk; Ticket stores runtime evidence; FAQ uses optional FAQApplication references. Common namespaces include ZTicket, ZBlue, ZState, ZRM, ZTAM and ZTSMServiceSupportMap. Owner-approved exceptions include FAQApplication, ChangeType and ChangeClassification.

Dated exports are a schema baseline. Package bootstrap/defaults and managed installers add or migrate fields while preserving compatible IDs/data and administrator objects. The offline pack includes both origins rather than pretending a dated export is a fresh live export.

Script Sets have contiguous unique indices 1–99, at most 3800 characters per fragment and 376200 total. Assembly inserts no separator. Do not import both an owning Set and standalone source members.

External identities are tuples, never display strings split on colons. In Navis, collection namespace, returned CMDB identity namespace, InstanceID and Kubernetes namespace have distinct meanings. Missing/ambiguous identity fails closed.

See [offline schema reference](../scriptengine/README.md). Generated XML/JSON indexes are references, not native import files.


Application GO has an optional Text field named Navis for its stable topology label; resolved UUIDs belong to operation evidence. It is a managed0.1.5 addition, not present in the dated export. ApplicationNavisInstaller creates it idempotently and supplements an independent Agent page while preserving existing definitions. Membership/topology-creation automation remains pending.
