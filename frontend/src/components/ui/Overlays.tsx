import { useEffect, useId, useRef, type ReactNode } from 'react';
import { X } from 'lucide-react';

function useDismissable(open: boolean, onClose: () => void) {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const previouslyFocused = document.activeElement as HTMLElement | null;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.stopPropagation();
        onClose();
        return;
      }
      if (event.key !== 'Tab' || !containerRef.current) return;

      const focusables = containerRef.current.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])',
      );
      if (focusables.length === 0) return;
      const first = focusables[0];
      const last = focusables[focusables.length - 1];

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };

    document.addEventListener('keydown', onKeyDown);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const timer = window.setTimeout(() => {
      const target = containerRef.current?.querySelector<HTMLElement>(
        '[data-autofocus], button, input, textarea',
      );
      target?.focus();
    }, 20);

    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.body.style.overflow = overflow;
      window.clearTimeout(timer);
      previouslyFocused?.focus?.();
    };
  }, [open, onClose]);

  return containerRef;
}

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
  width?: string;
}

export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  width = 'max-w-lg',
}: ModalProps) {
  const containerRef = useDismissable(open, onClose);
  const titleId = useId();

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div
        className="absolute inset-0 bg-navy-deep/45 animate-fadeIn"
        onClick={onClose}
        aria-hidden="true"
      />
      <div
        ref={containerRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className={`relative w-full ${width} bg-surface border border-hairline rounded-t-xl sm:rounded-card
          shadow-raised animate-scaleIn max-h-[92vh] flex flex-col`}
      >
        <header className="flex items-start justify-between gap-4 px-5 py-4 border-b border-hairline">
          <div>
            <h2 id={titleId} className="text-md font-semibold text-navy">
              {title}
            </h2>
            {description && <p className="text-xs text-muted mt-0.5">{description}</p>}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close dialog"
            className="text-muted hover:text-navy transition-colors duration-150 -mr-1 -mt-1 p-1 rounded"
          >
            <X size={18} />
          </button>
        </header>
        <div className="overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <footer className="flex items-center justify-end gap-2 px-5 py-3.5 border-t border-hairline bg-canvas/60 rounded-b-card">
            {footer}
          </footer>
        )}
      </div>
    </div>
  );
}

interface SlideOverProps {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
}

export function SlideOver({
  open,
  onClose,
  title,
  description,
  children,
  footer,
}: SlideOverProps) {
  const containerRef = useDismissable(open, onClose);
  const titleId = useId();

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div
        className="absolute inset-0 bg-navy-deep/40 animate-fadeIn"
        onClick={onClose}
        aria-hidden="true"
      />
      <aside
        ref={containerRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative h-full w-full sm:w-[440px] bg-surface border-l border-hairline
          shadow-panel animate-slideInRight flex flex-col"
      >
        <header className="flex items-start justify-between gap-4 px-5 py-4 border-b border-hairline">
          <div>
            <h2 id={titleId} className="text-md font-semibold text-navy">
              {title}
            </h2>
            {description && <p className="text-xs text-muted mt-0.5">{description}</p>}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close panel"
            className="text-muted hover:text-navy transition-colors duration-150 -mr-1 -mt-1 p-1 rounded"
          >
            <X size={18} />
          </button>
        </header>
        <div className="flex-1 overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <footer className="px-5 py-3.5 border-t border-hairline bg-canvas/60">{footer}</footer>
        )}
      </aside>
    </div>
  );
}
