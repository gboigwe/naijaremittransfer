;; Naija Transfer - Decentralized Remittance Smart Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-transfer-failed (err u103))
(define-constant err-invalid-rate (err u104))
(define-constant err-not-authorized (err u105))

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
      (sorted-rates (fold less-than rates (list)))
    )
    (if (is-eq (mod len u2) u0)
      (/ (+ (unwrap-panic (element-at? sorted-rates mid-index))
            (unwrap-panic (element-at? sorted-rates (- mid-index u1))))
         u2)
      (unwrap-panic (element-at? sorted-rates mid-index)))))

(define-private (less-than (rate uint) (acc (list 150 uint)))
  (let ((insert-at (find-insert-index rate acc u0)))
    (unwrap-panic (as-max-len? (concat (take insert-at acc) (append (list rate) (drop insert-at acc))) u150))))

(define-private (find-insert-index (rate uint) (acc (list 150 uint)) (index uint))
  (if (or (>= index (len acc)) (< rate (unwrap-panic (element-at? acc index))))
    index
    (find-insert-index rate acc (+ index u1))))

(define-private (update-exchange-rate)
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (valid-rates (filter-valid-rates (map-to-list exchange-rates) current-time (list)))
    )
    (if (>= (len valid-rates) (var-get min-rate-providers))
      (let
        ((median-rate (calculate-median valid-rates)))
        (var-set current-exchange-rate median-rate)
        (ok median-rate))
      (err err-invalid-rate))))

(define-private (filter-valid-rates (rates (list 150 {provider: principal, rate: {rate: uint, timestamp: uint}})) (current-time uint) (acc (list 150 uint)))
  (match rates
    rates-tail:rest
    (let ((rate (get rate (get rate (unwrap! (element-at? rates u0) acc)))))
      (if (< (- current-time (get timestamp (get rate (unwrap! (element-at? rates u0) acc)))) (var-get rate-validity-period))
        (filter-valid-rates rates-tail current-time (unwrap! (as-max-len? (append acc rate) u150) acc))
        (filter-valid-rates rates-tail current-time acc)))
    acc))

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
      (fee (/ (* amount-stx (var-get transfer-fee)) u10000))
      (total-amount (+ amount-stx fee))
      (exchange-rate (unwrap! (update-exchange-rate) err-invalid-rate))
      (naira-amount (/ (* amount-stx exchange-rate) u10000))
    )
    (if (<= total-amount sender-balance)
      (if (is-some (get-user-details recipient))
        (begin
          (map-set balances tx-sender (- sender-balance total-amount))
          (map-set balances recipient (+ (get-balance recipient) amount-stx))
          (map-set balances contract-owner (+ (get-balance contract-owner) fee))
          (ok naira-amount))
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

(define-public (submit-exchange-rate (rate uint))
  (if (is-rate-provider tx-sender)
    (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
      (begin
        (map-set exchange-rates tx-sender {rate: rate, timestamp: current-time})
        (update-exchange-rate)))
    (err err-not-authorized)))

;; Admin functions
(define-public (set-transfer-fee (new-fee uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set transfer-fee new-fee)
      (ok true))
    (err err-owner-only)))

(define-public (add-rate-provider (provider principal))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set rate-providers provider true)
      (ok true))
    (err err-owner-only)))

(define-public (remove-rate-provider (provider principal))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-delete rate-providers provider)
      (map-delete exchange-rates provider)
      (update-exchange-rate))
    (err err-owner-only)))

(define-public (set-min-rate-providers (new-min uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set min-rate-providers new-min)
      (ok true))
    (err err-owner-only)))

(define-public (set-rate-validity-period (new-period uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set rate-validity-period new-period)
      (ok true))
    (err err-owner-only)))
