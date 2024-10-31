;; Naija Transfer - Remittance Smart Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-transfer-failed (err u103))

;; Define data variables
(define-data-var exchange-rate uint u400) ;; 1 STX = 400 Naira (example rate)
(define-data-var transfer-fee uint u1) ;; 1% transfer fee

;; Define maps
(define-map balances principal uint)
(define-map user-details 
  principal 
  {name: (string-ascii 50), 
   nigeria-bank-account: (string-ascii 20)})

;; Read-only functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances user)))

(define-read-only (get-exchange-rate)
  (ok (var-get exchange-rate)))

(define-read-only (get-user-details (user principal))
  (map-get? user-details user))

;; Public functions
(define-public (register-user (name (string-ascii 50)) (bank-account (string-ascii 20)))
  (begin
    (map-set user-details tx-sender {name: name, nigeria-bank-account: bank-account})
    (ok true)))

(define-public (deposit (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (if (> amount u0)
      (begin
        (map-set balances tx-sender (+ current-balance amount))
        (ok true))
      (err err-invalid-amount))))

(define-public (send-remittance (recipient principal) (amount-stx uint))
  (let 
    (
      (sender-balance (get-balance tx-sender))
      (fee (/ (* amount-stx (var-get transfer-fee)) u100))
      (total-amount (+ amount-stx fee))
    )
    (if (<= total-amount sender-balance)
      (if (is-some (get-user-details recipient))
        (begin
          (map-set balances tx-sender (- sender-balance total-amount))
          (map-set balances recipient (+ (get-balance recipient) amount-stx))
          (map-set balances contract-owner (+ (get-balance contract-owner) fee))
          (ok true))
        (err err-transfer-failed))
      (err err-insufficient-balance))))

(define-public (withdraw (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (if (<= amount current-balance)
      (begin
        (map-set balances tx-sender (- current-balance amount))
        ;; Here you would typically integrate with an off-chain system or oracle
        ;; to initiate the actual bank transfer in Nigeria
        (ok true))
      (err err-insufficient-balance))))

;; Admin functions
(define-public (set-exchange-rate (new-rate uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set exchange-rate new-rate)
      (ok true))
    (err err-owner-only)))

(define-public (set-transfer-fee (new-fee uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set transfer-fee new-fee)
      (ok true))
    (err err-owner-only)))
