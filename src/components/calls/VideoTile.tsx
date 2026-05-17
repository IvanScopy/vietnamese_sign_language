'use client'

import React from 'react'

export interface VideoTileProps {
  track?: MediaStream | null
  isLocal?: boolean
  isLoading: boolean
  hasPermission: boolean
  aspectRatio?: string
}

export default function VideoTile({
  track,
  isLocal = false,
  isLoading,
  hasPermission,
  aspectRatio = isLocal ? '9/16' : '16/9',
}: VideoTileProps) {
  const videoRef = React.useRef<HTMLVideoElement>(null)

  React.useEffect(() => {
    if (videoRef.current && track) {
      videoRef.current.srcObject = track
    }
  }, [track])

  // Permission denied state
  if (!hasPermission) {
    return (
      <div
        role="img"
        aria-label="Camera unavailable"
        style={{
          aspectRatio,
          backgroundColor: '#101010',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: 8,
          overflow: 'hidden',
        }}
      >
        <svg
          width="48"
          height="48"
          viewBox="0 0 24 24"
          fill="none"
          stroke="#6B7280"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <path d="M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2" />
          <polygon points="23 7 16 12 23 17 23 7" />
          <line x1="1" y1="1" x2="23" y2="23" />
        </svg>
        <span
          style={{
            fontSize: 20,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#6B7280',
            marginTop: 8,
          }}
        >
          Camera unavailable
        </span>
      </div>
    )
  }

  // Loading state
  if (isLoading) {
    return (
      <div
        role="status"
        aria-label="Connecting..."
        style={{
          aspectRatio,
          backgroundColor: '#101010',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: 8,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            width: 32,
            height: 32,
            border: '3px solid #2563EB',
            borderTopColor: 'transparent',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
          }}
          aria-hidden="true"
        />
        <span
          style={{
            fontSize: 20,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#FFFFFF',
            marginTop: 8,
          }}
        >
          Connecting...
        </span>
      </div>
    )
  }

  // Video track state
  return (
    <div
      style={{
        aspectRatio,
        backgroundColor: '#101010',
        borderRadius: 8,
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      {track ? (
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted={isLocal}
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'cover',
          }}
        />
      ) : (
        <div
          style={{
            width: '100%',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#101010',
          }}
        >
          <svg
            width="48"
            height="48"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#6B7280"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M23 7l-7 5 7 5V7z" />
            <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
          </svg>
        </div>
      )}
    </div>
  )
}
