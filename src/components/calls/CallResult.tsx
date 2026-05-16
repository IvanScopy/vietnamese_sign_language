'use client'

import React from 'react'

export type CallResultState = 'ended' | 'missed' | 'rejected' | 'cancelled' | 'busy' | 'failed'

export interface CallResultProps {
  state: CallResultState
  onRetry?: () => void
  onHome: () => void
  onSaveTranscript?: () => void
}

const stateConfig: Record<CallResultState, { heading: string; body?: string }> = {
  ended: {
    heading: 'Call ended',
    body: 'Only confirmed text will be saved. Audio and video are not recorded.',
  },
  missed: {
    heading: 'Missed call',
  },
  rejected: {
    heading: 'Call rejected',
  },
  cancelled: {
    heading: 'Call unavailable',
  },
  busy: {
    heading: 'Busy',
    body: 'This person is already in a call.',
  },
  failed: {
    heading: 'Call failed',
    body: 'Call could not connect. Check camera, microphone, and network access, then try again.',
  },
}

export default function CallResult({
  state,
  onRetry,
  onHome,
  onSaveTranscript,
}: CallResultProps) {
  const config = stateConfig[state]

  return (
    <div
      role="status"
      aria-label={`Call ${state}`}
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100%',
        padding: 24,
        backgroundColor: '#FFFFFF',
        textAlign: 'center',
      }}
    >
      {/* State icon */}
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: '50%',
          backgroundColor:
            state === 'ended'
              ? '#16A34A'
              : state === 'failed'
                ? '#DC2626'
                : state === 'busy'
                  ? '#7C3AED'
                  : state === 'missed'
                    ? '#7C3AED'
                    : '#6B7280',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: 24,
        }}
      >
        {state === 'ended' ? (
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <polyline points="20 6 9 17 4 12" />
          </svg>
        ) : state === 'failed' ? (
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10" />
            <line x1="15" y1="9" x2="9" y2="15" />
            <line x1="9" y1="9" x2="15" y2="15" />
          </svg>
        ) : state === 'busy' || state === 'missed' ? (
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10" />
            <polyline points="12 6 12 12 16 14" />
          </svg>
        ) : (
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        )}
      </div>

      {/* Heading */}
      <h2
        style={{
          fontSize: 28,
          fontWeight: 600,
          lineHeight: 1.2,
          color: '#101010',
          margin: '0 0 8px',
        }}
      >
        {config.heading}
      </h2>

      {/* Body text */}
      {config.body && (
        <p
          style={{
            fontSize: 16,
            fontWeight: 400,
            lineHeight: 1.5,
            color: '#6B7280',
            margin: '0 0 32px',
            maxWidth: 400,
          }}
        >
          {config.body}
        </p>
      )}

      {/* Action buttons */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 12,
          alignItems: 'center',
          marginTop: 8,
        }}
      >
        {/* Save transcript (ended only) */}
        {state === 'ended' && onSaveTranscript && (
          <button
            type="button"
            onClick={onSaveTranscript}
            aria-label="Save text transcript"
            style={{
              height: 44,
              padding: '0 24px',
              borderRadius: 8,
              border: '1px solid #16A34A',
              backgroundColor: 'transparent',
              color: '#16A34A',
              fontSize: 14,
              fontWeight: 600,
              lineHeight: 1.3,
              cursor: 'pointer',
              width: '100%',
              maxWidth: 280,
            }}
          >
            Save text transcript?
          </button>
        )}

        {/* Try again (failed only) */}
        {state === 'failed' && onRetry && (
          <button
            type="button"
            onClick={onRetry}
            aria-label="Try again"
            style={{
              height: 44,
              padding: '0 24px',
              borderRadius: 8,
              border: 'none',
              backgroundColor: '#16A34A',
              color: '#FFFFFF',
              fontSize: 14,
              fontWeight: 600,
              lineHeight: 1.3,
              cursor: 'pointer',
              width: '100%',
              maxWidth: 280,
            }}
          >
            Try again
          </button>
        )}

        {/* Back to home (all states) */}
        <button
          type="button"
          onClick={onHome}
          aria-label="Back to home"
          style={{
            height: 44,
            padding: '0 24px',
            borderRadius: 8,
            border: '1px solid #6B7280',
            backgroundColor: 'transparent',
            color: '#6B7280',
            fontSize: 14,
            fontWeight: 600,
            lineHeight: 1.3,
            cursor: 'pointer',
            width: '100%',
            maxWidth: 280,
          }}
        >
          Back to home
        </button>
      </div>
    </div>
  )
}
