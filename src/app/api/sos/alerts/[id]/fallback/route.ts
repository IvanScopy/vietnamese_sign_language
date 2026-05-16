import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedUser } from '@/app/lib/request-auth';
import { SosFallbackSchema } from '@/app/lib/validators';
import { recordSosFallback } from '@/app/lib/sos';

export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  const payload = await getAuthenticatedUser(request);
  if (!payload) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const alertId = parseInt(params.id, 10);
  if (isNaN(alertId)) return NextResponse.json({ error: 'Invalid id' }, { status: 400 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const validation = SosFallbackSchema.safeParse(body);
  if (!validation.success) {
    return NextResponse.json({ error: 'Invalid data', details: validation.error.flatten() }, { status: 400 });
  }

  const result = await recordSosFallback(payload.userId, alertId, validation.data);
  if (!result) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  return NextResponse.json({ success: true });
}
