'use client'

import React from 'react'

export interface SubtitleOverlayProps {
  subtitle: string
  speakerName?: string
}

export default function SubtitleOverlay({
  subtitle,
  speakerName,
}: SubtitleOverlayProps) {
  if (!subtitle) {
    return null
  }

  return (
    <div
      role="status"
      aria-live="polite"
      aria-label="Live subtitles"
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        padding: 16,
        backgroundColor: 'rgba(16, 16, 16, 0.72)',
        backdropFilter: 'blur(4px)',
      }}
    >
      <div
        style={{
          maxWidth: 640,
          margin: '0 auto',
          display: 'flex',
          alignItems: 'flex-start',
          gap: 8,
        }}
      >
        {speakerName && (
          <span
            style={{
              fontSize: 12,
              fontWeight: 600,
              lineHeight: 1.3,
              color: '#FFFFFF',
              backgroundColor: '#2563EB',
              padding: '2px 8px',
              borderRadius: 4,
              whiteSpace: 'nowrap',
              flexShrink: 0,
            }}
          >
            {speakerName}
          </span>
        )}
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
          {subtitle}
        </p>
      </div>
    </div>
  )
}
