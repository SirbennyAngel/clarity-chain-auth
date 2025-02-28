;; ChainAuth - Blockchain Identity Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-not-verifier (err u103))
(define-constant err-already-verified (err u104))
(define-constant err-invalid-tier (err u105))
(define-constant err-insufficient-tier (err u106))
(define-constant err-suspended (err u107))
(define-constant err-expired (err u108))

;; Data Variables
(define-map identities
    principal
    {
        registered: bool,
        verified: bool,
        metadata: (string-ascii 256),
        verifier: (optional principal),
        tier: uint,
        suspended: bool,
        verification-expiry: (optional uint)
    }
)

(define-map verifiers
    principal
    {
        active: bool,
        tier-level: uint,
        total-verifications: uint
    }
)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
    uint
    {
        event-type: (string-ascii 20),
        principal: principal,
        timestamp: uint
    }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 20)) (principal principal))
    (let ((event-id (+ (var-get last-event-id) u1)))
        (begin
            (map-set events event-id {
                event-type: event-type,
                principal: principal,
                timestamp: block-height
            })
            (var-set last-event-id event-id)
            true
        )
    )
)

;; Public Functions

;; Register a new identity
(define-public (register-identity (metadata (string-ascii 256)))
    (let ((existing-identity (default-to 
        {
            registered: false,
            verified: false,
            metadata: "",
            verifier: none,
            tier: u0,
            suspended: false,
            verification-expiry: none
        }
        (map-get? identities tx-sender)
    )))
    (if (get registered existing-identity)
        err-already-registered
        (begin
            (map-set identities tx-sender {
                registered: true,
                verified: false,
                metadata: metadata,
                verifier: none,
                tier: u0,
                suspended: false,
                verification-expiry: none
            })
            (emit-event "REGISTER" tx-sender)
            (ok true)
        ))
    )
)

;; Add a verifier with tier level
(define-public (add-verifier (verifier principal) (tier-level uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (asserts! (<= tier-level u3) err-invalid-tier)
            (map-set verifiers verifier {
                active: true,
                tier-level: tier-level,
                total-verifications: u0
            })
            (emit-event "ADD_VERIFIER" verifier)
            (ok true)
        )
        err-owner-only
    )
)

;; Revoke verifier status
(define-public (revoke-verifier (verifier principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set verifiers verifier {
                active: false,
                tier-level: u0,
                total-verifications: u0
            })
            (emit-event "REVOKE_VERIFIER" verifier)
            (ok true)
        )
        err-owner-only
    )
)

;; Suspend identity
(define-public (suspend-identity (identity principal))
    (if (is-eq tx-sender contract-owner)
        (let ((existing-identity (map-get? identities identity)))
            (asserts! (is-some existing-identity) err-not-registered)
            (map-set identities identity (merge (unwrap-panic existing-identity) {
                suspended: true
            }))
            (emit-event "SUSPEND" identity)
            (ok true)
        )
        err-owner-only
    )
)

;; Verify an identity with tier and expiration
(define-public (verify-identity (identity principal) (tier uint) (expiry-blocks uint))
    (let (
        (existing-identity (map-get? identities identity))
        (verifier-info (map-get? verifiers tx-sender))
    )
    (asserts! (is-some verifier-info) err-not-verifier)
    (asserts! (is-some existing-identity) err-not-registered)
    (asserts! (not (get verified (unwrap-panic existing-identity))) err-already-verified)
    (asserts! (<= tier (get tier-level (unwrap-panic verifier-info))) err-insufficient-tier)
    (asserts! (not (get suspended (unwrap-panic existing-identity))) err-suspended)
    
    (map-set identities identity (merge (unwrap-panic existing-identity) {
        verified: true,
        verifier: (some tx-sender),
        tier: tier,
        verification-expiry: (some (+ block-height expiry-blocks))
    }))
    (emit-event "VERIFY" identity)
    (ok true))
)

;; Read-only functions remain unchanged but documentation improved...
