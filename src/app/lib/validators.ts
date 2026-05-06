import { z } from 'zod'

export const RegisterSchema = z.object({
  email: z.email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().optional(),
  userType: z.enum(['DEAF', 'HEARING']).default('HEARING'),
})

export const LoginSchema = z.object({
  email: z.email(),
  password: z.string().min(1, 'Password is required'),
})

export const RefreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
})

export const GoogleAuthSchema = z.object({
  code: z.string().min(1, 'Authorization code is required'),
  state: z.string().optional(),
})

export type RegisterInput = z.infer<typeof RegisterSchema>
export type LoginInput = z.infer<typeof LoginSchema>
export type RefreshTokenInput = z.infer<typeof RefreshTokenSchema>
export type GoogleAuthInput = z.infer<typeof GoogleAuthSchema>
