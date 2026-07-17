<script>
  import * as Sidebar from '$lib/components/ui/sidebar/index.js';
  import { PanelLeft } from '@lucide/svelte';

  const sidebar = Sidebar.useSidebar();
</script>

<button
  onclick={() => sidebar.setOpenMobile(true)}
  class="fixed start-3 top-3 z-50 flex size-9 items-center justify-center rounded-lg border border-[var(--border-default)] bg-[var(--surface-default)] shadow-sm transition-colors hover:bg-[var(--surface-sunken)] md:hidden"
  aria-label="Open sidebar"
>
  <PanelLeft class="size-5 text-[var(--text-secondary)]" strokeWidth={1.6} />
</button>
