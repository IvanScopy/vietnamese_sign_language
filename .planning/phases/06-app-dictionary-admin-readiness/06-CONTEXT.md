# Phase 6: App, Dictionary & Admin Readiness - Context

**Gathered:** 2026-05-17T15:16:30+07:00
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the v1 product surfaces that make VSL Bridge usable across mobile and web:

- Production-quality mobile app shell and account flow.
- User-facing web app shell with practical v1 parity.
- Searchable and browsable VSL dictionary backed by 4,000 gesture videos.
- Admin panel for users, dictionary/content operations, SOS logs, and broadcast notifications.
- Shared account/session behavior across mobile and web.

Out of scope:

- Full structured learning curriculum, quizzes, progress tracking, and parent dashboards.
- 3D avatar signing.
- Advanced campaign/analytics tooling.
- Bulk video upload through admin UI for the initial 4,000-video dataset.
- Web SOS parity that pretends browser flows can replace mobile SMS, dialer, and reliable location affordances.

</domain>

<decisions>
## Implementation Decisions

### Dictionary Content And Ingestion

- **D-01:** Use a hybrid dictionary content model: seed the initial 4,000 VSL videos by batch import, then let admins edit metadata, replace videos, publish/unpublish entries, and add individual new entries.
- **D-02:** A user-visible dictionary entry requires Vietnamese text, category/topic, video reference, `published`/`draft` state, slug/search keywords, and updated timestamp.
- **D-03:** Seed entries with missing video or invalid metadata should still import into admin as `draft` or `needs_review`, but must not appear to users until fixed.
- **D-04:** Store dictionary videos in object storage/CDN. The database stores storage keys and/or public CDN URLs.

### Dictionary Search And Browsing

- **D-05:** The dictionary screen combines a prominent Vietnamese search bar with a topic/category grid for browsing.
- **D-06:** Search must normalize Vietnamese text: accent-insensitive matching, case-insensitive matching, whitespace/underscore normalization, partial match, and keywords.
- **D-07:** User-facing dictionary results use cards with video thumbnails, Vietnamese sign text, and category/topic.
- **D-08:** A sign detail page includes video controls, Vietnamese text, category/topic, keywords/tags, updated date, and a small set of related signs from the same category.

### Admin Roles And Operations

- **D-09:** Add multiple admin roles in Phase 6, not a single generic admin.
- **D-10:** Admin roles are `Super Admin`, `Content Admin`, and `Support Admin`.
- **D-11:** Super Admin can manage all admin areas and assign admin permissions. Content Admin manages dictionary and lesson placeholders. Support Admin manages user support, SOS logs, and support broadcasts.
- **D-12:** Admin user management includes viewing/searching users, activate/deactivate, and changing user type/admin role. It must not include manual password editing or exposing sensitive user data.
- **D-13:** Broadcast notifications support targeting by group, such as deaf, hearing, parent, teacher, and active users. Broadcast flow requires preview and confirmation before send.
- **D-14:** Add audit logs for sensitive admin actions: user deactivation, role changes, dictionary publish/unpublish, broadcast send, and SOS log handling.

### Web App Parity

- **D-15:** Phase 6 web includes both a user-facing app shell and a separate `/admin` surface visible only to admins.
- **D-16:** Web parity means practical core parity: auth/profile, dictionary, webcam recognition, video call pages, and notification/status surfaces.
- **D-17:** Web SOS is informational/limited only because browser flows cannot reliably match mobile SMS, native dialer, and location affordances.
- **D-18:** Browser webcam recognition should connect to the existing recognition pipeline. The user clarified that a full model now exists; Phase 2/STATE docs saying recognition is validation-pending are stale and must not force a mock-only design.
- **D-19:** Web app navigation should be a real app shell with responsive header/sidebar/nav for Dictionary, Recognition, Calls, Profile, and Notifications. `/admin` remains separate.

### Mobile Production Polish

- **D-20:** Replace the current button-list home screen with a tab-based Flutter app shell.
- **D-21:** Main mobile tabs are `Communicate`, `Dictionary`, `SOS`, and `Profile`.
- **D-22:** Conversation history belongs inside `Communicate` or `Profile`, not as a top-level tab.
- **D-23:** Mobile polish prioritizes accessibility and usability: tap targets, semantic labels, text scaling, contrast, non-flashing states, and clear error/offline states.
- **D-24:** Mobile also needs production visual polish: coherent color, typography, spacing, icons, and empty states.
- **D-25:** Mobile account flow should include login, register, logout, profile edit, user type, emergency contact link/edit, token refresh, and session-expired handling.

### Video Storage And Playback

- **D-26:** Dictionary video playback uses direct public URLs from object storage/CDN.
- **D-27:** Admin upload is only for adding or replacing individual videos after seed import, not for manually uploading the initial 4,000 videos.
- **D-28:** Video player controls should be learning-friendly: play/pause/seek, replay, 0.5x/0.75x/1x speed, fullscreen where supported, and clear loading/error states.
- **D-29:** Dictionary thumbnails come from `thumbnailUrl` or `thumbnailKey` metadata. They may be generated outside the app pipeline or uploaded alongside video.

### the agent's Discretion

- Choose exact database model names, enum names, API route shapes, and upload strategy details.
- Choose the storage provider during planning, with S3-compatible storage/CDN preferred.
- Choose exact topic/category taxonomy if no authoritative taxonomy exists, while preserving Vietnamese search and child-friendly browse behavior.
- Choose exact web/mobile visual treatment, as long as the app becomes production-quality and accessible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope

- `.planning/ROADMAP.md` — Phase 6 boundary, success criteria, dependencies, and out-of-scope learning/avatar work.
- `.planning/REQUIREMENTS.md` — Requirement IDs `MOB-01`, `MOB-02`, `WEB-01`, `WEB-03`, `WEB-04`, `DICT-01` through `DICT-04`, and `ADMIN-01` through `ADMIN-05`.
- `.planning/STATE.md` — Current milestone state, but treat recognition validation status as stale per user clarification that the full model now exists.
- `.planning/PROJECT.md` — Product vision, target users, platform strategy, privacy constraints, and v1/v2 boundaries.

### Existing Code

- `prisma/schema.prisma` — Existing users, notifications, SOS, calls, and transcripts; needs admin role/content/dictionary/audit additions.
- `recognition-service/vocabulary.json` — Current small recognition vocabulary seed; useful as a shape reference only, not the full 4,000-entry dictionary.
- `src/app/page.tsx` — Current web home is API-only and must become a real user-facing app shell.
- `src/app/api/users/route.ts` — Existing authenticated user lookup can inform admin/user management work.
- `src/app/api/user/profile/route.ts` — Existing profile read/update pattern and emergency contact inclusion.
- `src/app/api/notifications/send/route.ts` — Existing notification persistence/realtime pattern that broadcast work can build from or replace.
- `src/app/api/sos/alerts/route.ts` and `src/app/lib/sos.ts` — SOS records and status flow relevant to admin SOS review.
- `mobile/lib/main.dart` — Current Flutter routing/home screen; Phase 6 replaces this with a tab shell and real auth/profile flow.
- `mobile/lib/screens/recognition_screen.dart` — Existing mobile recognition screen and service wiring.
- `mobile/lib/widgets/camera_preview.dart` — Existing camera/MediaPipe integration.
- `mobile/lib/screens/sos_screen.dart` — Existing SOS mobile surface that should remain prominent in the new tab shell.
- `mobile/lib/services/push_notification_service.dart` — Existing notification-open routing and SOS/call handling.

### Prior Phase Context

- `.planning/phases/03-face-to-face-conversation-history/03-CONTEXT.md` — Mobile-first conversation/history UX, manual correction, non-flashing accessibility, text-only privacy boundary.
- `.planning/phases/04-video-calling/04-CONTEXT.md` — Mobile/web platform-native parity, notification expectations, call surfaces, no media recording.
- `.planning/phases/05-sos-emergency-safety/05-CONTEXT.md` — SOS mobile behavior, honest native fallback states, visual/haptic accessibility, and no flashing effects.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `prisma/schema.prisma`: provides existing account, notification, SOS, and call models but lacks dictionary, admin-role, admin-audit, content, and upload models.
- `mobile/lib/main.dart`: contains the current simple home and routes for recognition, conversation, history, calls, and SOS; it is the main integration point for the new tab shell.
- `mobile/lib/screens/recognition_screen.dart` and `mobile/lib/widgets/camera_preview.dart`: provide reusable mobile camera/recognition patterns.
- `src/app/api/users/route.ts`: provides a starting point for authenticated user lookup, though admin management will need role checks and broader fields.
- `src/app/api/notifications/send/route.ts`: provides a notification persistence/socket pattern that can inform broadcast notifications.
- `src/app/lib/sos.ts`: provides SOS data and status semantics for admin SOS log review.

### Established Patterns

- Backend uses Next.js route handlers, Prisma, Zod validation, JWT/cookie auth helpers, and Socket.io for foreground realtime events.
- Flutter uses explicit `MaterialApp` routes and service objects; Phase 6 should evolve this into a navigable app shell without breaking existing feature routes.
- Prior phases prefer honest status labels over pretending unverified/fallback actions succeeded.
- Prior accessibility decisions reject flashing effects and favor clear visual/haptic states.

### Integration Points

- Add dictionary schema, import tooling, user-facing dictionary APIs, admin dictionary APIs, and storage/CDN metadata.
- Add admin role/permission enforcement, admin app routes, audit log persistence, and tests around sensitive actions.
- Replace `src/app/page.tsx` with a real web app shell and add protected user-facing routes.
- Add `/admin` web routes gated by admin permissions.
- Add mobile dictionary screens and integrate them into the new tab shell.
- Add real mobile auth/profile/session handling to replace token-manual workflows.
- Add web webcam recognition page connected to the existing recognition pipeline.

</code_context>

<specifics>
## Specific Ideas

- The 4,000-video dataset should be batch imported; admin upload is only for one-off additions or replacements later.
- The user explicitly clarified that recognition model availability is no longer the blocker described in older planning docs; those docs need correction later.
- Dictionary browsing should work for children and learners, not only power users who know the exact Vietnamese word.
- Admin should be operationally useful but not overbuilt into full analytics/campaign tooling.

</specifics>

<deferred>
## Deferred Ideas

- Full structured lessons, quizzes, progress tracking, parent dashboard, and advanced learning player features remain v1.x.
- Bulk admin upload UI for the initial 4,000 videos is deferred; batch import is the correct path.
- Advanced video processing/transcoding, automatic thumbnail generation, frame-by-frame playback, annotations overlay, and looped segments are future enhancements.
- Web SOS full parity is deferred because mobile is the reliable SOS platform.
- Campaign scheduling, templates, analytics, retries, and complex segmentation are deferred.

</deferred>

---

*Phase: 06-App, Dictionary & Admin Readiness*
*Context gathered: 2026-05-17T15:16:30+07:00*
