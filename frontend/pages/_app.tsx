/**
 * Next.js App Component
 * Global configuration and providers
 */

import '../styles/globals.css';
import type { AppProps } from 'next/app';
import { useEffect, useState } from 'react';

export default function App({ Component, pageProps }: AppProps) {
  const [mounted, setMounted] = useState(false);

  // Prevent hydration mismatch for dark mode
  useEffect(() => {
    setMounted(true);

    // Initialize dark mode from localStorage or system preference
    const isDark =
      localStorage.theme === 'dark' ||
      (!('theme' in localStorage) &&
        window.matchMedia('(prefers-color-scheme: dark)').matches);

    if (isDark) {
      document.documentElement.classList.add('dark');
    }
  }, []);

  if (!mounted) {
    return null;
  }

  return (
    <div className="min-h-screen">
      <Component {...pageProps} />
    </div>
  );
}
