;; Naija Transfer - Decentralized Remittance System
;; Built with Clarity 2.0 (Security Enhanced)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-transfer-failed (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-invalid-exchange-rate (err u106))
(define-constant err-already-registered (err u107))
(define-constant err-invalid-input (err u108))

;; Data Variables
(define-data-var exchange-rate uint u0)
(define-data-var fee-percentage uint u100) ;; 1% fee, represented in basis points

;; Data Maps
(define-map user-balances principal uint)
(define-map user-details 
  principal 
  { name: (string-ascii 50), 
    bank-account: (string-ascii 20) })
(define-map exchange-rate-providers principal bool)

;; Read-only Functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? user-balances user)))

(define-read-only (get-user-details (user principal))
  (map-get? user-details user))

(define-read-only (get-exchange-rate)
  (ok (var-get exchange-rate)))

(define-read-only (is-exchange-rate-provider (provider principal))
  (default-to false (map-get? exchange-rate-providers provider)))

;; Private Functions
(define-private (validate-string (input (string-ascii 50)))
  (and (> (len input) u0) (<= (len input) u50)))

(define-private (validate-bank-account (account (string-ascii 20)))
  (and (> (len account) u0) (<= (len account) u20)))

;; Public Functions
(define-public (register-user (name (string-ascii 50)) (bank-account (string-ascii 20)))
  (begin
    (asserts! (is-none (get-user-details tx-sender)) err-already-registered)
    (asserts! (validate-string name) err-invalid-input)
    (asserts! (validate-bank-account bank-account) err-invalid-input)
    (ok (map-set user-details tx-sender {name: name, bank-account: bank-account}))))

(define-public (deposit (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (> amount u0) err-invalid-amount)
    (ok (map-set user-balances tx-sender (+ current-balance amount)))))

(define-public (send-remittance (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-balance tx-sender))
      (fee (/ (* amount (var-get fee-percentage)) u10000))
      (total-amount (+ amount fee))
      (current-exchange-rate (var-get exchange-rate))
    )
    (asserts! (is-some (get-user-details tx-sender)) err-not-registered)
    (asserts! (is-some (get-user-details recipient)) err-not-registered)
    (asserts! (>= sender-balance total-amount) err-insufficient-balance)
    (asserts! (> current-exchange-rate u0) err-invalid-exchange-rate)
    (try! (stx-transfer? amount tx-sender recipient))
    (try! (stx-transfer? fee tx-sender contract-owner))
    (map-set user-balances tx-sender (- sender-balance total-amount))
    (ok (/ (* amount current-exchange-rate) u100000000)))) ;; Return Naira amount, assuming 8 decimal places

(define-public (withdraw (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount contract-owner tx-sender)))
    (ok (map-set user-balances tx-sender (- current-balance amount)))))

(define-public (set-exchange-rate (new-rate uint))
  (begin
    (asserts! (is-exchange-rate-provider tx-sender) err-unauthorized)
    (asserts! (> new-rate u0) err-invalid-exchange-rate)
    (ok (var-set exchange-rate new-rate))))

;; Admin Functions
(define-public (set-fee-percentage (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee-percentage u10000) err-invalid-amount) ;; Ensure fee is not more than 100%
    (ok (var-set fee-percentage new-fee-percentage))))

(define-public (add-exchange-rate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? exchange-rate-providers provider)) err-invalid-input)
    (ok (map-set exchange-rate-providers provider true))))

(define-public (remove-exchange-rate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? exchange-rate-providers provider)) err-invalid-input)
    (ok (map-delete exchange-rate-providers provider))))
