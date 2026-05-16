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

// Call lifecycle schemas
export const CreateCallSchema = z.object({
  calleeId: z.number().int().positive(),
})

export const CallActionSchema = z.object({
  callId: z.number().int().positive(),
})
