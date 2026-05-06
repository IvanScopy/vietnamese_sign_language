import 'server-only'
import { SignJWT, jwtVerify, type JWTPayload } from 'jose'

const secretKey = process.env.JWT_SECRET!
const refreshSecretKey = process.env.REFRESH_TOKEN_SECRET!
const encodedAccessKey = new TextEncoder().encode(secretKey)
const encodedRefreshKey = new TextEncoder().encode(refreshSecretKey)

export interface AuthPayload extends JWTPayload {
  userId: number
  email: string
  userType: string
}

export async function encryptAccessToken(payload: AuthPayload): Promise<string> {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(encodedAccessKey)
}

export async function encryptRefreshToken(payload: AuthPayload): Promise<string> {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(encodedRefreshKey)
}

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

export async function verifyRefreshToken(token: string): Promise<AuthPayload | null> {
  try {
    const { payload } = await jwtVerify(token, encodedRefreshKey, {
      algorithms: ['HS256'],
    })
    return payload as AuthPayload
  } catch {
    return null
  }
}
