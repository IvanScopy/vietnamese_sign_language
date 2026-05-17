import twilio from 'twilio';

export interface SmsSendRequest {
  to: string; // E.164 phone number
  body: string;
  statusCallback?: string;
}

export interface SmsSendResult {
  success: boolean;
  provider: 'twilio' | 'unavailable';
  providerMessageSid?: string;
  providerStatus?: string;
  status: 'PROVIDER_QUEUED' | 'PROVIDER_SENT' | 'PROVIDER_FAILED' | 'PROVIDER_UNDELIVERED';
  errorCode?: string;
  errorMessage?: string;
}

export interface SmsProvider {
  send(request: SmsSendRequest): Promise<SmsSendResult>;
}

export function getSmsProvider(): SmsProvider {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID;
  const fromNumber = process.env.TWILIO_FROM_NUMBER;
  const statusCallbackBase = process.env.TWILIO_STATUS_CALLBACK_BASE_URL;

  if (!accountSid || !authToken || (!messagingServiceSid && !fromNumber)) {
    // Return unavailable provider — routes to native fallback
    return {
      async send(): Promise<SmsSendResult> {
        return {
          success: false,
          provider: 'unavailable',
          status: 'PROVIDER_FAILED',
          errorCode: 'TWILIO_NOT_CONFIGURED',
          errorMessage: 'SMS provider not configured',
        };
      },
    };
  }

  const client = twilio(accountSid, authToken);

  return {
    async send(request: SmsSendRequest): Promise<SmsSendResult> {
      try {
        const params: Record<string, string> = {
          to: request.to,
          body: request.body,
        };
        if (messagingServiceSid) {
          params.messagingServiceSid = messagingServiceSid;
        } else {
          params.from = fromNumber!;
        }
        if (statusCallbackBase && request.statusCallback) {
          params.statusCallback = statusCallbackBase + request.statusCallback;
        }

        const message = await client.messages.create(params as any);
        return {
          success: true,
          provider: 'twilio',
          providerMessageSid: message.sid,
          providerStatus: message.status,
          status: 'PROVIDER_QUEUED',
        };
      } catch (err: any) {
        return {
          success: false,
          provider: 'twilio',
          status: 'PROVIDER_FAILED',
          errorCode: err.code?.toString(),
          errorMessage: err.message,
        };
      }
    },
  };
}
