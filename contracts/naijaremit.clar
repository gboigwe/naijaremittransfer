;; Naija Transfer - Decentralized Remittance Smart Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-transfer-failed (err u103))
(define-constant err-invalid-rate (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-empty-rates (err u106))
(define-constant err-rate-not-found (err u107))

;; Define data variables
(define-data-var transfer-fee uint u100) ;; 1% transfer fee (in basis points)
(define-data-var min-rate-providers uint u3) ;; Minimum number of rate providers required
(define-data-var rate-validity-period uint u3600) ;; Validity period for submitted rates (in seconds)
(define-data-var current-exchange-rate uint u0) ;; Current exchange rate, updated on each submission

;; Define maps
(define-map balances principal uint)
(define-map user-details 
  principal 
  {name: (string-ascii 50), 
   nigeria-bank-account: (string-ascii 20)})
(define-map rate-providers principal bool)
(define-map exchange-rates 
  principal 
  {rate: uint, timestamp: uint})

;; Read-only functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances user)))

(define-read-only (get-user-details (user principal))
  (map-get? user-details user))

(define-read-only (is-rate-provider (provider principal))
  (default-to false (map-get? rate-providers provider)))

(define-read-only (get-provider-rate (provider principal))
  (map-get? exchange-rates provider))

(define-read-only (get-current-exchange-rate)
  (ok (var-get current-exchange-rate)))

;; Private functions
(define-private (calculate-median (rates (list 150 uint)))
  (let
    (
      (len (len rates))
      (mid-index (/ len u2))
    )
    (asserts! (> len u0) err-empty-rates)
    (match (element-at? rates mid-index)
      mid-rate (ok mid-rate)
      err-rate-not-found)))

(define-private (filter-valid-rates (rates (list 150 {rate: uint, timestamp: uint})) (current-time uint))
  (let ((valid-rates (list)))
    (ok (get valid-rates
        (for-each rate-entry rates
          (if (< (- current-time (get timestamp rate-entry)) (var-get rate-validity-period))
            (map-set valid-rates (append valid-rates (get rate rate-entry)) none)
            none))))))

(define-private (get-valid-rates)
  (let
    (
      (current-time (unwrap! (get-block-info? time (- block-height u1)) err-invalid-rate))
      (all-rates (unwrap! (get-all-rates) err-invalid-rate))
    )
    (filter-valid-rates all-rates current-time)))

(define-private (update-exchange-rate)
  (let
    (
      (valid-rates (unwrap! (get-valid-rates) err-invalid-rate))
    )
    (asserts! (>= (len valid-rates) (var-get min-rate-providers)) err-invalid-rate)
    (match (calculate-median valid-rates)
      median-rate (begin
                    (var-set current-exchange-rate median-rate)
                    (ok median-rate))
      error error)))

;; Public functions
(define-public (register-user (name (string-ascii 50)) (bank-account (string-ascii 20)))
  (ok (map-set user-details tx-sender {name: name, nigeria-bank-account: bank-account})))

(define-public (deposit (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (> amount u0) err-invalid-amount)
    (ok (map-set balances tx-sender (+ current-balance amount)))))

(define-public (send-remittance (recipient principal) (amount-stx uint))
  (let 
    (
      (sender-balance (get-balance tx-sender))
      (fee (/ (* amount-stx (var-get transfer-fee)) u10000))
      (total-amount (+ amount-stx fee))
      (exchange-rate (var-get current-exchange-rate))
      (naira-amount (/ (* amount-stx exchange-rate) u10000))
    )
    (asserts! (<= total-amount sender-balance) err-insufficient-balance)
    (asserts! (is-some (get-user-details recipient)) err-transfer-failed)
    (asserts! (> exchange-rate u0) err-invalid-rate)
    (match (map-set balances tx-sender (- sender-balance total-amount))
      success (match (map-set balances recipient (+ (get-balance recipient) amount-stx))
                recipient-success (match (map-set balances contract-owner (+ (get-balance contract-owner) fee))
                                    fee-success (ok naira-amount)
                                    error err-transfer-failed)
                error err-transfer-failed)
      error err-insufficient-balance)))

(define-public (withdraw (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (<= amount current-balance) err-insufficient-balance)
    (ok (map-set balances tx-sender (- current-balance amount)))))

(define-public (submit-exchange-rate (rate uint))
  (begin
    (asserts! (is-rate-provider tx-sender) err-not-authorized)
    (let ((current-time (unwrap! (get-block-info? time (- block-height u1)) err-invalid-rate)))
      (map-set exchange-rates tx-sender {rate: rate, timestamp: current-time})
      (update-exchange-rate))))

;; Admin functions
(define-public (set-transfer-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set transfer-fee new-fee))))

(define-public (add-rate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set rate-providers provider true))))

(define-public (remove-rate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete rate-providers provider)
    (map-delete exchange-rates provider)
    (ok true)))

(define-public (set-min-rate-providers (new-min uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set min-rate-providers new-min))))

(define-public (set-rate-validity-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set rate-validity-period new-period))))

;; Utility functions
(define-public (get-all-providers)
  (ok (map-keys rate-providers)))

(define-public (get-all-rates)
  (ok (map unwrap-panic (map get-provider-rate (map-keys rate-providers)))))
