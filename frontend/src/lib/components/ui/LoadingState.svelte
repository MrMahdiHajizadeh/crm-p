<script>
  import { Loader2 } from '@lucide/svelte';

  /** @type {{ message?: string }} */
  let { message = '' } = $props();
</script>

<div
  class="flex flex-col items-center justify-center gap-3 rounded-[var(--radius-xl)] border border-[var(--border-faint)] bg-[var(--surface-raised)] p-12 text-center"
>
  <Loader2 class="size-8 animate-spin text-[var(--text-muted)]" />
  {#if message}
    <p class="text-sm text-[var(--text-muted)]">{message}</p>
  {/if}
</div>
