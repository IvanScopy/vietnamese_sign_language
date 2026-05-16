'use client'

import React from 'react'

export interface CallControlBarProps {
  isMuted: boolean
  isCameraOn: boolean
  onToggleMute: () => void
  onToggleCamera: () => void
  onEnd: () => void
  connectionStatus: 'connected' | 'connecting' | 'disconnected'
}

const statusConfig = {
  connected: { color: '#16A34A', label: 'Connected' },
  connecting: { color: '#F59E0B', label: 'Connecting' },
  disconnected: { color: '#6B7280', label: 'Disconnected' },
}

export default function CallControlBar({
  isMuted,
  isCameraOn,
  onToggleMute,
  onToggleCamera,
  onEnd,
  connectionStatus,
}: CallControlBarProps) {
  const status = statusConfig[connectionStatus]

  return (
    <div
      role="toolbar"
      aria-label="Call controls"
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        padding: 16,
        backgroundColor: 'rgba(16, 16, 16, 0.9)',
        backdropFilter: 'blur(8px)',
        borderTop: '1px solid rgba(255, 255, 255, 0.1)',
      }}
    >
      {/* Connection status pill */}
      <span
        aria-label={`Call status: ${status.label}`}
        style={{
          fontSize: 14,
          fontWeight: 600,
          lineHeight: 1.3,
          color: status.color,
          padding: '4px 12px',
          borderRadius: 16,
          backgroundColor: `${status.color}1A`,
          minWidth: 80,
          textAlign: 'center',
        }}
      >
        {status.label}
      </span>

      {/* Mute microphone button */}
      <button
        type="button"
        onClick={onToggleMute}
        aria-label={isMuted ? 'Unmute microphone' : 'Mute microphone'}
        style={{
          width: 44,
          height: 44,
          borderRadius: '50%',
          border: 'none',
          backgroundColor: isMuted ? '#DC2626' : 'rgba(255, 255, 255, 0.1)',
          color: '#FFFFFF',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          transition: 'background-color 0.15s ease',
        }}
      >
        {isMuted ? (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <line x1="1" y1="1" x2="23" y2="23" />
            <path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6" />
            <path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2c0 .76-.13 1.49-.35 2.17" />
            <line x1="12" y1="19" x2="12" y2="23" />
            <line x1="8" y1="23" x2="16" y2="23" />
          </svg>
        ) : (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z" />
            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
            <line x1="12" y1="19" x2="12" y2="23" />
            <line x1="8" y1="23" x2="16" y2="23" />
          </svg>
        )}
      </button>

      {/* Camera toggle button */}
      <button
        type="button"
        onClick={onToggleCamera}
        aria-label={isCameraOn ? 'Turn off camera' : 'Turn on camera'}
        style={{
          width: 44,
          height: 44,
          borderRadius: '50%',
          border: 'none',
          backgroundColor: !isCameraOn ? '#DC2626' : 'rgba(255, 255, 255, 0.1)',
          color: '#FFFFFF',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          transition: 'background-color 0.15s ease',
        }}
      >
        {!isCameraOn ? (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2" />
            <polygon points="23 7 16 12 23 17 23 7" />
            <line x1="1" y1="1" x2="23" y2="23" />
          </svg>
        ) : (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <polygon points="23 7 16 12 23 17 23 7" />
            <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
          </svg>
        )}
      </button>

      {/* End call button */}
      <button
        type="button"
        onClick={onEnd}
        aria-label="End call"
        style={{
          height: 44,
          padding: '0 24px',
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
          justifyContent: 'center',
          gap: 8,
          transition: 'background-color 0.15s ease',
        }}
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.42 19.42 0 0 1-3.33-2.67m-2.67-3.34a19.79 19.79 0 0 1-3.07-8.63A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91" />
          <line x1="23" y1="1" x2="1" y2="23" />
        </svg>
        End call
      </button>
    </div>
  )
}
