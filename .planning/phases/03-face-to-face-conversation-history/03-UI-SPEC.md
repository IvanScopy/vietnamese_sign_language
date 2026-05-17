---
phase: 03-face-to-face-conversation-history
status: ready
type: ui-design-contract
requirements:
  - COMM-04
  - HIST-01
  - HIST-02
  - HIST-03
  - HIST-04
---

# Phase 3 UI Spec: Face-to-Face Conversation & History

## Product Surface

Phase 3 adds a mobile-first one-device conversation mode for a deaf signer and a hearing speaker sharing one phone. The experience is operational, not editorial: the first screen must be the working conversation tool with direct access to history, not a landing page.

## Primary Layout

- Use portrait top/bottom split-screen.
- The top participant panel is rotated 180 degrees so a person sitting across the table can read naturally.
- The bottom participant panel remains normally oriented.
- Both panels display the same confirmed conversation timeline, filtered visually by role but not by data source.
- Keep the active turn control in the center band between the two panels.
- Use compact controls with icons where possible: signing hand, mic, check, play, history, copy, search, close.
- Avoid nested cards. Message bubbles may be card-like individual repeated items.

## Interaction Contract

- Only one active input mode is enabled at a time: signing or speaking.
- Switching modes finalizes any non-empty draft into the conversation timeline.
- Sign drafts start from recognition results or phrase completion events and remain editable before confirmation.
- Low-confidence sign recognition below 0.60 must show an unclear state and keep manual correction available.
- TTS is user-triggered only through Play or Confirm & Play actions.
- Speech-side input uses tap-controlled capture where available and keeps manual text entry as the fallback path.
- Recognition service disconnects must pause sign input but leave speech/manual input and history available.
- Demo/manual mode must be visibly labeled when recognition is not connected or confidence is low.

## History Contract

- Store only confirmed messages.
- Store local text only; no audio, video, images, landmarks, or remote sync.
- Group messages into conversation sessions with timestamps.
- History list shows session start time, message count, and short transcript preview.
- History detail supports search across confirmed text.
- Share/copy exports plain text with timestamp, role, and message text.

## Visual Quality Bar

- Mobile-first, dense, and readable under one-handed use.
- Text must not overflow in the center controls, message bubbles, history rows, or rotated panel.
- Use neutral surfaces, accessible contrast, and restrained role colors:
  - Signing user: green accent.
  - Speaking user: blue accent.
  - Manual/demo/unclear state: amber accent.
- Font sizes are fixed, not viewport-scaled.
- Cards and bubbles use border radius <= 8px.

## Accessibility

- All actionable icon buttons must have tooltips.
- Touch targets should be at least 44px where space allows.
- Color is not the only status indicator; use text labels for draft, confirmed, unclear, manual, and disconnected states.
- Rotated panel must preserve readable text order and control hit targets.

## Out Of Scope

- Remote video calling.
- Messenger-style inbox between accounts.
- 3D avatar signing.
- Media retention or cloud-synced history.
