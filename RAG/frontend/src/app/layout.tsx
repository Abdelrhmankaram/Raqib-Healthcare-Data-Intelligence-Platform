import type { Metadata } from 'next';
import { DM_Sans, Space_Grotesk } from 'next/font/google';
import type { ReactNode } from 'react';
import './globals.css';

const bodyFont = DM_Sans({
  subsets: ['latin'],
  variable: '--font-body',
});

const displayFont = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-display',
});

export const metadata: Metadata = {
  title: 'RAG Studio',
  description: 'Upload, index, and chat with your documents inside a polished RAG workflow UI.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${bodyFont.variable} ${displayFont.variable}`}>{children}</body>
    </html>
  );
}
