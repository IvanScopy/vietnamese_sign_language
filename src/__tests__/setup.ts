import { jest } from '@jest/globals'

// Mock Prisma client
jest.mock('@/app/lib/db', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
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
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
    notification: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    sOSAlert: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    sosAlertAttempt: {
      create: jest.fn(),
      createMany: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    deviceToken: {
      upsert: jest.fn(),
      findMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    dictionaryEntry: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      upsert: jest.fn(),
      count: jest.fn(),
    },
    dictionaryCategory: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      upsert: jest.fn(),
      count: jest.fn(),
    },
    lessonPlaceholder: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    adminAuditLog: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    broadcastMessage: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    dictionaryUpload: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    callSession: {
      create: jest.fn(),
      findUnique: jest.fn(),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      count: jest.fn(),
    },
    $queryRaw: jest.fn(),
    $executeRaw: jest.fn(),
    $transaction: jest.fn(async (fn) => fn((jest.requireMock('@/app/lib/db') as { prisma: unknown }).prisma)),
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
