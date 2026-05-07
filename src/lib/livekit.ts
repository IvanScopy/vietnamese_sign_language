import { AccessToken } from 'livekit-server-sdk'

export interface LiveKitTokenParams {
  roomName: string
  participantName: string
  userId: number
}

export function generateLiveKitToken(params: LiveKitTokenParams): string {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    {
      identity: `user-${params.userId}-${params.participantName}`,
      name: params.participantName,
    }
  )

  token.addGrant({
    roomJoin: true,
    room: params.roomName,
    canPublish: true,
    canSubscribe: true,
  })

  return token.toJwt()
}

export function generateLiveKitRoomToken(roomName: string): string {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    { identity: 'server' }
  )

  token.addGrant({
    roomAdmin: true,
    room: roomName,
  })

  return token.toJwt()
}
