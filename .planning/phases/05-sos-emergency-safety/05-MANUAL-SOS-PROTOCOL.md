# Phase 05 — Manual SOS Physical-Device Verification Protocol

**Version:** 1.0  
**Phase:** 05-SOS Emergency & Safety  
**Pre-requisites:** Automated tests pass (`npm test` + `cd mobile && flutter test`), Twilio credentials configured in `.env` for live send tests, consented Vietnam test number available.

> **SAFETY NOTE:** When testing `Gọi 115`, verify that the dialer opens with `115` prefilled — then **immediately cancel/dismiss the dialer** without placing a call. Do NOT place a real emergency call under any circumstances.

---

## Setup Checklist

- [ ] Physical Android device (API 26+) connected via USB debug or wireless
- [ ] Physical iOS device (iOS 15+) connected (optional — Android-first if iOS unavailable)
- [ ] Backend running locally or on staging with `TWILIO_*` env vars set
- [ ] Flutter app built in debug mode and installed on device
- [ ] Consented Vietnam test phone number available (not 115)
- [ ] At least one emergency contact configured in the app with `phoneE164` set to the consented number
- [ ] Twilio Console: Vietnam SMS geo permissions enabled, Messaging Service sender verified

---

## Test Cases

### T-01: Hold/Countdown/Cancel — Accidental Activation Prevention (D-01, D-02, D-04)

**Requirement:** EMERG-01, EMERG-02  
**Threat:** T-05-20

**Steps:**
1. Open the app, log in, navigate to home screen.
2. Confirm the `SOS khẩn cấp` button appears only on the home screen (not in calls, conversation, or dictionary screens).
3. Tap the SOS button briefly (< 2 seconds) and release.
4. **Expected:** Nothing happens, no countdown begins, no backend call made.
5. Press and hold the SOS button for the full 2 seconds.
6. **Expected:** A 5-second countdown screen appears with a large `Hủy` button and countdown number.
7. Tap `Hủy` during the countdown.
8. **Expected:** Screen shows `Đã hủy` for ~2–3 seconds, then returns to home. No SMS was sent.

**Evidence to record:**
- [ ] Brief tap → no countdown  
- [ ] Hold 2s → countdown begins  
- [ ] `Hủy` → shows `Đã hủy` → navigates home  
- Screenshot or screen recording of cancel flow

---

### T-02: Location Permission Allowed — Current GPS (D-05, D-06, D-07)

**Requirement:** MOB-04  
**Threat:** T-05-16, T-05-17

**Steps:**
1. Ensure location permission is set to **Allow while using app** for the app in device settings.
2. Trigger SOS (hold 2s, let countdown complete).
3. **Expected:** Screen shows `Đang lấy vị trí...` briefly, then `Đang gửi...`, then a success or fallback state.
4. In backend logs/Twilio Console, confirm the SOS alert record includes latitude, longitude, and `locationLabel: 'current'` or `'approximate'` depending on GPS accuracy.

**Evidence to record:**
- [ ] Status label shown in app UI  
- [ ] Backend alert record shows coordinates and location label  
- Screenshot of status screen with location label

---

### T-03: Location Permission Denied (D-05)

**Requirement:** MOB-04

**Steps:**
1. In device settings, revoke location permission for the app (set to **Deny**).
2. Trigger SOS.
3. **Expected:** App shows a location-unavailable status (`Không có vị trí GPS` or similar). SOS still proceeds — no location should not block the send.
4. Backend alert record should have `latitude: null, locationLabel: 'unavailable'`.

**Evidence to record:**
- [ ] SOS sends without blocking on missing location  
- [ ] Location-unavailable copy visible in app

---

### T-04: Location Service Disabled (D-05)

**Requirement:** MOB-04

**Steps:**
1. Turn off location services entirely in device settings (not just for this app).
2. Trigger SOS.
3. **Expected:** Same as T-03 — SOS proceeds with unavailable location.

**Evidence to record:**
- [ ] No crash or hang when location services off  
- [ ] SOS sends (or reaches fallback) without location

---

### T-05: GPS Timeout / Low Accuracy / Last-Known Labels (D-06, D-07)

**Requirement:** MOB-04

**Steps:**
1. In an area with poor GPS signal (indoors), trigger SOS.
2. **Expected:** After ~5 seconds, app falls back to last-known position or shows approximate label. Status display uses honest Vietnamese copy: `vị trí gần đúng` (approximate, accuracy > 100m) or `vị trí cuối cùng đã biết` (last-known after timeout).

**Evidence to record:**
- [ ] Approximate label shown when accuracy > 100m  
- [ ] Last-known label shown when current GPS timed out  
- [ ] Unavailable label shown when no GPS history available

---

### T-06: Provider SMS Delivery — Twilio to Vietnam Number (D-09, D-10, D-12, D-13)

**Requirement:** EMERG-01, MOB-05  
**Threat:** T-05-10, T-05-11

**Steps:**
1. Configure an emergency contact in the app with the consented Vietnam test number.
2. Trigger SOS (full hold + countdown).
3. **Expected:** App shows `Đang gửi...` then `Đã gửi`.
4. Open Twilio Console → Messaging → Logs and confirm a message was created with `delivered` status to the test number.
5. Check the received SMS on the consented test number device. Confirm it contains:
   - User name
   - `Tôi cần trợ giúp khẩn cấp`
   - Phone number 115 (emergency line mention)
   - GPS coordinates and/or Google Maps link, OR `Không có vị trí GPS`
   - Location quality label (if applicable)
   - Timestamp

**Evidence to record:**
- [ ] Twilio Console message SID and status  
- [ ] Screenshot of received SMS on test device  
- [ ] App shows `Đã gửi` status

---

### T-07: No-Contact SOS (D-14)

**Requirement:** EMERG-01, EMERG-02

**Steps:**
1. Remove all emergency contacts from the app settings.
2. Trigger SOS.
3. **Expected:** App shows a no-contact warning (e.g., `Không có danh bạ khẩn cấp`) but does NOT block the flow. `Gọi 115` button should still be available.

**Evidence to record:**
- [ ] No-contact warning visible  
- [ ] `Gọi 115` button present even with no contacts

---

### T-08: Provider Failure / Native SMS Composer Fallback (D-08, D-09, D-10)

**Requirement:** EMERG-01, MOB-05  
**Threat:** T-05-12, T-05-19

**Steps:**
1. Temporarily set an invalid Twilio credential or disconnect network to simulate provider failure.
2. Trigger SOS.
3. **Expected:** After provider failure, the app shows a fallback state and offers to open the native SMS composer.
4. Tap the native SMS button.
5. **Expected:** Device SMS app opens with the emergency contact number and message body pre-filled. App shows `Đã mở SMS, chờ người dùng gửi` — **NOT** `Đã gửi`.
6. **Do NOT send the SMS** (or send it only to the consented test number if doing a full end-to-end test).

**Evidence to record:**
- [ ] Provider failure state displayed  
- [ ] Native SMS composer opens with pre-filled content  
- [ ] App status is `Đã mở SMS, chờ người dùng gửi` — NOT confirmed sent  
- Screenshot of app status and SMS composer

---

### T-09: No-Network / Offline Fallback (D-08)

**Requirement:** EMERG-01, MOB-05

**Steps:**
1. Enable airplane mode or disconnect WiFi/mobile data.
2. Trigger SOS.
3. **Expected:** Backend request fails. App routes to native SMS fallback without crashing. Native SMS composer opens (or is offered) even without network.

**Evidence to record:**
- [ ] No crash in offline mode  
- [ ] Native SMS composer accessible offline

---

### T-10: `Gọi 115` Dialer Handoff (D-11)

**Requirement:** EMERG-02  
**Threat:** T-05-21

> **⚠️ CRITICAL: Do NOT place a real call to 115. Verify the dialer opens with 115 prefilled, then immediately cancel/dismiss the dialer.**

**Steps:**
1. Trigger SOS to reach either the success status or fallback state.
2. Tap `Gọi 115`.
3. **Expected:** The phone dialer opens with `115` prefilled. The app does not automatically place the call.
4. **Immediately cancel/dismiss the dialer** without placing the call.

**Evidence to record:**
- [ ] Dialer opens with `115` prefilled  
- [ ] App does not auto-dial  
- Screenshot of dialer screen (with 115 visible, before tapping call)

---

### T-11: Visual/Haptic Accessibility — No Strong Flashing (D-16)

**Requirement:** NOTIF-02  
**Threat:** T-05-23

**Steps:**
1. Trigger the full SOS hold → countdown → send flow on a physical device.
2. Observe and feel:
   - Hold start: light haptic
   - Hold complete / countdown start: stronger haptic
   - Countdown ticks: subtle selection haptics
   - Send success or failure: haptic feedback
3. Observe the visual states:
   - Red/emergency color treatment throughout
   - Clear numeric countdown
   - **No rapid flashing, strobe effects, or rapid pulsing animations**

**Evidence to record:**
- [ ] Haptic feedback felt at each state  
- [ ] No strong flashing visual effects  
- [ ] Red/urgent color treatment consistent  
- [ ] Text is large and readable during countdown

---

### T-12: Push Notification SOS Routing (NOTIF-02)

**Requirement:** NOTIF-02

**Steps:**
1. Have a second device logged in as a user who is configured as a `linkedUserId` emergency contact.
2. Trigger SOS from the first device.
3. **Expected:** Second device receives a push notification with SOS status and sender name. Tapping the notification routes to an SOS status view (not a video call screen).

**Evidence to record:**
- [ ] Push notification received on linked contact's device  
- [ ] Notification routing correct  
- Screenshot of notification and SOS status view

---

## Full Automated Suite Results (before this checklist)

Record results here before beginning physical-device tests:

| Suite | Result | Notes |
|-------|--------|-------|
| `npm test -- --runInBand src/__tests__/sos/sos-api.test.ts src/__tests__/sos/sos-fallback.test.ts src/__tests__/sos/sos-notifications.test.ts src/__tests__/sos/emergency-contacts.test.ts src/__tests__/notifications/register-token.test.ts` | | |
| `cd mobile && flutter test test/services/sos_api_service_test.dart test/services/sos_location_service_test.dart test/services/sos_platform_service_test.dart test/screens/sos_screen_test.dart test/services/push_notification_service_test.dart` | | |
| `npm test` (full backend) | | |
| `cd mobile && flutter test` (full Flutter) | | |

---

## Verification Sign-Off

After completing all test cases above, record outcomes:

| Test | Result | Notes |
|------|--------|-------|
| T-01: Hold/Countdown/Cancel | ⬜ | |
| T-02: GPS allowed | ⬜ | |
| T-03: Location denied | ⬜ | |
| T-04: Location disabled | ⬜ | |
| T-05: GPS timeout/labels | ⬜ | |
| T-06: Twilio SMS delivery | ⬜ | |
| T-07: No contacts | ⬜ | |
| T-08: Provider failure / SMS fallback | ⬜ | |
| T-09: Offline fallback | ⬜ | |
| T-10: `Gọi 115` dialer (no auto-call) | ⬜ | |
| T-11: Visual/haptic accessibility | ⬜ | |
| T-12: Push notification routing | ⬜ | |

**Verified by:** _______________  
**Date:** _______________  
**Devices tested:** _______________  

> Phase 05 is ready for release when all test cases show ✅ or documented issues have accepted mitigations.
