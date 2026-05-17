# Phase 06: App, Dictionary & Admin Readiness - Research

**Researched:** 2026-05-17
**Domain:** Next.js App Router + Prisma/PostgreSQL + Flutter product shell + dictionary/admin workflows
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Dictionary Content And Ingestion

- **D-01:** Use a hybrid dictionary content model: seed the initial 4,000 VSL videos by batch import, then let admins edit metadata, replace videos, publish/unpublish entries, and add individual new entries.
- **D-02:** A user-visible dictionary entry requires Vietnamese text, category/topic, video reference, `published`/`draft` state, slug/search keywords, and updated timestamp.
- **D-03:** Seed entries with missing video or invalid metadata should still import into admin as `draft` or `needs_review`, but must not appear to users until fixed.
- **D-04:** Store dictionary videos in object storage/CDN. The database stores storage keys and/or public CDN URLs.
- **D-05:** The dictionary screen combines a prominent Vietnamese search bar with a topic/category grid for browsing.
- **D-06:** Search must normalize Vietnamese text: accent-insensitive matching, case-insensitive matching, whitespace/underscore normalization, partial match, and keywords.
- **D-07:** User-facing dictionary results use cards with video thumbnails, Vietnamese sign text, and category/topic.
- **D-08:** A sign detail page includes video controls, Vietnamese text, category/topic, keywords/tags, updated date, and a small set of related signs from the same category.

#### Admin Roles And Operations

- **D-09:** Add multiple admin roles in Phase 6, not a single generic admin.
- **D-10:** Admin roles are `Super Admin`, `Content Admin`, and `Support Admin`.
- **D-11:** Super Admin can manage all admin areas and assign admin permissions. Content Admin manages dictionary and lesson placeholders. Support Admin manages user support, SOS logs, and support broadcasts.
- **D-12:** Admin user management includes viewing/searching users, activate/deactivate, and changing user type/admin role. It must not include manual password editing or exposing sensitive user data.
- **D-13:** Broadcast notifications support targeting by group, such as deaf, hearing, parent, teacher, and active users. Broadcast flow requires preview and confirmation before send.
- **D-14:** Add audit logs for sensitive admin actions: user deactivation, role changes, dictionary publish/unpublish, broadcast send, and SOS log handling.

#### Web App Parity

- **D-15:** Phase 6 web includes both a user-facing app shell and a separate `/admin` surface visible only to admins.
- **D-16:** Web parity means practical core parity: auth/profile, dictionary, webcam recognition, video call pages, and notification/status surfaces.
- **D-17:** Web SOS is informational/limited only because browser flows cannot reliably match mobile SMS, native dialer, and location affordances.
- **D-18:** Browser webcam recognition should connect to the existing recognition pipeline. The user clarified that a full model now exists; Phase 2/STATE docs saying recognition is validation-pending are stale and must not force a mock-only design.
- **D-19:** Web app navigation should be a real app shell with responsive header/sidebar/nav for Dictionary, Recognition, Calls, Profile, and Notifications. `/admin` remains separate.

#### Mobile Production Polish

- **D-20:** Replace the current button-list home screen with a tab-based Flutter app shell.
- **D-21:** Main mobile tabs are `Communicate`, `Dictionary`, `SOS`, and `Profile`.
- **D-22:** Conversation history belongs inside `Communicate` or `Profile`, not as a top-level tab.
- **D-23:** Mobile polish prioritizes accessibility and usability: tap targets, semantic labels, text scaling, contrast, non-flashing states, and clear error/offline states.
- **D-24:** Mobile also needs production visual polish: coherent color, typography, spacing, icons, and empty states.
- **D-25:** Mobile account flow should include login, register, logout, profile edit, user type, emergency contact link/edit, token refresh, and session-expired handling.

#### Video Storage And Playback

- **D-26:** Dictionary video playback uses direct public URLs from object storage/CDN.
- **D-27:** Admin upload is only for adding or replacing individual videos after seed import, not for manually uploading the initial 4,000 videos.
- **D-28:** Video player controls should be learning-friendly: play/pause/seek, replay, 0.5x/0.75x/1x speed, fullscreen where supported, and clear loading/error states.
- **D-29:** Dictionary thumbnails come from `thumbnailUrl` or `thumbnailKey` metadata. They may be generated outside the app pipeline or uploaded alongside video.

### the agent's Discretion

- Choose exact database model names, enum names, API route shapes, and upload strategy details.
- Choose the storage provider during planning, with S3-compatible storage/CDN preferred.
- Choose exact topic/category taxonomy if no authoritative taxonomy exists, while preserving Vietnamese search and child-friendly browse behavior.
- Choose exact web/mobile visual treatment, as long as the app becomes production-quality and accessible.

### Deferred Ideas (OUT OF SCOPE)

- Full structured lessons, quizzes, progress tracking, parent dashboard, and advanced learning player features remain v1.x.
- Bulk admin upload UI for the initial 4,000 videos is deferred; batch import is the correct path.
- Advanced video processing/transcoding, automatic thumbnail generation, frame-by-frame playback, annotations overlay, and looped segments are future enhancements.
- Web SOS full parity is deferred because mobile is the reliable SOS platform.
- Campaign scheduling, templates, analytics, retries, and complex segmentation are deferred.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOB-01 | iOS production-quality UI/UX | Use Flutter Material app shell with accessibility checklist: screen reader labels, 48x48 targets, contrast, scaling, and non-flashing states. [CITED: docs.flutter.dev/ui/accessibility] |
| MOB-02 | Android production-quality UI/UX | Same shared Flutter shell; verify with `flutter analyze` and widget tests for tab navigation, auth state, dictionary, SOS prominence. [VERIFIED: mobile/pubspec.yaml] |
| WEB-01 | Responsive web application with feature parity | Replace API-only home with protected user app shell for Dictionary, Recognition, Calls, Profile, Notifications. [VERIFIED: src/app/page.tsx + 06-CONTEXT.md] |
| WEB-03 | Webcam access for browser recognition | Use `navigator.mediaDevices.getUserMedia()` in a secure context and stream landmarks/results through existing recognition pipeline. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia] |
| WEB-04 | Shared account system with mobile app | Reuse existing JWT/cookie auth for web and Bearer token path for mobile; fix profile endpoints to support both. [VERIFIED: src/app/lib/request-auth.ts] |
| DICT-01 | Searchable dictionary of 4,000 videos | Add Prisma dictionary models, import script, publication states, CDN URL/key fields, and user-facing list/detail APIs. [VERIFIED: prisma/schema.prisma + 06-CONTEXT.md] |
| DICT-02 | Video playback with controls | Use native HTML5 video on web and the official Flutter `video_player` package on mobile for direct CDN/network MP4 playback, play/pause, seek, replay, speed choices, and fullscreen shell integration. Direct CDN URLs are locked. [VERIFIED: pub.dev/packages/video_player; CITED: docs.flutter.dev/cookbook/plugins/play-video] |
| DICT-03 | Vietnamese partial search | Store normalized search text/keywords and use PostgreSQL indexes; `unaccent` supports diacritic removal for text search. [CITED: postgresql.org/docs/15/unaccent.html] |
| DICT-04 | Category/tag browsing | Model categories/topics as first-class records or stable enum-plus-table; expose browsable published counts. [ASSUMED] |
| ADMIN-01 | Admin user management | Add admin roles, active/deactivated status, role-gated APIs, and audit log entries. [VERIFIED: 06-CONTEXT.md] |
| ADMIN-02 | Dictionary content management | Add admin CRUD, publish/unpublish, one-off upload/replace flow, metadata validation, and audit logs. [VERIFIED: 06-CONTEXT.md] |
| ADMIN-03 | Lesson content placeholders | Implement minimal lesson/topic placeholder CRUD only; full curriculum is out of scope. [VERIFIED: 06-CONTEXT.md] |
| ADMIN-04 | SOS incident review and statistics dashboard | Reuse existing SOSAlert/SosAlertAttempt models for list/detail/status handling; keep analytics basic. [VERIFIED: prisma/schema.prisma] |
| ADMIN-05 | Broadcast/selective notifications | Build preview/confirm broadcast flow over existing Notification persistence/socket/push patterns. [VERIFIED: src/app/api/notifications/send/route.ts] |
</phase_requirements>

## Summary

Phase 06 is a product-readiness phase across four surfaces: Flutter mobile shell, Next.js web app shell, dictionary data/content workflows, and role-gated admin operations. [VERIFIED: 06-CONTEXT.md] The repo already has Next.js App Router route handlers, Prisma 7/PostgreSQL, Zod validation, JWT auth, Socket.io, SOS records, call pages, and Flutter service/screen patterns. [VERIFIED: package.json + prisma/schema.prisma + rg --files]

The planner should treat dictionary search as a backend/data problem first, not a UI filter. [ASSUMED] The safest v1 design is to persist canonical Vietnamese display text plus normalized searchable fields (`searchText`, `keywords`, slug) during import/admin save, then query published entries only for user surfaces and include drafts/needs-review only in admin. [VERIFIED: 06-CONTEXT.md; CITED: postgresql.org/docs/15/unaccent.html]

**Primary recommendation:** Plan a backend-first vertical slice: schema/enums/seed import/admin guards/audit logs, then user dictionary APIs, then web/mobile shells consuming those APIs, with upload presigning and admin broadcast handled after role enforcement is in place. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Mobile tab shell and production polish | Browser / Client (Flutter mobile client) | API / Backend | Flutter owns navigation, semantics, tap targets, empty/error states; backend only supplies session/data. [VERIFIED: mobile/lib/main.dart] |
| Web app shell | Frontend Server (Next.js App Router) | Browser / Client | Next.js owns route structure and protected pages; client components handle webcam/calls. [VERIFIED: src/app/page.tsx + src/app/calls/page.tsx] |
| Dictionary search and publication filtering | API / Backend | Database / Storage | Backend must enforce published-only user reads and admin-only drafts; DB owns indexes and normalized fields. [VERIFIED: 06-CONTEXT.md] |
| Dictionary videos | CDN / Static | Database / Storage | Object storage/CDN owns bytes; DB stores URL/key metadata. [VERIFIED: 06-CONTEXT.md] |
| Admin authorization | API / Backend | Frontend Server (SSR) | Route handlers must enforce role permissions; UI hiding is secondary only. [ASSUMED] |
| Admin audit logs | Database / Storage | API / Backend | Sensitive actions need durable records created transactionally with the state change. [VERIFIED: 06-CONTEXT.md] |
| Browser recognition | Browser / Client | Recognition service / Socket.io | Browser owns `getUserMedia`; existing recognition pipeline owns inference/events. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia; VERIFIED: mobile/lib/services/sign_recognition_service.dart] |
| Broadcast notifications | API / Backend | Database / Storage + Socket.io/Push | Backend resolves target users, creates notifications, emits foreground events, and uses existing push helper. [VERIFIED: src/app/api/notifications/send/route.ts] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Next.js | 16.2.4 in project; 16.2.6 latest | Web app, `/admin`, route handlers | Existing app uses App Router; official docs support Route Handlers as BFF/public endpoints. [VERIFIED: package.json/npm registry; CITED: nextjs.org/docs/app/guides/backend-for-frontend] |
| Prisma ORM | 7.8.0 | Schema, migrations, typed DB access | Existing schema and app DB client use Prisma 7 with PostgreSQL adapter. [VERIFIED: package.json/npm registry + src/app/lib/db.ts] |
| PostgreSQL | local `psql` 16.13 | Relational persistence and search indexes | Existing Prisma datasource is PostgreSQL; `unaccent` supports accent-insensitive text search. [VERIFIED: prisma/schema.prisma + psql --version; CITED: postgresql.org/docs/15/unaccent.html] |
| Zod | 4.4.3 | Request validation | Existing validators use `.safeParse`; Zod docs define `.safeParse` as non-throwing result validation. [VERIFIED: package.json/npm registry + src/app/lib/validators.ts; CITED: zod.dev/basics] |
| Flutter | 3.41.9 local | iOS/Android app shell | Existing mobile app is Flutter; official accessibility checklist covers screen readers, contrast, targets, scale. [VERIFIED: flutter --version + mobile/pubspec.yaml; CITED: docs.flutter.dev/ui/accessibility] |
| Socket.io | 4.8.3 | Foreground realtime notifications/recognition events | Existing recognition/call/notification paths use Socket.io. [VERIFIED: package.json + mobile/lib/services/sign_recognition_service.dart] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@aws-sdk/client-s3` | 3.1048.0 | S3-compatible object storage client | Use for admin one-off upload/replace metadata and optional server-side object checks. [VERIFIED: npm registry + slopcheck OK] |
| `@aws-sdk/s3-request-presigner` | 3.1048.0 | Generate presigned URLs | Use to let admin browser/mobile upload directly to object storage without routing large video bytes through Next.js. [VERIFIED: npm registry + slopcheck OK; CITED: docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/migrate-s3.html] |
| `video_player` | 2.11.1 | Flutter mobile dictionary video playback | Use the official Flutter package for network video playback and custom learning controls around play/pause, seek, replay, playback speed, and fullscreen routing. [VERIFIED: pub.dev/packages/video_player; CITED: docs.flutter.dev/cookbook/plugins/play-video] |
| firebase-admin | 13.10.0 | Push notifications | Existing dependency for background notifications; broadcast can reuse it after target selection. [VERIFIED: package.json/npm registry] |
| livekit-client/components | 2.x | Web video calls | Existing call pages already use LiveKit components and should remain separate from dictionary/admin work. [VERIFIED: package.json + src/app/calls] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Persisted normalized search fields | Compute normalization in every request | Persisting fields keeps imports/admin edits consistent and avoids repeated normalization bugs. [ASSUMED] |
| S3 presigned upload | Next.js multipart upload endpoint | Presigned upload avoids large MP4 buffering in route handlers; AWS docs warn v3 S3 streams must be consumed to avoid socket issues. [CITED: docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/migrate-s3.html] |
| Role checks in UI only | Backend guard helper + UI gating | Backend guard is required because Route Handlers are public endpoints. [CITED: nextjs.org/docs/app/guides/backend-for-frontend] |

**Installation:**

```bash
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
cd mobile && flutter pub add video_player
```

**Version verification:** `npm view` on 2026-05-17 returned `@aws-sdk/client-s3@3.1048.0` and `@aws-sdk/s3-request-presigner@3.1048.0`, both modified 2026-05-15. `pub.dev/packages/video_player` on 2026-05-17 lists latest `video_player` as `2.11.1` from `flutter.dev`; Flutter docs use `flutter pub add video_player` for internet video playback. [VERIFIED: npm registry + pub.dev; CITED: docs.flutter.dev/cookbook/plugins/play-video]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@aws-sdk/client-s3` | npm | created 2020-01-14 | 28,000,646/week | github.com/aws/aws-sdk-js-v3 | OK | Approved [VERIFIED: npm registry + npm downloads API + slopcheck] |
| `@aws-sdk/s3-request-presigner` | npm | created 2019-07-12 | 12,330,778/week | github.com/aws/aws-sdk-js-v3 | OK | Approved [VERIFIED: npm registry + npm downloads API + slopcheck] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: slopcheck]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: slopcheck]

Note: local `slopcheck` 0.6.1 rejected `--json` and its `install` subcommand invoked `npm install`; I immediately ran `npm uninstall` for the two AWS packages so the research step does not own dependency changes. [VERIFIED: terminal output + git diff]

## Architecture Patterns

### System Architecture Diagram

```text
Mobile Flutter tabs / Next.js app shell
  -> auth/profile/dictionary/admin/calls/recognition API calls
  -> Next.js Route Handlers
      -> getAuthenticatedUser(request)
      -> requireAdminRole(role set)
      -> Zod validation
      -> Prisma transaction
          -> users / dictionary entries / categories / notifications / SOS / audit logs
      -> Socket.io / Firebase push where needed

Dictionary import CSV/JSON manifest
  -> import script validates metadata + storage keys
  -> draft/needs_review/published rows
  -> published-only user API
  -> web/mobile card grid + detail video playback from CDN URL

Admin upload replace/add
  -> admin API creates presigned PUT URL
  -> browser uploads MP4/thumbnail to object storage
  -> admin API confirms key/url + metadata
  -> audit log entry
```

### Recommended Project Structure

```text
src/app/
├── admin/                 # protected admin pages and server/client components
├── dictionary/            # user-facing web dictionary pages
├── recognition/           # browser webcam recognition page
├── profile/               # web profile/account pages
└── api/
    ├── admin/             # role-gated admin APIs
    ├── dictionary/        # published user dictionary APIs
    └── storage/           # presigned upload/confirm APIs

src/app/lib/
├── admin-auth.ts          # requireAdminRole/permission helpers
├── dictionary-search.ts   # normalization/query helpers
├── storage.ts             # S3-compatible client/presigner
└── audit.ts               # admin audit helper

mobile/lib/
├── screens/dictionary/    # search, browse, detail
├── screens/profile/       # login/register/profile/session state
├── services/auth_service.dart
├── services/dictionary_service.dart
└── widgets/app_shell.dart
```

### Pattern 1: Route Handler With Auth, Validation, Transaction, Audit

**What:** Keep admin state changes in backend route handlers that authenticate, authorize, validate, mutate, and audit in one call. [VERIFIED: existing route handler pattern + 06-CONTEXT.md]
**When to use:** Role changes, user deactivation, dictionary publish/unpublish, broadcast send, SOS handling. [VERIFIED: 06-CONTEXT.md]

```typescript
// Source: local pattern from src/app/api/auth/login/route.ts + Zod docs safeParse
const payload = await getAuthenticatedUser(request)
if (!payload) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

await requireAdminRole(payload.userId, ['SUPER_ADMIN', 'CONTENT_ADMIN'])

const parsed = PublishDictionaryEntrySchema.safeParse(await request.json())
if (!parsed.success) {
  return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
}

const result = await prisma.$transaction(async (tx) => {
  const entry = await tx.dictionaryEntry.update({ where: { id }, data: parsed.data })
  await tx.adminAuditLog.create({
    data: { actorUserId: payload.userId, action: 'DICTIONARY_PUBLISH', targetId: entry.id },
  })
  return entry
})
```

### Pattern 2: Vietnamese Search Normalization At Write Time

**What:** Normalize display text and keywords during import/admin save; query normalized columns for accent/case/underscore/whitespace-insensitive partial matching. [ASSUMED]
**When to use:** Dictionary import, admin edit, user search, related signs. [VERIFIED: 06-CONTEXT.md]

```typescript
// Source: PostgreSQL unaccent docs + local Prisma/Zod conventions
export function normalizeVietnameseSearch(input: string): string {
  return input
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[_\s]+/g, ' ')
    .trim()
    .toLowerCase()
}
```

### Pattern 3: Flutter Shell Keeps Feature Routes Stable

**What:** Replace the button-list home with a `Scaffold` + Material 3 `NavigationBar`; keep existing deep routes for calls/SOS so push routing does not break. [VERIFIED: mobile/lib/main.dart; CITED: api.flutter.dev NavigationBar]
**When to use:** Main mobile tabs `Communicate`, `Dictionary`, `SOS`, `Profile`. [VERIFIED: 06-CONTEXT.md]

```dart
// Source: Flutter NavigationBar API docs + current mobile/lib/main.dart route pattern
Scaffold(
  body: IndexedStack(index: selectedIndex, children: const [
    CommunicateTab(),
    DictionaryTab(),
    SosTab(),
    ProfileTab(),
  ]),
  bottomNavigationBar: NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: setSelectedIndex,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Communicate'),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Dictionary'),
      NavigationDestination(icon: Icon(Icons.sos_outlined), label: 'SOS'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ],
  ),
)
```

### Anti-Patterns to Avoid

- **Client-only admin protection:** Route handlers are public endpoints; hiding `/admin` links is not authorization. [CITED: nextjs.org/docs/app/guides/backend-for-frontend]
- **User dictionary returns drafts:** Import defects must be visible to admin but hidden from users. [VERIFIED: 06-CONTEXT.md]
- **Web SOS pretending to be mobile SOS:** Browser SOS is informational/limited only. [VERIFIED: 06-CONTEXT.md]
- **Search only with raw `contains`:** Raw contains misses accent/underscore/spacing requirements. [VERIFIED: 06-CONTEXT.md]
- **Bulk-upload UI for 4,000 seed videos:** Initial dataset import is batch tooling, not admin UI. [VERIFIED: 06-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Object storage upload transport | Custom MP4 upload proxy in Next.js | S3-compatible storage + AWS SDK presigned URLs | Avoid buffering large video bytes and credential exposure. [CITED: docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/migrate-s3.html] |
| Request validation | Manual body checks | Zod schemas with `.safeParse` | Existing code already uses Zod; docs define typed parse/error result behavior. [VERIFIED: src/app/lib/validators.ts; CITED: zod.dev/basics] |
| Admin authorization | Per-route ad hoc `if` blocks | Shared `requireAdminRole`/permission map | Role matrix is explicit and must be consistent. [VERIFIED: 06-CONTEXT.md] |
| Audit logging | Console logs | `AdminAuditLog` table helper inside transactions | Required sensitive actions need durable history. [VERIFIED: 06-CONTEXT.md] |
| Browser camera polyfill | Deprecated `Navigator.getUserMedia` | `navigator.mediaDevices.getUserMedia()` | Current MDN docs mark mediaDevices API as baseline and secure-context gated. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia] |

**Key insight:** The difficult parts are state and permission boundaries, not page rendering. [ASSUMED] Plan admin role/audit/search/import contracts first, then attach web/mobile UI. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Admin UI Without Backend Authorization
**What goes wrong:** Non-admins can call admin APIs directly. [ASSUMED]
**Why it happens:** Planner treats `/admin` route visibility as security. [ASSUMED]
**How to avoid:** Every admin API calls shared auth + role helper before validation/mutation. [ASSUMED]
**Warning signs:** Tests only check page visibility, not direct API 401/403 responses. [ASSUMED]

### Pitfall 2: Vietnamese Search Works Only For Exact Accented Text
**What goes wrong:** Users cannot find entries when they omit accents, use case variants, or use underscores. [VERIFIED: 06-CONTEXT.md]
**Why it happens:** Query uses raw `contains` on display text only. [ASSUMED]
**How to avoid:** Persist normalized search columns and add DB indexes; optionally enable PostgreSQL `unaccent`. [CITED: postgresql.org/docs/15/unaccent.html]
**Warning signs:** Tests include `gia_dinh` but not `gia đình`, `Gia Dinh`, or partial terms. [ASSUMED]

### Pitfall 3: Draft/Needs-Review Entries Leak To Users
**What goes wrong:** Missing-video seed rows appear in dictionary results. [VERIFIED: 06-CONTEXT.md]
**Why it happens:** Admin and user APIs share one query without status filtering. [ASSUMED]
**How to avoid:** Separate user dictionary service/query that always enforces `status = PUBLISHED` and `videoUrl` present. [ASSUMED]
**Warning signs:** User API tests seed only published fixtures. [ASSUMED]

### Pitfall 4: Web Recognition Fails Outside Localhost
**What goes wrong:** Camera API unavailable on deployed HTTP or iframe contexts. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia]
**Why it happens:** `getUserMedia` requires secure contexts and explicit permission. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia]
**How to avoid:** HTTPS deployment, explicit permission/error UI, and tests for `NotAllowedError`/`NotFoundError`. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia]
**Warning signs:** Webcam page assumes `navigator.mediaDevices` exists. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia]

### Pitfall 5: Mobile Auth Token Remains Manual/One-Way
**What goes wrong:** Mobile app starts with empty `auth_token`, cannot register/login/refresh/logout cleanly, and push registration uses stale token. [VERIFIED: mobile/lib/main.dart]
**Why it happens:** Phase 1 web cookies exist, but mobile token storage/session flow is incomplete. [VERIFIED: src/app/api/auth/login/route.ts + mobile/lib/main.dart]
**How to avoid:** Add `AuthService`, secure token storage decision, refresh handling, and session-expired routing. [ASSUMED]
**Warning signs:** Profile/API calls only read cookies and ignore Bearer token. [VERIFIED: src/app/api/user/profile/route.ts]

## Code Examples

### User Dictionary Query Shape

```typescript
// Source: local Prisma pattern + Phase 06 decisions
export async function listPublishedDictionaryEntries(query: string | null, categorySlug: string | null) {
  const normalized = query ? normalizeVietnameseSearch(query) : null
  return prisma.dictionaryEntry.findMany({
    where: {
      status: 'PUBLISHED',
      videoUrl: { not: null },
      ...(categorySlug ? { category: { slug: categorySlug } } : {}),
      ...(normalized ? {
        OR: [
          { searchText: { contains: normalized, mode: 'insensitive' } },
          { keywordsText: { contains: normalized, mode: 'insensitive' } },
        ],
      } : {}),
    },
    orderBy: [{ vietnameseText: 'asc' }],
    take: 50,
  })
}
```

### Presigned Upload Route Shape

```typescript
// Source: AWS SDK v3 S3 presigner docs
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

const s3 = new S3Client({ region: process.env.S3_REGION })

export async function createDictionaryVideoUploadUrl(key: string, contentType: string) {
  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    ContentType: contentType,
  })
  return getSignedUrl(s3, command, { expiresIn: 300 })
}
```

### Browser Webcam Recognition Guard

```typescript
// Source: MDN getUserMedia docs
if (!navigator.mediaDevices?.getUserMedia) {
  setError('Camera requires HTTPS, localhost, and a supported browser.')
  return
}

const stream = await navigator.mediaDevices.getUserMedia({
  video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: 'user' },
  audio: false,
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Next.js Pages API routes | App Router `route.ts` Route Handlers/BFF | App Router era; current docs updated 2026-03-31 | Keep APIs under `src/app/api/**/route.ts`. [CITED: nextjs.org/docs/app/guides/backend-for-frontend] |
| Deprecated browser `Navigator.getUserMedia` | `navigator.mediaDevices.getUserMedia()` | Current MDN docs | Use secure-context mediaDevices API. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia] |
| Flutter `BottomNavigationBar` default for new M3 apps | Material 3 `NavigationBar` | Current Flutter API | Use `NavigationBar` for main mobile tabs. [CITED: api.flutter.dev/flutter/material/NavigationBar-class.html] |
| Manual exact text search | Normalized text fields + PostgreSQL search/indexing | Phase-specific requirement | Required for Vietnamese accent-insensitive partial matching. [VERIFIED: 06-CONTEXT.md; CITED: postgresql.org/docs/15/unaccent.html] |

**Deprecated/outdated:**
- Phase 2/STATE recognition validation wording is stale for Phase 6 planning; user clarified a full model now exists, so web recognition should connect to the real pipeline. [VERIFIED: 06-CONTEXT.md]
- Web SOS full parity is out of scope; do not plan browser SMS/dialer/GPS parity as a v1 requirement. [VERIFIED: 06-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Native mobile dictionary video playback requires adding the official Flutter `video_player` dependency. | Phase Requirements | Resolved: plan must install `video_player` and implement actual network playback controls, not metadata-only playback. |
| A2 | Category taxonomy can be chosen by planner if no authoritative VSL taxonomy exists. | User Constraints/Architecture | Browse UX may need user review before seeding categories. |
| A3 | Persisted normalized search fields are preferable to per-request normalization. | Summary/Patterns | Search implementation may be less optimal if DB extension/index strategy differs. |
| A4 | Admin authorization should use a shared role helper. | Architecture/Pitfalls | Ad hoc checks can drift across routes. |
| A5 | Mobile secure token storage choice is not yet established. | Pitfalls | Resolved for Phase 6: keep the existing `SharedPreferences` `auth_token` pattern for compatibility and document secure storage as a later hardening item unless already present. |

## Open Questions (RESOLVED)

1. **Which S3-compatible provider/bucket/CDN will be used?**
   - What we know: object storage/CDN is locked and S3-compatible is preferred. [VERIFIED: 06-CONTEXT.md]
   - Resolution: implement provider-neutral S3-compatible storage through environment variables: `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_FORCE_PATH_STYLE`, and `DICTIONARY_CDN_BASE_URL`. Do not hard-code provider, bucket, or CDN values in source. Admin presign APIs must fail with an explicit configuration error when credentials are absent. [ASSUMED]

2. **What is the source format for the 4,000-entry seed manifest?**
   - What we know: batch import is required and invalid rows become draft/needs_review. [VERIFIED: 06-CONTEXT.md]
   - Resolution: Phase 6 seed import accepts CSV as the canonical operator format with headers `slug`, `vietnameseText`, `category`, `keywords`, `videoKey`, `videoUrl`, `thumbnailKey`, `thumbnailUrl`, and optional `status`. The importer may also accept JSON arrays with the same field names if cheap, but CSV fixture coverage is mandatory. Rows with missing `videoKey`/`videoUrl`, missing Vietnamese text, duplicate slug, or invalid category import as `NEEDS_REVIEW` or `DRAFT` and never appear in user APIs. [ASSUMED]

3. **Should mobile use secure storage for tokens?**
   - What we know: mobile currently reads `auth_token` from SharedPreferences. [VERIFIED: mobile/lib/main.dart]
   - Resolution: Phase 6 keeps the existing `SharedPreferences` `auth_token` storage to avoid auth migration risk while adding session-expired handling and token refresh. Do not add `flutter_secure_storage` in Phase 6 unless it already exists in the repo; record secure token storage as future security hardening. [ASSUMED]

4. **Which Flutter package provides mobile dictionary video playback?**
   - What we know: mobile must deliver actual DICT-02/D-28 video playback from direct CDN URLs with play/pause/seek/replay/speed/fullscreen where supported. [VERIFIED: 06-CONTEXT.md + 06-UI-SPEC.md]
   - Resolution: use official `video_player` `2.11.1` from `flutter.dev` via `cd mobile && flutter pub add video_player`. Build a small app-specific control layer for replay, speed choices `0.5x`, `0.75x`, `1x`, and fullscreen route/dialog behavior; do not reduce this to metadata-only tests. [VERIFIED: pub.dev/packages/video_player; CITED: docs.flutter.dev/cookbook/plugins/play-video]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Next.js/Jest/npm scripts | yes | v20.20.2 | Upgrade may be needed if Prisma dependency engine requirements bite. [VERIFIED: node --version + npm warning] |
| npm | package verification/install | yes | 10.8.2 | none. [VERIFIED: npm --version] |
| Prisma CLI | schema/migration generation | yes | 7.8.0 | none. [VERIFIED: npx prisma --version] |
| PostgreSQL client | DB checks/migrations | yes | psql 16.13 | none. [VERIFIED: psql --version] |
| Flutter | mobile shell/tests | yes | 3.41.9 / Dart 3.11.5 | none. [VERIFIED: flutter --version] |
| Docker | local service orchestration | no | - | Use already configured external/local services or install Docker if planner needs compose. [VERIFIED: command -v docker] |
| ctx7 | docs lookup | no | - | Official docs via web used in this research. [VERIFIED: command -v ctx7] |
| slopcheck | package legitimacy | yes | 0.6.1 | Text output only; no `--json` support. [VERIFIED: slopcheck output] |

**Missing dependencies with no fallback:** none for planning. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Docker is missing; planner should avoid assuming docker-compose unless it adds an install/provisioning step. [VERIFIED: command -v docker]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Web/backend framework | Jest 29.7.0 with ts-jest; config `jest.config.ts`. [VERIFIED: package.json + jest.config.ts] |
| Mobile framework | `flutter_test` with Flutter 3.41.9; tests under `mobile/test`. [VERIFIED: mobile/pubspec.yaml + find mobile/test] |
| Quick web command | `npm test -- --runInBand src/__tests__/dictionary src/__tests__/admin` [ASSUMED] |
| Full web command | `npm test` [VERIFIED: package.json] |
| Mobile quick command | `cd mobile && flutter test test/widgets/app_shell_test.dart test/services/dictionary_service_test.dart` [ASSUMED] |
| Mobile full command | `cd mobile && flutter analyze && flutter test` [VERIFIED: mobile/analysis_options.yaml] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| MOB-01/MOB-02 | Tab shell, accessibility labels, SOS tab prominence, session expired state | widget | `cd mobile && flutter test test/widgets/app_shell_test.dart` | no - Wave 0 [VERIFIED: find mobile/test] |
| WEB-01 | Protected responsive app shell routes | React/Jest | `npm test -- src/__tests__/web/app-shell.test.tsx` | no - Wave 0 [VERIFIED: find src/__tests__] |
| WEB-03 | Webcam permission/error states and recognition connection | React/Jest | `npm test -- src/__tests__/web/recognition-page.test.tsx` | no - Wave 0 [VERIFIED: find src/__tests__] |
| WEB-04 | Cookie + Bearer auth profile behavior | API/Jest | `npm test -- src/__tests__/profile/profile.test.ts` | yes but needs Bearer cases [VERIFIED: rg] |
| DICT-01/02/03/04 | Import, published filtering, normalized search, categories, detail video metadata | API/Jest | `npm test -- src/__tests__/dictionary` | no - Wave 0 [VERIFIED: find src/__tests__] |
| ADMIN-01..05 | Role gates, user actions, dictionary publish, SOS review, broadcast preview/confirm, audit logs | API/Jest | `npm test -- src/__tests__/admin` | no - Wave 0 [VERIFIED: find src/__tests__] |

### Sampling Rate

- **Per task commit:** Run focused Jest/Flutter test for touched surface. [ASSUMED]
- **Per wave merge:** `npm test` plus `cd mobile && flutter analyze && flutter test` when mobile touched. [VERIFIED: package.json + mobile/pubspec.yaml]
- **Phase gate:** Full web/backend and mobile suites green before `$gsd-verify-work`. [ASSUMED]

### Wave 0 Gaps

- [ ] `src/__tests__/dictionary/dictionary-api.test.ts` - covers DICT-01 through DICT-04. [VERIFIED: absent by find]
- [ ] `src/__tests__/admin/admin-auth.test.ts` - covers ADMIN role/403 matrix. [VERIFIED: absent by find]
- [ ] `src/__tests__/admin/admin-audit.test.ts` - covers D-14 audit writes. [VERIFIED: absent by find]
- [ ] `src/__tests__/web/app-shell.test.tsx` - covers WEB-01 shell/nav. [VERIFIED: absent by find]
- [ ] `src/__tests__/web/recognition-page.test.tsx` - covers WEB-03 permission states. [VERIFIED: absent by find]
- [ ] `mobile/test/widgets/app_shell_test.dart` - covers MOB-01/MOB-02 shell. [VERIFIED: absent by find]
- [ ] `mobile/test/services/dictionary_service_test.dart` - covers mobile dictionary API client. [VERIFIED: absent by find]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing JWT access/refresh token flow, extended to mobile Bearer refresh/session handling. [VERIFIED: src/app/api/auth/*] |
| V3 Session Management | yes | Refresh-token rotation exists; add mobile session-expired handling and deactivation checks. [VERIFIED: src/app/api/auth/refresh/route.ts] |
| V4 Access Control | yes | Shared `requireAdminRole` for Super/Content/Support Admin and API-level 403 tests. [VERIFIED: 06-CONTEXT.md] |
| V5 Input Validation | yes | Zod schemas for all route bodies/query params; manifest importer validates rows. [VERIFIED: src/app/lib/validators.ts; CITED: zod.dev/basics] |
| V6 Cryptography | yes | Keep `jose` JWT and `bcrypt`; do not implement custom crypto. [VERIFIED: package.json + src/app/lib/auth.ts] |
| V7 Error Handling and Logging | yes | Return generic client errors; write `AdminAuditLog` for sensitive actions. [VERIFIED: 06-CONTEXT.md; CITED: nextjs.org/docs/app/guides/backend-for-frontend] |
| V12 File and Resources | yes | Presigned URL upload with content-type/key validation and no public arbitrary write paths. [ASSUMED] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| IDOR on admin user/SOS/dictionary routes | Elevation of privilege | API-level auth + role + ownership checks, not UI-only controls. [ASSUMED] |
| Draft dictionary content exposure | Information disclosure | Separate admin/user queries and published-only user filter. [VERIFIED: 06-CONTEXT.md] |
| Malicious upload key/content type | Tampering | Server-generated storage keys, allowlist MP4/image MIME types, presigned URL expiry, confirm route. [ASSUMED] |
| Broadcast abuse | Spoofing/repudiation | Super/Support role gate, preview/confirm, target count, immutable audit record. [VERIFIED: 06-CONTEXT.md] |
| Webcam privacy failure | Information disclosure | Permission-first UX, secure context, explicit stop/cleanup of media tracks. [CITED: developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia] |
| Sensitive user data in admin list | Information disclosure | Explicit Prisma `select` fields; no password/token/emergency secrets in list responses. [VERIFIED: 06-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/06-app-dictionary-admin-readiness/06-CONTEXT.md` - locked phase decisions and scope. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - requirement IDs, phase dependencies, stale recognition note. [VERIFIED: codebase grep]
- `package.json`, `mobile/pubspec.yaml`, `prisma/schema.prisma`, `src/app/lib/*`, `mobile/lib/*` - current stack and patterns. [VERIFIED: codebase grep]
- Next.js Backend for Frontend docs - route handlers are public endpoints, validation/auth guidance, Server Component caveat: https://nextjs.org/docs/app/guides/backend-for-frontend [CITED: nextjs.org]
- PostgreSQL `unaccent` docs - accent-insensitive text processing: https://www.postgresql.org/docs/15/unaccent.html [CITED: postgresql.org]
- MDN `getUserMedia` docs - secure context, permission, error behavior: https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia [CITED: developer.mozilla.org]
- Flutter accessibility docs - screen reader, contrast, 48x48 target, scaling checklist: https://docs.flutter.dev/ui/accessibility [CITED: docs.flutter.dev]
- Flutter `NavigationBar` API docs - Material 3 persistent destinations: https://api.flutter.dev/flutter/material/NavigationBar-class.html [CITED: api.flutter.dev]
- Zod basics - `.safeParse`, errors, inferred types: https://zod.dev/basics [CITED: zod.dev]
- AWS SDK for JavaScript S3 docs - v3 presigner package and S3 stream considerations: https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/migrate-s3.html [CITED: docs.aws.amazon.com]

### Secondary (MEDIUM confidence)

- npm registry and downloads API for package versions/downloads/repositories. [VERIFIED: npm registry]
- `slopcheck` 0.6.1 text output for AWS SDK package legitimacy. [VERIFIED: slopcheck]

### Tertiary (LOW confidence)

- Assumptions in this document about exact taxonomy, mobile secure storage, and normalized search implementation details. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - project package files, local versions, npm registry, and official docs were checked. [VERIFIED: package.json/npm registry]
- Architecture: HIGH - phase decisions and existing code boundaries are explicit. [VERIFIED: 06-CONTEXT.md + codebase grep]
- Pitfalls: MEDIUM - most are derived from locked decisions and official docs; some implementation-specific risk is assumed. [ASSUMED]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16 for local stack shape; re-check npm/package versions and browser/mobile docs before installing new dependencies. [ASSUMED]
