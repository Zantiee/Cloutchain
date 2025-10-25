# Cloutchain Contract

File: contracts/Cloutchain.clar

## Overview
This Clarity contract maintains a reputation mapping for principals and restricts mutation to a single owner that is set once via initialization. It enforces per-transaction and total caps on reputation increases and returns explicit error codes for invalid operations.

## Storage
- Map
  - reputation: principal => uint
- Data variables
  - owner: (optional principal), initially none

## Constants
- Error codes
  - ERR-NOT-INITIALIZED: u400
  - ERR-UNAUTHORIZED: u401
  - ERR-INVALID-POINTS: u402
  - ERR-ALREADY-INITIALIZED: u409
- Limits
  - MAX-POINTS-PER-TX: u1000
  - MAX-TOTAL-REP: u1000000

## Functions

### Public
- init
  - Signature: (define-public (init) ...)
  - Behavior:
    - If owner is none: sets owner to tx-sender and returns (ok true).
    - If owner is already set: returns (err ERR-ALREADY-INITIALIZED).
  - Return type: (response bool uint)

- add-rep
  - Signature: (define-public (add-rep (user principal) (points uint)) ...)
  - Behavior:
    - Requires owner to be set and tx-sender to equal owner; otherwise returns:
      - (err ERR-NOT-INITIALIZED) if owner is none
      - (err ERR-UNAUTHORIZED) if tx-sender is not owner
    - Requires points != u0; otherwise returns (err ERR-INVALID-POINTS).
    - Applies caps:
      - inc = min(points, MAX-POINTS-PER-TX)
      - remaining = max(MAX-TOTAL-REP - current, u0)
      - safe-inc = min(inc, remaining)
      - new-total = current + safe-inc
    - Updates reputation[user] to new-total and returns (ok new-total).
  - Return type: (response uint uint)

### Read-only
- is-owner
  - Signature: (define-read-only (is-owner (who principal)) ...)
  - Behavior:
    - Returns true if who equals the stored owner; false if not set or not equal.
  - Return type: bool

- get-rep
  - Signature: (define-read-only (get-rep (user principal)) ...)
  - Behavior:
    - Returns the user’s reputation, defaulting to u0 if the user has no entry.
  - Return type: uint

## Data Flow and Logic Notes
- Reputation increases are clamped both per call and in total per user.
- If a user’s reputation is already at MAX-TOTAL-REP, add-rep writes the current value back and returns (ok current) with no increase.
- The contract does not define any functions to decrease reputation, transfer ownership, or re-initialize the owner.