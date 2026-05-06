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
