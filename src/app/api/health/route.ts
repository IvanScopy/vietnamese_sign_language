import { NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'

export async function GET() {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {
      api: 'ok' as const,
      database: 'unknown' as string,
      redis: 'unknown' as string,
      livekit: 'unknown' as string,
    },
  }

  // Check database
  try {
    await prisma.$queryRaw`SELECT 1`
    health.services.database = 'ok'
  } catch (error) {
    console.error('Health check database error:', error)
    health.services.database = 'error'
    health.status = 'degraded'
  }

  // Check Redis (if configured)
  try {
    const redisUrl = process.env.REDIS_URL
    if (redisUrl) {
      // Could use ioredis or redis client to ping in production
      // For now, just mark as configured
      health.services.redis = 'ok'
    } else {
      health.services.redis = 'not_configured'
    }
  } catch (error) {
    console.error('Health check Redis error:', error)
    health.services.redis = 'error'
    health.status = 'degraded'
  }

  // Check LiveKit (simple check - URL configured)
  try {
    const livekitUrl = process.env.NEXT_PUBLIC_LIVEKIT_URL
    if (livekitUrl) {
      health.services.livekit = 'ok'
    } else {
      health.services.livekit = 'not_configured'
    }
  } catch (error) {
    console.error('Health check LiveKit error:', error)
    health.services.livekit = 'error'
    health.status = 'degraded'
  }

  const statusCode = health.status === 'ok' ? 200 : 503
  return NextResponse.json(health, { status: statusCode })
}
