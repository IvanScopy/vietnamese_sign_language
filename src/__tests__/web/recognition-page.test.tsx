import { beforeEach, describe, expect, jest, test } from '@jest/globals'

type MediaTrack = {
  stop: jest.Mock
}

type RecognitionModule = {
  default: () => unknown
  startCamera: () => Promise<MediaStream>
  stopCamera: (stream: MediaStream | null) => void
  getCameraUnavailableMessage: () => string
  getCameraDeniedMessage: () => string
}

const loadRecognitionPage = (): RecognitionModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require('@/app/recognition/page') as RecognitionModule

const ensureNavigator = () => {
  if (!global.navigator) {
    Object.defineProperty(global, 'navigator', {
      configurable: true,
      value: {},
    })
  }
}

const installMediaDevices = (getUserMedia: jest.Mock) => {
  ensureNavigator()
  Object.defineProperty(global.navigator, 'mediaDevices', {
    configurable: true,
    value: { getUserMedia },
  })
}

describe('web recognition camera contract', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('exposes explicit Start camera and Stop camera controls', () => {
    const page = loadRecognitionPage()
    const rendered = JSON.stringify(page.default())

    expect(rendered).toContain('Start camera')
    expect(rendered).toContain('Stop camera')
  })

  test('shows unsupported browser copy when navigator.mediaDevices is unavailable', () => {
    ensureNavigator()
    Object.defineProperty(global.navigator, 'mediaDevices', {
      configurable: true,
      value: undefined,
    })

    const page = loadRecognitionPage()

    expect(page.getCameraUnavailableMessage()).toBe(
      'Camera requires HTTPS, localhost, and a supported browser.',
    )
  })

  test('shows denied-permission copy when getUserMedia rejects', async () => {
    const denied = new DOMException('Permission denied', 'NotAllowedError')
    installMediaDevices(jest.fn().mockRejectedValue(denied))

    const page = loadRecognitionPage()

    await expect(page.startCamera()).rejects.toThrow('Permission denied')
    expect(page.getCameraDeniedMessage()).toBe(
      'Camera permission was denied. Allow camera access in your browser settings and try again.',
    )
  })

  test('requests webcam video through navigator.mediaDevices.getUserMedia', async () => {
    const stream = { getTracks: () => [] } as unknown as MediaStream
    const getUserMedia = jest.fn().mockResolvedValue(stream)
    installMediaDevices(getUserMedia)

    const page = loadRecognitionPage()
    await expect(page.startCamera()).resolves.toBe(stream)

    expect(getUserMedia).toHaveBeenCalledWith({ video: true, audio: false })
  })

  test('Stop camera cleans up every active media track', () => {
    const tracks: MediaTrack[] = [{ stop: jest.fn() }, { stop: jest.fn() }]
    const stream = {
      getTracks: () => tracks,
    } as unknown as MediaStream

    const page = loadRecognitionPage()
    page.stopCamera(stream)

    for (const track of tracks) {
      expect(track.stop).toHaveBeenCalledTimes(1)
    }
  })
})
