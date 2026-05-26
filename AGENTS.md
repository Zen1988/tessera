# TESSERA / ZTSM Architecture

## Core Philosophy

- Book defines governance truth
- Process orchestrates runtime
- Ticket represents execution evidence
- StateBook controls lifecycle choreography
- BlueBook controls execution choreography

## Dynamic Field Naming

- ZTicket-*
- ZBlue-*
- ZState-*
- ZTSMServiceSupportMap-*

Never invent field names.

## Important Runtime Principles

- Parent ticket is governance ledger
- Child ticket is execution ledger
- Governance snapshots are immutable after orchestration starts

## OTOBO Extension Rules

- Avoid hardcoding workflow routing
- Resolve governance from CMDB objects
- Use TransitionAction modules whenever possible

## Key Modules

- ZTSMServiceLibrarian
- ZTSMStateBookReader
- ZTSMBlueBookReader

## UI Principles

- Portal-first interaction
- CustomerTicketZoom is runtime interaction surface
- ActivityDialog preferred over hardcoded buttons

## Current Known Areas

- DynamicField Set rendering bypasses Row_DynamicField
- Customer process actions injected dynamically into TicketZoom