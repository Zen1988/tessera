# CMDB network scope and enforcement selection

Confirmed with the owner on 2026-10-27 for the 184 network-planning work.

The requester supplies source and destination. The backend resolves authorized
CMDB snapshots and the requested service supplies protocol/ports. The requester
does not select a firewall, firewall zone, NSX manager, or device credentials.

## Existing exported objects

* `NetworkSegment`: `ZCI-CIDR`, `ZCI-Zone`, `ZTAM-Platform`.
* `NetworkAddressPool`: `ZCI-Network`, `ZCI-RangeStart`, `ZCI-RangeEnd`.
* `NetworkDomain`: `ZTAM-NetworkDomainType`, `ZTAM-ParentNetworkDomain`,
  `ZTAM-Product`, `ZTAM-TechnologyProfile`, `ZTAM-Config`.

`ZCI-Zone` references the CMDB NetworkZone classification. It is never copied
into a firewall's source/destination zone or treated as an NSX group.

The current exported NetworkSegment has no direct NetworkDomain field. Until
the authoritative model adds that relationship, the existing governed automation
provides `SegmentDomains` (segment CI ID to domain CI ID). `DomainBindings`
uses the actual domain CI ID to identify its reviewed Overlay/Underlay layer
and managed enforcement contexts. These are internal mapping keys, not new
Dynamic Fields. Do not infer a domain from display names or from platform alone:
one platform can contain multiple domains, overlapping address spaces and managers.

## Resolution

1. Resolve each endpoint to an authorized address and network scope.
2. Find the longest matching `ZCI-CIDR` within that scope. Equal matches are
   ambiguous; never choose the first record. For overlapping address spaces the
   authorized endpoint mapping can supply an explicit SegmentID; its CIDR must
   still contain the address. This is a backend mapping key, not a new DF or a
   requester override. Resolve an address pool through
   `ZCI-Network` and verify its address range. Overlapping pools block resolution.
3. Resolve the explicit segment/domain relationship and retain the actual
   NetworkDomain snapshot. Unknown domain or layer blocks planning.
4. Gather both directions of NetXMS path evidence; classify managed firewalls
   through the authorized CMDB mapping. Unknown hops remain unresolved.
5. Add enforcement systems from each domain, independently of routed hops.
   VMware overlay bindings include the relevant NSX manager/domain context.
   Underlay bindings may also contain explicit enforcement systems.
6. AWX reads the selected contexts. NSX evidence determines group membership,
   policies, applied scope and whether DFW changes are needed. Overlay membership
   requires DFW **analysis**, not unconditional creation of a new rule. Existing
   matching policy may already allow the flow; gateway policy can also be relevant.
7. Preserve the CMDB classification, observed device zones/groups, path and
   proposed changes as separate evidence. Ambiguity, NAT, missing topology or
   insufficient policy semantics must remain explicit, never a guessed rule.

For example, a source in a VMware overlay and a destination beyond a physical
firewall can require both NSX DFW and physical-firewall analysis. Two endpoints
in the same overlay can require DFW analysis even when no physical firewall is
visible in the L3 path. The manager/context is selected by backend mappings;
target credentials stay in AWX.

## Implementation status

The 184 NetworkIntelligence resolver resolves segment/pool and explicit domain
bindings, preserving NetworkZone separately. The authorized automation adapter
connects discovery, AWX collection and saved callback interpretation. Offline
tests cover domain selection, ambiguity, callback storage and actor boundaries.
See tessera-184-network-assessment.md for installation and the exact collector
limits. Live NSX acceptance and full effective-policy evaluation are not complete.
No ConfigItem definitions, Dynamic Fields or live records were changed.
