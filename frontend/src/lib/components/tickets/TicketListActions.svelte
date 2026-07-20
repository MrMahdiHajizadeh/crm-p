<script>
  import { _ } from '$lib/i18n';
  import { Plus, Eye, Filter, List, Columns, Upload } from '@lucide/svelte';
  import { Button } from '$lib/components/ui/button/index.js';
  import * as DropdownMenu from '$lib/components/ui/dropdown-menu/index.js';

  /** @type {{
   *   viewMode: 'list' | 'kanban',
   *   filtersExpanded: boolean,
   *   activeFiltersCount: number,
   *   columns: any[],
   *   visibleCount: number,
   *   totalCount: number,
   *   isColumnVisible: (key: string) => boolean,
   *   onViewMode: (m: 'list' | 'kanban') => void,
   *   onToggleFilters: () => void,
   *   onToggleColumn: (key: string) => void,
   *   onCreate: () => void,
   *   onImport?: () => void
   * }} */
  let {
    viewMode,
    filtersExpanded,
    activeFiltersCount,
    columns,
    visibleCount,
    totalCount,
    isColumnVisible,
    onViewMode,
    onToggleFilters,
    onToggleColumn,
    onCreate,
    onImport
  } = $props();
</script>

<div class="flex items-center gap-2">
  <div class="border-input bg-background inline-flex rounded-lg border p-1">
    <Button
      variant={viewMode === 'list' ? 'secondary' : 'ghost'}
      size="sm"
      onclick={() => onViewMode('list')}
      class="h-8 px-3"
    >
      <List class="me-1.5 h-4 w-4" />{$_('tickets.view_list')}
    </Button>
    <Button
      variant={viewMode === 'kanban' ? 'secondary' : 'ghost'}
      size="sm"
      onclick={() => onViewMode('kanban')}
      class="h-8 px-3"
    >
      <Columns class="me-1.5 h-4 w-4" />{$_('tickets.view_board')}
    </Button>
  </div>

  <Button
    variant={filtersExpanded ? 'secondary' : 'outline'}
    size="sm"
    class="gap-2"
    onclick={onToggleFilters}
  >
    <Filter class="h-4 w-4" />{$_('common.filter')}
    {#if activeFiltersCount > 0}
      <span
        class="rounded-full bg-[var(--color-primary-light)] px-1.5 py-0.5 text-xs font-medium text-[var(--color-primary-default)]"
      >
        {activeFiltersCount}
      </span>
    {/if}
  </Button>

  <DropdownMenu.Root>
    <DropdownMenu.Trigger>
      {#snippet child({ props })}
        <Button {...props} variant="outline" size="sm" class="gap-2">
          <Eye class="h-4 w-4" />{$_('tickets.columns')}
          {#if visibleCount < totalCount}
            <span
              class="rounded-full bg-[var(--color-primary-light)] px-1.5 py-0.5 text-xs font-medium text-[var(--color-primary-default)]"
            >
              {visibleCount}/{totalCount}
            </span>
          {/if}
        </Button>
      {/snippet}
    </DropdownMenu.Trigger>
    <DropdownMenu.Content align="end" class="w-48">
      <DropdownMenu.Label>{$_('tickets.toggle_columns')}</DropdownMenu.Label>
      <DropdownMenu.Separator />
      {#each columns as column (column.key)}
        <DropdownMenu.CheckboxItem
          class=""
          checked={isColumnVisible(column.key)}
          onCheckedChange={() => onToggleColumn(column.key)}
          disabled={column.canHide === false}
        >
          {column.label}
        </DropdownMenu.CheckboxItem>
      {/each}
    </DropdownMenu.Content>
  </DropdownMenu.Root>

  {#if onImport}
    <Button variant="outline" size="sm" class="gap-2" onclick={onImport}>
      <Upload class="h-4 w-4" />{$_('tickets.import_csv')}
    </Button>
  {/if}

  <Button onclick={onCreate}>
    <Plus class="me-2 h-4 w-4" />{$_('tickets.create')}
  </Button>
</div>
