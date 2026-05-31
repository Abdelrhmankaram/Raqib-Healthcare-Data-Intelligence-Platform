'use client';

import { useState } from 'react';
import axios from 'axios';
import PipelineSidebar from '@/components/PipelineSidebar';
import FileUpload from '@/components/FileUpload';
import ChatWindow from '@/components/ChatWindow';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3001';
const MAX_FILE_SIZE_MB = 10;

type Message = {
  role: 'user' | 'assistant';
  content: string;
};

type UploadTone = 'info' | 'success' | 'error';

type UploadState = {
  tone: UploadTone;
  message: string;
};

function extractErrorMessage(error: unknown, fallback: string) {
  if (axios.isAxiosError(error)) {
    const payload = error.response?.data;

    if (payload && typeof payload === 'object') {
      if ('error' in payload && typeof payload.error === 'string') {
        return payload.error;
      }

      if ('message' in payload && typeof payload.message === 'string') {
        return payload.message;
      }
    }

    return error.message || fallback;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return fallback;
}

export default function Home() {
  const [file, setFile] = useState<File | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [isChatting, setIsChatting] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [chunks, setChunks] = useState<string[]>([]);
  const [isDocumentReady, setIsDocumentReady] = useState(false);
  const [uploadState, setUploadState] = useState<UploadState>({
    tone: 'info',
    message: 'Drop a plain text file here or browse to prepare it for indexing.',
  });

  const handleFileSelect = (nextFile: File) => {
    const isTextFile = /\.txt$/i.test(nextFile.name) || nextFile.type === 'text/plain' || nextFile.type === '';

    if (!isTextFile) {
      setFile(null);
      setIsDocumentReady(false);
      setMessages([]);
      setChunks([]);
      setCurrentStep(0);
      setUploadState({
        tone: 'error',
        message: 'The current backend parser accepts .txt files only. Please choose a plain text document.',
      });
      return;
    }

    if (nextFile.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
      setFile(null);
      setIsDocumentReady(false);
      setMessages([]);
      setChunks([]);
      setCurrentStep(0);
      setUploadState({
        tone: 'error',
        message: `Please keep the file under ${MAX_FILE_SIZE_MB} MB.`,
      });
      return;
    }

    setFile(nextFile);
    setMessages([]);
    setChunks([]);
    setIsDocumentReady(false);
    setCurrentStep(0);
    setUploadState({
      tone: 'info',
      message: `${nextFile.name} is selected. Upload it to build the retrieval index.`,
    });
  };

  const clearSelection = () => {
    setFile(null);
    setMessages([]);
    setChunks([]);
    setIsDocumentReady(false);
    setCurrentStep(0);
    setUploadState({
      tone: 'info',
      message: 'Pick another document whenever you are ready.',
    });
  };

  const handleUpload = async () => {
    if (!file) {
      setUploadState({
        tone: 'error',
        message: 'Choose a file first so the upload can start.',
      });
      return;
    }

    const selectedFile = file;
    const formData = new FormData();
    formData.append('file', selectedFile);

    setIsUploading(true);
    setCurrentStep(0);
    setUploadState({
      tone: 'info',
      message: `Uploading ${selectedFile.name} and preparing embeddings...`,
    });

    try {
      await axios.post(`${API_BASE_URL}/upload`, formData);
      setIsDocumentReady(true);
      setCurrentStep(3);
      setUploadState({
        tone: 'success',
        message: `${selectedFile.name} is indexed and ready for questions.`,
      });
    } catch (error) {
      setIsDocumentReady(false);
      setCurrentStep(0);
      setUploadState({
        tone: 'error',
        message: extractErrorMessage(
          error,
          'Upload failed. Make sure the backend and ChromaDB are running, then try again.',
        ),
      });
    } finally {
      setIsUploading(false);
    }
  };

  const handleChat = async (question: string) => {
    if (!isDocumentReady) {
      return;
    }

    setMessages((prev) => [...prev, { role: 'user', content: question }]);
    setIsChatting(true);
    setCurrentStep(3);

    try {
      const response = await axios.post(`${API_BASE_URL}/chat`, { question });
      const answer =
        typeof response.data?.answer === 'string'
          ? response.data.answer
          : 'The assistant did not return an answer.';
      const retrievedChunks = Array.isArray(response.data?.chunks)
        ? response.data.chunks.filter((chunk: unknown): chunk is string => typeof chunk === 'string')
        : [];

      setMessages((prev) => [...prev, { role: 'assistant', content: answer }]);
      setChunks(retrievedChunks);
      setCurrentStep(4);
    } catch (error) {
      setMessages((prev) => [
        ...prev,
        {
          role: 'assistant',
          content: extractErrorMessage(
            error,
            'The assistant could not answer right now. Please verify the backend services and retry.',
          ),
        },
      ]);
    } finally {
      setIsChatting(false);
    }
  };

  const clearChat = () => {
    setMessages([]);
    setChunks([]);
    setCurrentStep(isDocumentReady ? 3 : 0);
  };

  const statusLabel = isDocumentReady ? 'Ready to chat' : file ? 'Awaiting upload' : 'No document yet';
  const isBusy = isUploading || isChatting;

  return (
    <div className="min-h-screen px-4 py-6 md:px-6 lg:px-10">
      <div className="mx-auto flex max-w-7xl flex-col gap-6 xl:flex-row">
        <PipelineSidebar
          currentStep={currentStep}
          fileName={file?.name ?? null}
          documentReady={isDocumentReady}
          messageCount={messages.length}
        />

        <main className="flex-1 space-y-6">
          <section className="glass-panel rounded-[32px] p-6 md:p-8">
            <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
              <div className="max-w-3xl">
                <span className="eyebrow">RAG Studio</span>
                <h1 className="mt-4 max-w-2xl text-4xl font-semibold leading-tight md:text-5xl">
                  Upload a document, index it once, then keep the conversation grounded.
                </h1>
                <p className="mt-4 max-w-2xl text-base text-[var(--text-secondary)] md:text-lg">
                  The refresh issue is handled by explicit form submission guards and browser drop prevention, so the
                  upload flow stays in-app instead of letting the browser take over the file.
                </p>
              </div>

              <div className="grid gap-3 sm:grid-cols-2">
                <div className="soft-card min-w-[180px]">
                  <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">Status</p>
                  <p className="mt-3 text-2xl font-semibold">{statusLabel}</p>
                  <p className="mt-2 text-sm text-[var(--text-secondary)]">{uploadState.message}</p>
                </div>
                <div className="soft-card min-w-[180px]">
                  <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">Backend</p>
                  <p className="mt-3 text-2xl font-semibold">Port 3001</p>
                  <p className="mt-2 text-sm text-[var(--text-secondary)] break-all">{API_BASE_URL}</p>
                </div>
              </div>
            </div>
          </section>

          <div className="grid gap-6 2xl:grid-cols-[1.02fr,1.24fr]">
            <FileUpload
              file={file}
              onFileSelect={handleFileSelect}
              onClearSelection={clearSelection}
              onUpload={handleUpload}
              loading={isUploading}
              busy={isBusy}
              status={uploadState}
              documentReady={isDocumentReady}
            />

            <ChatWindow
              messages={messages}
              onSend={handleChat}
              loading={isChatting}
              busy={isBusy}
              onClear={clearChat}
              chunks={chunks}
              documentReady={isDocumentReady}
            />
          </div>
        </main>
      </div>
    </div>
  );
}
