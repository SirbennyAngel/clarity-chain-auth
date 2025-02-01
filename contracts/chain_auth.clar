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

;; Data Variables
(define-map identities
    principal
    {
        registered: bool,
        verified: bool,
        metadata: (string-ascii 256),
        verifier: (optional principal),
        tier: uint
    }
)

(define-map verifiers
    principal
    {
        active: bool,
        tier-level: uint
    }
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
            tier: u0
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
                tier: u0
            })
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
                tier-level: tier-level
            })
            (ok true)
        )
        err-owner-only
    )
)

;; Verify an identity with tier
(define-public (verify-identity (identity principal) (tier uint))
    (let (
        (existing-identity (map-get? identities identity))
        (verifier-info (map-get? verifiers tx-sender))
    )
    (asserts! (is-some verifier-info) err-not-verifier)
    (asserts! (is-some existing-identity) err-not-registered)
    (asserts! (not (get verified (unwrap-panic existing-identity))) err-already-verified)
    (asserts! (<= tier (get tier-level (unwrap-panic verifier-info))) err-insufficient-tier)
    
    (map-set identities identity (merge (unwrap-panic existing-identity) {
        verified: true,
        verifier: (some tx-sender),
        tier: tier
    }))
    (ok true))
)

;; Read-only functions

;; Check if an identity is registered
(define-read-only (is-registered (identity principal))
    (let ((existing-identity (map-get? identities identity)))
        (if (is-some existing-identity)
            (ok (get registered (unwrap-panic existing-identity)))
            (ok false)
        )
    )
)

;; Check if an identity is verified
(define-read-only (is-verified (identity principal))
    (let ((existing-identity (map-get? identities identity)))
        (if (is-some existing-identity)
            (ok (get verified (unwrap-panic existing-identity)))
            (ok false)
        )
    )
)

;; Get identity metadata
(define-read-only (get-identity-info (identity principal))
    (map-get? identities identity)
)

;; Check verifier status and tier
(define-read-only (get-verifier-info (address principal))
    (map-get? verifiers address)
)

;; Get identity tier level
(define-read-only (get-identity-tier (identity principal))
    (let ((existing-identity (map-get? identities identity)))
        (if (is-some existing-identity)
            (ok (get tier (unwrap-panic existing-identity)))
            (err err-not-registered)
        )
    )
)
