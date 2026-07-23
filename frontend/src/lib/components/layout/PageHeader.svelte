<script>
  import { ChevronRight } from '@lucide/svelte';

  /**
   * @typedef {Object} BreadcrumbItem
   * @property {string} label
   * @property {string} [href]
   */

  /**
   * @typedef {Object} Props
   * @property {string} title
   * @property {string} [subtitle]
   * @property {'page' | 'display'} [size]
   * @property {string} [eyebrow]
   * @property {BreadcrumbItem[]} [breadcrumb]
   * @property {import('svelte').Snippet} [titleIcon]
   * @property {import('svelte').Snippet} [meta]
   * @property {import('svelte').Snippet} [amount]
   * @property {import('svelte').Snippet} [actions]
   * @property {import('svelte').Snippet} [tabs]
   */

  /** @type {Props} */
  let {
    title,
    subtitle = '',
    size = 'page',
    eyebrow = '',
    breadcrumb = [],
    titleIcon,
    meta,
    amount,
    actions,
    tabs,
  } = $props();
</script>

<header
  class="sticky top-0 z-10 flex flex-col gap-3 bg-[color:var(--bg)] px-4 pt-3 sm:px-7 sm:pt-6 md:px-8 {tabs ? 'pb-0' : 'pb-4'}"
>
  {#if breadcrumb.length > 0}
    <nav
      aria-label="Breadcrumb"
      class="flex flex-wrap items-center gap-1 text-[13px] leading-none text-[color:var(--text-subtle)]"
    >
      {#each breadcrumb as crumb, i (i)}
        {#if i > 0}
          <ChevronRight class="size-[14px] shrink-0 stroke-[1.6]" aria-hidden="true" />
        {/if}
        {#if crumb.href && i < breadcrumb.length - 1}
          <a
            href={crumb.href}
            class="rounded-sm transition-colors hover:text-[color:var(--text-muted)] focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-[color:var(--ring)]"
          >{crumb.label}</a>
        {:else}
          <span class={i === breadcrumb.length - 1 ? 'text-[color:var(--text-muted)]' : ''}>{crumb.label}</span>
        {/if}
      {/each}
    </nav>
  {/if}

  <div class="flex min-h-[44px] flex-col sm:flex-row sm:items-start justify-between gap-3">
    <div class="flex min-w-0 flex-1 items-start gap-3">
      {#if titleIcon}
        <div class="flex size-7 shrink-0 items-center justify-center rounded-[var(--r-md)] bg-[color:var(--bg-elevated)] text-[color:var(--text-muted)]">
          {@render titleIcon()}
        </div>
      {/if}
      <div class="flex min-w-0 flex-1 flex-col gap-1">
        {#if eyebrow}
          <p class="label-tiny">{eyebrow}</p>
        {/if}
        <h1 class="{size === 'display' ? 'h-display' : 'h-page'} truncate text-lg sm:text-xl md:text-2xl">{title}</h1>
        {#if subtitle}
          <p class="t-body-sm truncate">{subtitle}</p>
        {/if}
      </div>
    </div>
    {#if amount || actions}
      <div class="flex w-full sm:w-auto shrink-0 flex-wrap items-center gap-2 justify-start sm:justify-end">
        {#if amount}
          <div class="flex flex-col items-start sm:items-end gap-0.5">
            {@render amount()}
          </div>
        {/if}
        {#if actions}
          <div class="flex flex-wrap items-center gap-2 w-full sm:w-auto">
            {@render actions()}
          </div>
        {/if}
      </div>
    {/if}
  </div>

  {#if meta}
    <div class="flex flex-wrap items-center gap-2 text-[color:var(--text-muted)]">
      {@render meta()}
    </div>
  {/if}

  {#if tabs}
    <div class="-mx-4 mt-1 overflow-x-auto border-t border-[color:var(--border-faint)] px-4 sm:-mx-7 sm:px-7 md:-mx-8 md:px-8">
      {@render tabs()}
    </div>
  {/if}
</header>
