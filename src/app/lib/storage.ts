import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3'
import { getSignedUrl } from '@aws-sdk/s3-request-presigner'

type StorageConfig = {
  endpoint: string
  region: string
  bucket: string
  accessKeyId: string
  secretAccessKey: string
  forcePathStyle: boolean
  cdnBaseUrl: string | null
}

function requireEnv(name: string): string {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Missing required storage configuration: ${name}`)
  }
  return value
}

export function getStorageConfig(): StorageConfig {
  return {
    endpoint: requireEnv('S3_ENDPOINT'),
    region: requireEnv('S3_REGION'),
    bucket: requireEnv('S3_BUCKET'),
    accessKeyId: requireEnv('S3_ACCESS_KEY_ID'),
    secretAccessKey: requireEnv('S3_SECRET_ACCESS_KEY'),
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true',
    cdnBaseUrl: process.env.DICTIONARY_CDN_BASE_URL ?? null,
  }
}

function createClient(config: StorageConfig) {
  return new S3Client({
    endpoint: config.endpoint,
    region: config.region,
    forcePathStyle: config.forcePathStyle,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
  })
}

export function buildDictionaryAssetUrl(key: string): string {
  const { cdnBaseUrl, bucket, endpoint } = getStorageConfig()
  if (cdnBaseUrl) {
    return `${cdnBaseUrl.replace(/\/$/, '')}/${key.replace(/^\//, '')}`
  }

  return `${endpoint.replace(/\/$/, '')}/${bucket}/${key.replace(/^\//, '')}`
}

export async function createDictionaryUploadUrl(key: string, contentType: string) {
  if (!['video/mp4', 'image/jpeg', 'image/png', 'image/webp'].includes(contentType)) {
    throw new Error(`Unsupported dictionary upload content type: ${contentType}`)
  }

  const config = getStorageConfig()
  const client = createClient(config)
  const command = new PutObjectCommand({
    Bucket: config.bucket,
    Key: key,
    ContentType: contentType,
  })

  const uploadUrl = await getSignedUrl(client, command, { expiresIn: 900 })

  return {
    uploadUrl,
    key,
    publicUrl: buildDictionaryAssetUrl(key),
  }
}
