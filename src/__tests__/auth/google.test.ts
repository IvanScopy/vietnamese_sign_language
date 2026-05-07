import { describe, it, skip } from '@jest/globals'

// Note: Google OAuth route was removed from the current scope.
// The project uses email/password authentication as the primary auth method.
// This test file documents the historical decision and is skipped.

describe('Google OAuth /api/auth/google', () => {
  it.skip('GET should redirect to Google authorization URL', () => {
    // Skipped - Google OAuth not implemented in current scope
    // If re-added, would test:
    // - Redirect status (307)
    // - Location header contains accounts.google.com
  })

  it.skip('POST should authenticate with valid Google code', () => {
    // Skipped - Google OAuth not implemented in current scope
    // If re-added, would test:
    // - Valid Google auth code returns user and tokens
    // - New users are created
    // - Existing users are logged in
  })

  it.skip('POST should return 401 for invalid Google token', () => {
    // Skipped - Google OAuth not implemented in current scope
    // Would test invalid token rejection
  })
})
