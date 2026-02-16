/**
 * Input Validation for Event Sync Worker
 * Purpose: Validate blockchain addresses, event data, environment variables
 */

import { ethers } from 'ethers';
import { ValidationError } from './errors.js';

/**
 * Validate Ethereum address (EIP-55 compliant)
 */
export function validateAddress(address: string, fieldName: string = 'address'): void {
  if (!address) {
    throw new ValidationError(`${fieldName} is required`, fieldName);
  }

  if (!ethers.isAddress(address)) {
    throw new ValidationError(`${fieldName} is not a valid Ethereum address: ${address}`, fieldName);
  }
}

/**
 * Validate bigint is positive
 */
export function validatePositiveBigInt(value: bigint, fieldName: string = 'value'): void {
  if (value < 0n) {
    throw new ValidationError(`${fieldName} must be positive: ${value}`, fieldName);
  }
}

/**
 * Validate environment variables are defined
 */
export function validateEnvVars(requiredVars: string[]): void {
  const missing: string[] = [];

  for (const varName of requiredVars) {
    if (!process.env[varName]) {
      missing.push(varName);
    }
  }

  if (missing.length > 0) {
    throw new ValidationError(
      `Missing required environment variables: ${missing.join(', ')}`,
      'environment'
    );
  }
}

/**
 * Validate event log structure
 */
export function validateEventLog(event: any): void {
  if (!event) {
    throw new ValidationError('Event is null or undefined', 'event');
  }

  if (!event.transactionHash) {
    throw new ValidationError('Event missing transactionHash', 'transactionHash');
  }

  if (event.blockNumber === undefined || event.blockNumber === null) {
    throw new ValidationError('Event missing blockNumber', 'blockNumber');
  }
}
