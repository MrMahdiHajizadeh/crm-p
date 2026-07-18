<script>
  import { AlertCircle, RefreshCw } from '@lucide/svelte';

  /** @type {{ message?: string, onRetry?: () => void }} */
  let { message = '', onRetry } = $props();

  const errorMessage = $derived(message || 'خطایی رخ داد. لطفاً دوباره تلاش کنید.');
</script>

<div
  class="flex flex-col items-center justify-center gap-4 rounded-[var(--radius-xl)] border border-[var(--color-negative-default)]/20 bg-[var(--color-negative-light)] p-8 text-center dark:border-[var(--color-negative-default)]/30 dark:bg-[var(--color-negative-default)]/10"
>
  <div
    class="flex size-12 items-center justify-center rounded-full bg-[var(--color-negative-light)] dark:bg-[var(--color-negative-default)]/20"
  >
    <AlertCircle class="size-6 text-[var(--color-negative-default)]" />
  </div>
  <div>
    <p class="text-sm font-medium text-[var(--color-negative-default)]">
      {errorMessage}
    </p>
  </div>
  {#if onRetry}
    <button
      onclick={onRetry}
      class="inline-flex items-center gap-2 rounded-[var(--radius-md)] bg-[var(--color-negative-default)] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[var(--color-negative-hover)]"
    >
      <RefreshCw size={14} />
      تلاش مجدد
    </button>
  {/if}
</div>
