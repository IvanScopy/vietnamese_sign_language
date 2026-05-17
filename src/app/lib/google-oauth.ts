import { OAuth2Client } from 'google-auth-library'

const client = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/api/auth/google/callback'
)

export interface GoogleUserInfo {
  email: string
  name: string
  picture?: string
  emailVerified: boolean
}

export async function verifyGoogleToken(code: string): Promise<GoogleUserInfo | null> {
  try {
    // Exchange code for tokens
    const { tokens } = await client.getToken(code)

    if (!tokens.id_token) {
      return null
    }

    // Verify the ID token
    const ticket = await client.verifyIdToken({
      idToken: tokens.id_token,
      audience: process.env.GOOGLE_CLIENT_ID,
    })

    const payload = ticket.getPayload()

    if (!payload || !payload.email) {
      return null
    }

    return {
      email: payload.email,
      name: payload.name || '',
      picture: payload.picture,
      emailVerified: payload.email_verified || false,
    }
  } catch (error) {
    console.error('Google OAuth verification error:', error)
    return null
  }
}

export function getGoogleAuthURL(state?: string): string {
  const scopes = ['profile', 'email']
  return client.generateAuthUrl({
    access_type: 'offline',
    scope: scopes,
    state,
  })
}
