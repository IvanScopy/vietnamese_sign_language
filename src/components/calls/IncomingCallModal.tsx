'use client'

import React from 'react'

export interface IncomingCallModalProps {
  callerName: string
  callId: number
  onAccept: () => void
  onReject: () => void
  isOpen: boolean
}

export default function IncomingCallModal({
  callerName,
  callId,
  onAccept,
  onReject,
  isOpen,
}: IncomingCallModalProps) {
  if (!isOpen) {
    return null
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Incoming video call"
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 50,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(4px)',
      }}
    >
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: 16,
          padding: 24,
          maxWidth: 400,
          width: '100%',
          margin: 16,
          textAlign: 'center',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)',
        }}
      >
        {/* Caller icon */}
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            backgroundColor: '#16A34A',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 16px',
          }}
        >
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
          </svg>
        </div>

        {/* Heading */}
        <h2
          style={{
            fontSize: 14,
            fontWeight: 600,
            lineHeight: 1.3,
            color: '#6B7280',
            margin: '0 0 8px',
            textTransform: 'uppercase',
            letterSpacing: '0.05em',
          }}
        >
          Incoming video call
        </h2>

        {/* Caller name */}
        <p
          style={{
            fontSize: 28,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#101010',
            margin: '0 0 32px',
          }}
        >
          {callerName}
        </p>

        {/* Action buttons */}
        <div
          style={{
            display: 'flex',
            gap: 16,
            justifyContent: 'center',
          }}
        >
          {/* Reject button */}
          <button
            type="button"
            onClick={onReject}
            aria-label="Reject call"
            style={{
              height: 48,
              padding: '0 32px',
              borderRadius: 24,
              border: 'none',
              backgroundColor: '#DC2626',
              color: '#FFFFFF',
              fontSize: 14,
              fontWeight: 600,
              lineHeight: 1.3,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              transition: 'background-color 0.15s ease',
            }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
            Reject
          </button>

          {/* Accept button */}
          <button
            type="button"
            onClick={onAccept}
            aria-label="Accept call"
            style={{
              height: 48,
              padding: '0 32px',
              borderRadius: 24,
              border: 'none',
              backgroundColor: '#16A34A',
              color: '#FFFFFF',
              fontSize: 14,
              fontWeight: 600,
              lineHeight: 1.3,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              transition: 'background-color 0.15s ease',
            }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            Accept
          </button>
        </div>
      </div>
    </div>
  )
}
