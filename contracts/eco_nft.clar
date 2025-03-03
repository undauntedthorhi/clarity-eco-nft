;; EcoMint NFT Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-exceeds-carbon-limit (err u103))
(define-constant err-already-staked (err u104))
(define-constant err-not-staked (err u105))
(define-constant err-invalid-params (err u106))
(define-constant err-max-supply-reached (err u107))
(define-constant err-zero-value (err u108))
(define-constant max-supply u10000)
(define-constant max-reward-per-block u100)

;; Define NFT token
(define-non-fungible-token eco-nft uint)

;; Data Variables
(define-data-var carbon-limit uint u100)
(define-data-var total-minted uint u0)
(define-data-var reward-rate uint u10)

;; Data Maps
(define-map token-data uint 
  {
    owner: principal,
    carbon-footprint: uint,
    energy-consumed: uint,
    green-certified: bool,
    creation-time: uint
  }
)

(define-map staking-data uint
  {
    staked: bool,
    stake-time: uint,
    accumulated-rewards: uint
  }
)

;; Getter Functions
(define-read-only (get-token-data (token-id uint))
  (map-get? token-data token-id)
)

(define-read-only (get-staking-info (token-id uint))
  (map-get? staking-data token-id)
)

(define-read-only (get-total-minted)
  (var-get total-minted)
)

;; Admin Functions
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate max-reward-per-block) err-invalid-params)
    (var-set reward-rate new-rate)
    (print { event: "reward-rate-updated", new-rate: new-rate })
    (ok true)))

(define-public (set-carbon-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set carbon-limit new-limit)
    (print { event: "carbon-limit-updated", new-limit: new-limit })
    (ok true)))

;; Mint new NFT
(define-public (mint (carbon-footprint uint) (energy-consumed uint))
  (let
    (
      (token-id (var-get total-minted))
      (new-total (+ token-id u1))
    )
    (asserts! (> carbon-footprint u0) err-zero-value)
    (asserts! (> energy-consumed u0) err-zero-value)
    (asserts! (< token-id max-supply) err-max-supply-reached)
    (asserts! (<= carbon-footprint (var-get carbon-limit)) err-exceeds-carbon-limit)
    (try! (nft-mint? eco-nft token-id tx-sender))
    (map-set token-data token-id {
      owner: tx-sender,
      carbon-footprint: carbon-footprint,
      energy-consumed: energy-consumed,
      green-certified: (is-eco-friendly carbon-footprint energy-consumed),
      creation-time: block-height
    })
    (map-set staking-data token-id {
      staked: false,
      stake-time: u0,
      accumulated-rewards: u0
    })
    (var-set total-minted new-total)
    (print { event: "nft-minted", token-id: token-id, owner: tx-sender })
    (ok token-id)
  ))

;; Calculate staking rewards with safety checks
(define-private (calculate-rewards (token-id uint))
  (let
    (
      (staking-info (unwrap-panic (map-get? staking-data token-id)))
      (stake-time (get stake-time staking-info))
      (blocks-staked (if (>= block-height stake-time)
        (- block-height stake-time)
        u0))
    )
    (min
      (* blocks-staked (var-get reward-rate))
      (* max-reward-per-block blocks-staked)
    )
  ))
