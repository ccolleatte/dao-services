/**
 * Retry Logic for Blockchain Calls
 * Purpose: Exponential backoff retry for transient blockchain errors
 */

import { logger } from './logger.js';
import { BlockchainConnectionError } from './errors.js';

interface RetryOptions {
  maxRetries?: number;
  initialDelayMs?: number;
  maxDelayMs?: number;
  backoffFactor?: number;
}

const DEFAULT_OPTIONS: Required<RetryOptions> = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffFactor: 2,
};

/**
 * Sleep helper
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retry function with exponential backoff
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  context: string,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  let lastError: Error | undefined;

  for (let attempt = 0; attempt < opts.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      const isLastAttempt = attempt === opts.maxRetries - 1;
      if (isLastAttempt) {
        logger.error(
          { error, context, attempts: opts.maxRetries },
          'All retry attempts failed'
        );
        break;
      }

      const delayMs = Math.min(
        opts.initialDelayMs * Math.pow(opts.backoffFactor, attempt),
        opts.maxDelayMs
      );

      logger.warn(
        { error: (error as Error).message, context, attempt: attempt + 1, delayMs },
        'Retrying after error'
      );

      await sleep(delayMs);
    }
  }

  throw new BlockchainConnectionError(
    `${context} failed after ${opts.maxRetries} attempts`,
    lastError
  );
}
