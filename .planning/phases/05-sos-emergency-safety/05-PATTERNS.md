# Phase 05: SOS Emergency & Safety - Pattern Map

**Mapped:** 2026-05-16
**Files analyzed:** 31
**Analogs found:** 27 / 31

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `prisma/schema.prisma` | model | CRUD | `prisma/schema.prisma` | exact-existing-models |
| `package.json` | config | batch | `package.json` | exact |
| `package-lock.json` | config | batch | `package-lock.json` | exact |
| `src/app/lib/validators.ts` | utility | transform | `src/app/lib/validators.ts` | exact |
| `src/app/lib/sms-provider.ts` | service | request-response | `src/app/lib/providers/tts-provider.ts` + `src/app/lib/providers/elevenlabs-tts.ts` | role-match |
| `src/app/lib/sos.ts` | service | CRUD/event-driven | `src/lib/calls.ts` | role-match |
| `src/app/lib/push.ts` | service | event-driven | `src/app/lib/push.ts` | exact |
| `src/app/lib/socket.ts` | service | pub-sub/event-driven | `src/app/lib/socket.ts` | exact |
| `src/app/api/sos/alerts/route.ts` | controller | request-response/CRUD | `src/app/api/calls/route.ts` | exact-role |
| `src/app/api/sos/alerts/[id]/location/route.ts` | controller | request-response/CRUD | `src/app/api/calls/[callId]/transcript/route.ts` | role-match |
| `src/app/api/sos/alerts/[id]/fallback/route.ts` | controller | request-response/CRUD | `src/app/api/calls/[callId]/token/route.ts` | role-match |
| `src/app/api/sos/twilio/status/route.ts` | route/webhook | event-driven | `src/app/api/notifications/send/route.ts` | partial |
| `src/app/api/user/emergency-contacts/route.ts` | controller | CRUD | `src/app/api/user/profile/route.ts` | exact-domain |
| `src/__tests__/sos/sos-api.test.ts` | test | request-response/CRUD | `src/__tests__/profile/profile.test.ts` | role-match |
| `src/__tests__/sos/sos-fallback.test.ts` | test | request-response/event-driven | `src/__tests__/notifications/push.test.ts` | role-match |
| `src/__tests__/sos/sos-notifications.test.ts` | test | event-driven | `src/__tests__/notifications/call-push.test.ts` | role-match |
| `src/__tests__/sos/emergency-contacts.test.ts` | test | CRUD | `src/__tests__/profile/profile.test.ts` | role-match |
| `mobile/pubspec.yaml` | config | batch | `mobile/pubspec.yaml` | exact |
| `mobile/android/app/src/main/AndroidManifest.xml` | config | platform-permission | `mobile/android/app/src/main/AndroidManifest.xml` | exact |
| `mobile/ios/Runner/Info.plist` | config | platform-permission | `mobile/ios/Runner/Info.plist` | exact |
| `mobile/lib/main.dart` | component/route | request-response | `mobile/lib/main.dart` | exact |
| `mobile/lib/screens/sos_screen.dart` | component | event-driven/request-response | `mobile/lib/screens/calls/incoming_call_screen.dart` + `mobile/lib/screens/calls/outgoing_call_screen.dart` | role-match |
| `mobile/lib/services/sos_api_service.dart` | service | request-response | `mobile/lib/services/call_api_service.dart` | exact-role |
| `mobile/lib/services/sos_location_service.dart` | service | device-I/O | None | no-analog |
| `mobile/lib/services/sos_platform_service.dart` | service | platform-I/O | None | no-analog |
| `mobile/lib/services/push_notification_service.dart` | service | event-driven | `mobile/lib/services/push_notification_service.dart` | exact |
| `mobile/test/services/sos_api_service_test.dart` | test | request-response | `mobile/test/services/call_api_service_test.dart` | role-match |
| `mobile/test/services/sos_location_service_test.dart` | test | device-I/O | None | no-analog |
| `mobile/test/services/sos_platform_service_test.dart` | test | platform-I/O | None | no-analog |
| `mobile/test/screens/sos_screen_test.dart` | test | event-driven/UI | `mobile/test/widgets/active_call_screen_test.dart` | role-match |
| `mobile/test/services/push_notification_service_test.dart` | test | event-driven | `mobile/test/services/push_notification_service_test.dart` | exact |

## Pattern Assignments

### `src/app/api/sos/alerts/route.ts` (controller, request-response/CRUD)

**Analog:** `src/app/api/calls/route.ts`

**Copy imports/auth/validation pattern** (lines 1-36):
```typescript
import { NextRequest, NextResponse } from 'next/server'
import { verifyAccessToken } from '@/app/lib/auth'
import { CreateCallSchema } from '@/app/lib/validators'
import { createCall, checkBusy } from '@/lib/calls'
import { emitCallEvent } from '@/app/lib/call-signaling'
import { sendCallPushNotification } from '@/app/lib/push'
import { prisma } from '@/app/lib/db'

export async function POST(request: NextRequest) {
  try {
    const accessToken = request.cookies.get('accessToken')?.value
    if (!accessToken) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const payload = await verifyAccessToken(accessToken)
    if (!payload) {
      return NextResponse.json(
        { error: 'Invalid or expired token' },
        { status: 401 },
      )
    }
    const callerId = payload.userId

    const body = await request.json()
    const validated = CreateCallSchema.safeParse(body)
    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 },
      )
    }
```

**Copy response/error pattern** (lines 93-102):
```typescript
return NextResponse.json(
  { callId, roomName, expiresAt },
  { status: 201 },
)
} catch (error) {
  console.error('Create call error:', error)
  const message =
    error instanceof Error ? error.message : 'Internal server error'
  return NextResponse.json({ error: message }, { status: 500 })
}
```

Apply with SOS changes: derive `userId` only from JWT, call `createSosAlert(...)`, load emergency contacts server-side, return aggregate provider/fallback status and `smsBody`/fallback targets.

---

### `src/app/api/sos/alerts/[id]/location/route.ts` (controller, request-response/CRUD)

**Analog:** `src/app/api/calls/[callId]/transcript/route.ts`

**Copy dynamic route + participant/ownership guard** (lines 10-49):
```typescript
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const accessToken = request.cookies.get('accessToken')?.value
    if (!accessToken) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const payload = await verifyAccessToken(accessToken)
    if (!payload) {
      return NextResponse.json(
        { error: 'Invalid or expired token' },
        { status: 401 },
      )
    }
    const userId = payload.userId

    const { callId: callIdStr } = await params
    const callId = parseInt(callIdStr, 10)
    if (isNaN(callId)) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }

    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      select: { callerId: true, calleeId: true, state: true },
    })

    if (!callSession) {
      return NextResponse.json({ error: 'Call not found' }, { status: 404 })
    }

    if (callSession.callerId !== userId && callSession.calleeId !== userId) {
      return NextResponse.json(
        { error: 'Not a participant in this call' },
        { status: 403 },
      )
    }
```

**Copy request body validation/create pattern** (lines 63-87):
```typescript
const body = await request.json()
const validation = transcriptSchema.safeParse(body)
if (!validation.success) {
  return NextResponse.json(
    { error: 'Invalid request body', details: validation.error.issues },
    { status: 400 },
  )
}

const { transcript } = validation.data

const callTranscript = await prisma.callTranscript.create({
  data: {
    callId,
    userId,
    text: transcript,
  },
})

return NextResponse.json(
  { success: true, transcriptId: callTranscript.id },
  { status: 201 },
)
```

Apply with `alertId`, SOS ownership (`sosAlert.userId === userId`), and late GPS fields: coordinates/map link, accuracy, stale/approximate label, captured timestamp.

---

### `src/app/api/sos/alerts/[id]/fallback/route.ts` (controller, request-response/CRUD)

**Analog:** `src/app/api/calls/[callId]/token/route.ts`

**Copy param parsing + state/ownership conflict pattern** (lines 25-52):
```typescript
const { callId: callIdStr } = await params
const callId = parseInt(callIdStr, 10)
if (isNaN(callId)) {
  return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
}

const callSession = await prisma.callSession.findUnique({
  where: { id: callId },
})

if (!callSession) {
  return NextResponse.json({ error: 'Call not found' }, { status: 404 })
}

if (callSession.state !== 'ACTIVE') {
  return NextResponse.json(
    { error: 'Call is not active' },
    { status: 409 },
  )
}

if (callSession.callerId !== userId && callSession.calleeId !== userId) {
  return NextResponse.json(
    { error: 'Not a participant in this call' },
    { status: 403 },
  )
}
```

Apply with fallback state transitions (`native_composer_opened`, `native_composer_failed`, `dialer_opened`) and never mark native SMS as delivered.

---

### `src/app/api/sos/twilio/status/route.ts` (route/webhook, event-driven)

**Analog:** `src/app/api/notifications/send/route.ts` for event persistence/fanout; no Twilio webhook analog exists.

**Copy validate -> emit -> persist shape** (lines 8-42):
```typescript
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
```

Planner note: add Twilio signature verification before status writes. Existing code has no signed-webhook pattern, so use RESEARCH.md provider guidance for that part.

---

### `src/app/api/user/emergency-contacts/route.ts` (controller, CRUD)

**Analog:** `src/app/api/user/profile/route.ts`

**Copy user-owned emergency contact select** (lines 25-43):
```typescript
const user = await prisma.user.findUnique({
  where: { id: payload.userId },
  select: {
    id: true,
    email: true,
    name: true,
    userType: true,
    emergencyContacts: {
      select: { id: true, name: true, phone: true }
    },
    createdAt: true,
  },
})

if (!user) {
  return NextResponse.json({ error: 'User not found' }, { status: 404 })
}

return NextResponse.json({ user })
```

**Copy update/select pattern** (lines 63-92):
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
    emergencyContacts: {
      select: { id: true, name: true, phone: true }
    },
  },
})

return NextResponse.json({ user: updatedUser })
```

Apply to `EmergencyContact` create/update/delete with `where: { userId: payload.userId }` ownership checks and phone normalization.

---

### `src/app/lib/sos.ts` (service, CRUD/event-driven)

**Analog:** `src/lib/calls.ts`

**Copy service-layer imports and concurrent validation** (lines 1-38):
```typescript
import { prisma } from '@/app/lib/db'
import { generateLiveKitToken } from '@/lib/livekit'

export async function createCall(callerId: number, calleeId: number) {
  if (callerId === calleeId) {
    throw new Error('Caller and callee cannot be the same user')
  }

  const [caller, callee] = await Promise.all([
    prisma.user.findUnique({ where: { id: callerId } }),
    prisma.user.findUnique({ where: { id: calleeId } }),
  ])
```

**Copy durable create return shape** (lines 47-64):
```typescript
const roomName = generateRoomName()
const expiresAt = new Date(Date.now() + 30_000)

const callSession = await prisma.callSession.create({
  data: {
    roomName,
    callerId,
    calleeId,
    state: 'RINGING',
    expiresAt,
  },
})

return {
  callId: callSession.id,
  roomName: callSession.roomName,
  expiresAt: callSession.expiresAt,
}
```

**Copy atomic transition pattern** (lines 71-87):
```typescript
const result = await prisma.callSession.updateMany({
  where: {
    id: callId,
    calleeId: userId,
    state: 'RINGING',
    expiresAt: { gt: new Date() },
  },
  data: {
    state: 'ACTIVE',
    acceptedAt: new Date(),
  },
})

if (result.count !== 1) {
  throw new Error('Call unavailable')
}
```

Apply to SOS active-alert checks, per-contact attempt creation, late GPS update, fallback state update, and status aggregation. Use `Promise.all` for simultaneous provider sends to all contacts.

---

### `src/app/lib/sms-provider.ts` (service, request-response)

**Analog:** `src/app/lib/providers/tts-provider.ts` + `src/app/lib/providers/elevenlabs-tts.ts`

**Copy provider interface/factory pattern** (`src/app/lib/providers/tts-provider.ts` lines 1-18):
```typescript
export interface TTSProvider {
  synthesize(text: string, language?: string): Promise<Buffer>
}

export function getTTSProvider(): TTSProvider {
  const provider = process.env.TTS_PROVIDER || 'elevenlabs'
  switch (provider) {
    case 'elevenlabs':
      return new (require('./elevenlabs-tts').ElevenLabsTTSProvider)()
    case 'local':
      return new (require('./coqui-tts').CoquiTTSProvider)()
    default:
      return new (require('./elevenlabs-tts').ElevenLabsTTSProvider)()
  }
}
```

**Copy external API error style** (`src/app/lib/providers/elevenlabs-tts.ts` lines 5-24):
```typescript
const response = await fetch('https://api.elevenlabs.io/v1/text-to-speech/eleven_multilingual_v2', {
  method: 'POST',
  headers: {
    'Accept': 'audio/mpeg',
    'Content-Type': 'application/json',
    'xi-api-key': process.env.ELEVENLABS_API_KEY!,
  },
  body: JSON.stringify({
    text,
    model_id: 'eleven_multilingual_v2',
    voice_settings: {
      stability: 0.5,
      similarity_boost: 0.75,
    },
  }),
})

if (!response.ok) {
  throw new Error(`ElevenLabs API error: ${response.status} ${await response.text()}`)
}
```

Apply to `SmsProvider` with a Twilio implementation returning structured attempt status, provider SID, provider status, and error metadata. Do not expose credentials to Flutter.

---

### `src/app/lib/push.ts` (service, event-driven)

**Analog:** `src/app/lib/push.ts`

**Copy missing-Firebase graceful behavior** (lines 17-45):
```typescript
let messaging: Messaging
try {
  if (getApps().length === 0) {
    console.warn(
      '[push] Firebase not initialized — skipping push notification for call',
      callId,
    )
    return { sent: 0, failed: 0 }
  }
  messaging = getMessaging(getApp())
} catch {
  console.warn(
    '[push] Firebase initialization error — skipping push notification for call',
    callId,
  )
  return { sent: 0, failed: 0 }
}

const deviceTokens = await prisma.deviceToken.findMany({
  where: { userId },
  select: { token: true },
})

if (deviceTokens.length === 0) {
  console.log(`[push] No device tokens found for user ${userId}`)
  return { sent: 0, failed: 0 }
}
```

**Copy multicast + stale-token cleanup** (lines 50-104):
```typescript
const message = {
  notification: {
    title: 'Incoming video call',
    body: `${callerName} is calling`,
  },
  data: {
    type: 'VIDEO_CALL',
    callId: String(callId),
    callerName,
  },
  android: {
    priority: 'high' as const,
  },
  apns: {
    payload: {
      aps: {
        sound: 'default',
        badge: 1,
      },
    },
  },
  tokens,
}

try {
  const response = await messaging.sendEachForMulticast(message)

  const unregisteredTokens: string[] = []
  response.responses.forEach((res, index) => {
    if (!res.success) {
      const error = res.error
      if (error?.code === 'messaging/registration-token-not-registered') {
        unregisteredTokens.push(tokens[index])
      }
    }
  })

  if (unregisteredTokens.length > 0) {
    await prisma.deviceToken.deleteMany({
      where: { token: { in: unregisteredTokens } },
    })
  }

  return {
    sent: response.successCount,
    failed: response.failureCount,
  }
} catch (error) {
  console.error('[push] FCM send error:', error)
  return { sent: 0, failed: 0 }
}
```

Apply for app-user emergency contacts only. SMS remains primary delivery.

---

### `src/app/lib/socket.ts` (service, pub-sub/event-driven)

**Analog:** `src/app/lib/socket.ts`

**Copy user room registration** (lines 25-37):
```typescript
socket.on('register', async (userId: number, userType: string) => {
  socket.userId = userId
  socket.userType = userType

  const existing = userSockets.get(userId) || []
  userSockets.set(userId, [...existing, socket.id])

  socket.join(`user:${userId}`)

  console.log(`User ${userId} registered on socket ${socket.id}`)
})
```

**Replace current client-authoritative SOS handler** (lines 43-61):
```typescript
socket.on('sos:alert', async ({ userId, location, emergencyContacts }) => {
  for (const contactId of emergencyContacts) {
    io.to(`user:${contactId}`).emit('sos:alert', {
      fromUserId: userId,
      location,
      timestamp: Date.now(),
      type: 'SOS',
      priority: 'HIGH',
      visualConfig: {
        color: '#FF0000',
        pulse: true,
        vibrationPattern: [200, 100, 200, 100, 200],
      },
    })
  }
})
```

Planner action: do not keep this as the safety-critical send path. Mirror call signaling's server-authoritative comment and emit SOS events only from backend route/service code.

---

### `src/app/lib/validators.ts` (utility, transform)

**Analog:** `src/app/lib/validators.ts`

**Copy Zod schema style** (lines 28-50):
```typescript
export const RegisterTokenSchema = z.object({
  token: z.string().min(1, 'Device token is required'),
  platform: z.enum(['ios', 'android', 'web']),
  userId: z.number().int().positive(),
})

export const SendNotificationSchema = z.object({
  toUserId: z.number().int().positive(),
  title: z.string().min(1),
  body: z.string().min(1),
  data: z.record(z.string()).optional(),
  priority: z.enum(['normal', 'high']).default('normal'),
  type: z.enum(['CALL', 'SOS', 'MESSAGE', 'LEARNING']).default('MESSAGE'),
})

export const CreateCallSchema = z.object({
  calleeId: z.number().int().positive(),
})

export const CallActionSchema = z.object({
  callId: z.number().int().positive(),
})
```

Add SOS schemas here for alert create, late location update, fallback record, contact create/update, and Twilio callback normalization.

---

### `prisma/schema.prisma` (model, CRUD)

**Analog:** existing SOS/contact models in `prisma/schema.prisma`

**Copy existing contact and SOS model conventions** (lines 50-117):
```prisma
model EmergencyContact {
  id        Int      @id @default(autoincrement())
  name      String
  phone     String
  userId    Int
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@map("emergency_contacts")
}

model SOSAlert {
  id        Int      @id @default(autoincrement())
  userId    Int
  user      User     @relation("SOSAlertSender", fields: [userId], references: [id], onDelete: Cascade)
  location  String?
  status    SOSStatus @default(ACTIVE)
  createdAt DateTime  @default(now())

  receivers SOSAlertReceiver[] @relation("SOSAlertReceiverRelation")

  @@map("sos_alerts")
}

model SOSAlertReceiver {
  id            Int      @id @default(autoincrement())
  sosAlertId    Int
  sosAlert      SOSAlert @relation("SOSAlertReceiverRelation", fields: [sosAlertId], references: [id], onDelete: Cascade)
  contactId     Int
  contact       User     @relation(fields: [contactId], references: [id], onDelete: Cascade)
  deliveredAt   DateTime?
  acknowledgedAt DateTime?

  @@map("sos_alert_receivers")
}

enum SOSStatus {
  ACTIVE
  RESOLVED
  CANCELLED
}
```

**Copy index convention** (lines 145-148):
```prisma
@@index([callerId])
@@index([calleeId])
@@index([state])
@@map("call_sessions")
```

Planner should extend/replace receiver storage to support freeform phone contacts and provider/native attempt statuses.

---

### `mobile/lib/main.dart` (component/route, request-response)

**Analog:** `mobile/lib/main.dart`

**Copy service initialization pattern** (lines 20-43):
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

  runApp(
    VSLBridgeApp(
      config: config,
      authToken: authToken,
      pushService: pushService,
    ),
  );
}
```

**Copy explicit routes/onGenerateRoute pattern** (lines 68-151):
```dart
routes: {
  '/recognition': (context) => RecognitionScreen(
    serverUrl: config.serverUrl,
    serverPort: config.serverPort,
    authToken: authToken,
    config: config,
  ),
  '/conversation': (context) =>
      ConversationScreen(config: config, authToken: authToken),
  '/history': (context) => const ConversationHistoryScreen(),
},
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/calls/incoming':
      final args = settings.arguments as Map<String, dynamic>?;
      final callId = args?['callId'] as int? ?? 0;
      final fromUserName = args?['fromUserName'] as String?;
      return MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callApiService: CallApiService(
            baseUrl: config.httpUrl,
            authToken: authToken,
          ),
          callId: callId,
          fromUserName: fromUserName,
        ),
      );
    default:
      return null;
  }
},
```

**Copy home action entry pattern** (lines 186-230):
```dart
if (isLoggedIn)
  Column(
    children: [
      ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/conversation');
        },
        icon: const Icon(Icons.forum),
        label: const Text('Start Conversation'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/recognition');
        },
        icon: const Icon(Icons.back_hand),
        label: const Text('Sign Recognition'),
      ),
    ],
  )
```

Add SOS entry only on the home screen with a hold gesture leading to `/sos`.

---

### `mobile/lib/screens/sos_screen.dart` (component, event-driven/request-response)

**Analog:** `mobile/lib/screens/calls/incoming_call_screen.dart` + `mobile/lib/screens/calls/outgoing_call_screen.dart` + `mobile/lib/screens/calls/active_call_screen.dart`

**Copy full-screen stateful screen structure** (`incoming_call_screen.dart` lines 12-36):
```dart
class IncomingCallScreen extends StatefulWidget {
  final CallApiService callApiService;
  final int callId;
  final String? fromUserName;

  const IncomingCallScreen({
    super.key,
    required this.callApiService,
    required this.callId,
    this.fromUserName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _isLoading = true;
  bool _isUnavailable = false;

  @override
  void initState() {
    super.initState();
    _verifyCallState();
  }
```

**Copy async action with mounted checks** (`incoming_call_screen.dart` lines 69-96):
```dart
Future<void> _onAccept() async {
  try {
    final session = await widget.callApiService.acceptCall(widget.callId);
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/calls/active',
      arguments: {
        'callSession': session,
      },
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to accept call: $e')),
    );
  }
}
```

**Copy cancel/best-effort pattern** (`outgoing_call_screen.dart` lines 94-103):
```dart
Future<void> _onCancel() async {
  try {
    await widget.callApiService.cancelCall(widget.callId);
  } catch (_) {
    // Best effort
  }
  if (mounted) {
    Navigator.of(context).pop();
  }
}
```

**Copy Timer lifecycle pattern** (`active_call_screen.dart` lines 47-55, 100-107, 160-170):
```dart
Timer? _statusTimer;
StreamSubscription<RoomEvent>? _eventsSubscription;

_statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
  if (mounted && _room != null) {
    setState(() {
      _connectionStatus = 'Connected';
    });
  }
});

@override
void dispose() {
  _statusTimer?.cancel();
  _eventsSubscription?.cancel();
  super.dispose();
}
```

Use the Timer pattern for 2-second hold and 5-second countdown cleanup. Do not use flashing effects.

---

### `mobile/lib/services/sos_api_service.dart` (service, request-response)

**Analog:** `mobile/lib/services/call_api_service.dart`

**Copy exception hierarchy and constructor** (lines 6-44):
```dart
class CallApiException implements Exception {
  final String message;
  final int? statusCode;

  CallApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'CallApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

class AuthException extends CallApiException {
  AuthException(super.message);
}

class CallUnavailableException extends CallApiException {
  CallUnavailableException(super.message);
}

class CallApiService {
  final String baseUrl;
  final String authToken;
  final http.Client _client;

  CallApiService({
    required this.baseUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();
```

**Copy POST + decode pattern** (lines 49-60):
```dart
Future<CallSession> createCall(int calleeId) async {
  final uri = Uri.parse('$baseUrl/api/calls');
  final response = await _client.post(
    uri,
    headers: _authHeaders,
    body: jsonEncode({'calleeId': calleeId}),
  );

  _throwOnError(response);

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return CallSession.fromJson(data);
}
```

**Copy auth headers and error mapping** (lines 129-155):
```dart
Map<String, String> get _authHeaders => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

void _throwOnError(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  }

  String message;
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    message = body['message'] as String? ?? body['error'] as String? ?? 'Unknown error';
  } catch (_) {
    message = 'Request failed with status ${response.statusCode}';
  }

  switch (response.statusCode) {
    case 401:
      throw AuthException('Authentication required: $message');
    case 409:
      throw CallUnavailableException(message);
    default:
      throw CallApiException(message, statusCode: response.statusCode);
  }
}
```

Apply to create SOS alert, patch late location, and record fallback/dialer states.

---

### `mobile/lib/services/push_notification_service.dart` (service, event-driven)

**Analog:** `mobile/lib/services/push_notification_service.dart`

**Copy graceful Firebase init** (lines 34-43):
```dart
Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      '[PushNotification] Firebase not configured — push notifications disabled. '
      'Foreground Socket.io signaling still works. Error: $e',
    );
    return;
  }
```

**Copy token registration and refresh pattern** (lines 60-88):
```dart
if (_fcmToken != null && authToken != null) {
  await _registerTokenWithBackend(_fcmToken!);
}

final initialMessage = await _messaging!.getInitialMessage();
if (initialMessage != null) {
  _handleNotificationOpen(initialMessage, navigatorKey);
}

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  _handleNotificationOpen(message, navigatorKey);
});

FirebaseMessaging.onMessage.listen((message) {
  debugPrint('[PushNotification] Foreground message: ${message.notification?.title}');
});

_messaging!.onTokenRefresh.listen((newToken) {
  debugPrint('[PushNotification] Token refreshed');
  _fcmToken = newToken;
  if (authToken != null) {
    _registerTokenWithBackend(newToken);
  }
});
```

**Copy notification-open routing** (lines 131-153):
```dart
void _handleNotificationOpen(
  RemoteMessage message,
  GlobalKey<NavigatorState> navigatorKey,
) {
  final data = message.data;
  final type = data['type'] as String?;

  if (type == 'VIDEO_CALL') {
    debugPrint('[PushNotification] VIDEO_CALL notification opened');
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(
        '/calls/incoming',
        arguments: {
          'callId': data['callId'],
          'fromUserId': data['fromUserId'],
          'fromUserName': data['fromUserName'],
        },
      );
    }
  }
}
```

Add `SOS` routing/state rendering while preserving graceful no-Firebase behavior.

---

### `mobile/lib/services/sos_location_service.dart` (service, device-I/O)

**Analog:** no existing geolocation service in repo.

Use the service shape from `mobile/lib/services/call_api_service.dart` lines 35-44 for injectable dependencies and disposal, then use RESEARCH.md's `geolocator` pattern for permission/current/last-known location. Keep all location labels honest: current, approximate, or last-known.

---

### `mobile/lib/services/sos_platform_service.dart` (service, platform-I/O)

**Analog:** no existing `url_launcher`/haptics service in repo.

Use the same injectable service/test seam as `mobile/lib/services/call_api_service.dart` lines 35-44. Implement `sms:` composer and `tel:115` dialer with `url_launcher`; record only composer opened/failed, never sent.

---

### Config Files

#### `package.json` / `package-lock.json`

**Analog:** `package.json`

**Copy dependency placement** (lines 21-37):
```json
"dependencies": {
  "@livekit/components-react": "^2.9.21",
  "@livekit/components-styles": "^1.2.0",
  "@prisma/client": "^7.8.0",
  "bcrypt": "^6.0.0",
  "firebase-admin": "^13.10.0",
  "google-auth-library": "^10.6.2",
  "jose": "^6.2.3",
  "livekit-client": "^2.19.0",
  "livekit-server-sdk": "^2.15.2",
  "next": "^16.2.4",
  "openapi-typescript": "^7.13.0",
  "prisma": "^7.8.0",
  "socket.io": "^4.8.3",
  "socket.io-client": "^4.8.3",
  "zod": "^4.4.3"
}
```

Add `twilio` under dependencies via package manager so `package-lock.json` is updated mechanically.

#### `mobile/pubspec.yaml`

**Analog:** `mobile/pubspec.yaml`

**Copy dependency placement** (lines 38-54):
```yaml
# Sign Language Recognition
# Using native Android MediaPipe Holistic via custom plugin
socket_io_client: ^3.1.4
camera: ^0.12.0+1
json_annotation: ^4.11.0
permission_handler: ^12.0.1
audioplayers: ^6.4.0
shared_preferences: ^2.3.3
http: ^1.6.0
record: ^6.2.0
path_provider: ^2.1.5

# Video Calling
livekit_client: ^2.7.0
firebase_core: ^4.9.0
firebase_messaging: ^16.2.2
```

Add `geolocator` and `url_launcher` under dependencies with the existing grouping style.

#### `mobile/android/app/src/main/AndroidManifest.xml`

**Analog:** same file.

**Copy permission/query placement** (lines 1-7, 40-50):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
```

Add location permission and any required `sms:`/`tel:` package-visibility queries in the same areas.

#### `mobile/ios/Runner/Info.plist`

**Analog:** same file.

**Copy permission key placement** (lines 29-39):
```xml
<!-- Camera permission for sign language recognition -->
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to detect Vietnamese sign language gestures for real-time communication.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to transcribe Vietnamese speech during face-to-face conversations.</string>
<!-- Network permissions -->
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
</dict>
```

Add location usage copy near existing permission keys and URL-scheme query keys if the implementation calls `canLaunchUrl` for `sms`/`tel`.

## Test Pattern Assignments

### Backend SOS Route/Service Tests

**Apply to:** `src/__tests__/sos/sos-api.test.ts`, `src/__tests__/sos/sos-fallback.test.ts`, `src/__tests__/sos/emergency-contacts.test.ts`

**Analog:** `src/__tests__/profile/profile.test.ts`

**Copy auth mocking and per-test reset** (lines 7-16):
```typescript
jest.mock('@/app/lib/auth', () => ({
  verifyAccessToken: jest.fn(),
}))

describe('GET /api/user/profile', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(verifyAccessToken as jest.Mock).mockResolvedValue({ userId: 1, email: 'test@example.com' })
  })
```

**Copy NextRequest construction and assertions** (lines 30-39):
```typescript
const request = new NextRequest('http://localhost:3000/api/user/profile', {
  method: 'GET',
  headers: { 'Cookie': 'accessToken=mock-token' },
})

const response = await GET(request)
expect(response.status).toBe(200)
const data = await response.json()
expect(data.user).toBeDefined()
expect(data.user.email).toBe('test@example.com')
```

**Copy validation/auth failure tests** (lines 128-147):
```typescript
it('should return 400 for invalid userType', async () => {
  const request = new NextRequest('http://localhost:3000/api/user/profile', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'Cookie': 'accessToken=mock-token' },
    body: JSON.stringify({ userType: 'INVALID' }),
  })

  const response = await PUT(request)
  expect(response.status).toBe(400)
})

it('should return 401 when access token is missing', async () => {
  const request = new NextRequest('http://localhost:3000/api/user/profile', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Test' }),
  })

  const response = await PUT(request)
  expect(response.status).toBe(401)
})
```

Update `src/__tests__/setup.ts` mock Prisma models before adding SOS tests.

**Mock extension source:** `src/__tests__/setup.ts` lines 20-41:
```typescript
emergencyContact: {
  findMany: jest.fn(),
  create: jest.fn(),
  delete: jest.fn(),
},
notification: {
  create: jest.fn(),
  findMany: jest.fn(),
},
deviceToken: {
  upsert: jest.fn(),
},
callSession: {
  create: jest.fn(),
  findUnique: jest.fn(),
  updateMany: jest.fn().mockResolvedValue({ count: 1 }),
  count: jest.fn(),
},
$queryRaw: jest.fn(),
$executeRaw: jest.fn(),
$transaction: jest.fn(async (fn) => fn),
```

---

### Backend SOS Notification Tests

**Apply to:** `src/__tests__/sos/sos-notifications.test.ts`

**Analog:** `src/__tests__/notifications/call-push.test.ts`

**Copy external module mocks** (lines 4-20):
```typescript
jest.mock('@/app/lib/db', () => ({
  prisma: {
    deviceToken: {
      findMany: jest.fn(),
      deleteMany: jest.fn(),
    },
  },
}))

jest.mock('firebase-admin/app', () => ({
  getApps: jest.fn(),
  getApp: jest.fn(),
}))

jest.mock('firebase-admin/messaging', () => ({
  getMessaging: jest.fn(),
}))
```

**Copy todo coverage style if implementation tests are not ready** (lines 27-39):
```typescript
test.todo(
  'sendCallPushNotification formats VIDEO_CALL data payload correctly',
)

test.todo(
  'sendCallPushNotification handles failed UNREGISTERED tokens by deletion',
)

test.todo(
  'sendCallPushNotification returns { sent: 0, failed: 0 } when Firebase not initialized',
)
```

Prefer real tests over `todo` for Phase 5 safety gates.

---

### Flutter Tests

**Apply to:** `mobile/test/services/sos_api_service_test.dart`, `mobile/test/services/sos_location_service_test.dart`, `mobile/test/services/sos_platform_service_test.dart`, `mobile/test/screens/sos_screen_test.dart`, `mobile/test/services/push_notification_service_test.dart`

**Analog:** `mobile/test/services/call_api_service_test.dart`

**Copy group/test naming style** (lines 1-16):
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallApiService', () {
    test('createCall returns CallSession with callId and roomName', () {}, skip: true);
    test('createCall throws CallUnavailableException on 409 busy', () {}, skip: true);
    test('createCall throws AuthException on 401', () {}, skip: true);
    test('acceptCall returns CallSession with token after accept', () {}, skip: true);
    test('rejectCall completes without error', () {}, skip: true);
    test('cancelCall completes without error', () {}, skip: true);
    test('endCall completes without error', () {}, skip: true);
    test('getToken returns fresh token string', () {}, skip: true);
    test('all methods include Bearer auth header', () {}, skip: true);
    test('getCallState returns current call state from backend', () {}, skip: true);
  });
}
```

**Widget-test analog:** `mobile/test/widgets/active_call_screen_test.dart` lines 3-13:
```dart
void main() {
  group('ActiveCallScreen', () {
    test('renders remote video placeholder when no remote track', () {}, skip: true);
    test('renders local preview tile in top-right corner', () {}, skip: true);
    test('renders control bar with mute/camera/end buttons', () {}, skip: true);
    test('shows connection status pill', () {}, skip: true);
    test('handles permission error with recoverable screen', () {}, skip: true);
    test('end call navigates to call result screen with ended state', () {}, skip: true);
    test('mute button toggles microphone state', () {}, skip: true);
    test('camera button toggles camera state', () {}, skip: true);
  });
}
```

Planner should upgrade these from placeholders to real service/widget tests for SOS.

## Shared Patterns

### Authentication

**Source:** `src/app/lib/auth.ts`
**Apply to:** all authenticated SOS/contact controllers.

```typescript
export async function verifyAccessToken(token: string): Promise<AuthPayload | null> {
  try {
    const { payload } = await jwtVerify(token, encodedAccessKey, {
      algorithms: ['HS256'],
    })
    return payload as AuthPayload
  } catch {
    return null
  }
}
```

**Route usage source:** `src/app/api/calls/route.ts` lines 11-24. Derive user ID from token; ignore body user IDs for safety-critical sends.

### Response And Error Handling

**Source:** `src/app/api/calls/route.ts` lines 97-102.
**Apply to:** all route handlers unless a route has a more specific status.

```typescript
} catch (error) {
  console.error('Create call error:', error)
  const message =
    error instanceof Error ? error.message : 'Internal server error'
  return NextResponse.json({ error: message }, { status: 500 })
}
```

### Server-Authoritative Events

**Source:** `src/app/lib/call-signaling.ts` lines 7-20.
**Apply to:** SOS socket/notification fanout.

```typescript
export function emitCallEvent(
  eventType: string,
  userId: number,
  payload: object,
): void {
  const io = getIOInstance()
  if (!io) {
    console.warn(
      `[call-signaling] Socket.io instance not available — cannot emit ${eventType} to user ${userId}`,
    )
    return
  }

  io.to(`user:${userId}`).emit(eventType, payload)
}
```

Create an SOS equivalent or generalize carefully; do not let clients choose SOS recipients.

### Mobile API Services

**Source:** `mobile/lib/services/call_api_service.dart` lines 129-155.
**Apply to:** `sos_api_service.dart`.

Use one `_authHeaders` getter, one `_throwOnError` mapper, injectable `http.Client`, and `dispose()`.

### Mobile Routes

**Source:** `mobile/lib/main.dart` lines 79-151.
**Apply to:** SOS route creation.

Use explicit named routes and pass service instances through `MaterialPageRoute`; keep the SOS entry on `HomeScreen` only for Phase 5.

### Platform Permission Config

**Source:** `mobile/android/app/src/main/AndroidManifest.xml` lines 2-7 and `mobile/ios/Runner/Info.plist` lines 29-39.
**Apply to:** location and URL launcher permissions/queries.

Add permissions in the same local blocks as current camera/mic/network permissions.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `mobile/lib/services/sos_location_service.dart` | service | device-I/O | No existing geolocation service or device-location permission wrapper exists. Use RESEARCH.md `geolocator` pattern. |
| `mobile/lib/services/sos_platform_service.dart` | service | platform-I/O | No existing `url_launcher`, SMS composer, dialer, or haptics wrapper exists. Use RESEARCH.md `url_launcher` pattern. |
| `mobile/test/services/sos_location_service_test.dart` | test | device-I/O | No existing mobile tests mock geolocation/plugin wrappers. Create fakes around the new service seam. |
| `mobile/test/services/sos_platform_service_test.dart` | test | platform-I/O | No existing mobile tests mock URL launcher/haptics wrappers. Create fakes around injectable launcher functions. |
| `src/app/api/sos/twilio/status/route.ts` | route/webhook | event-driven | Existing routes do not validate signed third-party callbacks. Use route validation/persistence patterns plus Twilio signature guidance from RESEARCH.md. |

## Metadata

**Analog search scope:** `src/app/api`, `src/app/lib`, `src/lib`, `src/__tests__`, `mobile/lib`, `mobile/test`, `prisma`, mobile Android/iOS config.
**Files scanned:** 45+ by `rg --files`, `find`, and targeted `nl -ba` reads.
**Pattern extraction date:** 2026-05-16
