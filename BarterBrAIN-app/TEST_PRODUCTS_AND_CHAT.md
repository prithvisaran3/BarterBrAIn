# 🧪 Quick Test Guide - Products & Chat

## ✅ All Firestore Rules, Indexes, and Storage Rules Deployed!

**Status**: All systems operational ✅

---

## 📦 Test 1: Add a Product (2 minutes)

### Steps:
1. **Open the app** on your iOS simulator/device
2. **Tap the "+" tab** (Add Product)
3. **Add 3 images**:
   - Tap the camera icon
   - Select "Gallery" (or Camera if available)
   - Choose an image
   - Repeat for 2nd and 3rd slots
4. **Fill product details**:
   - Name: "iPhone 14 Pro"
   - Details: "Great condition, barely used"
   - Brand: "Apple"
   - Age: "6" (months)
   - Product Link: (leave empty or add a link)
   - Condition: Select "Good"
5. **Click "Set Price"**
6. **Wait for AI** (6-14 seconds with fun messages) or skip if AI unavailable
7. **Set price**: Enter "800" or accept AI suggestion
8. **Click "List Product"** (or "Accept AI Price")

### ✅ Expected Results:
- ✅ Success message appears
- ✅ Product appears in Firestore Console: `https://console.firebase.google.com/project/barterbrain-1254a/firestore/data/~2Fproducts`
- ✅ Images appear in Storage: `https://console.firebase.google.com/project/barterbrain-1254a/storage/files`
- ✅ You're taken back to the home screen

### 🐛 If it fails:
- Check console for errors
- Ensure `isVerifiedEdu = true` in your user document
- Check image picker permissions on iOS simulator (try drag & drop)

---

## 🏠 Test 2: View Products in Home (1 minute)

### Steps:
1. **Tap the "Home" tab**
2. **Scroll down to "Featured Products"**
3. **Look for products from other users**

### ✅ Expected Results:
- ✅ You see products (if there are any from other users)
- ✅ You DON'T see your own product
- ✅ Each product shows:
  - Product image
  - Product name
  - Price
  - Brand
  - Condition badge

### 🐛 If no products appear:
- **Check console**: Look for index errors like:
  ```
  [cloud_firestore/failed-precondition] The query requires an index
  ```
- **If index error**: Firebase will show a link in the error. Click it to auto-create the index.
- **Wait 1-2 minutes** for the index to build
- **Hot restart the app** (press `R` in the terminal)

### 💡 Test with Multiple Users:
To properly test, you need 2+ users:
1. Create a second user account (signup with different email)
2. Add a product from User 2
3. Switch back to User 1
4. User 1 should now see User 2's product in the home view

---

## 💬 Test 3: Start a Chat (2 minutes)

### Prerequisites:
- Need 2 user accounts
- User 2 must have at least 1 product listed

### Steps (as User 1):
1. **Go to Home tab**
2. **Tap on User 2's product**
3. **Tap "Start Chat"** button
4. **Type a message**: "Hi, is this still available?"
5. **Tap send button** (paper airplane icon)

### ✅ Expected Results:
- ✅ Chat is created in Firestore: `https://console.firebase.google.com/project/barterbrain-1254a/firestore/data/~2Fchats`
- ✅ Message appears in the chat: `chats/{chatId}/messages/{messageId}`
- ✅ Message displays in the chat view
- ✅ User 2 gets a notification (check bell icon)

---

## 💬 Test 4: Chat Features (3 minutes)

### Test Text Messages:
1. **Send a few messages** back and forth (switch between User 1 and User 2)
2. **Check real-time updates**: Messages should appear instantly

### Test Emojis:
1. **Tap the emoji icon** (smiley face next to message input)
2. **Select an emoji**
3. **Send it**
4. ✅ Emoji appears in chat

### Test Image Messages:
1. **Tap the camera icon**
2. **Select "Gallery"**
3. **Choose an image**
4. **Wait for upload**
5. ✅ Image appears in chat
6. ✅ Tap image to view full screen

### Test Chat Navigation:
1. **Go back to Chat tab**
2. ✅ Chat appears in the list
3. ✅ Shows last message preview
4. ✅ Shows timestamp
5. ✅ Shows unread count (if any)

---

## 🔔 Test 5: Notifications (1 minute)

### Steps:
1. **As User 1, send a message to User 2**
2. **Switch to User 2's device/simulator**
3. **Tap the bell icon** (top right of home screen)

### ✅ Expected Results:
- ✅ Notification appears: "New message from [User 1]"
- ✅ Shows timestamp ("Just now", "5 minutes ago", etc.)
- ✅ Tap notification → Opens chat

---

## 📊 Test 6: Home Screen Stats (1 minute)

### Steps:
1. **Go to Home tab**
2. **Look at the 3 stat cards**:
   - My Products
   - Active Trades
   - Completed

### ✅ Expected Results:
- ✅ "My Products" shows count of your active products
- ✅ Numbers update when you add/remove products
- ✅ Animations play on load (subtle bounces and fades)

---

## 🔍 Debug Console Output

### When Adding a Product:
```
🚀 DEBUG: Uploading images...
✅ DEBUG: Image 0 uploaded successfully
✅ DEBUG: Image 1 uploaded successfully
✅ DEBUG: Image 2 uploaded successfully
🚀 DEBUG: Creating product model...
🚀 DEBUG: Saving product to Firestore...
✅ DEBUG: Product saved successfully with ID: abc123xyz
💰 DEBUG: Final price stored: $800.00
```

### When Starting a Chat:
```
💬 DEBUG: Creating chat between user1 and user2
✅ DEBUG: Chat created with ID: chat123
```

### When Sending a Message:
```
💬 DEBUG [ChatDetail]: Sending text message: "Hi, is this still..."
💬 DEBUG [ChatDetail]: Sender: John Doe
✅ SUCCESS [ChatDetail]: Message sent successfully
```

---

## 🚨 Common Issues & Fixes

### Issue: Products not appearing in home
**Fix**: 
1. Check if any products exist (other than your own)
2. Check console for index errors
3. Create index via error link or wait 1-2 minutes
4. Hot restart app

### Issue: Images not uploading
**Fix**:
1. **iOS Simulator**: Use drag & drop instead of gallery
2. **Check Storage Rules**: Should be deployed ✅
3. **Check permissions**: Allow photo access when prompted

### Issue: Messages not sending
**Fix**:
1. Check console for permission errors
2. Ensure Firestore rules are deployed ✅
3. Check that chat exists in Firestore

### Issue: "AI service unavailable"
**Fix**: This is normal - AI is optional
- You can still set manual price
- AI service needs to be deployed separately by Keerthi

### Issue: Chat doesn't open
**Fix**:
1. Ensure product has a valid `userId`
2. Check that both users exist in Firestore `users` collection
3. Check console for errors

---

## 📱 Quick Test Checklist

Copy this and check off as you test:

```
PRODUCT FLOW:
[ ] Add product with 3 images
[ ] Product appears in Firestore
[ ] Images appear in Storage
[ ] Product appears in home view (from other account)
[ ] Can click product to view details

CHAT FLOW:
[ ] Start chat from product detail
[ ] Chat appears in Firestore
[ ] Send text message
[ ] Message appears in chat
[ ] Send emoji
[ ] Send image
[ ] Image uploads and displays
[ ] Chat appears in Chat tab list
[ ] Other user receives notification

NOTIFICATIONS:
[ ] Bell icon shows unread count
[ ] Notification list displays
[ ] Can tap notification to open chat
[ ] Notification marks as read

HOME SCREEN:
[ ] Stats cards show correct counts
[ ] Featured products display
[ ] Products sorted by price
[ ] Can navigate to product details
```

---

## 🎯 Next Steps

Once all tests pass:
1. ✅ Products & Chat are fully functional
2. ✅ Ready for trade finalization testing
3. ✅ Ready for Capital One Nessie integration
4. ✅ Ready for final polish & demo

---

## 🆘 Need Help?

If tests fail:
1. **Check Console**: Look for specific error messages
2. **Check Firestore Console**: Verify data is being saved
3. **Check Storage Console**: Verify images are uploading
4. **Check Rules**: Ensure all rules are deployed
5. **Check Indexes**: Wait 1-2 minutes for index building

**Firebase Console**: https://console.firebase.google.com/project/barterbrain-1254a

**Firestore Data**: https://console.firebase.google.com/project/barterbrain-1254a/firestore/data

**Storage Files**: https://console.firebase.google.com/project/barterbrain-1254a/storage/files

**Indexes Status**: https://console.firebase.google.com/project/barterbrain-1254a/firestore/indexes


