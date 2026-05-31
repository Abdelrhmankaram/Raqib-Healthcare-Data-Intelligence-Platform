'use client';

import { useEffect, useRef, useState, type FormEvent } from 'react';

interface Props {
  messages: { role: 'user' | 'assistant'; content: string }[];
  onSend: (question: string) => void;
  loading: boolean;
  busy: boolean;
  onClear: () => void;
  chunks: string[];
  documentReady: boolean;
}

export default function ChatWindow({ messages, onSend, loading, busy, onClear, chunks, documentReady }: Props) {
  const [question, setQuestion] = useState('');
  const messagesRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesRef.current?.scrollTo({
      top: messagesRef.current.scrollHeight,
      behavior: 'smooth',
    });
  }, [messages, loading]);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    const trimmedQuestion = question.trim();
    if (!trimmedQuestion || !documentReady || busy) {
      return;
    }

    onSend(trimmedQuestion);
    setQuestion('');
  };

  return (
    <section className="glass-panel rounded-[32px] p-6 md:p-7">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <span className="eyebrow">Grounded Chat</span>
          <h2 className="mt-4 text-2xl font-semibold">Ask questions against the indexed document</h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-[var(--text-secondary)] md:text-base">
            The chat stays disabled until the document finishes indexing, so users cannot send a request before the
            retrieval context is ready.
          </p>
        </div>

        <div className="pill shrink-0">{documentReady ? 'Context ready' : 'Upload required'}</div>
      </div>

      {chunks.length > 0 && (
        <div className="mt-6 grid gap-3 md:grid-cols-3">
          {chunks.map((chunk, index) => (
            <div key={`${index}-${chunk.slice(0, 12)}`} className="soft-card">
              <p className="text-xs uppercase tracking-[0.22em] text-[var(--text-secondary)]">Retrieved chunk {index + 1}</p>
              <p className="mt-3 text-sm leading-6 text-[var(--text-primary)]">{chunk.slice(0, 180)}...</p>
            </div>
          ))}
        </div>
      )}

      <div className="mt-6 overflow-hidden rounded-[28px] border border-[rgba(16,54,59,0.12)] bg-[rgba(255,255,255,0.46)]">
        <div ref={messagesRef} className="message-scroll h-[420px] space-y-4 overflow-y-auto p-4 md:p-6">
          {messages.length === 0 && !loading && (
            <div className="flex h-full flex-col items-center justify-center text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[rgba(78,183,167,0.14)] text-2xl text-[var(--accent-secondary)]">
                Q
              </div>
              <h3 className="mt-4 text-xl font-semibold">No conversation yet</h3>
              <p className="mt-2 max-w-md text-sm leading-6 text-[var(--text-secondary)]">
                Upload a document first, then ask for summaries, definitions, or answers grounded in the indexed text.
              </p>
            </div>
          )}

          {messages.map((msg, index) => (
            <div key={`${msg.role}-${index}`} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div
                className={`max-w-[88%] rounded-[24px] px-4 py-3 text-sm leading-6 md:text-[0.95rem] ${
                  msg.role === 'user'
                    ? 'bg-[linear-gradient(135deg,var(--accent-secondary),#78d2c3)] text-white shadow-[0_18px_30px_rgba(78,183,167,0.24)]'
                    : 'border border-[rgba(16,54,59,0.12)] bg-white/80 text-[var(--text-primary)]'
                }`}
              >
                {msg.content}
              </div>
            </div>
          ))}

          {loading && (
            <div className="flex justify-start">
              <div className="rounded-[24px] border border-[rgba(16,54,59,0.12)] bg-white/80 px-4 py-3 text-sm text-[var(--text-secondary)]">
                Thinking through the retrieved context...
              </div>
            </div>
          )}
        </div>
      </div>

      <form className="mt-5 grid gap-3 md:grid-cols-[1fr_auto_auto]" onSubmit={handleSubmit}>
        <input
          type="text"
          value={question}
          onChange={(event) => setQuestion(event.target.value)}
          className="min-h-[54px] rounded-full border border-[rgba(16,54,59,0.14)] bg-white/80 px-5 text-sm text-[var(--text-primary)] outline-none transition placeholder:text-[var(--text-secondary)] focus:border-[var(--accent-secondary)] focus:bg-white disabled:cursor-not-allowed disabled:opacity-60"
          placeholder={documentReady ? 'Ask a question about the uploaded document...' : 'Upload a document to start chatting'}
          disabled={!documentReady || busy}
        />
        <button
          type="submit"
          disabled={!documentReady || busy || !question.trim()}
          className="inline-flex min-h-[54px] items-center justify-center rounded-full bg-[linear-gradient(135deg,var(--accent-secondary),#78d2c3)] px-6 text-sm font-semibold text-white shadow-[0_16px_30px_rgba(78,183,167,0.28)] transition hover:-translate-y-0.5 hover:shadow-[0_20px_34px_rgba(78,183,167,0.32)] disabled:cursor-not-allowed disabled:opacity-60 disabled:shadow-none"
        >
          Send
        </button>
        <button
          type="button"
          onClick={onClear}
          disabled={busy || (messages.length === 0 && chunks.length === 0)}
          className="inline-flex min-h-[54px] items-center justify-center rounded-full border border-[rgba(16,54,59,0.14)] px-6 text-sm font-medium text-[var(--text-primary)] transition hover:bg-white/80 disabled:cursor-not-allowed disabled:opacity-60"
        >
          Clear chat
        </button>
      </form>
    </section>
  );
}
