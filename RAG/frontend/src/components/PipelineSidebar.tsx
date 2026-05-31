interface Props {
  currentStep: number;
  fileName: string | null;
  documentReady: boolean;
  messageCount: number;
}

const steps = [
  {
    title: 'Intake',
    description: 'Choose the source document and keep the browser from stealing the drop event.',
  },
  {
    title: 'Chunking',
    description: 'Break the text into smaller overlapping slices that can be embedded consistently.',
  },
  {
    title: 'Embeddings',
    description: 'Convert each slice to vectors so similarity search can find the right passages later.',
  },
  {
    title: 'Retrieval',
    description: 'Pull the highest-signal chunks whenever the user asks a question.',
  },
  {
    title: 'Answer',
    description: 'Generate a final response grounded in the retrieved context.',
  },
];

export default function PipelineSidebar({ currentStep, fileName, documentReady, messageCount }: Props) {
  return (
    <aside className="glass-panel rounded-[32px] p-6 xl:sticky xl:top-6 xl:h-fit xl:w-[320px] xl:min-w-[320px]">
      <span className="eyebrow">Pipeline View</span>
      <h2 className="mt-4 text-3xl font-semibold leading-tight">Track every stage of the document workflow.</h2>
      <p className="mt-3 text-sm leading-6 text-[var(--text-secondary)]">
        The sidebar mirrors the live state so it is easier to tell whether we are still indexing or already answering.
      </p>

      <div className="soft-card mt-6">
        <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">Loaded file</p>
        <p className="mt-3 text-lg font-semibold">{fileName ?? 'No file selected yet'}</p>
        <p className="mt-2 text-sm text-[var(--text-secondary)]">
          {documentReady ? 'Indexed and ready for retrieval.' : 'Waiting for a successful upload before chat unlocks.'}
        </p>
      </div>

      <ol className="mt-6 space-y-4">
        {steps.map((step, index) => {
          const isComplete = index < currentStep;
          const isActive = index === currentStep;

          return (
            <li
              key={step.title}
              className={`rounded-[24px] border px-4 py-4 transition ${
                isComplete
                  ? 'border-[rgba(28,143,104,0.14)] bg-[rgba(28,143,104,0.1)]'
                  : isActive
                    ? 'border-[rgba(255,122,89,0.18)] bg-[rgba(255,122,89,0.11)]'
                    : 'border-[rgba(16,54,59,0.12)] bg-white/55'
              }`}
            >
              <div className="flex gap-3">
                <div
                  className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-semibold ${
                    isComplete
                      ? 'bg-[var(--success)] text-white'
                      : isActive
                        ? 'bg-[var(--accent)] text-white'
                        : 'bg-[rgba(16,54,59,0.08)] text-[var(--text-secondary)]'
                  }`}
                >
                  {index + 1}
                </div>
                <div>
                  <p className="text-base font-semibold">{step.title}</p>
                  <p className="mt-2 text-sm leading-6 text-[var(--text-secondary)]">{step.description}</p>
                </div>
              </div>
            </li>
          );
        })}
      </ol>

      <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-1">
        <div className="soft-card">
          <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">Conversation</p>
          <p className="mt-3 text-2xl font-semibold">{messageCount}</p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">Messages in the current thread.</p>
        </div>
        <div className="soft-card">
          <p className="text-xs uppercase tracking-[0.24em] text-[var(--text-secondary)]">System state</p>
          <p className="mt-3 text-2xl font-semibold">{documentReady ? 'Live' : 'Standby'}</p>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            {documentReady ? 'Retrieval is ready for questions.' : 'Upload is required before answers can start.'}
          </p>
        </div>
      </div>
    </aside>
  );
}
