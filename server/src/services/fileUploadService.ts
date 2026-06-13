/**
 * File Upload Service
 * Handles file uploads to Supabase Storage and generates signed URLs
 */

import { randomUUID } from 'crypto';
import { supabase } from '../db/client.js';

export interface FileMetadata {
  id: string;
  name: string;
  url: string;
  size: number;
  mime_type: string;
  storage_path: string;
  uploaded_at: string;
}

export interface UploadResponse {
  success: boolean;
  file?: FileMetadata;
  error?: string;
}

// File upload constraints
export const UPLOAD_CONFIG = {
  MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
  MAX_FILES_PER_ITEM: 4,
  MAX_TOTAL_SIZE_PER_ITEM: 200 * 1024 * 1024, // 200MB
  SIGNED_URL_EXPIRY: 7 * 24 * 60 * 60, // 7 days in seconds
  ALLOWED_MIME_TYPES: [
    // Images
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml',
    // Documents
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'text/csv',
    // Archives
    'application/zip',
    'application/x-rar-compressed',
    'application/x-7z-compressed',
  ],
  BUCKET_NAME: 'items-attachments',
};

/**
 * Validate file before upload
 */
export function validateFile(
  file: { size: number; type: string; name: string },
  existingFilesSize: number = 0
): { valid: boolean; error?: string } {
  // Check file size
  if (file.size > UPLOAD_CONFIG.MAX_FILE_SIZE) {
    return {
      valid: false,
      error: `File too large. Max size: ${UPLOAD_CONFIG.MAX_FILE_SIZE / 1024 / 1024}MB`,
    };
  }

  // Check MIME type
  if (!UPLOAD_CONFIG.ALLOWED_MIME_TYPES.includes(file.type)) {
    return {
      valid: false,
      error: `File type not allowed: ${file.type}`,
    };
  }

  // Check total size
  if (existingFilesSize + file.size > UPLOAD_CONFIG.MAX_TOTAL_SIZE_PER_ITEM) {
    return {
      valid: false,
      error: `Total file size would exceed limit. Max: ${UPLOAD_CONFIG.MAX_TOTAL_SIZE_PER_ITEM / 1024 / 1024}MB`,
    };
  }

  return { valid: true };
}

/**
 * Upload file to Supabase Storage
 * @param file - File to upload (from multipart form)
 * @param itemId - Associated item ID (for path organization)
 * @returns FileMetadata if successful, error otherwise
 */
export async function uploadFileToStorage(
  file: { content: Buffer; filename: string; type: string },
  itemId: string
): Promise<UploadResponse> {
  try {
    // Validate file
    const validation = validateFile(
      {
        size: file.content.length,
        type: file.type,
        name: file.filename,
      }
    );

    if (!validation.valid) {
      return {
        success: false,
        error: validation.error,
      };
    }

    // Generate unique file ID and storage path
    const fileId = randomUUID();
    const sanitizedFilename = file.filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `${itemId}/${fileId}/${sanitizedFilename}`;

    console.log(`[FileUpload] Uploading file: ${storagePath}`);

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from(UPLOAD_CONFIG.BUCKET_NAME)
      .upload(storagePath, file.content, {
        contentType: file.type,
        upsert: false,
      });

    if (error) {
      console.error(`[FileUpload] Upload error: ${error.message}`);
      return {
        success: false,
        error: `Upload failed: ${error.message}`,
      };
    }

    // Generate signed URL (valid for 7 days)
    const { data: urlData, error: urlError } = await supabase.storage
      .from(UPLOAD_CONFIG.BUCKET_NAME)
      .createSignedUrl(storagePath, UPLOAD_CONFIG.SIGNED_URL_EXPIRY);

    if (urlError) {
      console.error(`[FileUpload] Signed URL error: ${urlError.message}`);
      return {
        success: false,
        error: `Failed to generate download URL: ${urlError.message}`,
      };
    }

    const fileMetadata: FileMetadata = {
      id: fileId,
      name: file.filename,
      url: urlData.signedUrl,
      size: file.content.length,
      mime_type: file.type,
      storage_path: storagePath,
      uploaded_at: new Date().toISOString(),
    };

    console.log(`[FileUpload] Success: ${file.filename} (${file.content.length} bytes)`);

    return {
      success: true,
      file: fileMetadata,
    };
  } catch (err: any) {
    console.error(`[FileUpload] Exception: ${err.message}`);
    return {
      success: false,
      error: err.message,
    };
  }
}

/**
 * Delete file from Supabase Storage
 */
export async function deleteFileFromStorage(storagePath: string): Promise<boolean> {
  try {
    const { error } = await supabase.storage
      .from(UPLOAD_CONFIG.BUCKET_NAME)
      .remove([storagePath]);

    if (error) {
      console.error(`[FileUpload] Delete error: ${error.message}`);
      return false;
    }

    console.log(`[FileUpload] Deleted: ${storagePath}`);
    return true;
  } catch (err: any) {
    console.error(`[FileUpload] Delete exception: ${err.message}`);
    return false;
  }
}

/**
 * Generate or refresh signed URL for existing file
 */
export async function getSignedUrl(storagePath: string): Promise<string | null> {
  try {
    const { data, error } = await supabase.storage
      .from(UPLOAD_CONFIG.BUCKET_NAME)
      .createSignedUrl(storagePath, UPLOAD_CONFIG.SIGNED_URL_EXPIRY);

    if (error) {
      console.error(`[FileUpload] SignedURL error: ${error.message}`);
      return null;
    }

    return data.signedUrl;
  } catch (err: any) {
    console.error(`[FileUpload] SignedURL exception: ${err.message}`);
    return null;
  }
}
