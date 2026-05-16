'use client'

import React, { useEffect, useState, useCallback } from 'react'
import { useParams, useRouter, useSearchParams } from 'next/navigation'
import ActiveCallCanvas from '@/components/calls/ActiveCallCanvas'
import CallResult, { type CallResultState } from '@/components/calls/CallResult'
import IncomingCallModal from '@/components/calls/IncomingCallModal'

type CallState = 'RINGING' | 'ACTIVE' | 'ENDED' | 'MISSED' | 'REJECTED' | 'CANCELLED' | 'BUSY' | 'FAILED'

export interface CallData {
  id: number
  state: CallState
  roomName?: string
  callerId: number
  calleeId: number
  callerName?: string
  calleeName?: string
}

const terminalStates: CallState[] = ['ENDED', 'MISSED', 'REJECTED', 'CANCELLED', 'BUSY', 'FAILED']

const stateToResultMap: Record<string, CallResultState> = {
  ENDED: 'ended',
  MISSED: 'missed',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled',
  BUSY: 'busy',
  FAILED: 'failed',
}

export async function fetchActiveCallToken(callId: number): Promise<string> {
  const tokenResponse = await fetch(`/api/calls/${callId}/token`, {
    method: 'POST',
    credentials: 'include',
  })

  if (!tokenResponse.ok) {
    throw new Error('Failed to fetch call token')
  }

  const tokenData = await tokenResponse.json()
  if (!tokenData.token) {
    throw new Error('Call token missing from response')
  }

  return tokenData.token
}

export async function fetchCallPageData(
  callId: number,
): Promise<{ data: CallData; token: string | null }> {
  const response = await fetch(`/api/calls/${callId}`, {
    credentials: 'include',
  })

  if (!response.ok) {
    throw new Error('Call not found')
  }

  const data = await response.json()
  if (data.state === 'ACTIVE') {
    return {
      data,
      token: await fetchActiveCallToken(callId),
    }
  }

  return { data, token: null }
}

export async function acceptRingingCall(callId: number): Promise<string> {
  const response = await fetch(`/api/calls/${callId}/accept`, {
    method: 'POST',
    credentials: 'include',
  })

  if (!response.ok) {
    throw new Error('Failed to accept call')
  }

  const data = await response.json()
  return data.token || data.calleeToken
}

export default function CallPage() {
  const params = useParams()
  const router = useRouter()
  const searchParams = useSearchParams()
  const callId = Number(params.callId)

  const [callData, setCallData] = useState<CallData | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showIncomingModal, setShowIncomingModal] = useState(false)
  const [callerName, setCallerName] = useState('')

  // Handle state query param (for post-call result navigation)
  const stateParam = searchParams.get('state') as CallState | null

  // Fetch call data and token
  useEffect(() => {
    if (stateParam && terminalStates.includes(stateParam)) {
      // Terminal state from query param — skip API call, show result directly
      setIsLoading(false)
      return
    }

    async function fetchCallData() {
      try {
        const { data, token: activeToken } = await fetchCallPageData(callId)
        setCallData(data)

        if (data.state === 'RINGING') {
          // Show incoming modal for callee, ringing display for caller
          setShowIncomingModal(true)
          setCallerName(data.callerName || 'Unknown caller')
        } else if (data.state === 'ACTIVE') {
          setToken(activeToken)
        } else if (terminalStates.includes(data.state)) {
          // Terminal state from API
          setIsLoading(false)
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load call')
      } finally {
        setIsLoading(false)
      }
    }

    if (callId) {
      fetchCallData()
    }
  }, [callId, stateParam])

  const handleAccept = useCallback(async () => {
    if (!callId) return

    try {
      const acceptToken = await acceptRingingCall(callId)
      setToken(acceptToken)
      setShowIncomingModal(false)
      setCallData((prev) => (prev ? { ...prev, state: 'ACTIVE' } : null))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to accept call')
      setShowIncomingModal(false)
    }
  }, [callId])

  const handleReject = useCallback(async () => {
    if (!callId) return

    try {
      await fetch(`/api/calls/${callId}/reject`, {
        method: 'POST',
        credentials: 'include',
      })
    } catch (err) {
      console.error('Failed to reject call:', err)
    } finally {
      setShowIncomingModal(false)
      router.push('/calls')
    }
  }, [callId, router])

  const handleEnd = useCallback(() => {
    router.push(`/calls/${callId}?state=ended`)
  }, [callId, router])

  const handleHome = useCallback(() => {
    router.push('/calls')
  }, [router])

  const handleRetry = useCallback(() => {
    router.push('/calls')
  }, [router])

  // Loading state
  if (isLoading) {
    return (
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          backgroundColor: '#101010',
        }}
      >
        <div
          style={{
            width: 32,
            height: 32,
            border: '3px solid #16A34A',
            borderTopColor: 'transparent',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
          }}
          aria-hidden="true"
        />
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div style={{ minHeight: '100vh', backgroundColor: '#FFFFFF' }}>
        <CallResult
          state="failed"
          onRetry={handleRetry}
          onHome={handleHome}
        />
      </div>
    )
  }

  // Terminal state from query param
  if (stateParam && terminalStates.includes(stateParam)) {
    const resultState = stateToResultMap[stateParam] ?? 'ended'
    return (
      <div style={{ minHeight: '100vh', backgroundColor: '#FFFFFF' }}>
        <CallResult
          state={resultState}
          onRetry={resultState === 'failed' ? handleRetry : undefined}
          onHome={handleHome}
          onSaveTranscript={resultState === 'ended' ? () => {} : undefined}
        />
      </div>
    )
  }

  // Terminal state from API
  if (callData && terminalStates.includes(callData.state)) {
    const resultState = stateToResultMap[callData.state] ?? 'ended'
    return (
      <div style={{ minHeight: '100vh', backgroundColor: '#FFFFFF' }}>
        <CallResult
          state={resultState}
          onRetry={resultState === 'failed' ? handleRetry : undefined}
          onHome={handleHome}
          onSaveTranscript={resultState === 'ended' ? () => {} : undefined}
        />
      </div>
    )
  }

  // Active call — render LiveKit canvas
  if (callData?.state === 'ACTIVE' && token) {
    return (
      <div style={{ height: '100vh', width: '100vw' }}>
        <ActiveCallCanvas
          token={token}
          roomName={callData.roomName || ''}
          callId={callId}
          serverUrl={process.env.NEXT_PUBLIC_LIVEKIT_URL || ''}
          onEnd={handleEnd}
        />
      </div>
    )
  }

  // Ringing state — show incoming modal or outgoing ringing
  if (callData?.state === 'RINGING' || showIncomingModal) {
    return (
      <div
        style={{
          minHeight: '100vh',
          backgroundColor: '#FFFFFF',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 24,
        }}
      >
        {/* Outgoing ringing display */}
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            backgroundColor: '#16A34A',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 24,
          }}
        >
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
          </svg>
        </div>
        <h2
          style={{
            fontSize: 28,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#101010',
            margin: '0 0 8px',
          }}
        >
          {callData?.calleeName || 'Contact'}
        </h2>
        <p
          style={{
            fontSize: 16,
            fontWeight: 400,
            lineHeight: 1.5,
            color: '#6B7280',
            margin: '0 0 32px',
          }}
        >
          Ringing...
        </p>
        <button
          type="button"
          onClick={() => {
            router.push('/calls')
          }}
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
          }}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M10.68 13.31a16 16 0 0 0 3.41 2.6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7 2 2 0 0 1 1.72 2v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.42 19.42 0 0 1-3.33-2.67m-2.67-3.34a19.79 19.79 0 0 1-3.07-8.63A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91" />
            <line x1="23" y1="1" x2="1" y2="23" />
          </svg>
          Cancel
        </button>

        {/* Incoming call modal for callee */}
        <IncomingCallModal
          callerName={callerName}
          callId={callId}
          onAccept={handleAccept}
          onReject={handleReject}
          isOpen={showIncomingModal}
        />
      </div>
    )
  }

  // Connecting state
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        backgroundColor: '#101010',
      }}
    >
      <div
        style={{
          width: 32,
          height: 32,
          border: '3px solid #16A34A',
          borderTopColor: 'transparent',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite',
        }}
        aria-hidden="true"
      />
    </div>
  )
}
