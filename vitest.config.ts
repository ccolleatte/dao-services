import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['backend/**/*.ts'],
      exclude: [
        'backend/**/*.test.ts',
        'backend/**/*.spec.ts',
        'node_modules',
        'backend/supabase/**' // Exclude Supabase migrations/config
      ],
      // Gate 1 thresholds
      lines: 70,
      functions: 70,
      branches: 60,
      statements: 70
    },
    include: ['backend/**/*.test.ts', 'backend/**/*.spec.ts'],
    testTimeout: 10000
  }
})
