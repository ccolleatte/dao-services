/**
 * Supabase Type Declarations
 *
 * Temporary type declarations to resolve TypeScript compilation errors.
 * See: backend/TODO-SUPABASE-TYPES.md for proper type generation instructions.
 */

declare module '@supabase/supabase-js' {
  export interface PostgrestQueryBuilder<Schema> {
    select(columns?: string): PostgrestFilterBuilder<Schema>;
    insert(data: any | any[], options?: any): PostgrestFilterBuilder<Schema>;
    update(data: any, options?: any): PostgrestFilterBuilder<Schema>;
    delete(options?: any): PostgrestFilterBuilder<Schema>;
  }

  export interface PostgrestFilterBuilder<Schema> {
    eq(column: string, value: any): this;
    neq(column: string, value: any): this;
    gt(column: string, value: any): this;
    gte(column: string, value: any): this;
    lt(column: string, value: any): this;
    lte(column: string, value: any): this;
    like(column: string, pattern: string): this;
    ilike(column: string, pattern: string): this;
    is(column: string, value: any): this;
    in(column: string, values: any[]): this;
    contains(column: string, value: any): this;
    containedBy(column: string, value: any): this;
    rangeGt(column: string, range: string): this;
    rangeGte(column: string, range: string): this;
    rangeLt(column: string, range: string): this;
    rangeLte(column: string, range: string): this;
    rangeAdjacent(column: string, range: string): this;
    overlaps(column: string, value: any): this;
    textSearch(column: string, query: string, options?: any): this;
    match(query: Record<string, any>): this;
    not(column: string, operator: string, value: any): this;
    or(filters: string, options?: any): this;
    filter(column: string, operator: string, value: any): this;
    order(column: string, options?: { ascending?: boolean; nullsFirst?: boolean }): this;
    limit(count: number, options?: { foreignTable?: string }): this;
    range(from: number, to: number, options?: { foreignTable?: string }): this;
    single(): Promise<{ data: any; error: any }>;
    maybeSingle(): Promise<{ data: any; error: any }>;
    csv(): Promise<{ data: any; error: any }>;
    then<TResult1 = { data: any; error: any }, TResult2 = never>(
      onfulfilled?: ((value: { data: any; error: any }) => TResult1 | PromiseLike<TResult1>) | null,
      onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | null
    ): Promise<TResult1 | TResult2>;
  }

  export interface SupabaseClient<Database = any> {
    from<TableName extends string>(
      table: TableName
    ): PostgrestQueryBuilder<Database>;
    auth: any;
    storage: any;
    functions: any;
    channel: any;
    removeChannel: any;
  }

  export function createClient<Database = any>(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any
  ): SupabaseClient<Database>;
}
