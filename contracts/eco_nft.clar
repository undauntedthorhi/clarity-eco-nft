;; EcoMint NFT Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-exceeds-carbon-limit (err u103))
(define-constant err-already-staked (err u104))
(define-constant err-not-staked (err u105))

;; Define NFT token
(define-non-fungible-token eco-nft uint)

;; Data Variables
(define-data-var carbon-limit uint u100)
(define-data-var total-minted uint u0)
(define-data-var reward-rate uint u10) ;; Reward tokens per block

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

;; Mint new NFT
(define-public (mint (carbon-footprint uint) (energy-consumed uint))
  (let
    (
      (token-id (var-get total-minted))
      (new-total (+ token-id u1))
    )
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
    (ok token-id)
  )
)

;; Stake NFT
(define-public (stake (token-id uint))
  (let
    (
      (token-owner (get owner (map-get? token-data token-id)))
      (staking-info (unwrap! (map-get? staking-data token-id) err-token-not-found))
    )
    (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
    (asserts! (not (get staked staking-info)) err-already-staked)
    (ok (map-set staking-data token-id
      (merge staking-info
        {
          staked: true,
          stake-time: block-height,
          accumulated-rewards: u0
        })))
  )
)

;; Unstake NFT and collect rewards
(define-public (unstake (token-id uint))
  (let
    (
      (token-owner (get owner (map-get? token-data token-id)))
      (staking-info (unwrap! (map-get? staking-data token-id) err-token-not-found))
    )
    (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
    (asserts! (get staked staking-info) err-not-staked)
    (let
      (
        (rewards (calculate-rewards token-id))
      )
      ;; TODO: Add reward token transfer here
      (ok (map-set staking-data token-id
        (merge staking-info
          {
            staked: false,
            stake-time: u0,
            accumulated-rewards: u0
          })))
    )
  )
)

;; Calculate staking rewards
(define-private (calculate-rewards (token-id uint))
  (let
    (
      (staking-info (unwrap-panic (map-get? staking-data token-id)))
      (blocks-staked (- block-height (get stake-time staking-info)))
    )
    (* blocks-staked (var-get reward-rate))
  )
)

;; Transfer NFT
(define-public (transfer (token-id uint) (recipient principal))
  (let
    (
      (token-owner (get owner (map-get? token-data token-id)))
      (staking-info (unwrap! (map-get? staking-data token-id) err-token-not-found))
    )
    (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
    (asserts! (not (get staked staking-info)) err-already-staked)
    (try! (nft-transfer? eco-nft token-id tx-sender recipient))
    (ok (map-set token-data token-id
      (merge (unwrap-panic (map-get? token-data token-id))
        { owner: recipient })))
  )
)

;; Internal function to check if NFT is eco-friendly
(define-private (is-eco-friendly (carbon uint) (energy uint))
  (and (<= carbon (var-get carbon-limit))
       (<= energy u1000))
)

;; Read only functions
(define-read-only (get-token-data (token-id uint))
  (ok (map-get? token-data token-id))
)

(define-read-only (get-carbon-footprint (token-id uint))
  (ok (get carbon-footprint (map-get? token-data token-id)))
)

(define-read-only (is-green-certified (token-id uint))
  (ok (get green-certified (map-get? token-data token-id)))
)

(define-read-only (get-staking-data (token-id uint))
  (ok (map-get? staking-data token-id))
)
