<script>
  import { _ } from '$lib/i18n';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { onMount, onDestroy } from 'svelte';
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
    UserPlus,
    AlertTriangle,
    ArrowUp,
    GitMerge,
    Clock,
    CheckCircle,
    XCircle,
    ArrowRightLeft,
    Gavel,
    Calendar,
    File,
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';
  import * as Select from '$lib/components/ui/select/index.js';
  import { DateRangeFilter } from '$lib/components/ui/filter';
  import { formatRelativeDate, formatDate } from '$lib/utils/formatting.js';

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
    { value: 'Event', label: 'Event' },
    { value: 'Document', label: 'Document' },
    { value: 'Team', label: 'Team' },
  ];

  const actionTypes = [
    { value: '', label: $_('supervision.all_actions') },
    { value: 'CREATE', label: $_('supervision.action_create') },
    { value: 'UPDATE', label: $_('supervision.action_update') },
    { value: 'DELETE', label: $_('supervision.action_delete') },
    { value: 'ASSIGN', label: $_('supervision.action_assign') },
    { value: 'STATUS_CHANGED', label: $_('supervision.action_status_changed') },
    { value: 'PRIORITY_CHANGED', label: $_('supervision.action_priority_changed') },
    { value: 'APPROVED', label: $_('supervision.action_approved') },
    { value: 'REJECTED', label: $_('supervision.action_rejected') },
    { value: 'ESCALATED', label: $_('supervision.action_escalated') },
    { value: 'ROUTED', label: $_('supervision.action_routed') },
    { value: 'MERGED', label: $_('supervision.action_merged') },
    { value: 'TIME_LOGGED', label: $_('supervision.action_time_logged') },
  ];

  const entityIcons = {
    Lead: Target,
    Contact: User,
    Account: Building2,
    Opportunity: Sparkles,
    Case: Briefcase,
    Task: CheckSquare,
    Invoice: FileText,
    Event: Calendar,
    Document: File,
    Team: Users,
  };

  const actionIcons = {
    CREATE: Plus,
    UPDATE: Pencil,
    DELETE: Trash2,
    VIEW: Eye,
    COMMENT: MessageSquare,
    ASSIGN: UserPlus,
    STATUS_CHANGED: RefreshCw,
    PRIORITY_CHANGED: AlertTriangle,
    APPROVED: CheckCircle,
    REJECTED: XCircle,
    ESCALATED: ArrowUp,
    ROUTED: ArrowRightLeft,
    MERGED: GitMerge,
    TIME_LOGGED: Clock,
  };

  const actionColors = {
    CREATE: 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400',
    UPDATE: 'bg-blue-100 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400',
    DELETE: 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400',
    VIEW: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300',
    COMMENT: 'bg-violet-100 text-violet-700 dark:bg-violet-900/20 dark:text-violet-400',
    ASSIGN: 'bg-orange-100 text-orange-700 dark:bg-orange-900/20 dark:text-orange-400',
    STATUS_CHANGED: 'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/20 dark:text-cyan-400',
    PRIORITY_CHANGED: 'bg-amber-100 text-amber-700 dark:bg-amber-900/20 dark:text-amber-400',
    APPROVED: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400',
    REJECTED: 'bg-rose-100 text-rose-700 dark:bg-rose-900/20 dark:text-rose-400',
    ESCALATED: 'bg-red-100 text-red-700 dark:bg-red-900/20 dark:text-red-400',
    ROUTED: 'bg-sky-100 text-sky-700 dark:bg-sky-900/20 dark:text-sky-400',
    MERGED: 'bg-purple-100 text-purple-700 dark:bg-purple-900/20 dark:text-purple-400',
    TIME_LOGGED: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
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
    Event: $_('supervision.entity_event'),
    Document: $_('supervision.entity_document'),
    Team: $_('supervision.entity_team'),
  };

  // Action display names
  const actionDisplayNames = {
    CREATE: $_('supervision.action_create'),
    UPDATE: $_('supervision.action_update'),
    DELETE: $_('supervision.action_delete'),
    VIEW: $_('supervision.action_view'),
    COMMENT: $_('supervision.action_comment'),
    ASSIGN: $_('supervision.action_assign'),
    STATUS_CHANGED: $_('supervision.action_status_changed'),
    PRIORITY_CHANGED: $_('supervision.action_priority_changed'),
    APPROVED: $_('supervision.action_approved'),
    REJECTED: $_('supervision.action_rejected'),
    ESCALATED: $_('supervision.action_escalated'),
    ROUTED: $_('supervision.action_routed'),
    MERGED: $_('supervision.action_merged'),
    TIME_LOGGED: $_('supervision.action_time_logged'),
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
      Event: 'events',
      Document: 'documents',
      Team: 'teams',
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

  // Auto-refresh every 30s for real-time sync across all org members
  let refreshInterval;
  onMount(() => {
    refreshInterval = setInterval(() => {
      goto($page.url.pathname + $page.url.search, { invalidateAll: true, keepFocus: true, noScroll: true });
    }, 30000);
  });
  onDestroy(() => {
    if (refreshInterval) clearInterval(refreshInterval);
  });

  function resetFilters() {
    filterEntityType = '';
    filterAction = '';
    filterUserId = '';
    filterDateFrom = '';
    filterDateTo = '';
    goto('/supervision');
  }
</script>

<svelte:head>
  <title>{$_('supervision.title')} Â· BottleCRM</title>
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
      <label class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('supervision.filter_from')} — {$_('supervision.filter_to')}</label>
      <DateRangeFilter
        bind:startDate={filterDateFrom}
        bind:endDate={filterDateTo}
        placeholder={$_('supervision.all_types')}
        onchange={(from, to) => { filterDateFrom = from; filterDateTo = to; }}
      />
    </div>
    <Button variant="default" size="sm" onclick={applyFilters} class="text-[12px]">
      <Filter class="me-1.5 size-3.5" />
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
    <!-- Loading: data hasn't arrived yet (undefined, not empty array) -->
    {#if data.activities === undefined && data.totalCount === undefined}
      <div class="flex items-center justify-center py-16">
        <RefreshCw class="size-6 animate-spin text-[var(--text-subtle)]" />
      </div>
    {:else}
    <div class="flex flex-col items-center justify-center py-20 text-center">
      <Activity class="mb-4 size-12 text-[var(--text-subtle)]" />
      <h3 class="text-[15px] font-medium text-[var(--text)]">{$_('supervision.empty_title')}</h3>
      <p class="mt-1 text-[13px] text-[var(--text-subtle)]">{$_('supervision.empty_desc')}</p>
    </div>
    {/if}
  {:else}
    <!-- Loading overlay -->
    {#if data.activities === undefined && data.totalCount === undefined}
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
                    {(act.user?.name || act.user?.email || '?')[0]?.toUpperCase() || '?'}
                  </div>
                  <span class="truncate text-[var(--text)]">
                    {act.user?.name || act.user?.email || 'System'}
                  </span>
                </div>
              </td>
              <td class="px-4 py-3">
                <Badge variant="secondary" class={actionColors[act.action] || 'bg-gray-100 text-gray-700'}>
                  {#if actionIcons[act.action]}
                    {@const Icon = actionIcons[act.action]}
                    <Icon class="me-1 size-3" />
                  {:else}
                    <Activity class="me-1 size-3" />
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
                {act.timestamp ? formatDate(act.timestamp) : '—'}
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
            <ChevronRight class="me-1 size-3" />
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
            <ChevronLeft class="ms-1 size-3" />
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
