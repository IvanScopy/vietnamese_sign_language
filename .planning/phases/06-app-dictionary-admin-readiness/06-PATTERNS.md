# Phase 06: App, Dictionary & Admin Readiness - Pattern Map

**Mapped:** 2026-05-17  
**Files analyzed:** 34  
**Analogs found:** 31 / 34

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `prisma/schema.prisma` | model | CRUD | `prisma/schema.prisma` `User`, `Notification`, `SOSAlert`, `CallSession` | exact |
| `scripts/import-dictionary.ts` | utility | batch | `src/app/lib/sos.ts` | partial |
| `src/app/lib/admin-auth.ts` | utility | request-response | `src/app/lib/request-auth.ts` | role-match |
| `src/app/lib/audit.ts` | utility | CRUD | `src/app/lib/sos.ts` | role-match |
| `src/app/lib/dictionary-search.ts` | utility | transform | `src/app/lib/sos.ts` | partial |
| `src/app/lib/storage.ts` | service | file-I/O | none | none |
| `src/app/lib/validators.ts` | utility | request-response | `src/app/lib/validators.ts` | exact |
| `src/app/api/dictionary/route.ts` | route | request-response | `src/app/api/users/route.ts` | role-match |
| `src/app/api/dictionary/[slug]/route.ts` | route | request-response | `src/app/api/calls/[callId]/route.ts` | role-match |
| `src/app/api/admin/users/route.ts` | route | request-response | `src/app/api/users/route.ts` | role-match |
| `src/app/api/admin/users/[id]/route.ts` | route | CRUD | `src/app/api/user/profile/route.ts` | role-match |
| `src/app/api/admin/dictionary/route.ts` | route | CRUD | `src/app/api/calls/route.ts` | role-match |
| `src/app/api/admin/dictionary/[id]/route.ts` | route | CRUD | `src/app/api/user/profile/route.ts` | role-match |
| `src/app/api/admin/dictionary/[id]/publish/route.ts` | route | CRUD | `src/app/api/calls/route.ts` | role-match |
| `src/app/api/admin/storage/presign/route.ts` | route | file-I/O | `src/app/api/stt/transcribe/route.ts` | partial |
| `src/app/api/admin/sos/route.ts` | route | request-response | `src/app/api/sos/alerts/route.ts` + `src/app/lib/sos.ts` | role-match |
| `src/app/api/admin/notifications/broadcast/route.ts` | route | event-driven | `src/app/api/notifications/send/route.ts` | role-match |
| `src/app/page.tsx` | component | request-response | `src/app/calls/page.tsx` | role-match |
| `src/app/dictionary/page.tsx` | component | request-response | `src/components/calls/CallEntry.tsx` | role-match |
| `src/app/dictionary/[slug]/page.tsx` | component | request-response | `src/app/calls/page.tsx` | role-match |
| `src/app/recognition/page.tsx` | component | streaming | `src/app/calls/page.tsx` + `mobile/lib/services/sign_recognition_service.dart` | partial |
| `src/app/profile/page.tsx` | component | request-response | `src/app/calls/page.tsx` | role-match |
| `src/app/admin/page.tsx` | component | request-response | `src/app/calls/page.tsx` | role-match |
| `src/app/admin/**/page.tsx` | component | CRUD | `src/components/calls/CallEntry.tsx` | role-match |
| `mobile/lib/main.dart` | route/provider | event-driven | `mobile/lib/main.dart` | exact |
| `mobile/lib/widgets/app_shell.dart` | component | event-driven | `mobile/lib/main.dart` `HomeScreen` | role-match |
| `mobile/lib/services/auth_service.dart` | service | request-response | `mobile/lib/services/sos_api_service.dart` | role-match |
| `mobile/lib/services/dictionary_service.dart` | service | request-response | `mobile/lib/services/sos_api_service.dart` | role-match |
| `mobile/lib/screens/dictionary/*.dart` | component | request-response | `mobile/lib/screens/sos_screen.dart` | role-match |
| `mobile/lib/screens/profile/*.dart` | component | request-response | `mobile/lib/screens/conversation_screen.dart` | role-match |
| `src/__tests__/dictionary/*.test.ts` | test | request-response | `src/__tests__/sos/sos-api.test.ts` | role-match |
| `src/__tests__/admin/*.test.ts` | test | CRUD | `src/__tests__/profile/profile.test.ts` | role-match |
| `src/__tests__/web/*.test.tsx` | test | request-response | `src/__tests__/web/call-page.test.tsx` | role-match |
| `mobile/test/services/dictionary_service_test.dart` | test | request-response | `mobile/test/services/sos_api_service_test.dart` | role-match |

## Pattern Assignments

### `prisma/schema.prisma` (model, CRUD)

**Analog:** `prisma/schema.prisma`

**Model/relation pattern** (lines 9-29):
```prisma
model User {
  id           Int       @id @default(autoincrement())
  email        String    @unique
  password     String    // bcrypt hash
  name         String?
  userType     UserType  @default(HEARING)
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  // Relations
  refreshTokens              RefreshToken[]
  emergencyContacts          EmergencyContact[]
  linkedEmergencyContacts    EmergencyContact[] @relation("EmergencyContactLinkedUser")
  deviceTokens               DeviceToken[]
  notifications              Notification[]

  @@map("users")
}
```

**Enum pattern** (lines 44-49):
```prisma
enum UserType {
  DEAF
  HEARING
  PARENT
  TEACHER
}
```

**Indexed operational model pattern** (lines 167-197):
```prisma
model SosAlertAttempt {
  id                   Int                @id @default(autoincrement())
  sosAlertId           Int
  sosAlert             SOSAlert           @relation(fields: [sosAlertId], references: [id], onDelete: Cascade)
  status               SOSAttemptStatus
  createdAt            DateTime           @default(now())
  updatedAt            DateTime           @updatedAt

  @@index([sosAlertId])
  @@index([status])
  @@map("sos_alert_attempts")
}
```

Apply to dictionary entries/categories, admin roles, content placeholders, upload metadata, and `AdminAuditLog`: use explicit enums, `createdAt`/`updatedAt`, relation arrays on `User`, `@@index` for search/status/actor fields, and `@@map` snake-case table names.

---

### `src/app/lib/admin-auth.ts` (utility, request-response)

**Analog:** `src/app/lib/request-auth.ts`

**Auth source pattern** (lines 1-20):
```typescript
import { NextRequest } from 'next/server'
import { verifyAccessToken } from './auth'
import type { AuthPayload } from './auth'

export async function getAuthenticatedUser(request: NextRequest): Promise<AuthPayload | null> {
  const cookieToken = request.cookies.get('accessToken')?.value
  if (cookieToken) {
    const payload = await verifyAccessToken(cookieToken)
    if (payload) return payload
  }
  const authHeader = request.headers.get('Authorization')
  if (authHeader?.startsWith('Bearer ')) {
    const bearerToken = authHeader.slice(7)
    const payload = await verifyAccessToken(bearerToken)
    if (payload) return payload
  }
  return null
}
```

Use this as the base for admin guards. `requireAdminRole` should call `getAuthenticatedUser(request)`, then load the user/admin role with Prisma and return either a typed actor or a `NextResponse`-ready 401/403 result. Keep cookie plus Bearer support because web and mobile share account/session behavior.

---

### `src/app/lib/validators.ts` (utility, request-response)

**Analog:** `src/app/lib/validators.ts`

**Schema export pattern** (lines 1-13, 34-41, 52-83):
```typescript
import { z } from 'zod'

export const RegisterSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required'),
  userType: z.enum(['DEAF', 'HEARING', 'PARENT', 'TEACHER']),
})

export const SendNotificationSchema = z.object({
  toUserId: z.number().int().positive(),
  title: z.string().min(1),
  body: z.string().min(1),
  priority: z.enum(['normal', 'high']).default('normal'),
  type: z.enum(['CALL', 'SOS', 'MESSAGE', 'LEARNING']).default('MESSAGE'),
})
```

Add dictionary/admin schemas here or in colocated validator modules with the same `z.object` + exported constant style. Route handlers should use `.safeParse` and return `{ errors: validated.error.flatten() }` on 400.

---

### `src/app/api/dictionary/route.ts` (route, request-response)

**Analog:** `src/app/api/users/route.ts`

**List/select pattern** (lines 1-29):
```typescript
import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function GET(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const users = await prisma.user.findMany({
      where: { id: { not: payload.userId } },
      select: { id: true, name: true, email: true, userType: true },
      orderBy: [{ name: 'asc' }, { email: 'asc' }],
      take: 50,
    })

    return NextResponse.json({ users })
  } catch (error) {
    console.error('Users lookup error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
```

Copy the limited `select`, deterministic `orderBy`, `take`, and generic 500 pattern. Change auth only if public dictionary browsing is intended; regardless, enforce `status: 'PUBLISHED'` and video URL/key present in the query.

---

### `src/app/api/admin/**/route.ts` (route, CRUD/request-response)

**Analogs:** `src/app/api/calls/route.ts`, `src/app/api/user/profile/route.ts`

**Authenticated mutation pattern** (`src/app/api/calls/route.ts` lines 9-30):
```typescript
export async function POST(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const validated = CreateCallSchema.safeParse(body)
    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 },
      )
    }

    const { calleeId } = validated.data
```

**Update/select response pattern** (`src/app/api/user/profile/route.ts` lines 63-95):
```typescript
const body = await request.json()
const validated = UpdateProfileSchema.safeParse(body)

if (!validated.success) {
  return NextResponse.json(
    { errors: validated.error.flatten() },
    { status: 400 }
  )
}

const updatedUser = await prisma.user.update({
  where: { id: payload.userId },
  data: {
    ...(name !== undefined && { name }),
    ...(userType !== undefined && { userType }),
  },
  select: {
    id: true,
    email: true,
    name: true,
    userType: true,
  },
})

return NextResponse.json({ user: updatedUser })
```

Apply to admin user management, dictionary CRUD, publish/unpublish, lesson placeholder CRUD, SOS handling, and broadcast confirmation. Add admin role checks before reading the body. Use explicit `select` to avoid password/token leakage.

---

### `src/app/lib/audit.ts` and sensitive admin mutations (utility, CRUD)

**Analog:** `src/app/lib/sos.ts`

**Durable operation record pattern** (lines 72-86, 100-114, 141-164):
```typescript
const alert = await prisma.sOSAlert.create({
  data: {
    userId,
    status: contacts.length === 0 ? 'SENT' : 'SENDING',
    latitude: data.latitude,
    longitude: data.longitude,
    smsBody,
    idempotencyKey: data.idempotencyKey,
    sentAt: new Date(),
  },
})

const attemptCreates = contacts.map((contact) =>
  prisma.sosAlertAttempt.create({
    data: {
      sosAlertId: alert.id,
      emergencyContactId: contact.id,
      status: 'PROVIDER_QUEUED',
      queuedAt: new Date(),
    },
  })
)
const attempts = await Promise.all(attemptCreates)
```

For admin audit, create the domain mutation and audit row in one transaction where possible. Mirror the pattern of creating the parent record, then child operational records with action/status timestamps.

---

### `src/app/api/admin/notifications/broadcast/route.ts` (route, event-driven)

**Analog:** `src/app/api/notifications/send/route.ts`

**Validation + realtime + persistence pattern** (lines 6-42):
```typescript
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = SendNotificationSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { toUserId, title, body: messageBody, data, priority, type } = validated.data

    const io = getIOInstance()
    if (io) {
      io.to(`user:${toUserId}`).emit('notification', {
        title,
        body: messageBody,
        data,
        priority,
        type,
        timestamp: Date.now(),
      })
    }

    await prisma.$executeRaw`
      INSERT INTO notifications (title, body, data, priority, type, "userId")
      VALUES (${title}, ${messageBody}, ${JSON.stringify(data || {})}, ${priority}, ${type}, ${toUserId})
    `

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Send notification error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
```

For broadcast, replace single `toUserId` with target resolution (`findMany` by user type/active filters), preview returning target count, confirm creating notifications, socket emits per user room, push dispatch if available, and audit log.

---

### `src/app/api/admin/sos/route.ts` (route, request-response)

**Analog:** `src/app/api/sos/alerts/route.ts` + `src/app/lib/sos.ts`

**Route/service split pattern** (`src/app/api/sos/alerts/route.ts` lines 6-27):
```typescript
export async function POST(request: NextRequest) {
  const payload = await getAuthenticatedUser(request);
  if (!payload) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const validation = CreateSosAlertSchema.safeParse(body);
  if (!validation.success) {
    return NextResponse.json({ error: 'Invalid request', details: validation.error.flatten() }, { status: 400 });
  }

  try {
    const result = await createSosAlert(payload.userId, validation.data);
    return NextResponse.json(result, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: 'SOS creation failed', message: err.message }, { status: 500 });
  }
}
```

**Status semantics pattern** (`src/app/lib/sos.ts` lines 225-258):
```typescript
const statusMap = {
  native_sms_opened: 'NATIVE_COMPOSER_OPENED' as const,
  native_sms_failed: 'NATIVE_COMPOSER_FAILED' as const,
  dialer_opened: 'DIALER_OPENED' as const,
};
const status = statusMap[data.fallbackType];

await prisma.sosAlertAttempt.create({
  data: {
    sosAlertId: alertId,
    channel: data.fallbackType === 'dialer_opened' ? 'DIALER' : 'NATIVE_SMS',
    status,
    openedAt: now,
  },
});
```

Admin SOS review should preserve honest status semantics and avoid converting fallback intent into confirmed delivery.

---

### `src/app/lib/dictionary-search.ts` and `scripts/import-dictionary.ts` (utility, transform/batch)

**Analog:** `src/app/lib/sos.ts`

**Pure transform before persistence pattern** (lines 1-29, 64-83):
```typescript
export function buildSosSmsBody({ userName, latitude, longitude, locationLabel, locationCapturedAt }: {
  userName: string;
  latitude?: number;
  longitude?: number;
  locationLabel?: string;
  locationCapturedAt?: Date | string;
}): string {
  const now = locationCapturedAt ? new Date(locationCapturedAt) : new Date();
  const timeStr = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  let locationText: string;
  if (latitude != null && longitude != null) {
    const mapLink = `https://maps.google.com/?q=${latitude},${longitude}`;
    locationText = `Vị trí: ${mapLink}`;
  } else {
    locationText = 'Không có vị trí GPS';
  }
  return `...${locationText}\nThời gian: ${timeStr}`;
}
```

Use a pure `normalizeVietnameseSearch(input)` helper before import/admin save. Import script should validate rows, derive slug/search fields, mark invalid rows `NEEDS_REVIEW`/`DRAFT`, and persist without exposing invalid rows to user APIs.

---

### `src/app/page.tsx`, `src/app/dictionary/**/*.tsx`, `src/app/profile/page.tsx`, `src/app/admin/**/*.tsx` (component, request-response/CRUD)

**Analogs:** `src/app/calls/page.tsx`, `src/components/calls/CallEntry.tsx`, `src/components/calls/IncomingCallModal.tsx`

**Client page data loading pattern** (`src/app/calls/page.tsx` lines 35-66):
```typescript
useEffect(() => {
  async function fetchPageData() {
    try {
      const [profileResponse, usersResponse] = await Promise.all([
        fetch('/api/user/profile', { credentials: 'include' }),
        fetch('/api/users', { credentials: 'include' }),
      ])

      if (profileResponse.ok) {
        const profile = (await profileResponse.json()) as ProfileResponse
        const user = profile.user ?? profile
        if (typeof user.id === 'number') {
          setCurrentUser({ id: user.id, userType: user.userType || 'HEARING' })
        }
      }

      if (usersResponse.ok) {
        const data = await usersResponse.json()
        setUsers(data.users || [])
      }
    } catch {
      setUsers([])
    } finally {
      setIsLoading(false)
    }
  }
  fetchPageData()
}, [])
```

**Form/action state pattern** (`src/components/calls/CallEntry.tsx` lines 18-45):
```typescript
const handleStartCall = async () => {
  if (!selectedUserId) return

  setIsInitiating(true)
  setError(null)

  try {
    const response = await fetch('/api/calls', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ calleeId: selectedUserId }),
      credentials: 'include',
    })

    if (!response.ok) {
      const data = await response.json().catch(() => ({}))
      throw new Error(data.error || 'Failed to start call')
    }
  } catch (err) {
    setError(err instanceof Error ? err.message : 'Failed to start call')
  } finally {
    setIsInitiating(false)
  }
}
```

**Accessible modal/action pattern** (`src/components/calls/IncomingCallModal.tsx` lines 24-39, 107-161):
```tsx
<div
  role="dialog"
  aria-modal="true"
  aria-label="Incoming video call"
  style={{ position: 'fixed', inset: 0, zIndex: 50 }}
>
  <button type="button" onClick={onReject} aria-label="Reject call">Reject</button>
  <button type="button" onClick={onAccept} aria-label="Accept call">Accept</button>
</div>
```

Use these for dictionary search/results/detail, profile forms, admin tables/forms, preview/confirm broadcast modals, and protected shell loading/error states.

---

### `src/app/recognition/page.tsx` (component, streaming)

**Analogs:** `src/app/calls/page.tsx`, `mobile/lib/services/sign_recognition_service.dart`

**Socket lifecycle pattern** (`src/app/calls/page.tsx` lines 68-98):
```typescript
useEffect(() => {
  const socket = io(process.env.NEXT_PUBLIC_CLIENT_URL || '/', {
    withCredentials: true,
    transports: ['websocket', 'polling'],
  })
  socketRef.current = socket

  socket.on('connect', () => {
    if (currentUser) {
      socket.emit('register', currentUser.id, currentUser.userType)
    }
  })

  socket.on('call:incoming', (data: IncomingCallEvent) => {
    setIncomingCall(data)
  })

  return () => {
    socket.disconnect()
  }
}, [currentUser])
```

**Recognition event parse pattern** (`mobile/lib/services/sign_recognition_service.dart` lines 112-146):
```dart
_socket!.on('sign_recognized', (data) {
  try {
    final result = RecognitionResult(
      sign: data['sign'] as String,
      confidence: (data['confidence'] as num).toDouble(),
    );
    _signController.add(result);
  } catch (e) {
    debugPrint('Error parsing sign_recognized: $e');
  }
});
```

Browser recognition should use `getUserMedia` for webcam frames and mirror the existing event names/results from the recognition pipeline.

---

### `mobile/lib/main.dart` and `mobile/lib/widgets/app_shell.dart` (route/provider/component, event-driven)

**Analog:** `mobile/lib/main.dart`

**App bootstrap and dependency injection pattern** (lines 31-54, 71-90):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.load();
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token') ?? '';

  final pushService = PushNotificationService(
    baseUrl: config.httpUrl,
    authToken: authToken.isNotEmpty ? authToken : null,
  );
  await pushService.initialize(navigatorKey);

  runApp(VSLBridgeApp(config: config, authToken: authToken, pushService: pushService));
}

return MaterialApp(
  title: 'VSL Bridge',
  navigatorKey: navigatorKey,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  ),
  home: HomeScreen(config: config, authToken: authToken),
  routes: { '/recognition': (context) => RecognitionScreen(...) },
);
```

**Stable generated route pattern** (lines 90-189):
```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/calls/incoming':
      final args = settings.arguments as Map<String, dynamic>?;
      final callId = _parseRouteInt(args?['callId']);
      if (callId == null || callId < 1) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid call notification')),
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => IncomingCallScreen(...));
    case '/sos':
      return MaterialPageRoute(builder: (_) => SosScreen(...));
    default:
      return null;
  }
}
```

Replace `HomeScreen` with a Material 3 tab shell, but keep named routes and push notification destinations stable.

---

### `mobile/lib/services/auth_service.dart` and `mobile/lib/services/dictionary_service.dart` (service, request-response)

**Analog:** `mobile/lib/services/sos_api_service.dart`

**DTO/exception/header pattern** (lines 86-139):
```dart
class SosApiException implements Exception {
  final int statusCode;
  final String message;

  SosApiException(this.statusCode, this.message);

  @override
  String toString() => 'SosApiException($statusCode): $message';
}

class SosAuthException extends SosApiException {
  SosAuthException() : super(401, 'Unauthorized');
}

class SosApiService {
  final http.Client _client;
  final String _authToken;
  final String _baseUrl;

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_authToken',
    'Content-Type': 'application/json',
  };

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) throw SosAuthException();
    if (response.statusCode >= 400) {
      String msg = 'Request failed';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        msg = body['error'] as String? ?? body['message'] as String? ?? msg;
      } catch (_) {}
      throw SosApiException(response.statusCode, msg);
    }
  }
}
```

**Request/parse pattern** (lines 145-174):
```dart
final response = await _client.post(
  Uri.parse('$_baseUrl/api/sos/alerts'),
  headers: _authHeaders,
  body: jsonEncode(body),
);
_throwOnError(response);
return SosAlertResponse.fromJson(
  jsonDecode(response.body) as Map<String, dynamic>,
);
```

Use the same injectable `http.Client`, typed response factories, Bearer header, 401-specific exception, and `dispose()` pattern.

---

### `mobile/lib/screens/dictionary/*.dart` and `mobile/lib/screens/profile/*.dart` (component, request-response)

**Analog:** `mobile/lib/main.dart` `HomeScreen`

**Accessible action pattern** (lines 322-395):
```dart
Semantics(
  label: 'Nút SOS khẩn cấp. Nhấn giữ 2 giây để bắt đầu.',
  child: SizedBox(
    height: 64,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pushNamed('/sos');
      },
      icon: const Icon(Icons.warning_rounded, color: Colors.white),
      label: const Text(
        'SOS khẩn cấp',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  ),
)
```

For dictionary/profile screens, keep large tap targets, semantic labels, clear loading/error/empty states, and no flashing effects. Use `Navigator.of(context).pushNamed(...)` for existing feature routes.

---

### `src/__tests__/dictionary/*.test.ts` and `src/__tests__/admin/*.test.ts` (test, CRUD/request-response)

**Analogs:** `src/__tests__/sos/sos-api.test.ts`, `src/__tests__/profile/profile.test.ts`, `src/__tests__/setup.ts`

**Route test auth mock pattern** (`src/__tests__/sos/sos-api.test.ts` lines 6-24, 42-54):
```typescript
jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

import { getAuthenticatedUser } from '@/app/lib/request-auth'

const MOCK_AUTH_USER = { userId: 42, email: 'deaf.user@example.com', userType: 'DEAF' }

const makeRequest = (body?: unknown) =>
  new NextRequest('http://localhost:3000/api/sos/alerts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body ?? {}),
  })

it('returns 401 when not authenticated', async () => {
  ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)
  const response = await POST(makeRequest({}))
  expect(response.status).toBe(401)
})
```

**Prisma mock setup pattern** (`src/__tests__/setup.ts` lines 3-64):
```typescript
jest.mock('@/app/lib/db', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
      delete: jest.fn(),
    },
    $transaction: jest.fn(async (fn) => fn),
  },
}))
```

Extend setup for dictionary/admin/audit/storage models. Tests should cover 401/403 role matrix, draft leakage prevention, normalized Vietnamese search variants, sensitive `select` fields, and audit writes.

---

### `src/__tests__/web/*.test.tsx` (test, request-response)

**Analog:** `src/__tests__/web/call-page.test.tsx`

**Fetch-driven page helper pattern** (lines 32-67):
```typescript
const jsonResponse = (body: unknown, ok = true) =>
  ({
    ok,
    json: jest.fn(async () => body),
  }) as unknown as Response

beforeEach(() => {
  global.fetch = jest.fn() as unknown as typeof fetch
})

test('ACTIVE call state triggers GET then POST token', async () => {
  const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
  fetchMock
    .mockResolvedValueOnce(jsonResponse({ id: 42, state: 'ACTIVE' }))
    .mockResolvedValueOnce(jsonResponse({ token: 'active-token' }))

  const result = await fetchCallPageData(42)

  expect(fetchMock).toHaveBeenNthCalledWith(1, '/api/calls/42', {
    credentials: 'include',
  })
  expect(result.token).toBe('active-token')
})
```

Use exported pure helpers for page fetch flows where possible. Test app shell navigation, dictionary loading/error/empty states, recognition camera unsupported/permission-denied states, and admin preview/confirm flows.

---

### `mobile/test/services/dictionary_service_test.dart` and `mobile/test/widgets/app_shell_test.dart` (test, request-response/event-driven)

**Analogs:** `mobile/test/services/sos_api_service_test.dart`, `mobile/test/widgets/conversation_screen_test.dart`

**Mock HTTP service test pattern** (`mobile/test/services/sos_api_service_test.dart` lines 14-41, 88-103):
```dart
void main() {
  const testToken = 'test-bearer-token-123';
  const baseUrl = 'http://test.example.com';

  test('includes Bearer Authorization header in request', () async {
    String? capturedAuth;
    final client = MockClient((request) async {
      capturedAuth = request.headers['authorization'];
      return _jsonResponse(200, {'id': 1, 'status': 'sending'});
    });

    final service = SosApiService(authToken: testToken, client: client, baseUrl: baseUrl);
    await service.createAlert();

    expect(capturedAuth, equals('Bearer $testToken'));
  });

  test('throws SosAuthException on 401 response', () async {
    final client = MockClient((request) async => http.Response('{"error":"Unauthorized"}', 401));
    final service = SosApiService(authToken: testToken, client: client, baseUrl: baseUrl);
    expect(() => service.createAlert(), throwsA(isA<SosAuthException>()));
  });
}
```

**Widget test dependency injection pattern** (`mobile/test/widgets/conversation_screen_test.dart` lines 13-37):
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  historyService = ConversationHistoryService(preferences);
  config = AppConfig.create(environment: 'test', serverUrl: 'localhost', serverPort: 8000);
});

await tester.pumpWidget(
  MaterialApp(
    home: ConversationScreen(
      config: config,
      authToken: 'token',
      historyService: historyService,
      autoConnect: false,
      enableCamera: false,
    ),
  ),
);
```

Use injected services/config and `SharedPreferences.setMockInitialValues` for shell/profile tests. Verify tab labels, SOS prominence, dictionary search states, profile session-expired behavior, and service 401 mapping.

## Shared Patterns

### Authentication

**Source:** `src/app/lib/request-auth.ts`  
**Apply to:** all protected route handlers and admin guards

Use cookie-first auth for web, Bearer fallback for mobile. Admin APIs must add a role lookup after this helper and return 403 for authenticated users without the required role.

### Validation

**Source:** `src/app/lib/validators.ts` and route usage in `src/app/api/calls/route.ts`  
**Apply to:** all POST/PUT/PATCH admin, auth, dictionary, SOS, storage, and broadcast routes

Use exported Zod schemas plus `.safeParse`; 400 responses should include flattened errors.

### Error Handling

**Source:** `src/app/api/users/route.ts`, `src/app/api/calls/route.ts`, `mobile/lib/services/sos_api_service.dart`  
**Apply to:** all API routes and Flutter services

Next routes use `try/catch`, log server errors, and return generic 500 JSON. Flutter services map 401 to a specific auth exception and parse backend `{ error }`/`{ message }` where available.

### Realtime And Notifications

**Source:** `src/app/api/notifications/send/route.ts`, `src/app/calls/page.tsx`, `mobile/lib/services/push_notification_service.dart`  
**Apply to:** broadcast notifications, web notification surfaces, app shell notification routing

Persist offline notification rows and emit foreground socket events to `user:{id}` rooms. Mobile notification routing uses typed `data['type']` and stable route names.

### Database Writes And Operational Records

**Source:** `src/app/lib/sos.ts`, `prisma/schema.prisma`  
**Apply to:** audit logs, dictionary publish/unpublish, SOS handling, broadcast confirmation

Use parent domain records plus child operational records with status enums and timestamps. Sensitive admin actions should write `AdminAuditLog` in the same transaction as the state change.

### UI Accessibility

**Source:** `src/components/calls/IncomingCallModal.tsx`, `mobile/lib/main.dart`  
**Apply to:** web app shell, admin dialogs, dictionary cards/detail, mobile tabs/profile/dictionary/SOS

Use semantic labels (`role`, `aria-*`, Flutter `Semantics`), stable 48px+ tap targets, explicit loading/error states, and no flashing status effects.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `src/app/lib/storage.ts` | service | file-I/O | No existing S3/object-storage helper or presigned upload flow exists. Use RESEARCH.md AWS SDK pattern. |
| `src/app/api/admin/storage/presign/route.ts` | route | file-I/O | No existing upload route for large binary/object storage. Closest route pattern is validation/auth only. |
| `scripts/import-dictionary.ts` | utility | batch | No existing batch import script exists. Use Prisma/service patterns plus RESEARCH.md manifest validation guidance. |

## Metadata

**Analog search scope:** `prisma`, `src/app`, `src/components`, `src/__tests__`, `mobile/lib`, `mobile/test`  
**Files scanned:** 80+ via `rg --files` and targeted reads  
**Pattern extraction date:** 2026-05-17
