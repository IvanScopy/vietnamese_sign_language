---
phase: 04-video-calling
reviewed: 2026-05-16T15:37:06Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - src/app/lib/validators.ts
  - src/app/api/calls/route.ts
  - src/app/api/calls/[callId]/route.ts
  - src/app/api/calls/[callId]/accept/route.ts
  - src/app/api/calls/[callId]/reject/route.ts
  - src/app/api/calls/[callId]/cancel/route.ts
  - src/app/api/calls/[callId]/end/route.ts
  - src/app/api/calls/[callId]/token/route.ts
  - src/app/calls/[callId]/page.tsx
  - src/__tests__/calls/call-state-route.test.ts
  - src/__tests__/web/call-page.test.tsx
  - mobile/lib/main.dart
  - mobile/lib/models/call_state.dart
  - mobile/lib/screens/calls/active_call_screen.dart
  - mobile/test/widgets/call_navigation_gap_test.dart
findings:
  critical: 6
  warning: 4
  info: 0
  total: 10
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-05-16T15:37:06Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the Phase 4 gap-closure call lifecycle routes, web call page, mobile active-call navigation, call-state parsing, and focused tests at standard depth. The re-review still finds blocker-class lifecycle defects. The most serious issues are server-emitted reject/cancel events without a successful authorized transition, accept responses that expose another participant's LiveKit token and omit the call id needed by mobile end-call, notification route parsing that breaks incoming mobile calls, and end-call escape paths that still bypass the server update.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Reject and cancel emit terminal events even when no authorized transition happened

**Classification:** BLOCKER
**File:** `src/app/api/calls/[callId]/reject/route.ts:30`, `src/app/api/calls/[callId]/cancel/route.ts:30`
**Issue:** `rejectCall` and `cancelCall` use `updateMany` but never check `result.count`. The routes then fetch the call by id and emit `call:rejected` or `call:cancelled` regardless of whether the authenticated user was the callee/caller or whether the call was still `RINGING`. Any authenticated non-participant can POST these endpoints for a known call id and cause misleading server-authoritative events to real participants, while the API returns `{ success: true }`.
**Fix:** Make the helpers return or enforce the update count, and only emit after exactly one authorized state transition. Return 403/404/409 instead of success on zero updated rows.

```ts
const result = await prisma.callSession.updateMany({
  where: { id: callId, calleeId: userId, state: 'RINGING' },
  data: { state: 'REJECTED' },
})

if (result.count !== 1) {
  throw new Error('Call unavailable')
}
```

### CR-02: Accept response leaks the caller's LiveKit token to the callee

**Classification:** BLOCKER
**File:** `src/app/api/calls/[callId]/accept/route.ts:52`
**Issue:** The accept endpoint is called by the callee, but it returns both `token: result.calleeToken` and `callerToken: result.callerToken`. The caller token grants room join/publish rights as the caller identity, so the callee receives credentials for another participant. This breaks participant isolation and enables impersonation inside the LiveKit room.
**Fix:** Return only the authenticated participant's token from `/accept`. The caller should obtain its own token through the authenticated `/api/calls/{callId}/token` endpoint after the call becomes `ACTIVE`.

```ts
return NextResponse.json({
  callId,
  state: 'ACTIVE',
  roomName: result.roomName,
  token: result.calleeToken,
})
```

### CR-03: Mobile accepted calls lose their call id and cannot end server-authoritatively

**Classification:** BLOCKER
**File:** `src/app/api/calls/[callId]/accept/route.ts:52`, `mobile/lib/screens/calls/active_call_screen.dart:144`
**Issue:** The accept response omits `callId` and `state`. The mobile `CallApiService.acceptCall` parser falls back to `callId: 0` when those fields are absent, then `ActiveCallScreen._onEndCall` posts `endCall(widget.callSession.callId)`. A callee who accepts a call can connect with the returned token, but ending the call targets `/api/calls/0/end`, fails strict id validation, and leaves the real server call active.
**Fix:** Include the accepted call id and active state in the accept response, or have the mobile accept path preserve `widget.callId` when constructing the session.

```ts
return NextResponse.json({
  callId,
  id: callId,
  state: 'ACTIVE',
  roomName: result.roomName,
  token: result.calleeToken,
})
```

### CR-04: Incoming mobile notification route crashes on string call ids

**Classification:** BLOCKER
**File:** `mobile/lib/main.dart:87`
**Issue:** `/calls/incoming` reads `args?['callId'] as int?`, but FCM data payloads are strings and the existing push routing tests use `'callId': '42'`. A real notification-open route therefore throws a type-cast exception before `IncomingCallScreen` is built. If the field is absent, the route silently defaults to `0`, which later fails strict backend id validation.
**Fix:** Parse both string and int arguments and fail visibly when the value is invalid.

```dart
int? parseRouteInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

final callId = parseRouteInt(args?['callId']);
if (callId == null || callId < 1) {
  return MaterialPageRoute(
    builder: (_) => const Scaffold(
      body: Center(child: Text('Invalid call notification')),
    ),
  );
}
```

### CR-05: Web media-error exits still bypass the server end-call transition

**Classification:** BLOCKER
**File:** `src/app/calls/[callId]/page.tsx:202`
**Issue:** The page-level `handleEnd` only navigates to `?state=ENDED`. The normal active-call control path wraps it with a POST to `/end`, but the cross-referenced `ActiveCallCanvas` media-error and failed-call exits call the raw `onEnd` callback. A user who hits a media failure can leave the call and see the ended result while the backend call remains `ACTIVE` and the remote participant receives no `call:ended` event.
**Fix:** Expose a single end-call callback that always awaits `/api/calls/{callId}/end` before navigating, and use it for normal controls and all error/recovery exits.

```ts
const handleEnd = useCallback(async () => {
  const response = await fetch(`/api/calls/${callId}/end`, {
    method: 'POST',
    credentials: 'include',
  })
  if (!response.ok) throw new Error('Failed to end call')
  router.push(`/calls/${callId}?state=ENDED`)
}, [callId, router])
```

### CR-06: Mobile outgoing calls create signaling listeners but never connect them

**Classification:** BLOCKER
**File:** `mobile/lib/main.dart:111`
**Issue:** The outgoing route constructs a fresh `CallSignalingService` and passes it to the outgoing call screen, but the cross-referenced outgoing screen only subscribes to its streams and no code calls `connect()`. The caller can remain stuck on ringing forever because `call:accepted`, `call:rejected`, `call:missed`, and `call:busy` events are never received; consequently the new active-call token fetch path is never reached for mobile callers.
**Fix:** Connect the signaling service when the outgoing screen starts, surface connection failure, and dispose the owned service when the route ends.

```dart
@override
void initState() {
  super.initState();
  _connectSignaling();
  _setupSignalingListeners();
}

Future<void> _connectSignaling() async {
  try {
    await widget.callSignalingService.connect();
  } catch (error) {
    if (mounted) _goToResult(CallState.failed);
  }
}
```

## Warnings

### WR-01: Active-call routes default every missing user type to deaf

**Classification:** WARNING
**File:** `mobile/lib/main.dart:123`
**Issue:** `/calls/active` defaults `currentUserType` to `UserType.deaf` when route arguments omit it. The incoming and outgoing navigation paths do omit it, so hearing users enter the wrong translation mode and the overlay can start the wrong capture/subscription behavior.
**Fix:** Pass the authenticated user's actual type into active-call navigation, or block the route until profile/session state is available.

### WR-02: Visible active-call controls are shipped as no-ops

**Classification:** WARNING
**File:** `mobile/lib/screens/calls/active_call_screen.dart:340`, `mobile/lib/screens/calls/active_call_screen.dart:547`
**Issue:** The Switch camera button and Open settings button are visible user controls, but both handlers contain only TODO bodies. Users can tap controls that cannot perform the advertised action, which is especially harmful on the permission recovery path.
**Fix:** Implement the handlers or hide/disable these controls until the behavior exists.

### WR-03: Invalid web call ids leave the page loading forever

**Classification:** WARNING
**File:** `src/app/calls/[callId]/page.tsx:102`
**Issue:** The web call page converts `params.callId` with `Number(...)` and only fetches when `if (callId)` is truthy. Invalid routes such as `/calls/not-a-number` or `/calls/0` skip the fetch and never clear `isLoading`, leaving a permanent spinner instead of an error or redirect.
**Fix:** Validate the route param with the same strict positive integer rules as the API and set an error state for invalid values.

```ts
const rawCallId = String(params.callId ?? '')
const callId = /^\d+$/.test(rawCallId) ? Number(rawCallId) : NaN
if (!Number.isSafeInteger(callId) || callId < 1) {
  setError('Invalid call ID')
  setIsLoading(false)
  return
}
```

### WR-04: Gap tests miss the remaining lifecycle regressions

**Classification:** WARNING
**File:** `src/__tests__/web/call-page.test.tsx:14`, `mobile/test/widgets/call_navigation_gap_test.dart:94`
**Issue:** The web test suite mocks `ActiveCallCanvas` to `null` and only exercises exported helper functions, so it cannot catch the raw `onEnd` error exits or actual `RINGING` rendering behavior. The mobile widget test only asserts that `ActiveCallScreen` receives props; it does not fake `CallApiService.getToken`, `endCall`, or LiveKit connection/disposal. There are also no in-scope route tests for unauthorized reject/cancel, accept response shape, or token exposure.
**Fix:** Add tests that assert: reject/cancel do not emit when `updateMany.count` is `0`; `/accept` returns only the callee token plus `callId`; media-error exits call `/end`; notification string call ids parse; and mobile active calls fetch/end/dispose with authenticated API calls.

---

_Reviewed: 2026-05-16T15:37:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
