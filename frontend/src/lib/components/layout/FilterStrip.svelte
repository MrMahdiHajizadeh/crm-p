<script>
  /**
   * @type {{
   *   children?: import('svelte').Snippet,
   *   meta?: import('svelte').Snippet,
   *   class?: string,
   * }}
   */
  let { children, meta, class: className = '' } = $props();
</script>

<div class="flex flex-wrap items-center justify-between gap-2 border-b border-[color:var(--border-faint)] px-4 py-2.5 sm:px-7 md:px-8 {className}">
  <div class="flex flex-wrap items-center gap-2 w-full sm:w-auto">
    {@render children?.()}
  </div>
  {#if meta}
    <div class="ml-auto sm:ml-0 flex items-center gap-2 text-[13px] text-[color:var(--text-subtle)]">
      {@render meta()}
    </div>
  {/if}
</div>
