;; Naija Transfer - Decentralized Remittance Smart Contract

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-USER-NOT-REGISTERED (err u103))
(define-constant ERR-INVALID-EXCHANGE-RATE (err u104))

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var transfer-fee uint u100) ;; 1% fee (basis points)
(define-data-var exchange-rate uint u0) ;; Current NGN/STX exchange rate

;; Define maps
(define-map Balances principal uint)
(define-map Users principal 
  {name: (string-ascii 50), 
   bank-account: (string-ascii 20)})
(define-map RateProviders principal bool)

;; Read-only functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? Balances user)))

(define-read-only (get-user (user principal))
  (map-get? Users user))

(define-read-only (get-exchange-rate)
  (ok (var-get exchange-rate)))

;; Private functions
(define-private (transfer (sender principal) (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-balance sender))
      (recipient-balance (get-balance recipient))
    )
    (if (>= sender-balance amount)
      (begin
        (map-set Balances sender (- sender-balance amount))
        (map-set Balances recipient (+ recipient-balance amount))
        (ok true))
      ERR-INSUFFICIENT-BALANCE)))

;; Public functions
(define-public (register-user (name (string-ascii 50)) (bank-account (string-ascii 20)))
  (ok (map-set Users tx-sender {name: name, bank-account: bank-account})))

(define-public (deposit (amount uint))
  (let
    ((current-balance (get-balance tx-sender)))
    (if (> amount u0)
      (ok (map-set Balances tx-sender (+ current-balance amount)))
      ERR-INVALID-AMOUNT)))

(define-public (send-remittance (recipient principal) (amount-stx uint))
  (let
    (
      (sender-balance (get-balance tx-sender))
      (fee (/ (* amount-stx (var-get transfer-fee)) u10000))
      (total-amount (+ amount-stx fee))
      (exchange-rate (var-get exchange-rate))
      (naira-amount (* amount-stx exchange-rate))
    )
    (asserts! (is-some (get-user recipient)) ERR-USER-NOT-REGISTERED)
    (asserts! (>= sender-balance total-amount) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> exchange-rate u0) ERR-INVALID-EXCHANGE-RATE)
    (match (transfer tx-sender recipient amount-stx)
      success (begin
        (map-set Balances tx-sender (- sender-balance total-amount))
        (map-set Balances (var-get contract-owner) (+ (get-balance (var-get contract-owner)) fee))
        (ok naira-amount))
      error error)))

(define-public (withdraw (amount uint))
  (let
    ((current-balance (get-balance tx-sender)))
    (asserts! (<= amount current-balance) ERR-INSUFFICIENT-BALANCE)
    (ok (map-set Balances tx-sender (- current-balance amount)))))

(define-public (set-exchange-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set exchange-rate new-rate))))

;; Admin functions
(define-public (set-transfer-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set transfer-fee new-fee))))

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))))
