import { z } from 'zod'

export const RegisterSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(1, 'Name is required'),
  userType: z.enum(['DEAF', 'HEARING', 'PARENT', 'TEACHER']),
})

export const LoginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(1, 'Password is required'),
})

export const GoogleAuthSchema = z.object({
  code: z.string().min(1, 'Authorization code is required'),
})

export const TranscribeSchema = z.object({
  language: z.string().default('vi'),
})

export const SynthesizeSchema = z.object({
  text: z.string().min(1, 'Text is required'),
  language: z.string().default('vi'),
})

export const RegisterTokenSchema = z.object({
  token: z.string().min(1, 'Device token is required'),
  platform: z.enum(['ios', 'android', 'web']),
  userId: z.number().int().positive().optional(),
})

export const SendNotificationSchema = z.object({
  toUserId: z.number().int().positive(),
  title: z.string().min(1),
  body: z.string().min(1),
  data: z.record(z.string(), z.string()).optional(),
  priority: z.enum(['normal', 'high']).default('normal'),
  type: z.enum(['CALL', 'SOS', 'MESSAGE', 'LEARNING']).default('MESSAGE'),
})

// Call lifecycle schemas
export const CreateCallSchema = z.object({
  calleeId: z.number().int().positive(),
})

export const CallActionSchema = z.object({
  callId: z.number().int().positive(),
})

// SOS schemas
export const CreateSosAlertSchema = z.object({
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  locationAccuracyMeters: z.number().optional(),
  locationLabel: z.enum(['current', 'approximate', 'last_known', 'unavailable']).optional(),
  locationCapturedAt: z.string().datetime().optional(),
  idempotencyKey: z.string().max(128).optional(),
})

export const SosLocationUpdateSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  locationAccuracyMeters: z.number().optional(),
  locationLabel: z.enum(['current', 'approximate', 'last_known', 'unavailable']),
  locationCapturedAt: z.string().datetime().optional(),
})

export const SosFallbackSchema = z.object({
  fallbackType: z.enum(['native_sms_opened', 'native_sms_failed', 'dialer_opened']),
  attemptIds: z.array(z.number().int()).optional(),
})

export const EmergencyContactSchema = z.object({
  name: z.string().min(1).max(100),
  phone: z.string().min(1).max(20),
  phoneE164: z.string().regex(/^\+[1-9]\d{1,14}$/).optional(),
  isActive: z.boolean().optional().default(true),
  linkedUserId: z.number().int().optional(),
})

export const UpdateEmergencyContactSchema = EmergencyContactSchema.partial()

export const TwilioStatusCallbackSchema = z.object({
  MessageSid: z.string(),
  MessageStatus: z.enum([
    'queued',
    'sent',
    'delivered',
    'failed',
    'undelivered',
    'canceled',
    'accepted',
    'scheduled',
    'read',
    'partially_delivered',
    'sending',
  ]),
  To: z.string().optional(),
  From: z.string().optional(),
  ErrorCode: z.string().optional(),
  ErrorMessage: z.string().optional(),
})
