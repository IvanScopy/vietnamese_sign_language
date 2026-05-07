import { jest } from '@jest/globals'

// Mock Prisma client
jest.mock('@/app/lib/db', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
      delete: jest.fn(),
    },
    refreshToken: {
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
      update: jest.fn(),
    },
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
    $queryRaw: jest.fn(),
    $executeRaw: jest.fn(),
  },
}))

// Mock auth module
jest.mock('@/app/lib/auth', () => ({
  verifyAccessToken: jest.fn(),
  verifyRefreshToken: jest.fn(),
  encryptAccessToken: jest.fn().mockResolvedValue('mock-access-token'),
  encryptRefreshToken: jest.fn().mockResolvedValue('mock-refresh-token'),
}))

// Mock bcrypt
jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed-password'),
  compare: jest.fn().mockResolvedValue(true),
}))

// Mock Google OAuth (for historical context - Google OAuth was removed from current scope)
jest.mock('@/app/lib/google-oauth', () => ({
  verifyGoogleToken: jest.fn().mockResolvedValue({
    email: 'google@example.com',
    name: 'Google User',
    emailVerified: true,
  }),
  getGoogleAuthURL: jest.fn().mockReturnValue('https://accounts.google.com/o/oauth2/v2/auth'),
}))

// Mock STT provider
jest.mock('@/app/lib/providers/stt-provider', () => ({
  getSTTProvider: () => ({
    transcribe: jest.fn().mockResolvedValue('Xin chào thế giới'),
  }),
}))

// Mock TTS provider
jest.mock('@/app/lib/providers/tts-provider', () => ({
  getTTSProvider: () => ({
    synthesize: jest.fn().mockResolvedValue(Buffer.from('mock audio')),
  }),
}))

// Mock Coqui TTS fallback
jest.mock('@/app/lib/providers/coqui-tts', () => ({
  CoquiTTSProvider: jest.fn().mockImplementation(() => ({
    synthesize: jest.fn().mockResolvedValue(Buffer.from('fallback audio')),
  })),
}))

// Mock WhisperCpp STT fallback
jest.mock('@/app/lib/providers/whisper-cpp-stt', () => ({
  WhisperCppSTTProvider: jest.fn().mockImplementation(() => ({
    transcribe: jest.fn().mockResolvedValue('fallback transcript'),
  })),
}))

// Global test timeout
jest.setTimeout(10000)
