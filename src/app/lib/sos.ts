export function buildSosSmsBody({
  userName,
  latitude,
  longitude,
  locationLabel,
  locationCapturedAt,
}: {
  userName: string;
  latitude?: number;
  longitude?: number;
  locationLabel?: string;
  locationCapturedAt?: Date | string;
}): string {
  const now = locationCapturedAt ? new Date(locationCapturedAt) : new Date();
  const timeStr = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });

  let locationText: string;
  if (latitude != null && longitude != null) {
    const mapLink = `https://maps.google.com/?q=${latitude},${longitude}`;
    const labelText =
      locationLabel === 'approximate' ? ' (vị trí gần đúng)' :
      locationLabel === 'last_known' ? ' (vị trí cuối cùng đã biết)' : '';
    locationText = `Vị trí: ${mapLink}${labelText}`;
  } else {
    locationText = 'Không có vị trí GPS';
  }

  return `🆘 ${userName} cần trợ giúp khẩn cấp!\nTôi cần trợ giúp khẩn cấp. Đường dây khẩn cấp: 115\n${locationText}\nThời gian: ${timeStr}`;
}

export async function createSosAlert(
  userId: number,
  data: {
    latitude?: number;
    longitude?: number;
    locationAccuracyMeters?: number;
    locationLabel?: string;
    locationCapturedAt?: string;
    idempotencyKey?: string;
  }
) {
  const { prisma } = await import('./db');
  const { getSmsProvider } = await import('./sms-provider');

  // Idempotency: check for existing alert with same key
  if (data.idempotencyKey) {
    const existing = await prisma.sOSAlert.findFirst({
      where: { userId, idempotencyKey: data.idempotencyKey },
      include: { attempts: true },
    });
    if (existing) {
      return buildResponseFromAlert(existing);
    }
  }

  // Load user and active contacts
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, name: true } });
  const userName = user?.name ?? 'Người dùng';

  const contacts = await prisma.emergencyContact.findMany({
    where: { userId, isActive: true },
  });

  const smsBody = buildSosSmsBody({
    userName,
    latitude: data.latitude,
    longitude: data.longitude,
    locationLabel: data.locationLabel,
    locationCapturedAt: data.locationCapturedAt,
  });

  // Create the alert
  const alert = await prisma.sOSAlert.create({
    data: {
      userId,
      status: contacts.length === 0 ? 'SENT' : 'SENDING',
      latitude: data.latitude,
      longitude: data.longitude,
      locationAccuracyMeters: data.locationAccuracyMeters,
      locationLabel: data.locationLabel,
      locationCapturedAt: data.locationCapturedAt ? new Date(data.locationCapturedAt) : undefined,
      smsBody,
      idempotencyKey: data.idempotencyKey,
      sentAt: new Date(),
    },
  });

  if (contacts.length === 0) {
    return {
      id: alert.id,
      status: 'SENT',
      smsBody,
      contactsCount: 0,
      noContacts: true,
      attempts: [],
      fallbackTargets: [],
    };
  }

  // Create attempt records
  const attemptCreates = contacts.map((contact) =>
    prisma.sosAlertAttempt.create({
      data: {
        sosAlertId: alert.id,
        emergencyContactId: contact.id,
        recipientName: contact.name,
        recipientPhoneE164: contact.phoneE164 ?? contact.phone,
        channel: 'PROVIDER_SMS',
        status: 'PROVIDER_QUEUED',
        queuedAt: new Date(),
      },
    })
  );
  const attempts = await Promise.all(attemptCreates);

  // Send provider SMS concurrently to all contacts
  const provider = getSmsProvider();
  const sendResults = await Promise.all(
    contacts.map(async (contact, i) => {
      const phoneNumber = contact.phoneE164 ?? contact.phone;
      if (!phoneNumber) {
        return {
          attempt: attempts[i],
          result: {
            success: false,
            provider: 'unavailable' as const,
            status: 'PROVIDER_FAILED' as const,
            errorMessage: 'No phone number',
          },
        };
      }
      const result = await provider.send({
        to: phoneNumber,
        body: smsBody,
        statusCallback: `/api/sos/twilio/status`,
      });
      return { attempt: attempts[i], result };
    })
  );

  // Update attempt records with provider results
  const updateOps = sendResults.map(({ attempt, result }) =>
    prisma.sosAlertAttempt.update({
      where: { id: attempt.id },
      data: {
        provider: result.provider,
        providerMessageSid: result.providerMessageSid,
        providerStatus: result.providerStatus,
        status: result.status,
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
        sentAt: result.success ? new Date() : undefined,
        failedAt: result.success ? undefined : new Date(),
      },
    })
  );
  const updatedAttempts = await Promise.all(updateOps);

  // Determine aggregate status
  const allFailed = sendResults.every((r) => !r.result.success);
  const someFailed = sendResults.some((r) => !r.result.success);
  const aggregateStatus = allFailed ? 'NATIVE_FALLBACK' : someFailed ? 'PARTIAL_FAILED' : 'SENDING';

  await prisma.sOSAlert.update({ where: { id: alert.id }, data: { status: aggregateStatus } });

  const fallbackTargets = allFailed
    ? contacts.map((c) => ({ name: c.name, phoneE164: c.phoneE164 ?? c.phone ?? '' }))
    : [];

  return {
    id: alert.id,
    status: aggregateStatus,
    smsBody,
    contactsCount: contacts.length,
    noContacts: false,
    attempts: updatedAttempts.map((a) => ({
      id: a.id,
      channel: a.channel,
      status: a.status,
      recipientName: a.recipientName,
      recipientPhoneE164: a.recipientPhoneE164,
    })),
    fallbackTargets,
  };
}

function buildResponseFromAlert(alert: any) {
  return {
    id: alert.id,
    status: alert.status,
    smsBody: alert.smsBody,
    contactsCount: alert.attempts?.length ?? 0,
    noContacts: (alert.attempts?.length ?? 0) === 0,
    attempts: (alert.attempts ?? []).map((a: any) => ({
      id: a.id,
      channel: a.channel,
      status: a.status,
      recipientName: a.recipientName,
      recipientPhoneE164: a.recipientPhoneE164,
    })),
    fallbackTargets: [],
  };
}
