import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedUser } from '@/app/lib/request-auth';
import { CreateSosAlertSchema } from '@/app/lib/validators';
import { createSosAlert } from '@/app/lib/sos';

export async function POST(request: NextRequest) {
  const payload = await getAuthenticatedUser(request);
  if (!payload) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const validation = CreateSosAlertSchema.safeParse(body);
  if (!validation.success) {
    return NextResponse.json({ error: 'Invalid request', details: validation.error.flatten() }, { status: 400 });
  }

  try {
    const result = await createSosAlert(payload.userId, validation.data);
    return NextResponse.json(result, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: 'SOS creation failed', message: err.message }, { status: 500 });
  }
}
