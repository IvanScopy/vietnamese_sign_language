---
phase: 01-foundation-authentication
plan: 04
type: execute
wave: 3
depends_on:
  - 01
  - 02
files_modified:
  - src/config/socket.ts
  - src/services/notification.service.ts
  - src/services/livekit.service.ts
  - src/routes/notifications.routes.ts
  - src/routes/livekit.routes.ts
  - .env.example
autonomous: true
requirements:
  - NOTIF-01
  - NOTIF-02
must_haves:
  truths:
    - "Socket.io server accepts authenticated connections"
    - "User joins personal room on connection (user:{userId})"
    - "Notification service sends to Socket.io room AND FCM/APNs"
    - "SOS notifications use high-priority (FCM priority=high, APNs priority=10)"
    - "Incoming call notification triggers visual alert with custom pattern"
    - "SOS received notification notifies emergency contacts"
    - "Socket.io disconnects cleanly on logout"
  artifacts:
    - path: "src/config/socket.ts"
      provides: "Socket.io server setup with JWT authentication middleware"
      exports:
        - "setupSocket(server, notificationService)"
    - path: "src/services/notification.service.ts"
      provides: "Hybrid notification service (Socket.io + FCM/APNs)"
      exports:
        - "sendToUser(userId, payload)"
        - "sendSOSAlert(userId, location, message)"
    - path: "src/services/livekit.service.ts"
      provides: "LiveKit token generation and room management"
      exports:
        - "generateToken(userId, room, isAdmin)"
        - "createRoom(name, ownerId)"
    - path: "src/routes/notifications.routes.ts"
      provides: "Push token registration, send notification, SOS endpoints"
    - path: "src/routes/livekit.routes.ts"
      provides: "LiveKit token and room creation endpoints"
  key_links:
    - from: "src/config/socket.ts"
      to: "Socket.io connection"
      via: "io.use auth middleware validates JWT"
    - from: "src/services/notification.service.ts"
      to: "FCM/APNs"
      via: "sendFCM and sendAPNs methods"
---

<objective>
Notification Infrastructure (Socket.io + FCM/APNs)

Purpose: Implement real-time notification system using Socket.io for in-app notifications and FCM/APNs for background/closed app alerts. SOS notifications use high-priority delivery. Notifications target specific user rooms.

Output: Socket.io server with JWT auth, notification service with hybrid delivery, LiveKit token generation
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-foundation-authentication/01-CONTEXT.md
@.planning/phases/01-foundation-authentication/01-RESEARCH.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Implement src/config/socket.ts with JWT authentication</name>
  <files>src/config/socket.ts</files>
  <read_first>
  - src/services/token.service.ts
  </read_first>
  <action>Create Socket.io server setup:

import { Server as SocketIOServer } from 'socket.io';
import { tokenService } from '../services/token.service.js';

export function setupSocket(server: any, notificationService?: any): SocketIOServer {
  const io = new SocketIOServer(server, {
    cors: { origin: process.env.CLIENT_ORIGIN || '*', credentials: true },
    transports: ['websocket', 'polling'],
  });

  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      next(new Error('No token provided'));
      return;
    }
    try {
      const decoded = tokenService.verifyAccessToken(token);
      socket.data.userId = decoded.sub;
      next();
    } catch (err) {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId;
    socket.join(`user:${userId}`);

    socket.on('disconnect', () => {
      socket.leave(`user:${userId}`);
    });
  });

  return io;
}</action>
  <verify>
  - src/config/socket.ts exists
  - grep -q "io.use" src/config/socket.ts
  - grep -q "verifyAccessToken" src/config/socket.ts
  - grep -q "socket.join" src/config/socket.ts
  - grep -q "user:.*userId" src/config/socket.ts
  - TypeScript compiles
  </verify>
  <done>Socket.io server configured with JWT auth and user room management</done>
</task>

<task type="auto">
  <name>Task 2: Implement notification service with FCM/APNs</name>
  <files>src/services/notification.service.ts</files>
  <read_first>
  - .env.example
  </read_first>
  <action>Create NotificationService:

import admin from 'firebase-admin';
import apn from 'node-apn';
import { redisClient } from '../config/redis.js';

export class NotificationService {
  private fcm: admin.messaging.MessagingService;
  private apnProvider: apn.Provider;

  constructor(private io: any) {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      this.fcm = admin.messaging();
    }

    this.apnProvider = new apn.Provider({
      cert: process.env.APNS_CERT,
      key: process.env.APNS_KEY,
      production: process.env.NODE_ENV === 'production',
    });
  }

  async sendToUser(userId: string, payload: { title: string; body: string; type: string; data?: any }): Promise<void> {
    this.io.to(`user:${userId}`).emit('notification', payload);

    const tokens = await this.getUserPushTokens(userId);
    if (tokens.fcm) await this.sendFCM(tokens.fcm, payload);
    if (tokens.apn) await this.sendAPNs(tokens.apn, payload);
  }

  async sendSOSAlert(userId: string, location?: { lat: number; lng: number }, message?: string): Promise<void> {
    const alert = {
      title: 'SOS Alert',
      body: message || 'User has triggered an emergency SOS',
      type: 'SOS',
      priority: 'critical',
      location,
    };
    await this.sendToUser(userId, alert);
  }

  private async sendFCM(token: string, payload: any): Promise<void> {
    const message: admin.messaging.Message = {
      token,
      notification: { title: payload.title, body: payload.body },
      data: { type: payload.type, ...(payload.data || {}) },
      priority: payload.type === 'SOS' ? 'high' : 'normal',
      android: { priority: payload.type === 'SOS' ? 'high' : 'normal' },
      apns: {
        headers: { 'apns-priority': payload.type === 'SOS' ? '10' : '5' },
        payload: { aps: { 'content-available': 1 } },
      },
    };
    await this.fcm.send(message);
  }

  private async sendAPNs(token: string, payload: any): Promise<void> {
    const note = new apn.Notification();
    note.alert = { title: payload.title, body: payload.body };
    note.payload = { type: payload.type, ...(payload.data || {}) };
    note.pushType = 'alert';
    note.priority = payload.type === 'SOS' ? 10 : 5;
    note.topic = process.env.APNS_TOPIC;
    await this.apnProvider.send(note, token);
  }

  private async getUserPushTokens(userId: string): Promise<{ fcm?: string; apn?: string }> {
    const fcmToken = await redisClient.get(`fcm:${userId}`);
    const apnToken = await redisClient.get(`apn:${userId}`);
    return { fcm: fcmToken || undefined, apn: apnToken || undefined };
  }
}

export const notificationService = new NotificationService(/* io set later */);</action>
  <verify>
  - src/services/notification.service.ts exists
  - grep -q "class NotificationService" src/services/notification.service.ts
  - grep -q "sendToUser" src/services/notification.service.ts
  - grep -q "sendSOSAlert" src/services/notification.service.ts
  - grep -q "priority.*high" src/services/notification.service.ts
  - grep -q "apns-priority" src/services/notification.service.ts
  - TypeScript compiles
  </verify>
  <done>NotificationService implements Socket.io + FCM/APNs with SOS priority</done>
</task>

<task type="auto">
  <name>Task 3: Create LiveKit service and routes</name>
  <files>
  src/services/livekit.service.ts
  src/routes/livekit.routes.ts
  </files>
  <read_first>
  - .env.example
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create src/services/livekit.service.ts:

import { RoomService, Room, LiveKitRoom } from 'livekit-server-sdk';

export class LiveKitRoomService {
  private roomService: RoomService;

  constructor() {
    const apiKey = process.env.LIVEKIT_API_KEY!;
    const apiSecret = process.env.LIVEKIT_API_SECRET!;
    const wsUrl = process.env.LIVEKIT_WS_URL || 'ws://localhost:7880';
    this.roomService = new RoomService(apiKey, apiSecret, wsUrl);
  }

  generateToken(userId: string, roomName: string, isAdmin = false): string {
    const { AccessToken } = require('livekit-server-sdk');
    const token = new AccessToken(apiKey, apiSecret, { identity: userId, name: userId });
    token.addGrant({ roomJoin: true, room: roomName, canPublish: !isAdmin, canSubscribe: true });
    return token.toJwt();
  }

  async createRoom(name: string, ownerId: string): Promise<Room> {
    const room = new LiveKitRoom({ name, ownerId });
    await this.roomService.createRoom(room);
    return room;
  }
}

Create src/routes/livekit.routes.ts:

import { Router } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { LiveKitRoomService } from '../services/livekit.service.js';

const router = Router();
const livekitService = new LiveKitRoomService();

router.get('/token', authenticate, async (req: AuthRequest, res) => {
  const { room, isAdmin } = req.query;
  if (!room) return res.status(400).json({ error: 'Room required' });
  const token = livekitService.generateToken(req.userId!, room as string, isAdmin === 'true');
  res.json({ token, room: room as string });
});

router.post('/room/create', authenticate, async (req: AuthRequest, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Room name required' });
  const room = await livekitService.createRoom(name, req.userId!);
  res.json(room);
});

export default router;</action>
  <verify>
  - src/services/livekit.service.ts exists
  - grep -q "generateToken" src/services/livekit.service.ts
  - grep -q "createRoom" src/services/livekit.service.ts
  - src/routes/livekit.routes.ts exists
  - grep -q "/token" src/routes/livekit.routes.ts
  - grep -q "/room/create" src/routes/livekit.routes.ts
  - TypeScript compiles
  </verify>
  <done>LiveKit service and routes implemented for token generation and room management</done>
</task>

<task type="auto">
  <name>Task 4: Create notification routes</name>
  <files>src/routes/notifications.routes.ts</files>
  <read_first>
  - src/services/notification.service.ts
  - src/middleware/auth.ts
  </read_first>
  <action>Create notifications routes:

import { Router } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth.js';
import { notificationService } from '../services/notification.service.js';
import { redisClient } from '../config/redis.js';

const router = Router();

router.post('/register-token', authenticate, async (req: AuthRequest, res) => {
  const { fcmToken, apnToken } = req.body;
  if (fcmToken) await redisClient.setEx(`fcm:${req.userId}`, 30 * 24 * 60 * 60, fcmToken);
  if (apnToken) await redisClient.setEx(`apn:${req.userId}`, 30 * 24 * 60 * 60, apnToken);
  res.json({ success: true });
});

router.post('/send', authenticate, async (req: AuthRequest, res) => {
  const { targetUserId, title, body, type, data } = req.body;
  await notificationService.sendToUser(targetUserId, { title, body, type, data });
  res.json({ success: true });
});

router.post('/sos', authenticate, async (req: AuthRequest, res) => {
  const { location, message } = req.body;
  await notificationService.sendSOSAlert(req.userId!, location, message);
  res.json({ success: true });
});

export default router;</action>
  <verify>
  - src/routes/notifications.routes.ts exists
  - grep -q "/register-token" src/routes/notifications.routes.ts
  - grep -q "/sos" src/routes/notifications.routes.ts
  - grep -q "sendSOSAlert" src/routes/notifications.routes.ts
  - Routes use authenticate middleware
  - TypeScript compiles
  </verify>
  <done>Notification routes implemented with token registration and SOS endpoint</done>
</task>

</tasks>
