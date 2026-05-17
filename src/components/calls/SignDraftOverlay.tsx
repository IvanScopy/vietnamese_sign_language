'use client'

import React from 'react'

export interface SignDraftOverlayProps {
  draftText: string
  confidence?: number
  onConfirm: () => void
  onConfirmAndPlay?: () => void
}

export default function SignDraftOverlay({
  draftText,
  confidence,
  onConfirm,
  onConfirmAndPlay,
}: SignDraftOverlayProps) {
  if (!draftText) {
    return null
  }

  const isLowConfidence = confidence !== undefined && confidence < 0.60

  return (
    <div
      role="status"
      aria-live="polite"
      aria-label="Sign recognition draft"
      style={{
        position: 'absolute',
        bottom: 80,
        left: 16,
        right: 16,
        padding: 12,
        backgroundColor: 'rgba(16, 16, 16, 0.85)',
        backdropFilter: 'blur(4px)',
        borderRadius: 8,
        border: isLowConfidence ? '1px solid #F59E0B' : '1px solid rgba(255, 255, 255, 0.1)',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          gap: 8,
        }}
      >
        <div style={{ flex: 1, minWidth: 0 }}>
          <p
            style={{
              fontSize: 16,
              fontWeight: 400,
              lineHeight: 1.5,
              color: '#FFFFFF',
              margin: 0,
              display: '-webkit-box',
              WebkitLineClamp: 2,
              WebkitBoxOrient: 'vertical',
              overflow: 'hidden',
            }}
          >
            {draftText}
          </p>
          {isLowConfidence && (
            <span
              style={{
                fontSize: 12,
                fontWeight: 600,
                lineHeight: 1.3,
                color: '#F59E0B',
                marginTop: 4,
                display: 'inline-block',
              }}
            >
              Unclear
            </span>
          )}
          {confidence !== undefined && !isLowConfidence && (
            <span
              style={{
                fontSize: 12,
                fontWeight: 600,
                lineHeight: 1.3,
                color: '#16A34A',
                marginTop: 4,
                display: 'inline-block',
              }}
            >
              {Math.round(confidence * 100)}% confidence
            </span>
          )}
        </div>

        <div
          style={{
            display: 'flex',
            gap: 8,
            flexShrink: 0,
          }}
        >
          <button
            type="button"
            onClick={onConfirm}
            aria-label="Confirm sign text"
            style={{
              height: 36,
              padding: '0 12px',
              borderRadius: 6,
              border: 'none',
              backgroundColor: '#16A34A',
              color: '#FFFFFF',
              fontSize: 14,
              fontWeight: 600,
              lineHeight: 1.3,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 4,
            }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            Confirm
          </button>

          {onConfirmAndPlay && (
            <button
              type="button"
              onClick={onConfirmAndPlay}
              aria-label="Confirm sign text and play audio"
              style={{
                height: 36,
                padding: '0 12px',
                borderRadius: 6,
                border: 'none',
                backgroundColor: '#2563EB',
                color: '#FFFFFF',
                fontSize: 14,
                fontWeight: 600,
                lineHeight: 1.3,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 4,
              }}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
                <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" />
              </svg>
              Confirm & Play
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
