<script>
  import { Inbox } from '@lucide/svelte';

  /** @type {{ message?: string, title?: string }} */
  let { message = 'نتیجه‌ای یافت نشد', title = '' } = $props();
</script>

<div
  class="flex flex-col items-center justify-center gap-3 rounded-[var(--radius-xl)] border border-[var(--border-faint)] bg-[var(--surface-raised)] p-12 text-center"
>
  <div
    class="flex size-14 items-center justify-center rounded-full bg-[var(--surface-sunken)]"
  >
    <Inbox class="size-7 text-[var(--text-subtle)]" />
  </div>
  {#if title}
    <h3 class="text-sm font-medium text-[var(--text)]">{title}</h3>
  {/if}
  <p class="text-sm text-[var(--text-muted)]">{message}</p>
</div>
