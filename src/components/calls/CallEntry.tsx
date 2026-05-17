'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import IncomingCallModal from '@/components/calls/IncomingCallModal'

export interface CallEntryProps {
  users?: Array<{ id: number; name: string }>
  onCallInitiated?: (calleeId: number) => void
}

export default function CallEntry({ users = [], onCallInitiated }: CallEntryProps) {
  const router = useRouter()
  const [isInitiating, setIsInitiating] = useState(false)
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handleStartCall = async () => {
    if (!selectedUserId) return

    setIsInitiating(true)
    setError(null)

    try {
      const response = await fetch('/api/calls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ calleeId: selectedUserId }),
        credentials: 'include',
      })

      if (!response.ok) {
        const data = await response.json().catch(() => ({}))
        throw new Error(data.error || 'Failed to start call')
      }

      const data = await response.json()
      onCallInitiated?.(selectedUserId)
      router.push(`/calls/${data.callId}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to start call')
    } finally {
      setIsInitiating(false)
    }
  }

  if (users.length === 0) {
    return (
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100%',
          padding: 24,
          textAlign: 'center',
        }}
      >
        <h1
          style={{
            fontSize: 20,
            fontWeight: 600,
            lineHeight: 1.2,
            color: '#101010',
            margin: '0 0 8px',
          }}
        >
          No active call
        </h1>
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
          Choose a registered contact to start a 1:1 video call.
        </p>
      </div>
    )
  }

  return (
    <div
      style={{
        padding: 24,
        maxWidth: 600,
        margin: '0 auto',
      }}
    >
      <h1
        style={{
          fontSize: 28,
          fontWeight: 600,
          lineHeight: 1.2,
          color: '#101010',
          margin: '0 0 24px',
        }}
      >
        Start video call
      </h1>

      {/* User selection */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 8,
          marginBottom: 24,
        }}
      >
        {users.map((user) => (
          <button
            key={user.id}
            type="button"
            onClick={() => setSelectedUserId(user.id)}
            aria-pressed={selectedUserId === user.id}
            style={{
              height: 48,
              padding: '0 16px',
              borderRadius: 8,
              border: selectedUserId === user.id ? '2px solid #16A34A' : '1px solid #E5E7EB',
              backgroundColor: selectedUserId === user.id ? '#16A34A1A' : '#FFFFFF',
              color: '#101010',
              fontSize: 16,
              fontWeight: 400,
              lineHeight: 1.5,
              cursor: 'pointer',
              textAlign: 'left',
              transition: 'border-color 0.15s ease, background-color 0.15s ease',
            }}
          >
            {user.name}
          </button>
        ))}
      </div>

      {/* Error message */}
      {error && (
        <p
          role="alert"
          style={{
            fontSize: 14,
            fontWeight: 600,
            lineHeight: 1.3,
            color: '#DC2626',
            margin: '0 0 16px',
          }}
        >
          {error}
        </p>
      )}

      {/* Start call button */}
      <button
        type="button"
        onClick={handleStartCall}
        disabled={!selectedUserId || isInitiating}
        style={{
          height: 48,
          padding: '0 32px',
          borderRadius: 24,
          border: 'none',
          backgroundColor: !selectedUserId || isInitiating ? '#6B7280' : '#16A34A',
          color: '#FFFFFF',
          fontSize: 14,
          fontWeight: 600,
          lineHeight: 1.3,
          cursor: !selectedUserId || isInitiating ? 'not-allowed' : 'pointer',
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 8,
          transition: 'background-color 0.15s ease',
        }}
      >
        {isInitiating ? (
          <>
            <div
              style={{
                width: 16,
                height: 16,
                border: '2px solid #FFFFFF',
                borderTopColor: 'transparent',
                borderRadius: '50%',
                animation: 'spin 1s linear infinite',
              }}
              aria-hidden="true"
            />
            Starting call...
          </>
        ) : (
          <>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polygon points="23 7 16 12 23 17 23 7" />
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
            </svg>
            Start video call
          </>
        )}
      </button>
    </div>
  )
}
