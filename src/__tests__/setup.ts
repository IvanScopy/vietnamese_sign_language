import { jest } from '@jest/globals'

// Mock Prisma Client
jest.mock('@/app/lib/db', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      deleteMany: jest.fn(),
      delete: jest.fn(),
    },
    emergencyContact: {
      findMany: jest.fn(),
      create: jest.fn(),
      delete: jest.fn(),
    },
    $queryRaw: jest.fn(),
  },
}))

// Mock bcrypt
jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed-password'),
  compare: jest.fn().mockResolvedValue(true),
}))

// Mock jose (JWT)
jest.mock('jose', () => ({
  SignJWT: jest.fn().mockReturnValue({
    setProtectedHeader: jest.fn().mockReturnThis(),
    setIssuedAt: jest.fn().mockReturnThis(),
    setExpirationTime: jest.fn().mockReturnThis(),
    sign: jest.fn().mockResolvedValue('mock-jwt-token'),
  }),
  jwtVerify: jest.fn().mockResolvedValue({
    payload: { userId: 1, email: 'test@example.com', userType: 'HEARING' },
  }),
}))
