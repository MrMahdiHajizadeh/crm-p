<script>
  import { _ } from '$lib/i18n';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import {
    Activity,
    Eye,
    Plus,
    Pencil,
    Trash2,
    MessageSquare,
    User,
    Filter,
    ChevronLeft,
    ChevronRight,
    Target,
    Building2,
    Users,
    Sparkles,
    Briefcase,
    CheckSquare,
    FileText,
    RefreshCw,
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';
  import * as Select from '$lib/components/ui/select/index.js';
  import { formatRelativeDate } from '$lib/utils/formatting.js';

  /** @type {{ data: { activities: any[], totalCount: number, offset: number, limit: number } }} */
  let { data } = $props();

  let activities = $derived(data.activities || []);
  let totalCount = $derived(data.totalCount || 0);
  let currentOffset = $derived(data.offset || 0);
  let limit = $derived(data.limit || 50);

  // Filters
  let filterEntityType = $state('');
  let filterAction = $state('');
  let filterUserId = $state('');
  let filterDateFrom = $state('');
  let filterDateTo = $state('');

  const entityTypes = [
    { value: '', label: $_('supervision.all_types') },
    { value: 'Lead', label: 'Lead' },
    { value: 'Contact', label: 'Contact' },
    { value: 'Account', label: 'Account' },
    { value: 'Opportunity', label: 'Opportunity' },
    { value: 'Case', label: 'Case' },
    { value: 'Task', label: 'Task' },
    { value: 'Invoice', label: 'Invoice' },
  ];

  const actionTypes = [
    { value: '', label: $_('supervision.all_actions') },
    { value: 'CREATE', label: $_('supervision.action_create') },
    { value: 'UPDATE', label: $_('supervision.action_update') },
    { value: 'DELETE', label: $_('supervision.action_delete') },
  ];

  const entityIcons = {
    Lead: Target,
    Contact: User,
    Account: Building2,
    Opportunity: Sparkles,
    Case: Briefcase,
    Task: CheckSquare,
    Invoice: FileText,
  };

  const actionIcons = {
    CREATE: Plus,
    UPDATE: Pencil,
    DELETE: Trash2,
    VIEW: Eye,
    COMMENT: MessageSquare,
  };

  const actionColors = {
    CREATE: 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400',
    UPDATE: 'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400',
    DELETE: 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400',
    VIEW: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300',
    COMMENT: 'bg-violet-100 text-violet-700 dark:bg-violet-900/20 dark:text-violet-400',
  };

  // Entity type display names
  const entityDisplayNames = {
    Lead: $_('supervision.entity_lead'),
    Contact: $_('supervision.entity_contact'),
    Account: $_('supervision.entity_account'),
    Opportunity: $_('supervision.entity_opportunity'),
    Case: $_('supervision.entity_case'),
    Task: $_('supervision.entity_task'),
    Invoice: $_('supervision.entity_invoice'),
  };

  // Action display names
  const actionDisplayNames = {
    CREATE: $_('supervision.action_create'),
    UPDATE: $_('supervision.action_update'),
    DELETE: $_('supervision.action_delete'),
    VIEW: $_('supervision.action_view'),
    COMMENT: $_('supervision.action_comment'),
  };

  function getEntityUrl(entityType, entityId) {
    const map = {
      Lead: 'leads',
      Contact: 'contacts',
      Account: 'accounts',
      Opportunity: 'opportunities',
      Case: 'tickets',
      Task: 'tasks',
      Invoice: 'invoices',
    };
    const prefix = map[entityType] || (entityType ? entityType.toLowerCase() : '');
    return prefix ? `/${prefix}/${entityId}` : '#';
  }

  function applyFilters() {
    const params = new URLSearchParams();
    if (filterEntityType) params.set('entity_type', filterEntityType);
    if (filterAction) params.set('action', filterAction);
    if (filterUserId) params.set('user_id', filterUserId);
    if (filterDateFrom) params.set('date_from', filterDateFrom);
    if (filterDateTo) params.set('date_to', filterDateTo);
    params.set('offset', '0');
    params.set('limit', String(limit));
    goto(`/supervision?${params.toString()}`);
  }

  function goToPage(newOffset) {
    if (newOffset < 0) newOffset = 0;
    const params = new URLSearchParams($page.url.searchParams);
    params.set('offset', String(newOffset));
    params.set('limit', String(limit));
    goto(`/supervision?${params.toString()}`);
  }

  const totalPages = $derived(Math.max(1, Math.ceil(totalCount / limit)));
  const currentPage = $derived(Math.floor(currentOffset / limit) + 1);

  // Load filter state from URL on mount
  onMount(() => {
    const params = $page.url.searchParams;
    filterEntityType = params.get('entity_type') || '';
    filterAction = params.get('action') || '';
    filterUserId = params.get('user_id') || '';
    filterDateFrom = params.get('date_from') || '';
    filterDateTo = params.get('date_to') || '';
  });

  function resetFilters() {
    filterEntityType = '';
    filterAction = '';
    filterUserId = '';
    filterDateFrom = '';
    filterDateTo = '';
    goto('/supervision');
  }

  // Fix for input[type="date"] not responding to clicks in RTL Chromium
  let dateInputsFixed = $state(false);
  $effect(() => {
    if (dateInputsFixed || typeof window === 'undefined') return;
    const timer = setTimeout(() => {
      document.querySelectorAll('.date-input-rtl-fix').forEach((el) => {
        el.addEventListener('click', (e) => {
          if (!e.isTrusted) return;
          try { el.showPicker?.(); } catch { el.focus(); }
        });
      });
      dateInputsFixed = true;
    }, 100);
    return () => clearTimeout(timer);
  });
</script>

<svelte:head>
  <title>{$_('supervision.title')} · BottleCRM</title>
</svelte:head>

<PageHeader
  title={$_('supervision.title')}
  subtitle={$_('supervision.subtitle')}
  breadcrumb={[{ label: $_('supervision.title') }]}
/>

<div class="px-7 pb-8 md:px-8">
  <!-- Filters -->
  <div class="mb-6 flex flex-wrap items-end gap-3 rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-4">
    <div class="flex flex-col gap-1.5">
      <label for="filter-entity" class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('supervision.filter_entity')}</label>
      <Select.Root type="single" bind:value={filterEntityType}>
        <Select.Trigger id="filter-entity" class="w-36 text-[12px]">
          {entityTypes.find((o) => o.value === filterEntityType)?.label || $_('supervision.all_types')}
        </Select.Trigger>
        <Select.Content>
          {#each entityTypes as et}
            <Select.Item value={et.value}>{et.label}</Select.Item>
          {/each}
        </Select.Content>
      </Select.Root>
    </div>
    <div class="flex flex-col gap-1.5">
      <label for="filter-action" class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('supervision.filter_action')}</label>
      <Select.Root type="single" bind:value={filterAction}>
        <Select.Trigger id="filter-action" class="w-32 text-[12px]">
          {actionTypes.find((o) => o.value === filterAction)?.label || $_('supervision.all_actions')}
        </Select.Trigger>
        <Select.Content>
          {#each actionTypes as at}
            <Select.Item value={at.value}>{at.label}</Select.Item>
          {/each}
        </Select.Content>
      </Select.Root>
    </div>
    <div class="flex flex-col gap-1.5">
      <label for="filter-date-from" class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('supervision.filter_from')}</label>
      <div class="relative">
        <Input id="filter-date-from" type="date" bind:value={filterDateFrom} class="w-36 text-[12px] date-input-rtl-fix" />
      </div>
    </div>
    <div class="flex flex-col gap-1.5">
      <label for="filter-date-to" class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('supervision.filter_to')}</label>
      <div class="relative">
        <Input id="filter-date-to" type="date" bind:value={filterDateTo} class="w-36 text-[12px] date-input-rtl-fix" />
      </div>
    </div>
    <Button variant="default" size="sm" onclick={applyFilters} class="text-[12px]">
      <Filter class="mr-1.5 size-3.5" />
      {$_('supervision.apply_filters')}
    </Button>
    <Button variant="ghost" size="sm" onclick={resetFilters} class="text-[12px]">
      {$_('supervision.reset_filters')}
    </Button>
  </div>

  <!-- Activity count -->
  <div class="mb-4 text-[12px] text-[var(--text-subtle)]">
    {$_('supervision.showing', { count: activities.length, total: totalCount })}
  </div>

  <!-- Activity list -->
  {#if activities.length === 0}
    <div class="flex flex-col items-center justify-center py-20 text-center">
      <Activity class="mb-4 size-12 text-[var(--text-subtle)]" />
      <h3 class="text-[15px] font-medium text-[var(--text)]">{$_('supervision.empty_title')}</h3>
      <p class="mt-1 text-[13px] text-[var(--text-subtle)]">{$_('supervision.empty_desc')}</p>
    </div>
  {:else}
    <!-- Loading overlay -->
    {#if data.activities === undefined}
      <div class="flex items-center justify-center py-16">
        <RefreshCw class="size-6 animate-spin text-[var(--text-subtle)]" />
      </div>
    {/if}
    <div class="overflow-hidden rounded-xl border border-[var(--border-faint)]">
      <table class="w-full text-[12px]">
        <thead>
          <tr class="border-b border-[var(--border-faint)] bg-[var(--bg-elevated)]">
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_user')}</th>
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_action')}</th>
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_entity')}</th>
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_name')}</th>
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_description')}</th>
            <th class="px-4 py-3 text-start font-medium text-[var(--text-subtle)]">{$_('supervision.col_time')}</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-[var(--border-faint)]">
          {#each activities as act (act.id)}
            <tr class="hover:bg-[var(--bg-elevated)]/50 transition-colors">
              <td class="px-4 py-3">
                <div class="flex items-center gap-2">
                  <div class="flex size-7 items-center justify-center rounded-full bg-[var(--color-primary-light)] text-[10px] font-medium text-[var(--color-primary-default)]">
                    {(act.user?.user_details?.name || act.user?.user_details?.email || '?')[0]?.toUpperCase() || '?'}
                  </div>
                  <span class="truncate text-[var(--text)]">
                    {act.user?.user_details?.name || act.user?.user_details?.email || 'System'}
                  </span>
                </div>
              </td>
              <td class="px-4 py-3">
                <Badge variant="secondary" class={actionColors[act.action] || 'bg-gray-100 text-gray-700'}>
                  {#if actionIcons[act.action]}
                    {@const Icon = actionIcons[act.action]}
                    <Icon class="mr-1 size-3" />
                  {:else}
                    <Activity class="mr-1 size-3" />
                  {/if}
                  {actionDisplayNames[act.action] || act.action}
                </Badge>
              </td>
              <td class="px-4 py-3">
                <div class="flex items-center gap-1.5 text-[var(--text-muted)]">
                  {#if entityIcons[act.entity_type]}
                    {@const Icon = entityIcons[act.entity_type]}
                    <Icon class="size-3.5" />
                  {:else}
                    <Activity class="size-3.5" />
                  {/if}
                  {entityDisplayNames[act.entity_type] || act.entity_type}
                </div>
              </td>
              <td class="px-4 py-3">
                {#if act.entity_name}
                  <a
                    href={getEntityUrl(act.entity_type, act.entity_id)}
                    class="text-[var(--color-primary-default)] hover:underline"
                  >
                    {act.entity_name}
                  </a>
                {:else}
                  <span class="text-[var(--text-subtle)]">—</span>
                {/if}
              </td>
              <td class="max-w-[200px] truncate px-4 py-3 text-[var(--text-muted)]">
                {act.description || '—'}
              </td>
              <td class="px-4 py-3 text-start text-[var(--text-subtle)] tabular-nums">
                {act.created_at ? formatRelativeDate(act.created_at) : '—'}
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    {#if totalPages > 1}
      <div class="mt-4 flex items-center justify-between text-[12px]">
        <span class="text-[var(--text-subtle)]">
          {$_('supervision.page_info', { page: currentPage, total: totalPages })}
        </span>
        <div class="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            disabled={currentOffset <= 0}
            onclick={() => goToPage(currentOffset - limit)}
            class="text-[11px]"
          >
            <ChevronRight class="mr-1 size-3" />
            {$_('supervision.previous')}
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={currentOffset + limit >= totalCount}
            onclick={() => goToPage(currentOffset + limit)}
            class="text-[11px]"
          >
            {$_('supervision.next')}
            <ChevronLeft class="ml-1 size-3" />
          </Button>
        </div>
      </div>
    {/if}
  {/if}
</div>

<style>
  /* Fix date inputs in RTL mode */
  :global(.date-input-rtl-fix) {
    direction: ltr !important;
    text-align: start !important;
  }
  :global(.date-input-rtl-fix::-webkit-calendar-picker-indicator) {
    cursor: pointer;
    opacity: 0.6;
  }
  :global(.date-input-rtl-fix::-webkit-calendar-picker-indicator:hover) {
    opacity: 1;
  }
</style>
