# TODO: Generate Supabase Types

## Problem
TypeScript compilation currently uses `any` types for Supabase client, resulting in no type safety for database operations.

## Solution
Generate proper TypeScript types from Supabase schema:

```bash
npx supabase login
npx supabase link --project-ref <your-project-ref>
npx supabase gen types typescript --local > supabase/database.types.ts
```

## Files to Update
- `backend/services/event-sync-worker.ts`: Replace `type Database = any` with proper import
- `backend/supabase/database.types.ts`: Replace with generated types

## Impact
- 🔴 **Type Safety**: Currently NO type checking on database operations
- 🟡 **Documentation**: Schema structure not self-documenting  
- 🟢 **Compilation**: All TypeScript errors resolved (Gate 1 ✅)

## Priority
- P2 - Medium (after MVP deployment)
- Required before: Production scale-up

## Estimated Effort
- 15-30 minutes (one-time setup)

Created: 2026-02-16
Status: PENDING
