'use client'

import React, { useEffect, useState, useRef } from 'react'
import { io, type Socket } from 'socket.io-client'
import CallEntry from '@/components/calls/CallEntry'
import IncomingCallModal from '@/components/calls/IncomingCallModal'
import { useRouter } from 'next/navigation'

interface IncomingCallEvent {
  callId: number
  fromUserId: number
  fromUserName?: string
  expiresAt: string
  type: 'VIDEO_CALL'
}

export default function CallsPage() {
  const router = useRouter()
  const socketRef = useRef<Socket | null>(null)
  const [incomingCall, setIncomingCall] = useState<IncomingCallEvent | null>(null)
  const [callerName, setCallerName] = useState<string>('')
  const [users, setUsers] = useState<Array<{ id: number; name: string }>>([])
  const [isLoading, setIsLoading] = useState(true)

  // Fetch available users for call initiation
  useEffect(() => {
    async function fetchUsers() {
      try {
        const response = await fetch('/api/users', { credentials: 'include' })
        if (response.ok) {
          const data = await response.json()
          setUsers(data.users || [])
        }
      } catch {
        // Users endpoint may not exist yet — show empty state
        setUsers([])
      } finally {
        setIsLoading(false)
      }
    }
    fetchUsers()
  }, [])

  // Set up Socket.io connection for incoming call events
  useEffect(() => {
    const socket = io(process.env.NEXT_PUBLIC_CLIENT_URL || '/', {
      withCredentials: true,
      transports: ['websocket', 'polling'],
    })
    socketRef.current = socket

    // Register with socket server once authenticated user ID is available
    // For now, listen for incoming call events
    socket.on('call:incoming', (data: IncomingCallEvent) => {
      setIncomingCall(data)
      setCallerName(data.fromUserName || 'Unknown caller')
    })

    socket.on('call:cancelled', () => {
      setIncomingCall(null)
    })

    socket.on('call:missed', () => {
      setIncomingCall(null)
    })

    return () => {
      socket.disconnect()
    }
  }, [])

  const handleAccept = async () => {
    if (!incomingCall) return

    try {
      const response = await fetch(`/api/calls/${incomingCall.callId}/accept`, {
        method: 'POST',
        credentials: 'include',
      })

      if (!response.ok) {
        throw new Error('Failed to accept call')
      }

      // Navigate to the active call page
      router.push(`/calls/${incomingCall.callId}`)
    } catch (err) {
      console.error('Failed to accept call:', err)
    }
  }

  const handleReject = async () => {
    if (!incomingCall) return

    try {
      await fetch(`/api/calls/${incomingCall.callId}/reject`, {
        method: 'POST',
        credentials: 'include',
      })
    } catch (err) {
      console.error('Failed to reject call:', err)
    } finally {
      setIncomingCall(null)
    }
  }

  if (isLoading) {
    return (
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100%',
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

  return (
    <div style={{ minHeight: '100%', backgroundColor: '#FFFFFF' }}>
      <CallEntry
        users={users}
        onCallInitiated={() => {
          // Call initiated — navigation handled in CallEntry
        }}
      />

      {/* Incoming call modal */}
      <IncomingCallModal
        callerName={callerName}
        callId={incomingCall?.callId ?? 0}
        onAccept={handleAccept}
        onReject={handleReject}
        isOpen={incomingCall !== null}
      />
    </div>
  )
}
