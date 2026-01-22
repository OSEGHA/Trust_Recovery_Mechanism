# Trust Recovery Mechanism Smart Contract

A Clarity smart contract for the Stacks blockchain that manages user trust scores with gradual restoration and penalty logic. This contract is designed to support systems where trust must be regained over time after penalties, with configurable intervals and limits.

---

## Features

- **Trust Score Tracking:** Each user has a trust score, last action block, recovery action count, and penalty count.
- **Gradual Trust Recovery:** Users can recover trust incrementally, but only after a minimum block interval.
- **Penalty Enforcement:** Admins can reduce a user's trust score and record penalties.
- **Admin Controls:** Admin can reset user records and transfer admin rights.
- **Configurable Parameters:** Trust limits, recovery intervals, and increments are easily adjustable.

---

## Contract Overview

- **Trust Map:**  
  Stores each user's trust state:
  - `trust-score`: Current trust value (uint)
  - `last-action`: Block height of last trust action (uint)
  - `recovery-actions`: Number of successful recoveries (uint)
  - `penalties`: Number of penalties received (uint)

- **Admin:**  
  The contract deployer is the initial admin. Admin rights can be transferred.

---

## Key Functions

### Read-Only

- `get-trust (user)`: Returns the full trust record for a user.
- `get-trust-score (user)`: Returns only the trust score.
- `is-trusted (user)`: Returns `true` if the user has a positive trust score.

### Public

- `init-user`: Initializes the caller's trust record (optional, auto-initialized on penalty).
- `apply-penalty (user)`: Admin-only. Reduces trust and records a penalty.
- `recover-trust`: Allows the caller to recover trust if enough blocks have passed since the last action.
- `reset-user (user)`: Admin-only. Deletes a user's trust record.
- `set-admin (new-admin)`: Admin-only. Transfers admin rights.

---

## Error Codes

- `u400` - Action attempted too soon (not enough blocks since last recovery)
- `u401` - User not found
- `u402` - Not authorized (admin-only function)
- `u403` - Maximum trust already reached

---

## Configuration Constants

- `MAX-TRUST`: Maximum trust score (default: 10)
- `RECOVERY-GAP`: Minimum blocks between recoveries (default: 144, ~1 day)
- `RECOVERY-INCREMENT`: Trust gained per recovery (default: 1)
- `PENALTY-DECREMENT`: Trust lost per penalty (default: 2)

---

## Usage

1. **Initialize Trust (optional):**
   ```
   (contract-call? .Trust_Recovery_Mechanism init-user)
   ```

2. **Recover Trust:**
   ```
   (contract-call? .Trust_Recovery_Mechanism recover-trust)
   ```

3. **Apply Penalty (admin only):**
   ```
   (contract-call? .Trust_Recovery_Mechanism apply-penalty '<user-principal>)
   ```

4. **Reset User (admin only):**
   ```
   (contract-call? .Trust_Recovery_Mechanism reset-user '<user-principal>)
   ```

5. **Transfer Admin Rights (admin only):**
   ```
   (contract-call? .Trust_Recovery_Mechanism set-admin '<new-admin-principal>)
   ```

---

## Deployment

Deploy the contract to the Stacks blockchain using the Clarity CLI or your preferred deployment tool.

---

## License

MIT License
