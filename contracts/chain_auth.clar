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
(define-constant err-contract-paused (err u109))
(define-constant err-invalid-expiry (err u110))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var grace-period uint u144) ;; ~24 hours in blocks

(define-map identities
    principal
    {
        registered: bool,
        verified: bool,
        metadata: (string-ascii 256),
        verifier: (optional principal),
        tier: uint,
        suspended: bool,
        verification-expiry: (optional uint),
        last-renewal: (optional uint)
    }
)

(define-map verifiers
    principal
    {
        active: bool,
        tier-level: uint,
        total-verifications: uint,
        last-active: uint
    }
)

;; Enhanced Events
(define-data-var last-event-id uint u0)

(define-map events
    uint
    {
        event-type: (string-ascii 20),
        principal: principal,
        timestamp: uint,
        metadata: (string-ascii 256),
        related-principal: (optional principal)
    }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 20)) (principal principal) (metadata (string-ascii 256)) (related-principal (optional principal)))
    (let ((event-id (+ (var-get last-event-id) u1)))
        (begin
            (map-set events event-id {
                event-type: event-type,
                principal: principal,
                timestamp: block-height,
                metadata: metadata,
                related-principal: related-principal
            })
            (var-set last-event-id event-id)
            true
        )
    )
)

(define-private (check-not-paused)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
)

;; Public Functions

;; Toggle contract pause state
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused paused)
        (emit-event (if paused "PAUSE" "UNPAUSE") tx-sender "" none)
        (ok true)
    )
)

;; Register a new identity
(define-public (register-identity (metadata (string-ascii 256)))
    (begin
        (check-not-paused)
        (let ((existing-identity (default-to 
            {
                registered: false,
                verified: false,
                metadata: "",
                verifier: none,
                tier: u0,
                suspended: false,
                verification-expiry: none,
                last-renewal: none
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
                    verification-expiry: none,
                    last-renewal: none
                })
                (emit-event "REGISTER" tx-sender metadata none)
                (ok true)
            ))
        )
    )
)

;; Renew verification
(define-public (renew-verification (identity principal))
    (begin
        (check-not-paused)
        (let (
            (existing-identity (unwrap! (map-get? identities identity) err-not-registered))
            (verifier-info (unwrap! (map-get? verifiers tx-sender) err-not-verifier))
        )
        (asserts! (get active verifier-info) err-not-verifier)
        (asserts! (get verified existing-identity) err-not-verified)
        (asserts! (not (get suspended existing-identity)) err-suspended)
        
        (map-set identities identity (merge existing-identity {
            verification-expiry: (some (+ block-height u52560)), ;; Extend by ~1 year
            last-renewal: (some block-height)
        }))
        (emit-event "RENEW" identity "Verification renewed" (some tx-sender))
        (ok true))
    )
)

;; Batch verify identities
(define-public (batch-verify-identities (identities (list 20 principal)) (tier uint) (expiry-blocks uint))
    (begin
        (check-not-paused)
        (asserts! (> expiry-blocks block-height) err-invalid-expiry)
        (map verify-identity identities)
        (ok true)
    )
)

[Previous functions remain unchanged...]
