# How to Run Encore on Your iPhone

---

## Option 1: Run Directly on Your iPhone (Free & Instant)

Best for: showing the app yourself on your own phone.

### Steps

1. **Plug your iPhone** into your Mac with a USB cable.

2. **Open Xcode** → at the top device selector (where it says a simulator name), choose your iPhone from the dropdown.

3. **Sign in with your Apple ID**
   - Go to **Xcode → Settings → Accounts**
   - Click **+** and sign in with your Apple ID if it's not already there

4. **Set your signing team**
   - In the Xcode project navigator, click the top-level **Encore** target
   - Go to the **Signing & Capabilities** tab
   - Under **Team**, select your personal Apple ID

5. **Hit Run (▶)** — Xcode will build and install the app directly on your phone.

6. **Trust the developer on your iPhone**
   - Go to **Settings → General → VPN & Device Management**
   - Tap your Apple ID → tap **Trust**
   - Open the app — it will work normally from now on

### How long does it last?
| Account Type | App Stays Active |
|---|---|
| Free Apple ID | 7 days (re-run from Xcode to renew) |
| Paid Developer ($99/year) | 1 year |

---
/Users/johncasildo/Downloads/ScreenRecording_03-08-2026 23-17-49_1.MP4
## Option 2: TestFlight — Share With Others

Best for: sending the app to friends, testers, or investors.

### Requirements
- An **Apple Developer Program** membership ($99/year)
- Enroll at [developer.apple.com](https://developer.apple.com)

### Steps

1. In Xcode, go to **Product → Archive**
2. In the Organizer window that opens, click **Distribute App**
3. Choose **TestFlight & App Store** → follow the prompts to upload
4. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
5. Find your app → go to the **TestFlight** tab
6. Add testers by email — they'll get a link to install via the free TestFlight app

---

## Option 3: Demo on Your Mac (No Setup Needed)

Best for: screen recordings, presentations, or Zoom demos.

- Run the app in the **iPhone 16 Pro** simulator in Xcode
- Use **Cmd+Shift+H** to go home
- Use **Cmd+Shift+A** to open the app switcher
- The simulator looks exactly like a real iPhone on screen

---

## Troubleshooting

**"Untrusted Developer" error on iPhone**
→ Go to Settings → General → VPN & Device Management → trust your Apple ID

**"No account for team" error in Xcode**
→ Go to Xcode → Settings → Accounts and add your Apple ID

**App disappeared after 7 days**
→ Re-run from Xcode while the phone is plugged in — it renews automatically

**Build fails after plugging in phone**
→ Make sure your iPhone's iOS version is supported. Update iOS or Xcode if needed.
