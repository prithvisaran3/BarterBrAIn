# 📱 Connecting Physical iPhone via USB Cable

## Current Status
Your iPhone is currently connected **wirelessly**. Follow these steps to switch to **wired (USB) connection**.

---

## Step-by-Step Instructions

### 1. Open Xcode Devices Window
**Xcode has been opened for you.** Now:
1. In Xcode, go to **Window → Devices and Simulators** (or press `Shift + Cmd + 2`)
2. Click on the **Devices** tab at the top

### 2. Disable Wireless Connection
1. Find your iPhone "Prithvi's iPhone" in the left sidebar
2. Click on it to select it
3. **UNCHECK** the box that says **"Connect via network"**
4. You should see the network icon disappear from your device

### 3. Connect USB Cable
1. Take your **Lightning/USB-C cable**
2. Plug one end into your iPhone
3. Plug the other end into your Mac
4. Wait for the device to be recognized

### 4. Trust the Device (if prompted)
On your iPhone:
1. You may see a prompt: **"Trust This Computer?"**
2. Tap **"Trust"**
3. Enter your iPhone passcode

### 5. Verify Wired Connection
Back in Terminal, run:
```bash
flutter devices
```

You should see:
```
Prithvi's iPhone (mobile) • 00008150-001C1DCE1102401C • ios • iOS 26.1
```

**Without** the "(wireless)" label.

---

## Running the App

### Option A: VS Code (Recommended)
1. Open the **Run and Debug** panel (`Cmd + Shift + D`)
2. Select **"BarterBrAIn (Debug - Prithvi's iPhone)"** from dropdown
3. Press **F5** or click the green ▶️ play button

### Option B: Terminal
```bash
cd /Users/prithvisaran/Desktop/Projects/BarterBrAIn
flutter run -d 00008150-001C1DCE1102401C
```

---

## Troubleshooting

### Device Not Showing Up?
```bash
# Check if device is recognized by iOS
idevice_id -l

# Restart usbmuxd service
sudo killall -9 usbmuxd
```

### "Device Locked" Error?
1. Unlock your iPhone
2. Keep it unlocked during app installation

### Still Showing Wireless?
1. Restart Xcode
2. Disconnect and reconnect USB cable
3. Run `flutter devices` again

### Cable Connection Not Working?
- Try a different USB port
- Try a different cable (must be data cable, not charge-only)
- Restart your Mac if needed

---

## Launch Configuration

Your `.vscode/launch.json` is already configured:

```json
{
  "name": "BarterBrAIn (Debug - Prithvi's iPhone)",
  "type": "dart",
  "program": "lib/main.dart",
  "args": [
    "-d",
    "00008150-001C1DCE1102401C"
  ],
  "flutterMode": "debug"
}
```

This will **always** use your physical device (wired or wireless), but wired is faster and more stable!

---

## Benefits of Wired Connection

✅ **Faster deployment** (no network overhead)
✅ **More stable** (no WiFi interruptions)
✅ **Better debugging** (faster log streaming)
✅ **Lower latency** (instant hot reload)
✅ **Works without WiFi**

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `flutter devices` | List all connected devices |
| `flutter run -d <device-id>` | Run on specific device |
| `killall -9 usbmuxd` | Restart iOS device daemon |
| `idevice_id -l` | List iOS devices via USB |

---

**Your device ID:** `00008150-001C1DCE1102401C`

---

Once you've disabled wireless in Xcode and connected the cable, run:
```bash
flutter devices
```

Then start debugging from VS Code! 🚀

