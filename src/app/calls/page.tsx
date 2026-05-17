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

interface ProfileResponse {
  user?: {
    id: number
    userType?: string
  }
  id?: number
  userType?: string
}

export default function CallsPage() {
  const router = useRouter()
  const socketRef = useRef<Socket | null>(null)
  const [incomingCall, setIncomingCall] = useState<IncomingCallEvent | null>(null)
  const [callerName, setCallerName] = useState<string>('')
  const [users, setUsers] = useState<Array<{ id: number; name: string }>>([])
  const [isLoading, setIsLoading] = useState(true)
  const [currentUser, setCurrentUser] = useState<{ id: number; userType: string } | null>(null)

  // Fetch available users for call initiation
  useEffect(() => {
    async function fetchPageData() {
      try {
        const [profileResponse, usersResponse] = await Promise.all([
          fetch('/api/user/profile', { credentials: 'include' }),
          fetch('/api/users', { credentials: 'include' }),
        ])

        if (profileResponse.ok) {
          const profile = (await profileResponse.json()) as ProfileResponse
          const user = profile.user ?? profile
          if (typeof user.id === 'number') {
            setCurrentUser({
              id: user.id,
              userType: user.userType || 'HEARING',
            })
          }
        }

        if (usersResponse.ok) {
          const data = await usersResponse.json()
          setUsers(data.users || [])
        }
      } catch {
        setUsers([])
      } finally {
        setIsLoading(false)
      }
    }
    fetchPageData()
  }, [])

  // Set up Socket.io connection for incoming call events
  useEffect(() => {
    const socket = io(process.env.NEXT_PUBLIC_CLIENT_URL || '/', {
      withCredentials: true,
      transports: ['websocket', 'polling'],
    })
    socketRef.current = socket

    socket.on('connect', () => {
      if (currentUser) {
        socket.emit('register', currentUser.id, currentUser.userType)
      }
    })

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
  }, [currentUser])

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
