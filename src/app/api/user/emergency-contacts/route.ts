import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { EmergencyContactSchema, UpdateEmergencyContactSchema } from '@/app/lib/validators'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

/**
 * Normalize a Vietnamese or international phone number to E.164 format.
 * Returns null if the number is not recognizable.
 */
function normalizePhoneE164(phone: string): string | null {
  // Strip spaces, hyphens, parentheses
  let cleaned = phone.replace(/[\s\-()]/g, '')

  // Vietnamese local numbers starting with 0 → replace 0 with +84
  if (cleaned.startsWith('0')) {
    cleaned = '+84' + cleaned.slice(1)
  }

  // Already international format
  // Validate E.164: starts with +, followed by 7-15 digits
  if (/^\+[1-9]\d{6,14}$/.test(cleaned)) {
    return cleaned
  }

  return null
}

export async function GET(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const contacts = await prisma.emergencyContact.findMany({
      where: { userId: payload.userId },
      orderBy: { createdAt: 'asc' },
    })

    return NextResponse.json({ contacts })
  } catch (error) {
    console.error('GET emergency contacts error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const validated = EmergencyContactSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { name, phone, linkedUserId } = validated.data

    // Normalize phone to E.164
    const phoneE164 = normalizePhoneE164(phone)
    if (!phoneE164) {
      return NextResponse.json(
        { error: 'Invalid phone number. Must be a valid Vietnamese (+84) or international E.164 number.' },
        { status: 400 }
      )
    }

    const contact = await prisma.emergencyContact.create({
      data: {
        name,
        phone,
        phoneE164,
        isActive: true,
        userId: payload.userId,
        ...(linkedUserId !== undefined && { linkedUserId }),
      },
    })

    return NextResponse.json({ contacts: [contact] }, { status: 201 })
  } catch (error) {
    console.error('POST emergency contact error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { id, ...rest } = body

    if (!id || typeof id !== 'number') {
      return NextResponse.json({ error: 'Contact id is required' }, { status: 400 })
    }

    const validated = UpdateEmergencyContactSchema.safeParse(rest)
    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const updates = validated.data

    // If phone is being updated, re-normalize
    if (updates.phone !== undefined) {
      const phoneE164 = normalizePhoneE164(updates.phone)
      if (!phoneE164) {
        return NextResponse.json(
          { error: 'Invalid phone number. Must be a valid Vietnamese (+84) or international E.164 number.' },
          { status: 400 }
        )
      }
      updates.phoneE164 = phoneE164
    }

    // Only update own contacts (scoped by userId)
    const updated = await prisma.emergencyContact.update({
      where: { id, userId: payload.userId } as { id: number; userId: number },
      data: updates,
    })

    return NextResponse.json({ contacts: [updated] })
  } catch (error) {
    console.error('PATCH emergency contact error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()
    const { id } = body

    if (!id || typeof id !== 'number') {
      return NextResponse.json({ error: 'Contact id is required' }, { status: 400 })
    }

    // Only delete own contacts
    await prisma.emergencyContact.deleteMany({
      where: { id, userId: payload.userId },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('DELETE emergency contact error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
