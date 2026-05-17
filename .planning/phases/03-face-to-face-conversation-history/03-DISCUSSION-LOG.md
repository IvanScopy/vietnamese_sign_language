# Phase 3: Face-to-Face Conversation & History - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-12
**Phase:** 03-Face-to-Face Conversation & History
**Areas discussed:** One-device layout, Turn-taking between signing and speaking, Conversation timeline, Text-only history, Recognition fallback

---

## One-Device Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Split 180 | Two people sit opposite each other; each half is oriented for its reader. | yes |
| Same direction | Easier to build/test; better when people sit side by side. | |
| Tabbed sides | Each person has a separate tab; simpler but weaker for one-device face-to-face use. | |

**User's choice:** Split 180.
**Notes:** The layout should be portrait top/bottom. Each side has its own input/output and a correctly rotated copy of the shared timeline.

---

## Turn-Taking Between Signing and Speaking

| Option | Description | Selected |
|--------|-------------|----------|
| Manual toggle | Clear user-controlled switching between signing and speaking. | yes |
| Auto detect | App attempts to infer whether camera or mic should be active. | |
| Push-to-talk / push-to-sign | User holds a button while producing input. | |

**User's choice:** Manual toggle.
**Notes:** Use one shared center control. Only one mode is active at a time. Switching turns finalizes the current phrase. STT uses tap-to-start/tap-to-stop rather than always listening.

---

## Conversation Timeline

| Option | Description | Selected |
|--------|-------------|----------|
| Chat bubbles by role | Messages appear as role-labeled bubbles. | yes |
| Continuous transcript | Messages appear as a plain transcript. | |
| Cards by turn | Each turn appears as a larger card with status. | |

**User's choice:** Chat bubbles by role.
**Notes:** Recognized sign text can be edited before confirmation. TTS plays only when the user taps Play or Confirm & Play. Messages move from draft to confirmed.

---

## Text-Only History

| Option | Description | Selected |
|--------|-------------|----------|
| Confirmed messages only | Save only messages users confirmed. | yes |
| Confirmed + drafts | Save all message states. | |
| Final transcript only | Save only the finished transcript text. | |

**User's choice:** Confirmed messages only.
**Notes:** History is local-device only. It is grouped by conversation session and timestamp. Search is full-text over confirmed transcript messages. Sharing uses plain text with timestamp, role, and text.

---

## Recognition Fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Show unclear + manual entry | Surface low confidence and let users type or edit. | yes |
| Show best guess with confidence | Display model guess even when confidence is low. | |
| Ignore low confidence | Drop low-confidence recognition from the UI. | |

**User's choice:** Show unclear + manual entry.
**Notes:** Manual/corrected text uses `source = manual`. Recognition service errors pause sign input but keep speech/manual conversation available. Provide a clearly labeled demo/manual-friendly mode while the real VSL model is not ready.

---

## the agent's Discretion

- Choose exact confidence thresholds during planning.
- Choose local storage implementation during research/planning.
- Refine labels and microcopy while preserving the locked decisions.

## Deferred Ideas

- Messenger/Discord-style chat between accounts.
- Backend-synced conversation history.
- 3D avatar signing.
