export function getCameraUnavailableMessage() {
  return 'Camera requires HTTPS, localhost, and a supported browser.'
}

export function getCameraDeniedMessage() {
  return 'Camera permission was denied. Allow camera access in your browser settings and try again.'
}

export async function startCamera() {
  if (!globalThis.navigator?.mediaDevices?.getUserMedia) {
    throw new Error(getCameraUnavailableMessage())
  }

  return globalThis.navigator.mediaDevices.getUserMedia({ video: true, audio: false })
}

export function stopCamera(stream: MediaStream | null) {
  if (!stream) return
  for (const track of stream.getTracks()) {
    track.stop()
  }
}

export default function RecognitionPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 24 }}>
      <header style={{ display: 'grid', gap: 8 }}>
        <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600 }}>Recognition</h1>
        <p style={{ margin: 0, fontSize: 16, color: '#6B7280' }}>Use your webcam to recognize Vietnamese signs.</p>
      </header>
      <section aria-live="polite" style={{ padding: 24, borderRadius: 8, background: '#F3F4F6', border: '1px solid #E5E7EB', display: 'grid', gap: 16 }}>
        <div style={{ aspectRatio: '16 / 9', borderRadius: 8, background: '#101010', color: '#FFFFFF', display: 'grid', placeItems: 'center' }}>
          Camera preview
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button type="button" style={recognitionButtonStyle}>Start camera</button>
          <button type="button" style={recognitionButtonStyle}>Stop camera</button>
        </div>
        <div style={{ padding: 16, background: '#FFFFFF', borderRadius: 8, border: '1px solid #E5E7EB' }}>
          <strong style={{ display: 'block', marginBottom: 8 }}>Recognition output</strong>
          <span style={{ color: '#6B7280' }}>Waiting for camera access.</span>
        </div>
      </section>
    </main>
  )
}

const recognitionButtonStyle: CSSProperties = {
  minHeight: 48,
  padding: '12px 20px',
  borderRadius: 8,
  border: '1px solid #E5E7EB',
  background: '#2563EB',
  color: '#FFFFFF',
  fontSize: 16,
  fontWeight: 600,
}
import type { CSSProperties } from 'react'
