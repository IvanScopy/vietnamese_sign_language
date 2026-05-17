# Phase 6: App, Dictionary & Admin Readiness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-17T15:16:30+07:00
**Phase:** 6-App, Dictionary & Admin Readiness
**Areas discussed:** Dictionary content model and ingestion, Dictionary search and browsing experience, Admin permissions and operational power, Web app parity boundary, Mobile production polish scope, Video storage and playback expectations

---

## Dictionary Content Model And Ingestion

**Selected:** Hybrid seed/import plus admin editing.

Options considered: seed-only, admin-managed-only, hybrid. The user chose hybrid. Metadata should be standardized enough for production search/browse: Vietnamese text, category/topic, video, published/draft, slug/search keywords, and updated timestamp. Broken seed entries import as draft/needs_review. Videos live in object storage/CDN.

---

## Dictionary Search And Browsing Experience

**Selected:** Search plus topic grid.

Options considered: search-first, browse-first, combined. The user chose combined. Search must normalize Vietnamese text. Results use cards with thumbnails. Detail pages include video controls, metadata, tags/keywords, updated date, and light related signs.

---

## Admin Permissions And Operational Power

**Selected:** Multiple admin roles with sensitive-action audit logs.

Options considered: one admin role, multiple admin roles, env/email allowlist. The user chose multiple roles: Super Admin, Content Admin, Support Admin. User management includes search/view, activate/deactivate, and role/user-type changes. Broadcasts target groups and require preview/confirm. Sensitive actions need audit logs.

---

## Web App Parity Boundary

**Selected:** User-facing web app shell plus separate `/admin`.

Options considered: user-first web, admin-first web, both user-facing and admin v1 surfaces. The user chose both. Web parity is practical core parity: auth/profile, dictionary, webcam recognition, video calls, notifications/status. SOS is informational/limited on web. The user clarified the full recognition model exists and older docs are stale.

---

## Mobile Production Polish Scope

**Selected:** Tab-based mobile shell.

Options considered: polish current button list, tab shell, drawer/sidebar. The user chose tabs: Communicate, Dictionary, SOS, Profile. Polish prioritizes accessibility/usability plus production visual polish. Mobile account flow should include login/register/logout, profile edit, user type, emergency contacts, token refresh, and session-expired handling.

---

## Video Storage And Playback Expectations

**Selected:** Public CDN/object-storage URLs and learning-friendly playback.

Options considered: public CDN URLs, signed/private URLs, backend proxy. The user chose public CDN URLs. Admin upload is only for one-off add/replace after seed, not for 4,000 initial videos. Player controls include play/pause/seek, replay, speed controls, fullscreen where supported, and clear loading/error states. Thumbnails come from metadata.

## the agent's Discretion

- Exact schema, route, enum, storage provider, and upload implementation details.
- Exact category taxonomy if no authoritative VSL taxonomy exists.
- Exact mobile/web visual treatment, subject to production-quality and accessibility decisions.

## Deferred Ideas

- Full learning curriculum, quiz/progress, parent dashboard.
- Bulk admin upload UI for the initial 4,000 videos.
- Advanced video processing, automatic thumbnails, frame-by-frame playback, annotations, and segment looping.
- Full web SOS parity.
- Advanced broadcast campaigns and analytics.
