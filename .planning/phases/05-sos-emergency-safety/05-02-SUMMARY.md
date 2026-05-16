---
plan: "05-02"
phase: "05"
status: complete
completed: "2026-05-16"
---
# Plan 05-02: SOS Persistence Schema & Validators — Summary

## What was built

Extended the Prisma schema with SOS-specific persistence models and enums, added Zod
validators for all SOS API surfaces, and extended Jest mocks for the new models.

**Schema changes:**

- Extended `EmergencyContact` with `phoneE164`, `isActive`, `linkedUserId` (self-referencing
  relation `EmergencyContactLinkedUser` to `User`), `updatedAt`, `attempts` relation,
  and `@@index([userId])` / `@@index([linkedUserId])`.
- Added `linkedEmergencyContacts` inverse relation to `User`.
- Extended `SOSAlert` with `latitude`, `longitude`, `locationAccuracyMeters`,
  `locationCapturedAt`, `locationLabel`, `smsBody`, `idempotencyKey` (unique),
  `sentAt`, `nativeFallbackOpenedAt`, `closedAt`, `updatedAt`, and `attempts` relation.
- Extended `SOSStatus` enum with: `SENDING`, `SENT`, `PARTIAL_FAILED`, `NATIVE_FALLBACK`, `FAILED`.
- Added `SOSDeliveryChannel` enum: `PROVIDER_SMS`, `NATIVE_SMS`, `PUSH`, `SOCKET`, `DIALER`.
- Added `SOSAttemptStatus` enum with 11 states covering provider delivery lifecycle,
  native composer, push, socket, and dialer outcomes.
- Added `SosAlertAttempt` model with full delivery attempt tracking (provider metadata,
  timestamps, status, error details, indexed by sosAlertId, emergencyContactId,
  linkedUserId, status, providerMessageSid).

**Validator changes (src/app/lib/validators.ts):**

- `CreateSosAlertSchema`: optional lat/lon/accuracy/label/capturedAt/idempotencyKey; no contact fields.
- `SosLocationUpdateSchema`: required lat/lon, optional accuracy/capturedAt, required label.
- `SosFallbackSchema`: `native_sms_opened | native_sms_failed | dialer_opened` only (no confirmed-sent state).
- `EmergencyContactSchema`: name, phone, optional phoneE164 (E.164 regex), isActive, linkedUserId.
- `UpdateEmergencyContactSchema`: partial of above.
- `TwilioStatusCallbackSchema`: MessageSid, 11-value MessageStatus enum, optional To/From/ErrorCode/ErrorMessage.
- `RegisterTokenSchema`: made `userId` optional (auth-derived instead of body-supplied).

**Jest mock changes (src/__tests__/setup.ts):**

- Extended `emergencyContact` mock with findUnique, findFirst, update, updateMany, deleteMany.
- Added `sOSAlert` mock (create/findUnique/findFirst/findMany/update/updateMany).
- Added `sosAlertAttempt` mock (create/createMany/findMany/findFirst/update/updateMany).
- Extended `deviceToken` mock with findMany and deleteMany.

## Verification

```
npx prisma validate
# => The schema at prisma/schema.prisma is valid

npx prisma generate
# => Generated Prisma Client (v7.8.0) in 253ms

DATABASE_URL=... npx prisma db push --accept-data-loss
# => Your database is now in sync with your Prisma schema. Done in 198ms

npx tsc --noEmit --pretty false 2>&1 | head -40
# => Only pre-existing errors (z.record, jest mock type inference, shared/types/landmarks.ts).
#    No new errors introduced by this plan.
```

## Commits

- `efc9095` feat(05-02): SOS Prisma schema, Zod validators, and Jest mocks

## Self-Check

- [x] `prisma/schema.prisma` exists and validates
- [x] `src/app/lib/validators.ts` has all 6 new SOS schemas
- [x] `src/__tests__/setup.ts` has sOSAlert, sosAlertAttempt, extended emergencyContact mocks
- [x] Commit efc9095 exists
- [x] No new TypeScript errors introduced
