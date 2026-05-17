import { AccessToken } from 'livekit-server-sdk'

export interface LiveKitTokenParams {
  roomName: string
  participantName: string
  userId: number
}

export async function generateLiveKitToken(params: LiveKitTokenParams): Promise<string> {
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

  return await token.toJwt()
}

export async function generateLiveKitRoomToken(roomName: string): Promise<string> {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    { identity: 'server' }
  )

  token.addGrant({
    roomAdmin: true,
    room: roomName,
  })

  return await token.toJwt()
}
