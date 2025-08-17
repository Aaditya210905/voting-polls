;; On-Chain Voting Polls Contract
;; Only admin can create polls
;; Anyone can vote once per poll
;; Votes stored on-chain transparently

(define-constant admin tx-sender)

;; Data structure for a poll
(define-map polls
  uint
  {
    question: (string-ascii 256),
    options: (list 10 (string-ascii 100)),
    creator: principal
  }
)

;; Store votes: (poll-id, voter) -> option-index
(define-map votes
  { poll-id: uint, voter: principal }
  uint
)

;; Store poll results: (poll-id, option-index) -> count
(define-map results
  { poll-id: uint, option: uint }
  uint
)

;; Track the next poll ID
(define-data-var poll-counter uint u0)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-already-voted (err u101))
(define-constant err-invalid-option (err u102))
(define-constant err-poll-not-found (err u103))

;; Create a new poll (only admin)
(define-public (create-poll (question (string-ascii 256)) (options (list 10 (string-ascii 100))))
  (begin
    (if (is-eq tx-sender admin)
      (let
        (
          (poll-id (+ (var-get poll-counter) u1))
        )
        (begin
          (var-set poll-counter poll-id)
          (map-set polls poll-id {
            question: question,
            options: options,
            creator: tx-sender
          })
          (ok poll-id)
        )
      )
      err-not-admin
    )
  )
)

;; Vote in a poll
(define-public (vote (poll-id uint) (option uint))
  (let
    (
      (poll (map-get? polls poll-id))
    )
    (match poll
      poll-data
      (if (is-some (map-get? votes {poll-id: poll-id, voter: tx-sender}))
        err-already-voted
        (let
          (
            (options (get options poll-data))
            (opt-len (len options))
          )
          (if (>= option opt-len)
            err-invalid-option
            (begin
              (map-set votes {poll-id: poll-id, voter: tx-sender} option)
              (let ((count (default-to u0 (map-get? results {poll-id: poll-id, option: option}))))
                (map-set results {poll-id: poll-id, option: option} (+ count u1))
              )
              (ok true)
            )
          )
        )
      )
      err-poll-not-found
    )
  )
)

;; Read-only: get poll details
(define-read-only (get-poll (poll-id uint))
  (map-get? polls poll-id)
)

;; Read-only: get vote of a user
(define-read-only (get-vote (poll-id uint) (voter principal))
  (map-get? votes {poll-id: poll-id, voter: voter})
)

;; Read-only: get results of a poll option
(define-read-only (get-result (poll-id uint) (option uint))
  (map-get? results {poll-id: poll-id, option: option})
)

