# 🎟️ Decentralized Event Ticketing

A smart contract system for issuing and transferring event tickets, preventing scalping and fraud on the Stacks blockchain.

## 🚀 Features

- **🎉 Event Creation**: Organizers can create events with customizable parameters
- **🎫 Ticket Purchase**: Users can buy tickets with built-in purchase limits
- **🔒 Anti-Scalping**: Multiple mechanisms to prevent scalping:
  - Per-address purchase limits
  - Minimum holding period (144 blocks ≈ 24 hours)
  - Resale price ceiling
  - Purchase cooldown between transactions (10 blocks ≈ 2.5 hours)
- **🔄 Secure Transfers**: Controlled ticket transfers with fraud prevention
- **💰 Direct Payments**: STX payments go directly to event organizers
- **📊 Event Management**: Organizers can cancel events when needed

## 🛠️ Setup

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/stacks-cli/overview) for deployment
- Node.js (for testing)

### Installation

```bash
git clone https://github.com/your-username/Decentralized-Event-Ticketing.git
cd Decentralized-Event-Ticketing
npm install
```

### Development

```bash
# Check contract syntax
clarinet check

# Run tests
npm test

# Start local development environment
clarinet integrate
```

## 📋 Contract Functions

### Public Functions

#### `create-event`
Creates a new event with specified parameters.

```clarity
(contract-call? .ticket create-event 
  "Concert 2024"                    ;; name
  "Amazing live music experience"    ;; description  
  "Madison Square Garden"           ;; location
  u1000000                         ;; event-date (block height)
  u50000000                        ;; price (microSTX)
  u1000                            ;; total-supply
  u4                               ;; max-per-address
  u75000000)                       ;; resale-price-ceiling
```

#### `purchase-ticket`
Purchases a ticket for a specific event and seat.

```clarity
(contract-call? .ticket purchase-ticket u0 u42)  ;; event-id, seat-number
```

#### `transfer-ticket`
Transfers a ticket to another user (after holding period).

```clarity
(contract-call? .ticket transfer-ticket u123 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u60000000)
```

#### `cancel-event`
Allows event organizers to cancel their events.

```clarity
(contract-call? .ticket cancel-event u0)
```

### Read-Only Functions

#### `get-event`
Returns event details by ID.

```clarity
(contract-call? .ticket get-event u0)
```

#### `get-ticket`
Returns ticket details by ID.

```clarity
(contract-call? .ticket get-ticket u123)
```

#### `can-user-purchase`
Checks if a user can purchase tickets for an event.

```clarity
(contract-call? .ticket can-user-purchase 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u0)
```

#### `is-ticket-transferable`
Checks if a ticket can be transferred.

```clarity
(contract-call? .ticket is-ticket-transferable u123)
```

## 🔐 Anti-Scalping & Security Features

### Purchase Limits
- **Per-Address Limit**: Configurable maximum tickets per address per event
- **Supply Limit**: Hard cap on total tickets available

### Transfer Restrictions
- **Holding Period**: 144 blocks (≈ 24 hours) minimum before transfer
- **Price Ceiling**: Resale price cannot exceed organizer-set maximum
- **Ownership Verification**: Only ticket owners can transfer their tickets

### Bot Prevention
- **Purchase Cooldown**: 10 blocks (≈ 2.5 hours) between purchases per user
- **Transaction Verification**: All purchases require valid STX payment
- **Seat Assignment**: Prevents duplicate ticket creation for same seat

## 📁 Project Structure

```
Decentralized-Event-Ticketing/
├── 📄 README.md
├── ⚙️ Clarinet.toml
├── 📦 package.json
├── 🔧 tsconfig.json
├── 🧪 vitest.config.js
├── 📁 contracts/
│   └── 🎟️ Ticket.clar
├── 📁 tests/
│   └── 🧪 Ticket.test.ts
└── 📁 settings/
    └── ⚙️ Devnet.toml
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test Ticket.test.ts

# Run tests in watch mode
npm run test:watch
```

## 🚀 Deployment

### Testnet Deployment

```bash
# Deploy to testnet
stx deploy contracts/Ticket.clar --testnet --fee 2000

# Verify deployment
stx call-read-only SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7.ticket get-next-event-id --testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet (use with caution)
stx deploy contracts/Ticket.clar --mainnet --fee 5000
```

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `ERR_NOT_AUTHORIZED` | Caller is not authorized for this action |
| `u101` | `ERR_INVALID_EVENT` | Event does not exist or invalid parameters |
| `u102` | `ERR_INVALID_TICKET` | Ticket does not exist or invalid |
| `u103` | `ERR_EVENT_NOT_ACTIVE` | Event is cancelled or inactive |
| `u104` | `ERR_INSUFFICIENT_PAYMENT` | Payment amount is insufficient |
| `u105` | `ERR_SOLD_OUT` | No more tickets available |
| `u106` | `ERR_PURCHASE_LIMIT` | User has reached purchase limit |
| `u107` | `ERR_TRANSFER_COOLDOWN` | Transfer attempted before holding period |
| `u108` | `ERR_PRICE_CEILING` | Resale price exceeds maximum allowed |
| `u109` | `ERR_SAME_OWNER` | Cannot transfer to the same owner |
| `u110` | `ERR_NOT_OWNER` | Only ticket owner can transfer |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarinet Documentation](https://docs.hiro.so/stacks/clarinet)
- [Clarity Language Reference](https://docs.stacks.co/stacks/clarity)

---

Built with ❤️ on Stacks blockchain