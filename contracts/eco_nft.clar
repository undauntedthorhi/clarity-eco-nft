;; EcoMint NFT Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-exceeds-carbon-limit (err u103))

;; Define NFT token
(define-non-fungible-token eco-nft uint)

;; Data Variables
(define-data-var carbon-limit uint u100)
(define-data-var total-minted uint u0)

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
    (var-set total-minted new-total)
    (ok token-id)
  )
)

;; Transfer NFT
(define-public (transfer (token-id uint) (recipient principal))
  (let
    (
      (token-owner (get owner (map-get? token-data token-id)))
    )
    (asserts! (is-eq tx-sender token-owner) err-not-token-owner)
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