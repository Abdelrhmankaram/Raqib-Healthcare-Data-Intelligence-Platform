'use client';

import { useEffect, useRef, useState, type ChangeEvent, type DragEvent, type FormEvent } from 'react';

interface Props {
  file: File | null;
  onFileSelect: (file: File) => void;
  onClearSelection: () => void;
  onUpload: () => void;
  loading: boolean;
  busy: boolean;
  status: {
    tone: 'info' | 'success' | 'error';
    message: string;
  };
  documentReady: boolean;
}

const toneClasses = {
  info: 'border-[rgba(16,54,59,0.12)] bg-[rgba(16,54,59,0.08)] text-[var(--text-primary)]',
  success: 'border-[rgba(28,143,104,0.18)] bg-[rgba(28,143,104,0.12)] text-[var(--success)]',
  error: 'border-[rgba(196,74,50,0.18)] bg-[rgba(196,74,50,0.12)] text-[var(--error)]',
};

export default function FileUpload({
  file,
  onFileSelect,
  onClearSelection,
  onUpload,
  loading,
  busy,
  status,
  documentReady,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragActive, setDragActive] = useState(false);

  useEffect(() => {
    const preventWindowDrop = (event: DragEvent) => {
      event.preventDefault();
    };

    window.addEventListener('dragover', preventWindowDrop);
    window.addEventListener('drop', preventWindowDrop);

    return () => {
      window.removeEventListener('dragover', preventWindowDrop);
      window.removeEventListener('drop', preventWindowDrop);
    };
  }, []);

  const submitUpload = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    onUpload();
  };

  const openPicker = () => {
    inputRef.current?.click();
  };

  const handleDrop = (event: DragEvent<HTMLButtonElement>) => {
    event.preventDefault();
    event.stopPropagation();
    setDragActive(false);

    const droppedFile = event.dataTransfer.files?.[0];
    if (droppedFile) {
      onFileSelect(droppedFile);
    }
  };

  const handleInputChange = (event: ChangeEvent<HTMLInputElement>) => {
    const chosenFile = event.target.files?.[0];
    if (chosenFile) {
      onFileSelect(chosenFile);
    }

    event.target.value = '';
  };

  return (
    <section className="glass-panel rounded-[32px] p-6 md:p-7">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <span className="eyebrow">Document Intake</span>
          <h2 className="mt-4 text-2xl font-semibold">Keep the upload flow on the page</h2>
          <p className="mt-3 max-w-xl text-sm leading-6 text-[var(--text-secondary)] md:text-base">
            Drag and drop is protected at the window level, and the upload action is wrapped in a guarded submit
            handler so the browser will not hijack the file and refresh the page.
          </p>
        </div>

        <div className="pill shrink-0">{documentReady ? 'Indexed' : file ? 'Ready to upload' : 'Waiting for file'}</div>
      </div>

      <form className="mt-6 space-y-4" onSubmit={submitUpload}>
        <button
          type="button"
          className={`group relative flex min-h-[260px] w-full flex-col items-center justify-center gap-4 overflow-hidden rounded-[28px] border-2 border-dashed px-6 py-10 text-center transition duration-300 ${
            dragActive
              ? 'border-[var(--accent)] bg-[rgba(255,122,89,0.12)]'
              : 'border-[rgba(16,54,59,0.16)] bg-[rgba(255,255,255,0.45)] hover:border-[var(--accent-secondary)] hover:bg-[rgba(78,183,167,0.08)]'
          }`}
          onClick={openPicker}
          onDragEnter={(event) => {
            event.preventDefault();
            event.stopPropagation();
            setDragActive(true);
          }}
          onDragOver={(event) => {
            event.preventDefault();
            event.stopPropagation();
            setDragActive(true);
          }}
          onDragLeave={(event) => {
            event.preventDefault();
            event.stopPropagation();
            setDragActive(false);
          }}
          onDrop={handleDrop}
        >
          <div className="absolute inset-x-8 top-6 h-px bg-[linear-gradient(90deg,transparent,rgba(16,54,59,0.16),transparent)]" />
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[linear-gradient(135deg,var(--accent),#ffb36a)] text-4xl text-white shadow-[0_18px_35px_rgba(255,122,89,0.28)]">
            T
          </div>
          <div className="space-y-2">
            <p className="text-xl font-semibold">Drop a text file here or browse your machine</p>
            <p className="mx-auto max-w-md text-sm leading-6 text-[var(--text-secondary)] md:text-base">
              This workspace is currently wired for plain text documents, which keeps the pipeline predictable while
              you test upload, chunking, embeddings, and chat end to end.
            </p>
          </div>
          <span className="pill bg-white/70">Supports `.txt` up to 10 MB</span>
        </button>

        <input
          ref={inputRef}
          type="file"
          accept=".txt,text/plain"
          className="hidden"
          onChange={handleInputChange}
        />

        {file && (
          <div className="soft-card flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">Selected file</p>
              <p className="mt-2 text-lg font-semibold">{file.name}</p>
              <p className="mt-1 text-sm text-[var(--text-secondary)]">
                {(file.size / 1024 / 1024).toFixed(2)} MB
                {documentReady ? ' | indexed successfully' : ' | ready for indexing'}
              </p>
            </div>

            <button
              type="button"
              className="inline-flex items-center justify-center rounded-full border border-[rgba(16,54,59,0.14)] px-4 py-2 text-sm font-medium text-[var(--text-primary)] transition hover:bg-white/80 disabled:cursor-not-allowed disabled:opacity-60"
              onClick={onClearSelection}
              disabled={busy}
            >
              Choose another file
            </button>
          </div>
        )}

        <div className={`rounded-[22px] border px-4 py-3 text-sm leading-6 ${toneClasses[status.tone]}`}>{status.message}</div>

        <div className="flex flex-col gap-3 sm:flex-row">
          <button
            type="submit"
            disabled={!file || busy}
            className="inline-flex items-center justify-center rounded-full bg-[linear-gradient(135deg,var(--accent),#ffb36a)] px-6 py-3 text-sm font-semibold text-white shadow-[0_16px_30px_rgba(255,122,89,0.26)] transition hover:-translate-y-0.5 hover:shadow-[0_20px_36px_rgba(255,122,89,0.3)] disabled:cursor-not-allowed disabled:opacity-60 disabled:shadow-none"
          >
            {loading ? 'Uploading...' : documentReady ? 'Re-index document' : 'Upload and index'}
          </button>

          <button
            type="button"
            className="inline-flex items-center justify-center rounded-full border border-[rgba(16,54,59,0.14)] px-6 py-3 text-sm font-medium text-[var(--text-primary)] transition hover:bg-white/80 disabled:cursor-not-allowed disabled:opacity-60"
            onClick={openPicker}
            disabled={busy}
          >
            Browse files
          </button>
        </div>
      </form>
    </section>
  );
}
