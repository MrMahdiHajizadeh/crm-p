<script>
  import { toasts } from './index.js';
  import { CheckCircle, XCircle, X } from '@lucide/svelte';

  const icons = {
    success: CheckCircle,
    error: XCircle,
    info: null
  };

  const bgClasses = {
    success: 'bg-green-600',
    error: 'bg-red-600',
    info: 'bg-blue-600'
  };

  let visibleToasts = $state([]);

  toasts.subscribe((t) => { visibleToasts = t; });
</script>

{#if visibleToasts.length > 0}
  <div class="fixed start-1/2 top-4 z-[9999] flex -translate-x-1/2 flex-col gap-2">
    {#each visibleToasts as t (t.id)}
      <div
        class="{bgClasses[t.type] || bgClasses.info} flex min-w-[280px] max-w-[420px] items-center gap-2 rounded-lg px-4 py-3 text-sm text-white shadow-lg"
      >
        {#if icons[t.type]}
          <svelte:component this={icons[t.type]} class="h-4 w-4 shrink-0" />
        {/if}
        <span class="flex-1">{t.message}</span>
        <button
          onclick={() => {
            const idx = visibleToasts.findIndex((x) => x.id === t.id);
            if (idx >= 0) {
              toasts.update((arr) => { arr.splice(idx, 1); return arr; });
            }
          }}
          class="ms-1 shrink-0 rounded p-0.5 opacity-70 hover:opacity-100"
        >
          <X class="h-3.5 w-3.5" />
        </button>
      </div>
    {/each}
  </div>
{/if}