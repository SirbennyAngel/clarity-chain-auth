;; ChainAuth - Blockchain Identity Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-not-verifier (err u103))
(define-constant err-already-verified (err u104))

;; Data Variables
(define-map identities
    principal
    {
        registered: bool,
        verified: bool,
        metadata: (string-ascii 256),
        verifier: (optional principal)
    }
)

(define-map verifiers
    principal
    bool
)

;; Public Functions

;; Register a new identity
(define-public (register-identity (metadata (string-ascii 256)))
    (let ((existing-identity (default-to 
        {
            registered: false,
            verified: false,
            metadata: "",
            verifier: none
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
                verifier: none
            })
            (ok true)
        ))
    )
)

;; Add a verifier
(define-public (add-verifier (verifier principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set verifiers verifier true)
            (ok true)
        )
        err-owner-only
    )
)

;; Verify an identity
(define-public (verify-identity (identity principal))
    (let (
        (existing-identity (map-get? identities identity))
        (is-verifier (default-to false (map-get? verifiers tx-sender)))
    )
    (asserts! is-verifier err-not-verifier)
    (asserts! (is-some existing-identity) err-not-registered)
    (asserts! (not (get verified (unwrap-panic existing-identity))) err-already-verified)
    
    (map-set identities identity (merge (unwrap-panic existing-identity) {
        verified: true,
        verifier: (some tx-sender)
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

;; Check if principal is a verifier
(define-read-only (is-verifier (address principal))
    (default-to false (map-get? verifiers address))
)