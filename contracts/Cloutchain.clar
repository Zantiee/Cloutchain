(define-map reputation principal uint)

;; Owner initialization for local workspace (set once via init)
(define-data-var owner (optional principal) none)

;; Error codes
(define-constant ERR-NOT-INITIALIZED   u400)
(define-constant ERR-UNAUTHORIZED      u401)
(define-constant ERR-INVALID-POINTS    u402)
(define-constant ERR-ALREADY-INITIALIZED u409)

;; Limits
(define-constant MAX-POINTS-PER-TX u1000)     ;; Cap per call
(define-constant MAX-TOTAL-REP     u1000000)  ;; Cap per user

;; One-time initialization to set the contract owner to tx-sender
(define-public (init)
  (if (is-some (var-get owner))
      (err ERR-ALREADY-INITIALIZED)
      (begin
        (var-set owner (some tx-sender))
        (ok true)
      )
  )
)

;; Read-only: check if a principal is the owner
(define-read-only (is-owner (who principal))
  (match (var-get owner)
    owner-p (is-eq owner-p who)
    false
  )
)

;; Read-only: get a user's reputation (defaults to u0 if none)
(define-read-only (get-rep (user principal))
  (default-to u0 (map-get? reputation user))
)

;; Public: add reputation points to a user (authorized callers only).
;; Returns (ok new-total) on success, or (err code) on failure.
(define-public (add-rep (user principal) (points uint))
  (match (var-get owner)
    owner-p
      (if (is-eq tx-sender owner-p)
          (if (is-eq points u0)
              (err ERR-INVALID-POINTS)
              (let (
                    (curr (default-to u0 (map-get? reputation user)))
                    (inc (if (> points MAX-POINTS-PER-TX) MAX-POINTS-PER-TX points))
                    ;; remaining = MAX-TOTAL-REP - curr (clamped at u0 to avoid underflow)
                    (remaining (if (> MAX-TOTAL-REP curr) (- MAX-TOTAL-REP curr) u0))
                    ;; safe-inc ensures we do not exceed MAX-TOTAL-REP
                    (safe-inc (if (> inc remaining) remaining inc))
                    (new-total (+ curr safe-inc))
                   )
                (begin
                  (map-set reputation user new-total)
                  (ok new-total)
                )
              )
          )
          (err ERR-UNAUTHORIZED)
      )
    (err ERR-NOT-INITIALIZED)
  )
)