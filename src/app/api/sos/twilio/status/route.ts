import { NextRequest, NextResponse } from 'next/server';
import twilio from 'twilio';
import { TwilioStatusCallbackSchema } from '@/app/lib/validators';
import { recordTwilioStatus } from '@/app/lib/sos';

export async function POST(request: NextRequest) {
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const callbackUrl = process.env.TWILIO_STATUS_CALLBACK_BASE_URL;

  // Validate Twilio signature if auth token is configured
  if (authToken && callbackUrl) {
    const signature = request.headers.get('X-Twilio-Signature') ?? '';
    const fullUrl = callbackUrl + '/api/sos/twilio/status';
    const formText = await request.text();
    const params = Object.fromEntries(new URLSearchParams(formText));

    const isValid = twilio.validateRequest(authToken, signature, fullUrl, params);
    if (!isValid) return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });

    const validation = TwilioStatusCallbackSchema.safeParse(params);
    if (!validation.success) {
      return NextResponse.json({ error: 'Invalid callback' }, { status: 400 });
    }

    await recordTwilioStatus({
      MessageSid: validation.data.MessageSid,
      MessageStatus: validation.data.MessageStatus,
      ErrorCode: validation.data.ErrorCode,
      ErrorMessage: validation.data.ErrorMessage,
    });
  } else {
    // Callback received without validation config — log and acknowledge
    console.warn('[sos] Twilio callback received but TWILIO_AUTH_TOKEN not configured for validation');
  }

  return NextResponse.json({ received: true });
}
