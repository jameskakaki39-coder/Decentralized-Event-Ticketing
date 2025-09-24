(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_EVENT (err u101))
(define-constant ERR_INVALID_TICKET (err u102))
(define-constant ERR_EVENT_NOT_ACTIVE (err u103))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u104))
(define-constant ERR_SOLD_OUT (err u105))
(define-constant ERR_PURCHASE_LIMIT (err u106))
(define-constant ERR_TRANSFER_COOLDOWN (err u107))
(define-constant ERR_PRICE_CEILING (err u108))
(define-constant ERR_SAME_OWNER (err u109))
(define-constant ERR_NOT_OWNER (err u110))

(define-data-var next-event-id uint u0)
(define-data-var next-ticket-id uint u0)

(define-map events
  { event-id: uint }
  {
    organizer: principal,
    name: (string-ascii 256),
    description: (string-ascii 512),
    location: (string-ascii 256),
    event-date: uint,
    price: uint,
    total-supply: uint,
    available-tickets: uint,
    status: uint,
    max-per-address: uint,
    resale-price-ceiling: uint
  }
)

(define-map tickets
  { ticket-id: uint }
  {
    event-id: uint,
    owner: principal,
    original-owner: principal,
    purchase-block: uint,
    purchase-price: uint,
    seat-number: uint
  }
)

(define-map user-tickets
  { user: principal, event-id: uint }
  { count: uint }
)

(define-map event-tickets
  { event-id: uint, seat-number: uint }
  { ticket-id: uint }
)

(define-map user-last-purchase
  { user: principal }
  { block-height: uint }
)

(define-public (create-event 
  (name (string-ascii 256))
  (description (string-ascii 512))
  (location (string-ascii 256))
  (event-date uint)
  (price uint)
  (total-supply uint)
  (max-per-address uint)
  (resale-price-ceiling uint))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (asserts! (> total-supply u0) ERR_INVALID_EVENT)
    (asserts! (> max-per-address u0) ERR_INVALID_EVENT)
    (asserts! (>= resale-price-ceiling price) ERR_INVALID_EVENT)
    (asserts! (> event-date stacks-block-height) ERR_INVALID_EVENT)
    
    (map-set events
      { event-id: event-id }
      {
        organizer: tx-sender,
        name: name,
        description: description,
        location: location,
        event-date: event-date,
        price: price,
        total-supply: total-supply,
        available-tickets: total-supply,
        status: u1,
        max-per-address: max-per-address,
        resale-price-ceiling: resale-price-ceiling
      }
    )
    
    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

(define-public (purchase-ticket (event-id uint) (seat-number uint))
  (let
    (
      (event (unwrap! (map-get? events { event-id: event-id }) ERR_INVALID_EVENT))
      (ticket-id (var-get next-ticket-id))
      (user-ticket-count (default-to { count: u0 } (map-get? user-tickets { user: tx-sender, event-id: event-id })))
      (last-purchase (map-get? user-last-purchase { user: tx-sender }))
    )
    
    (asserts! (is-eq (get status event) u1) ERR_EVENT_NOT_ACTIVE)
    (asserts! (> (get available-tickets event) u0) ERR_SOLD_OUT)
    (asserts! (< (get count user-ticket-count) (get max-per-address event)) ERR_PURCHASE_LIMIT)
    (asserts! (is-none (map-get? event-tickets { event-id: event-id, seat-number: seat-number })) ERR_INVALID_TICKET)
    
    (match last-purchase
      purchase-data (asserts! (>= stacks-block-height (+ (get block-height purchase-data) u10)) ERR_TRANSFER_COOLDOWN)
      true
    )
    
    (try! (stx-transfer? (get price event) tx-sender (get organizer event)))
    
    (map-set tickets
      { ticket-id: ticket-id }
      {
        event-id: event-id,
        owner: tx-sender,
        original-owner: tx-sender,
        purchase-block: stacks-block-height,
        purchase-price: (get price event),
        seat-number: seat-number
      }
    )
    
    (map-set event-tickets
      { event-id: event-id, seat-number: seat-number }
      { ticket-id: ticket-id }
    )
    
    (map-set user-tickets
      { user: tx-sender, event-id: event-id }
      { count: (+ (get count user-ticket-count) u1) }
    )
    
    (map-set user-last-purchase
      { user: tx-sender }
      { block-height: stacks-block-height }
    )
    
    (map-set events
      { event-id: event-id }
      (merge event { available-tickets: (- (get available-tickets event) u1) })
    )
    
    (var-set next-ticket-id (+ ticket-id u1))
    (ok ticket-id)
  )
)

(define-public (transfer-ticket (ticket-id uint) (new-owner principal) (price uint))
  (let
    (
      (ticket (unwrap! (map-get? tickets { ticket-id: ticket-id }) ERR_INVALID_TICKET))
      (event (unwrap! (map-get? events { event-id: (get event-id ticket) }) ERR_INVALID_EVENT))
      (current-owner (get owner ticket))
      (holding-period u144)
    )
    
    (asserts! (is-eq tx-sender current-owner) ERR_NOT_OWNER)
    (asserts! (not (is-eq current-owner new-owner)) ERR_SAME_OWNER)
    (asserts! (>= stacks-block-height (+ (get purchase-block ticket) holding-period)) ERR_TRANSFER_COOLDOWN)
    (asserts! (<= price (get resale-price-ceiling event)) ERR_PRICE_CEILING)
    
    (if (> price u0)
      (try! (stx-transfer? price new-owner current-owner))
      true
    )
    
    (let
      (
        (current-user-count (default-to { count: u0 } (map-get? user-tickets { user: current-owner, event-id: (get event-id ticket) })))
        (new-user-count (default-to { count: u0 } (map-get? user-tickets { user: new-owner, event-id: (get event-id ticket) })))
      )
      
      (map-set user-tickets
        { user: current-owner, event-id: (get event-id ticket) }
        { count: (- (get count current-user-count) u1) }
      )
      
      (map-set user-tickets
        { user: new-owner, event-id: (get event-id ticket) }
        { count: (+ (get count new-user-count) u1) }
      )
    )
    
    (map-set tickets
      { ticket-id: ticket-id }
      (merge ticket { owner: new-owner })
    )
    
    (ok true)
  )
)

(define-public (cancel-event (event-id uint))
  (let
    (
      (event (unwrap! (map-get? events { event-id: event-id }) ERR_INVALID_EVENT))
    )
    
    (asserts! (is-eq tx-sender (get organizer event)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status event) u1) ERR_EVENT_NOT_ACTIVE)
    
    (map-set events
      { event-id: event-id }
      (merge event { status: u0 })
    )
    
    (ok true)
  )
)

(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

(define-read-only (get-ticket (ticket-id uint))
  (map-get? tickets { ticket-id: ticket-id })
)

(define-read-only (get-user-ticket-count (user principal) (event-id uint))
  (default-to u0 (get count (map-get? user-tickets { user: user, event-id: event-id })))
)

(define-read-only (get-ticket-by-seat (event-id uint) (seat-number uint))
  (map-get? event-tickets { event-id: event-id, seat-number: seat-number })
)

(define-read-only (get-next-event-id)
  (var-get next-event-id)
)

(define-read-only (get-next-ticket-id)
  (var-get next-ticket-id)
)

(define-read-only (is-ticket-transferable (ticket-id uint))
  (match (map-get? tickets { ticket-id: ticket-id })
    ticket (>= stacks-block-height (+ (get purchase-block ticket) u144))
    false
  )
)

(define-read-only (get-user-last-purchase-block (user principal))
  (match (map-get? user-last-purchase { user: user })
    purchase-data (some (get block-height purchase-data))
    none
  )
)

(define-read-only (can-user-purchase (user principal) (event-id uint))
  (match (map-get? events { event-id: event-id })
    event
      (let
        (
          (user-count (get-user-ticket-count user event-id))
          (last-purchase (get-user-last-purchase-block user))
        )
        (and
          (is-eq (get status event) u1)
          (> (get available-tickets event) u0)
          (< user-count (get max-per-address event))
          (match last-purchase
            purchase-block (>= stacks-block-height (+ purchase-block u10))
            true
          )
        )
      )
    false
  )
)