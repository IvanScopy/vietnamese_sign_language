/**
 * Shared TypeScript definitions for recognition results and vocabulary.
 *
 * These types define the contract between the recognition service and
 * clients for sign recognition outputs.
 */

/**
 * Single recognized sign result from the classifier.
 */
export interface RecognitionResult {
  /** The recognized Vietnamese sign (e.g., 'xin_chào', 'cảm_ơn') */
  sign: string;
  /** Confidence score from the model (0.0 to 1.0) */
  confidence: number;
}

/**
 * Phrase completion event - sent when a phrase boundary is detected.
 */
export interface PhraseComplete {
  /** The complete recognized text (concatenated signs) */
  text: string;
  /** Individual sign results that make up the phrase */
  signs: RecognitionResult[];
  /** Optional base64-encoded audio for TTS output */
  audio?: string;
}

/**
 * Sign vocabulary entry for model output mapping.
 */
export interface SignVocabulary {
  /** Unique identifier for the sign */
  id: string;
  /** Vietnamese text representation (snake_case) */
  text: string;
  /** Optional category for grouping (e.g., 'greetings', 'pronouns') */
  category?: string;
}

/**
 * Vocabulary collection format for loading/saving.
 */
export interface VocabularyCollection {
  /** Version string for vocabulary schema */
  version: string;
  /** Array of sign vocabulary entries */
  signs: SignVocabulary[];
}

/**
 * Recognition service health status.
 */
export interface HealthStatus {
  status: 'healthy' | 'unhealthy';
  modelLoaded: boolean;
  vocabularySize: number;
  uptime: number;
}
