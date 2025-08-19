;; Secret Santa Smart Contract

;; Core Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u201))
(define-constant err-already-registered (err u202))
(define-constant err-balance-too-low (err u203))
(define-constant err-participant-not-found (err u204))
(define-constant err-pairing-completed (err u205))
(define-constant err-still-locked (err u206))
(define-constant err-already-claimed (err u207))
(define-constant err-insufficient-participants (err u208))
(define-constant err-pairing-failed (err u209))

;; Contract State
(define-data-var registration-open bool true)
(define-data-var reveal-time uint u1703462400) ;; Dec 24, 2024 00:00:00 UTC
(define-data-var min-participants uint u3)
(define-data-var minimum-contribution uint u100)
(define-data-var participant-count uint u0)
(define-data-var pairing-index uint u0)

;; Data Storage
(define-map participants principal 
  {
    registered: bool,
    contribution: uint,
    paired: bool,
    claimed: bool,
    position: uint
  }
)

(define-map participant-positions uint principal)
(define-map santa-assignments principal principal) ;; Santa -> Recipient
(define-map recipient-assignments principal principal) ;; Recipient -> Santa

;; Helper Functions
(define-private (is-participant-registered (wallet principal))
  (default-to false (get registered (map-get? participants wallet)))
)

(define-private (get-contribution-amount (wallet principal))
  (default-to u0 (get contribution (map-get? participants wallet)))
)

(define-private (is-participant-paired (wallet principal))
  (default-to false (get paired (map-get? participants wallet)))
)

;; Core Contract Functions
(define-public (register-for-santa (contribution uint))
  (let (
    (new-participant tx-sender)
    (current-count (var-get participant-count))
  )
    (asserts! (var-get registration-open) err-pairing-completed)
    (asserts! (>= contribution (var-get minimum-contribution)) err-balance-too-low)
    (asserts! (not (is-participant-registered new-participant)) err-already-registered)
    
    (try! (stx-transfer? contribution new-participant (as-contract tx-sender)))
    
    (map-set participants new-participant {
      registered: true,
      contribution: contribution,
      paired: false,
      claimed: false,
      position: current-count
    })
    
    (map-set participant-positions current-count new-participant)
    (var-set participant-count (+ current-count u1))
    
    (ok true))
)

(define-public (execute-pairing)
  (let (
    (caller tx-sender)
    (total-participants (var-get participant-count))
    (current-pairing (var-get pairing-index))
  )
    (asserts! (is-contract-owner) err-not-authorized)
    (asserts! (>= total-participants (var-get min-participants)) err-insufficient-participants)
    (asserts! (< current-pairing total-participants) err-pairing-failed)
    
    (let (
      (current-santa (unwrap! (map-get? participant-positions current-pairing) err-pairing-failed))
      (next-position (mod (+ current-pairing u1) total-participants))
      (assigned-recipient (unwrap! (map-get? participant-positions next-position) err-pairing-failed))
    )
      (map-set santa-assignments current-santa assigned-recipient)
      (map-set recipient-assignments assigned-recipient current-santa)
      
      (map-set participants current-santa 
        (merge (unwrap! (map-get? participants current-santa) err-participant-not-found)
          { paired: true }))
      
      (var-set pairing-index (+ current-pairing u1))
      
      (if (is-eq (+ current-pairing u1) total-participants)
        (var-set registration-open false)
        true)
      
      (ok true)))
)

(define-public (reveal-santa)
  (let ((participant tx-sender))
    (asserts! (>= block-height (var-get reveal-time)) err-still-locked)
    (asserts! (is-participant-registered participant) err-participant-not-found)
    (asserts! (is-participant-paired participant) err-pairing-completed)
    
    (ok (unwrap! (map-get? recipient-assignments participant) err-participant-not-found)))
)

(define-public (claim-gift)
  (let (
    (gift-recipient tx-sender)
    (participant-info (unwrap! (map-get? participants gift-recipient) err-participant-not-found))
  )
    (asserts! (>= block-height (var-get reveal-time)) err-still-locked)
    (asserts! (not (get claimed participant-info)) err-already-claimed)
    
    (let ((gift-giver (unwrap! (map-get? recipient-assignments gift-recipient) err-participant-not-found)))
      (try! (as-contract (stx-transfer? 
        (get contribution (unwrap! (map-get? participants gift-giver) err-participant-not-found))
        tx-sender
        gift-recipient)))
      
      (map-set participants gift-recipient 
        (merge participant-info { claimed: true }))
      
      (ok true)))
)

(define-public (withdraw-early)
  (let (
    (participant tx-sender)
    (participant-info (unwrap! (map-get? participants participant) err-participant-not-found))
  )
    (asserts! (var-get registration-open) err-pairing-completed)
    (asserts! (not (get paired participant-info)) err-pairing-completed)
    
    (try! (as-contract (stx-transfer? 
      (get contribution participant-info)
      tx-sender
      participant)))
    
    (map-delete participants participant)
    (var-set participant-count (- (var-get participant-count) u1))
    (ok true))
)

;; Query Functions
(define-read-only (get-participant-info (participant principal))
  (map-get? participants participant)
)

(define-read-only (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-read-only (get-participant-count)
  (var-get participant-count)
)

(define-read-only (get-pairing-progress)
  (var-get pairing-index)
)