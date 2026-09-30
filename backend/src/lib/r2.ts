// src/lib/r2.ts
//
// Cloudflare R2 helper — uses the AWS SDK v3 S3-compatible interface.
// R2 credentials are optional in dev; if they are missing, all upload
// functions throw a clear error instead of crashing at startup.
//
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const {
  R2_ACCOUNT_ID,
  R2_ACCESS_KEY_ID,
  R2_SECRET_ACCESS_KEY,
  R2_BUCKET_NAME,
  R2_PUBLIC_URL,
} = process.env;

/** True when all R2 env vars are present. */
export const r2Enabled =
  Boolean(R2_ACCOUNT_ID) &&
  Boolean(R2_ACCESS_KEY_ID) &&
  Boolean(R2_SECRET_ACCESS_KEY) &&
  Boolean(R2_BUCKET_NAME);

let _client: S3Client | null = null;

function getClient(): S3Client {
  if (!r2Enabled) {
    throw new Error(
      'R2 is not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, and R2_BUCKET_NAME in .env',
    );
  }
  if (!_client) {
    _client = new S3Client({
      region: 'auto',
      endpoint: `https://${R2_ACCOUNT_ID!}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID!,
        secretAccessKey: R2_SECRET_ACCESS_KEY!,
      },
    });
  }
  return _client;
}

/**
 * Generate a pre-signed PUT URL so the client can upload directly to R2.
 *
 * @param key       - R2 object key, e.g. `vendors/uuid/pan_card.pdf`
 * @param mimeType  - Content-Type the client will send with the PUT
 * @param ttlSeconds - URL lifetime (default 15 min)
 * @returns Pre-signed URL string
 */
export async function generatePresignedUploadUrl(
  key: string,
  mimeType: string,
  ttlSeconds = 900,
): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: R2_BUCKET_NAME!,
    Key: key,
    ContentType: mimeType,
  });
  return getSignedUrl(getClient(), command, { expiresIn: ttlSeconds });
}

/**
 * Generate a pre-signed GET URL for private-bucket objects.
 * If R2_PUBLIC_URL is set, returns the public CDN URL instead.
 *
 * @param key - R2 object key
 * @param ttlSeconds - URL lifetime for private buckets (default 1 hour)
 */
export async function generatePresignedDownloadUrl(
  key: string,
  ttlSeconds = 3600,
): Promise<string> {
  if (R2_PUBLIC_URL) {
    return `${R2_PUBLIC_URL.replace(/\/$/, '')}/${key}`;
  }
  const command = new GetObjectCommand({
    Bucket: R2_BUCKET_NAME!,
    Key: key,
  });
  return getSignedUrl(getClient(), command, { expiresIn: ttlSeconds });
}

/**
 * Build a public URL for a key — only valid when the bucket has public access
 * and R2_PUBLIC_URL is configured.
 */
export function getPublicUrl(key: string): string {
  if (!R2_PUBLIC_URL) {
    throw new Error('R2_PUBLIC_URL is not configured. Cannot build a public URL.');
  }
  return `${R2_PUBLIC_URL.replace(/\/$/, '')}/${key}`;
}
