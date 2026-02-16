/**
 * Custom Error Classes for Event Sync Worker
 * Purpose: Structured error handling with specific error types
 */

export class BlockchainConnectionError extends Error {
  constructor(message: string, public readonly cause?: Error) {
    super(message);
    this.name = 'BlockchainConnectionError';
  }
}

export class ValidationError extends Error {
  constructor(message: string, public readonly field?: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class DatabaseWriteError extends Error {
  constructor(message: string, public readonly cause?: Error) {
    super(message);
    this.name = 'DatabaseWriteError';
  }
}

export class EventProcessingError extends Error {
  constructor(message: string, public readonly eventName: string, public readonly cause?: Error) {
    super(message);
    this.name = 'EventProcessingError';
  }
}
