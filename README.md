# Secret Santa Smart Contract

A decentralized Secret Santa gift exchange protocol built on the Stacks blockchain using Clarity smart contracts.

## Overview

This smart contract enables trustless Secret Santa exchanges where participants can join with STX contributions, get randomly paired with other participants, and claim their gifts on a predetermined reveal date. The contract ensures fairness and prevents cheating through blockchain transparency and automated matching.

## Key Features

- **Trustless Operation**: No central authority needed after deployment
- **Automated Pairing**: Contract owner executes deterministic round-robin matching
- **Deposit Security**: STX contributions held in escrow until distribution
- **Time-Locked Distribution**: Gifts can only be claimed after reveal date
- **Early Withdrawal**: Participants can exit before pairing is complete

## How It Works

1. **Registration Phase**: Participants register with STX contributions (minimum 100 STX)
2. **Pairing Phase**: Contract owner executes pairing once minimum participants (3) join
3. **Reveal Phase**: After December 24, 2024, participants can discover their Secret Santa
4. **Distribution Phase**: Participants claim their gifts (receive their Santa's contribution)

## Contract State

### Core Parameters
- **Minimum Participants**: 3
- **Minimum Contribution**: 100 STX
- **Reveal Date**: December 24, 2024 (timestamp: 1703462400)
- **Registration Status**: Open/Closed based on pairing completion

### Participant Data
Each participant stores:
- `registered`: Registration status
- `contribution`: STX amount deposited
- `paired`: Whether they've been matched
- `claimed`: Whether they've claimed their gift
- `position`: Their sequence number for pairing

## Public Functions

### `register-for-santa(contribution: uint)`
Join the Secret Santa exchange with an STX contribution.
- **Requirements**: Registration must be open, contribution ≥ minimum, not already registered
- **Effect**: Transfers STX to contract, adds participant to exchange

### `execute-pairing()`
Execute one round of the pairing algorithm (contract owner only).
- **Requirements**: Owner only, sufficient participants, pairing not complete
- **Effect**: Pairs current participant with next in sequence, advances pairing progress

### `reveal-santa()`
Discover who your Secret Santa is.
- **Requirements**: After reveal date, registered and paired participant
- **Returns**: Principal address of your Secret Santa

### `claim-gift()`
Claim your Secret Santa gift.
- **Requirements**: After reveal date, not already claimed
- **Effect**: Transfers your Santa's contribution to your wallet

### `withdraw-early()`
Exit the exchange before pairing is complete.
- **Requirements**: Registration still open, not yet paired
- **Effect**: Refunds your contribution and removes you from exchange

## Read-Only Functions

- `get-participant-info(principal)`: Get participant details
- `is-contract-owner()`: Check if caller is contract owner
- `get-participant-count()`: Get total number of participants
- `get-pairing-progress()`: Get current pairing progress

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 201 | `err-not-authorized` | Caller is not contract owner |
| 202 | `err-already-registered` | Participant already registered |
| 203 | `err-balance-too-low` | Contribution below minimum |
| 204 | `err-participant-not-found` | Unknown participant |
| 205 | `err-pairing-completed` | Pairing already finished |
| 206 | `err-still-locked` | Before reveal date |
| 207 | `err-already-claimed` | Gift already claimed |
| 208 | `err-insufficient-participants` | Not enough participants |
| 209 | `err-pairing-failed` | Pairing algorithm error |

## Security Considerations

- **Round-Robin Matching**: Uses deterministic sequential pairing to ensure fairness
- **Time Locks**: Prevents early gift claiming before reveal date
- **Deposit Protection**: STX held in contract escrow until legitimate claims
- **Owner Permissions**: Only pairing execution requires owner privileges
- **Early Exit Protection**: Participants can withdraw before commitment (pairing)

## Deployment Notes

- Contract owner is set to deployer address at deployment time
- Reveal date is hardcoded to December 24, 2024
- Minimum parameters can only be changed by redeploying contract
- Consider gas costs for large participant pools during pairing phase

## Usage Example

```clarity
;; Register for Secret Santa with 150 STX
(contract-call? .secret-santa register-for-santa u150)

;; Check your participant info
(contract-call? .secret-santa get-participant-info tx-sender)

;; After pairing, reveal your Santa (after Dec 24)
(contract-call? .secret-santa reveal-santa)

;; Claim your gift
(contract-call? .secret-santa claim-gift)
```