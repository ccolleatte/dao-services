/**
 * Supabase Type Helpers
 *
 * Temporary helpers to resolve TypeScript errors until proper types are generated.
 * See: backend/TODO-SUPABASE-TYPES.md
 */

import type { SupabaseClient } from '@supabase/supabase-js';

export type TypedSupabaseClient = SupabaseClient<any>;

/**
 * Type-safe wrapper for Supabase select queries
 * Returns data with proper typing (not 'never')
 */
export async function typedSelect<T = any>(
  client: TypedSupabaseClient,
  table: string,
  select: string = '*'
): Promise<{ data: T[] | null; error: any }> {
  return await client.from(table).select(select) as any;
}

/**
 * Type-safe wrapper for Supabase select().single()
 * Returns single row with proper typing
 */
export async function typedSelectSingle<T = any>(
  query: any
): Promise<{ data: T | null; error: any }> {
  const result = await query;
  return result as { data: T | null; error: any };
}

/**
 * Type-safe wrapper for Supabase update
 */
export async function typedUpdate(
  query: any,
  data: Record<string, any>
): Promise<{ data: any; error: any }> {
  return await query.update(data) as any;
}

/**
 * Type-safe wrapper for Supabase insert
 */
export async function typedInsert(
  query: any,
  data: Record<string, any> | Record<string, any>[]
): Promise<{ data: any; error: any }> {
  return await query.insert(data) as any;
}
