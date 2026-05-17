'use client'

import { useMemo, useRef, useState, type CSSProperties } from 'react'

type Props = {
  src: string
  poster?: string | null
}

export default function DictionaryPlayer({ src, poster }: Props) {
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const [rate, setRate] = useState(1)
  const [status, setStatus] = useState<'idle' | 'loading' | 'ready' | 'error'>('idle')
  const speeds = useMemo(() => [0.5, 0.75, 1], [])

  const applyRate = (value: number) => {
    setRate(value)
    if (videoRef.current) {
      videoRef.current.playbackRate = value
    }
  }

  return (
    <div style={{ display: 'grid', gap: 16 }}>
      <div style={{ position: 'relative', borderRadius: 8, overflow: 'hidden', background: '#101010' }}>
        <video
          ref={videoRef}
          controls
          poster={poster ?? undefined}
          style={{ width: '100%', aspectRatio: '16 / 9', background: '#101010' }}
          onLoadStart={() => setStatus('loading')}
          onCanPlay={() => setStatus('ready')}
          onError={() => setStatus('error')}
        >
          <source src={src} type="video/mp4" />
        </video>
        {status === 'loading' ? (
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: '#FFFFFF' }}>
            Loading video...
          </div>
        ) : null}
        {status === 'error' ? (
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', color: '#FFFFFF', padding: 16, textAlign: 'center' }}>
            This video could not be loaded. Try again later.
          </div>
        ) : null}
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        <button type="button" onClick={() => videoRef.current?.play()} style={buttonStyle}>Play</button>
        <button type="button" onClick={() => videoRef.current?.pause()} style={buttonStyle}>Pause</button>
        <button
          type="button"
          onClick={() => {
            if (videoRef.current) {
              videoRef.current.currentTime = 0
              void videoRef.current.play()
            }
          }}
          style={buttonStyle}
        >
          Replay
        </button>
        {speeds.map((speed) => (
          <button
            key={speed}
            type="button"
            onClick={() => applyRate(speed)}
            style={{
              ...buttonStyle,
              backgroundColor: rate === speed ? '#2563EB' : '#F3F4F6',
              color: rate === speed ? '#FFFFFF' : '#101010',
            }}
          >
            {speed}x
          </button>
        ))}
        <button
          type="button"
          onClick={() => videoRef.current?.requestFullscreen?.()}
          style={buttonStyle}
        >
          Fullscreen
        </button>
      </div>
    </div>
  )
}

const buttonStyle: CSSProperties = {
  minHeight: 44,
  padding: '10px 16px',
  border: '1px solid #E5E7EB',
  borderRadius: 8,
  backgroundColor: '#F3F4F6',
  color: '#101010',
  fontSize: 14,
  fontWeight: 600,
}
