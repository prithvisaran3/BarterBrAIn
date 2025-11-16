# Negotiation Flow Implementation Plan

## 🎯 Objective
Fix critical logic flaws in trade completion and payment flow:
1. ❌ Trade shouldn't complete until payment succeeds
2. ❌ One user can't unilaterally complete negotiation
3. ❌ Wrong person initiates payment (payee shouldn't initiate)

---

## 📋 Current Status

### ✅ COMPLETED:
- [x] Updated `TradeModel` with new fields:
  - `negotiationStatus`: 'negotiating', 'awaiting_confirmation', 'awaiting_payment', 'completed'
  - `completionRequestedBy`: User ID who requested completion
  - `agreedAmount`: Amount both parties agreed on
- [x] Added helper methods to TradeModel
- [x] Updated fromFirestore, toFirestore, copyWith methods

### 🔄 IN PROGRESS:
- [ ] Update Firestore rules for new fields
- [ ] Create new notification types
- [ ] Rewrite ChatDetailView complete negotiation flow
- [ ] Implement payment request system
- [ ] Ensure trade completes only after payment success

---

## 🔄 NEW NEGOTIATION FLOW

### **Scenario 1: Direct Swap (No Money)**

```mermaid
User A → Clicks "Complete Negotiation"
  ↓
Trade: negotiationStatus = 'awaiting_confirmation'
Trade: completionRequestedBy = User A's ID
  ↓
User B → Gets Notification → Opens Chat
  ↓
User B Sees: "User A wants to complete. Accept?"
  ↓
If Accept → Trade completes immediately ✅
If Decline → Back to negotiating
```

**Implementation:**
1. User A clicks button → Update trade:
   ```dart
   negotiationStatus: 'awaiting_confirmation'
   completionRequestedBy: currentUserId
   ```
2. Send notification to User B:
   ```dart
   type: 'completion_request'
   ```
3. User B clicks notification → Shows dialog:
   - "User A wants to complete this trade. Do you agree?"
   - [Accept] [Continue Negotiating]
4. If Accept → Complete trade:
   ```dart
   status: 'completed'
   negotiationStatus: 'completed'
   completedAt: now()
   ```

---

### **Scenario 2: Trade with Money (Payee Receives)**

```mermaid
User A → Clicks "Complete Negotiation"
  ↓
Trade: negotiationStatus = 'awaiting_confirmation'
  ↓
User B → Gets Notification → Opens Chat
  ↓
User B Sees: "User A wants to complete. Accept?"
  ↓
If Accept + Money Involved:
  ↓
Payee → Enters agreed amount → Sends payment request
  ↓
Trade: negotiationStatus = 'awaiting_payment'
Trade: agreedAmount = entered amount
  ↓
Payer → Gets Notification → Opens payment dialog
  ↓
Payer: [Pay Now] [Pay at Exchange] [Decline]
  ↓
If Pay Now → Process payment
  ↓
If Payment Success → Complete trade ✅
If Payment Fails → Back to awaiting_payment ❌
```

**Implementation:**
1. **Initial Request** (same as Scenario 1)

2. **User B Accepts + Money Required:**
   - Determine who is payee vs payer
   - If current user is **payee**:
     - Show dialog: "Enter the amount agreed upon"
     - After entering amount → Update trade:
       ```dart
       negotiationStatus: 'awaiting_payment'
       agreedAmount: enteredAmount
       ```
     - Send notification to payer:
       ```dart
       type: 'payment_request'
       amount: agreedAmount
       ```
   - If current user is **payer**:
     - Show waiting message: "Waiting for other party to confirm amount"

3. **Payer Receives Payment Request:**
   - Notification shows: "User A requests $XX payment"
   - Click notification → Opens payment dialog:
     - "User A requests $XX to complete the trade"
     - [Pay Now] [Pay at Exchange] [Decline]

4. **Payment Processing:**
   - If "Pay Now":
     - Call Nessie API
     - **ONLY if payment succeeds**:
       ```dart
       isPaid: true
       status: 'completed'
       negotiationStatus: 'completed'
       completedAt: now()
       ```
     - If payment fails → Stay in 'awaiting_payment'
   - If "Pay at Exchange":
     ```dart
     paymentType: 'at_exchange'
     status: 'completed'
     negotiationStatus: 'completed'
     completedAt: now()
     ```
   - If "Decline":
     ```dart
     negotiationStatus: 'negotiating'
     completionRequestedBy: null
     agreedAmount: null
     ```

---

## 📱 UI CHANGES NEEDED

### ChatDetailView (Complete Negotiation Button)

**Current State:**
- Shows green checkmark
- One click completes trade immediately ❌

**New States:**

1. **Negotiating** (default):
   - Button: Green checkmark
   - Label: "Complete Negotiation"
   - Action: Send completion request

2. **Awaiting Your Response** (other user requested):
   - Button: Orange, pulsing animation
   - Label: "Respond to Completion Request"
   - Action: Show accept/decline dialog

3. **Waiting for Response** (you requested):
   - Button: Gray
   - Label: "Waiting for Response..."
   - Disabled

4. **Awaiting Payment** (payer perspective):
   - Button: Blue, animated
   - Label: "Pay to Complete"
   - Action: Open payment dialog

5. **Awaiting Payment** (payee perspective):
   - Button: Gray
   - Label: "Waiting for Payment..."
   - Disabled

6. **Completed**:
   - Button: Gray checkmark
   - Label: "Trade Completed"
   - Disabled

---

## 🔔 NEW NOTIFICATION TYPES

### 1. Completion Request
```dart
{
  type: 'completion_request',
  title: '{userName} wants to complete negotiation',
  message: 'Tap to respond',
  tradeId: '...',
  chatId: '...',
  requesterId: '...',
}
```

### 2. Payment Request
```dart
{
  type: 'payment_request',
  title: 'Payment request from {userName}',
  message: 'Amount: ${amount}',
  tradeId: '...',
  chatId: '...',
  amount: 100.00,
  payeeId: '...',
}
```

### 3. Completion Declined
```dart
{
  type: 'completion_declined',
  title: '{userName} wants to continue negotiating',
  message: 'Keep chatting to reach an agreement',
  tradeId: '...',
  chatId: '...',
}
```

### 4. Trade Completed
```dart
{
  type: 'trade_completed',
  title: 'Trade completed successfully! 🎉',
  message: 'Coordinate your meetup',
  tradeId: '...',
  chatId: '...',
}
```

---

## 🔒 FIRESTORE RULES UPDATE

```javascript
match /trades/{tradeId} {
  allow update: if isAuthenticated() &&
                   (request.auth.uid == resource.data.initiatorUserId ||
                    request.auth.uid == resource.data.recipientUserId) &&
                   // Allow updating negotiation fields
                   (request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['negotiationStatus', 'completionRequestedBy', 
                              'agreedAmount', 'updatedAt', 'status', 'isPaid',
                              'completedAt', 'paymentType', 'nessieTransferId',
                              'sustainabilityImpact']));
}
```

---

## 📝 IMPLEMENTATION CHECKLIST

### Phase 1: Core Logic (PRIORITY)
- [x] Update TradeModel
- [ ] Update Firestore rules
- [ ] Create notification helper methods
- [ ] Rewrite `_showCompleteTradeDialog` in ChatDetailView
- [ ] Implement `_handleCompletionRequest` method
- [ ] Implement `_handleCompletionResponse` method
- [ ] Implement `_handlePaymentRequest` method

### Phase 2: UI Updates
- [ ] Update complete negotiation button states
- [ ] Create completion request dialog
- [ ] Create payment request dialog  
- [ ] Add completion status indicators
- [ ] Update notification handling

### Phase 3: Payment Integration
- [ ] Modify payment flow to check negotiationStatus
- [ ] Ensure trade completes ONLY after payment success
- [ ] Handle payment failures gracefully
- [ ] Update transaction records

### Phase 4: Testing
- [ ] Test direct swap flow
- [ ] Test payment flow (payee → payer)
- [ ] Test declining completion
- [ ] Test payment failures
- [ ] Test notification delivery

---

## 🎯 KEY PRINCIPLES

1. **Two-Party Agreement Required**: Both users must agree before trade completes
2. **Payee Controls Amount**: Person receiving money enters the agreed amount
3. **Payer Controls Payment**: Person paying decides when and how to pay
4. **Payment Success = Trade Complete**: Trade status changes ONLY after successful payment
5. **Clear Communication**: Users always know what state negotiation is in

---

## 🚀 NEXT STEPS

1. Update Firestore rules
2. Implement notification helpers
3. Rewrite ChatDetailView complete negotiation logic
4. Test end-to-end flows
5. Deploy and monitor

---

*Last Updated: [Current Date]*
*Status: Phase 1 - Core Logic Implementation*

