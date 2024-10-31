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
    )
    (asserts! (> len u0) err-empty-rates)
    (let
      (
        (mid-index (/ len u2))
        (sorted-rates (fold less-than rates (list)))
      )
      (if (is-eq (mod len u2) u0)
        (/ (+ (unwrap! (element-at? sorted-rates mid-index) err-invalid-rate)
              (unwrap! (element-at? sorted-rates (- mid-index u1)) err-invalid-rate))
           u2)
        (unwrap! (element-at? sorted-rates mid-index) err-invalid-rate)))))

(define-private (less-than (rate uint) (acc (list 150 uint)))
  (let ((insert-at (find-insert-index rate acc u0)))
    (unwrap! (as-max-len? (concat (take insert-at acc) (cons rate (drop insert-at acc))) u150) acc)))

(define-private (find-insert-index (rate uint) (acc (list 150 uint)) (index uint))
  (if (or (>= index (len acc)) (< rate (default-to u0 (element-at? acc index))))
    index
    (find-insert-index rate acc (+ index u1))))

(define-private (filter-valid-rates (rates (list 150 {rate: uint, timestamp: uint})) (current-time uint) (acc (list 150 uint)))
  (match rates
    first-rate (let ((rate-entry (unwrap! (element-at? rates u0) acc)))
                 (if (< (- current-time (get timestamp rate-entry)) (var-get rate-validity-period))
                   (filter-valid-rates (unwrap! (as-max-len? (drop u1 rates) (list)) acc) 
                                       current-time 
                                       (unwrap! (as-max-len? (append acc (get rate rate-entry)) u150) acc))
                   (filter-valid-rates (unwrap! (as-max-len? (drop u1 rates) (list)) acc) 
                                       current-time 
                                       acc)))
    acc))

(define-private (get-valid-rates)
  (let
    (
      (current-time (unwrap! (get-block-info? time (- block-height u1)) err-invalid-rate))
      (all-rates (map unwrap-panic (map get-provider-rate (map-keys rate-providers))))
    )
    (filter-valid-rates all-rates current-time (list))))

(define-private (update-exchange-rate)
  (let
    (
      (valid-rates (get-valid-rates))
    )
    (asserts! (>= (len valid-rates) (var-get min-rate-providers)) err-invalid-rate)
    (let
      ((median-rate (calculate-median valid-rates)))
      (ok (var-set current-exchange-rate median-rate)))))

;; Public functions
(define-public (register-user (name (string-ascii 50)) (bank-account (string-ascii 20)))
  (begin
    (map-set user-details tx-sender {name: name, nigeria-bank-account: bank-account})
    (ok true)))

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
    (begin
      (map-set balances tx-sender (- sender-balance total-amount))
      (map-set balances recipient (+ (get-balance recipient) amount-stx))
      (map-set balances contract-owner (+ (get-balance contract-owner) fee))
      (ok naira-amount))))

(define-public (withdraw (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (asserts! (<= amount current-balance) err-insufficient-balance)
    (begin
      (map-set balances tx-sender (- current-balance amount))
      ;; Here you would typically integrate with an off-chain system or oracle
      ;; to initiate the actual bank transfer in Nigeria
      (ok true))))

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
    (update-exchange-rate)))

(define-public (set-min-rate-providers (new-min uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set min-rate-providers new-min))))

(define-public (set-rate-validity-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set rate-validity-period new-period))))
