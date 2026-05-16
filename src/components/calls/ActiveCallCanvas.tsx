'use client'

import React, { useState, useCallback } from 'react'
import {
  LiveKitRoom,
  RoomAudioRenderer,
  useTracks,
  useRoomContext,
  TrackToggle,
} from '@livekit/components-react'
import '@livekit/components-styles'
import { Track, MediaDeviceFailure } from 'livekit-client'
import VideoTile from '@/components/calls/VideoTile'
import CallControlBar from '@/components/calls/CallControlBar'
import SubtitleOverlay from '@/components/calls/SubtitleOverlay'
import SignDraftOverlay from '@/components/calls/SignDraftOverlay'
import CallResult from '@/components/calls/CallResult'

export interface ActiveCallCanvasProps {
  token: string
  roomName: string
  callId: number
  serverUrl: string
  onEnd: () => void
}

function CallContent({
  callId,
  onEnd,
}: {
  callId: number
  onEnd: () => void
}) {
  const room = useRoomContext()
  const [isMuted, setIsMuted] = useState(false)
  const [isCameraOn, setIsCameraOn] = useState(true)
  const [mediaError, setMediaError] = useState<string | null>(null)
  const [subtitle, setSubtitle] = useState('')
  const [draftText, setDraftText] = useState('')
  const [confidence, setConfidence] = useState<number | undefined>(undefined)

  const tracks = useTracks([Track.Source.Camera, Track.Source.Microphone])

  const remoteVideoTrack = tracks.find(
    (t) => t.publication.kind === Track.Kind.Video && !t.participant.isLocal
  )
  const localVideoTrack = tracks.find(
    (t) => t.publication.kind === Track.Kind.Video && t.participant.isLocal
  )

  const handleToggleMute = useCallback(async () => {
    try {
      await room.localParticipant.setMicrophoneEnabled(!isMuted)
      setIsMuted(!isMuted)
    } catch {
      setMediaError('Unable to toggle microphone')
    }
  }, [isMuted, room.localParticipant])

  const handleToggleCamera = useCallback(async () => {
    try {
      await room.localParticipant.setCameraEnabled(!isCameraOn)
      setIsCameraOn(!isCameraOn)
    } catch {
      setMediaError('Unable to toggle camera')
    }
  }, [isCameraOn, room.localParticipant])

  const handleEndCall = useCallback(async () => {
    try {
      await fetch(`/api/calls/${callId}/end`, {
        method: 'POST',
        credentials: 'include',
      })
    } catch (err) {
      console.error('Failed to end call:', err)
    } finally {
      onEnd()
    }
  }, [callId, onEnd])

  if (mediaError) {
    return (
      <div
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
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            backgroundColor: '#F59E0B',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 24,
          }}
        >
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
            <line x1="12" y1="9" x2="12" y2="13" />
            <line x1="12" y1="17" x2="12.01" y2="17" />
          </svg>
        </div>
        <h2
          style={{
            fontSize: 20,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#101010',
            margin: '0 0 8px',
          }}
        >
          Media access error
        </h2>
        <p
          style={{
            fontSize: 16,
            fontWeight: 400,
            lineHeight: 1.5,
            color: '#6B7280',
            margin: '0 0 24px',
            maxWidth: 400,
          }}
        >
          {mediaError}
        </p>
        <div style={{ display: 'flex', gap: 12 }}>
          <button
            type="button"
            onClick={() => setMediaError(null)}
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
            }}
          >
            Try again
          </button>
          <button
            type="button"
            onClick={onEnd}
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
            }}
          >
            End call
          </button>
        </div>
      </div>
    )
  }

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        backgroundColor: '#101010',
        position: 'relative',
      }}
    >
      {/* Remote video (main) */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {remoteVideoTrack ? (
          <VideoTile
            track={
              remoteVideoTrack.publication.track?.mediaStream ?? undefined
            }
            isLoading={false}
            hasPermission={true}
            aspectRatio="16/9"
          />
        ) : (
          <VideoTile
            isLoading={true}
            hasPermission={true}
            aspectRatio="16/9"
          />
        )}

        {/* Local preview (top-right corner) */}
        <div
          style={{
            position: 'absolute',
            top: 16,
            right: 16,
            width: 120,
            borderRadius: 8,
            overflow: 'hidden',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.4)',
          }}
        >
          {localVideoTrack && isCameraOn ? (
            <VideoTile
              track={
                localVideoTrack.publication.track?.mediaStream ?? undefined
              }
              isLocal
              isLoading={false}
              hasPermission={true}
              aspectRatio="9/16"
            />
          ) : (
            <VideoTile
              isLocal
              isLoading={false}
              hasPermission={isCameraOn}
              aspectRatio="9/16"
            />
          )}
        </div>

        {/* Subtitle overlay */}
        <SubtitleOverlay subtitle={subtitle} speakerName={subtitle ? 'Speaker' : undefined} />

        {/* Sign draft overlay (placeholder — Plan 05 will wire real data) */}
        {draftText && (
          <SignDraftOverlay
            draftText={draftText}
            confidence={confidence}
            onConfirm={() => setDraftText('')}
          />
        )}
      </div>

      {/* Audio renderer for LiveKit */}
      <RoomAudioRenderer />

      {/* Control bar */}
      <CallControlBar
        isMuted={isMuted}
        isCameraOn={isCameraOn}
        onToggleMute={handleToggleMute}
        onToggleCamera={handleToggleCamera}
        onEnd={handleEndCall}
        connectionStatus="connected"
      />
    </div>
  )
}

export default function ActiveCallCanvas({
  token,
  roomName,
  callId,
  serverUrl,
  onEnd,
}: ActiveCallCanvasProps) {
  const [error, setError] = useState<string | null>(null)

  const handleMediaError = useCallback((failure?: MediaDeviceFailure) => {
    const message =
      failure === MediaDeviceFailure.NotFound
        ? 'Camera or microphone not found'
        : failure === MediaDeviceFailure.PermissionDenied
          ? 'Camera or microphone permission denied'
          : 'Unable to access camera or microphone'
    setError(message)
  }, [])

  return (
    <LiveKitRoom
      token={token}
      serverUrl={serverUrl}
      connect
      audio
      video
      onMediaDeviceFailure={handleMediaError}
      style={{ height: '100%', width: '100%' }}
    >
      {error ? (
        <CallResult
          state="failed"
          onRetry={() => setError(null)}
          onHome={onEnd}
        />
      ) : (
        <CallContent callId={callId} onEnd={onEnd} />
      )}
    </LiveKitRoom>
  )
}
