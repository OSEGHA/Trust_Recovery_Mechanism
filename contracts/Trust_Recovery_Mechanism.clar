;; ---------------------------------------------------------
;; Trust Recovery Mechanism
;; Gradual trust restoration through time-separated actions
;; ---------------------------------------------------------

;; -------------------------
;; Error Codes
;; -------------------------
(define-constant ERR-TOO-SOON u400)
(define-constant ERR-NOT-FOUND u401)
(define-constant ERR-NOT-AUTHORIZED u402)
(define-constant ERR-MAX-TRUST u403)

;; -------------------------
;; Configuration Constants
;; -------------------------

;; Maximum trust a user can have
(define-constant MAX-TRUST u10)

;; Minimum blocks between recovery actions
;; (~1 day ~ 144 blocks)
(define-constant RECOVERY-GAP u144)

;; Trust gained per successful recovery action
(define-constant RECOVERY-INCREMENT u1)

;; Trust lost per penalty
(define-constant PENALTY-DECREMENT u2)

;; -------------------------
;; Data Structures
;; -------------------------

;; Tracks trust and recovery state
(define-map trust
  principal
  {
    trust-score: uint,
    last-action: uint,
    recovery-actions: uint,
    penalties: uint
  }
)

;; Optional admin
(define-data-var admin principal tx-sender)

;; -------------------------
;; Read-Only Functions
;; -------------------------

(define-read-only (get-trust (user principal))
  (match (map-get? trust user)
    data (ok data)
    (err ERR-NOT-FOUND)

  )
)


(define-read-only (get-trust-score (user principal))
  (match (map-get? trust user)
    data (ok (get trust-score data))
    (err ERR-NOT-FOUND)
  )
)





(define-read-only (is-trusted (user principal))
  (match (map-get? trust user)
    data (> (get trust-score data) u0)
    false
  )
)





;; -------------------------
;; Public Functions
;; -------------------------

;; Initialize trust record (optional but explicit)
 (define-public (init-user)
  (let ((caller tx-sender)
        (current-block burn-block-height))
    (match (map-get? trust caller)
      data (ok true)
      (begin
        (map-set trust caller
          {
            trust-score: MAX-TRUST,
            last-action: current-block,
            recovery-actions: u0,
            penalties: u0
          }
        )
        (ok true)
      )
    )
  )
)

;; -------------------------
;; Apply Penalty
;; -------------------------
;; Reduces trust and forces recovery mode
 (define-public (apply-penalty (user principal))
  (let ((current-block burn-block-height)
        (validated-user user))
    (if (is-eq tx-sender (var-get admin))
        (match (map-get? trust validated-user)

          data
          (let (
                (current-trust (get trust-score data))
                (new-trust
                  (if (> current-trust PENALTY-DECREMENT)
                      (- current-trust PENALTY-DECREMENT)
                      u0))
               )
            (map-set trust validated-user
              {
                trust-score: new-trust,
                last-action: current-block,
                recovery-actions: (get recovery-actions data),
                penalties: (+ (get penalties data) u1)
              }
            )
            (ok true)
          )

          ;; If user not found, initialize with penalty applied
          (begin
            (map-set trust validated-user
              {
                trust-score: u0,
                last-action: current-block,
                recovery-actions: u0,
                penalties: u1
              }
            )
            (ok true)
          )
        )
        (err ERR-NOT-AUTHORIZED)
    )
  )
)

;; -------------------------
;; Recover Trust
;; -------------------------
;; Requires time separation between actions
 (define-public (recover-trust)
  (let ((caller tx-sender)
        (current-block burn-block-height))
    (match (map-get? trust caller)
      data
        (let ((last (get last-action data))
              (current-trust (get trust-score data)))
          (if (>= current-trust MAX-TRUST)
              (err ERR-MAX-TRUST)
              (if (< (- current-block last) RECOVERY-GAP)
                  (err ERR-TOO-SOON)
                  (let ((new-trust (if (< (+ current-trust RECOVERY-INCREMENT) MAX-TRUST)
                                       (+ current-trust RECOVERY-INCREMENT)
                                       MAX-TRUST)))
                    (begin
                      (map-set trust caller
                        {
                          trust-score: new-trust,
                          last-action: current-block,
                          recovery-actions: (+ (get recovery-actions data) u1),
                          penalties: (get penalties data)
                        }
                      )
                      (ok true)
                    )
                  )
              )
          )
      )
      (err ERR-NOT-FOUND)
    )
  )
)

;; -------------------------
;; Admin Utilities
;; -------------------------

(define-public (reset-user (user principal))
  (let ((validated-user user))
    (if (is-eq tx-sender (var-get admin))
        (begin
          (map-delete trust validated-user)
          (ok true)
        )
        (err ERR-NOT-AUTHORIZED)
    )
  )
)

(define-public (set-admin (new-admin principal))
  (let ((validated-admin new-admin))
    (if (is-eq tx-sender (var-get admin))
        (begin
          (var-set admin validated-admin)
          (ok true)
        )
        (err ERR-NOT-AUTHORIZED)
    )
  )
)

