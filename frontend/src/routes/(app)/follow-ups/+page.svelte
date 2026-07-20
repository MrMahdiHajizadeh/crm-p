<script>
  import { _ } from '$lib/i18n';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { invalidateAll } from '$app/navigation';
  import {
    Phone,
    Mail,
    Users,
    FileText,
    Calendar,
    AlertTriangle,
    Clock,
    ChevronRight,
    User,
    Building2,
    Target,
    Sparkles,
    Filter,
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';
  import { formatRelativeDate, formatDate } from '$lib/utils/formatting.js';
  import InteractionDialog from '$lib/components/ui/interaction/InteractionDialog.svelte';

  /** @type {{ data: { groups: { overdue: any[], today: any[], tomorrow: any[], thisWeek: any[], later: any[] }, myOnly?: boolean } }} */
  let { data } = $props();

  let groups = $derived(data.groups || {
    overdue: [], today: [], tomorrow: [], thisWeek: [], later: []
  });

  const myOnly = $derived(data.myOnly || false);

  function toggleMyOnly() {
    if (myOnly) {
      goto('/follow-ups');
    } else {
      goto('/follow-ups?my_only=true');
    }
  }

  // Count totals
  const totalCount = $derived(
    groups.overdue.length + groups.today.length + groups.tomorrow.length +
    groups.thisWeek.length + groups.later.length
  );

  // Interaction dialog state
  let showDialog = $state(false);
  let selectedInteraction = $state(null);

  function openInteraction(interaction) {
    selectedInteraction = interaction;
    showDialog = true;
  }

  function handleInteractionSuccess() {
    invalidateAll();
  }

  // Entity icon mapping
  const entityIcons = {
    Lead: Target,
    Contact: User,
    Account: Building2,
    Opportunity: Sparkles,
  };

  // Group config: label, icon, color
  const groupConfig = {
    overdue: {
      label: $_('followups.overdue'),
      icon: AlertTriangle,
      class: 'text-red-500 dark:text-red-400',
      bgClass: 'bg-red-50 dark:bg-red-950/20 border-red-200 dark:border-red-900/30'
    },
    today: {
      label: $_('followups.today'),
      icon: Clock,
      class: 'text-amber-500 dark:text-amber-400',
      bgClass: 'bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900/30'
    },
    tomorrow: {
      label: $_('followups.tomorrow'),
      icon: Calendar,
      class: 'text-blue-500 dark:text-blue-400',
      bgClass: 'bg-blue-50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-900/30'
    },
    thisWeek: {
      label: $_('followups.this_week'),
      icon: Calendar,
      class: 'text-violet-500 dark:text-violet-400',
      bgClass: 'bg-violet-50 dark:bg-violet-950/20 border-violet-200 dark:border-violet-900/30'
    },
    later: {
      label: $_('followups.later'),
      icon: Calendar,
      class: 'text-gray-500 dark:text-gray-400',
      bgClass: 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-800/30'
    }
  };

  /** @type {Record<string, { value: string, label: string, icon: any }>} */
  const typeConfig = {
    call: { value: 'call', label: $_('interaction.types.call'), icon: Phone },
    email: { value: 'email', label: $_('interaction.types.email'), icon: Mail },
    meeting: { value: 'meeting', label: $_('interaction.types.meeting'), icon: Users },
    note: { value: 'note', label: $_('interaction.types.note'), icon: FileText },
  };
</script>

<svelte:head>
  <title>{$_('followups.title')} Â· BottleCRM</title>
</svelte:head>

<PageHeader
  title={$_('followups.title')}
  subtitle={$_('followups.subtitle', { count: totalCount })}
  breadcrumb={[{ label: $_('followups.title') }]}
/>

<InteractionDialog
  open={showDialog}
  entityType={selectedInteraction?.entity_type || 'Lead'}
  entityId={selectedInteraction?.entity_id || ''}
  entityName={selectedInteraction?.entity_name || ''}
  completedInteractionId={selectedInteraction?.id || ''}
  onClose={() => { showDialog = false; selectedInteraction = null; }}
  onSuccess={handleInteractionSuccess}
/>

<div class="px-7 pb-8 md:px-8">
  <!-- Toggle: All / My Only -->
  <div class="mb-5 flex items-center justify-end">
    <button
      type="button"
      class="inline-flex items-center gap-2 rounded-lg border px-3.5 py-2 text-sm font-medium transition-all duration-200 {myOnly ? 'border-[var(--color-primary-default)]/30 bg-[var(--color-primary-light)] text-[var(--color-primary-default)] dark:bg-[var(--color-primary-default)]/15' : 'border-[var(--border-default)] bg-[var(--surface-raised)] text-[var(--text-secondary)] hover:border-[var(--border-default)] hover:text-[var(--text-primary)]'}"
      onclick={toggleMyOnly}
    >
      <Filter class="size-4" />
      {myOnly ? $_('followups.my_only') : $_('followups.all_followups')}
    </button>
  </div>

  {#if totalCount === 0}
    <div class="flex flex-col items-center justify-center py-20 text-center">
      <Calendar class="mb-4 size-12 text-[var(--text-subtle)]" />
      <h3 class="text-[15px] font-medium text-[var(--text)]">{$_('followups.empty_title')}</h3>
      <p class="mt-1 text-[13px] text-[var(--text-subtle)]">{$_('followups.empty_desc')}</p>
    </div>
  {:else}
    <div class="flex flex-col gap-8">
      {#each Object.entries(groupConfig) as [key, config]}
        {#if groups[key]?.length > 0}
          <section>
            <div class="mb-3 flex items-center gap-2">
              <svelte:component this={config.icon} class="size-4 {config.class}" />
              <h2 class="text-[13px] font-semibold text-[var(--text)]">{config.label}</h2>
              <span class="rounded-full bg-[var(--bg-elevated)] px-2 py-0.5 text-[11px] tabular-nums text-[var(--text-subtle)]">
                {groups[key].length}
              </span>
            </div>

            <div class="flex flex-col gap-2">
              {#each groups[key] as item (item.id)}
                <div class="rounded-xl border {config.bgClass} p-4 transition-colors hover:shadow-sm">
                  <div class="flex items-start justify-between gap-4">
                    <div class="min-w-0 flex-1">
                      <!-- Top row: entity type badge + name + date -->
                      <div class="mb-1.5 flex items-center gap-2">
                        <Badge variant="secondary" class="text-[10px] uppercase tracking-wider">
                          <svelte:component this={entityIcons[item.entity_type] || Target} class="me-1 size-3" />
                          {item.entity_type}
                        </Badge>
                        <button
                          type="button"
                          class="truncate text-[13px] font-medium text-[var(--color-primary-default)] hover:underline"
                          onclick={() => {
                            const routeMap = { Lead: 'leads', Contact: 'contacts', Account: 'accounts', Opportunity: 'opportunities' };
                            goto(`/${routeMap[item.entity_type] || item.entity_type.toLowerCase()}/${item.entity_id}`);
                          }}
                        >
                          {item.entity_name || 'â€”'}
                        </button>
                      </div>

                      <!-- Subject -->
                      {#if item.subject}
                        <p class="mb-1.5 text-[13px] font-medium text-[var(--text)]">{item.subject}</p>
                      {/if}

                      <!-- Details row -->
                      <div class="flex flex-wrap items-center gap-3 text-[11px] text-[var(--text-subtle)]">
                        <span class="flex items-center gap-1">
                          <svelte:component this={typeConfig[item.interaction_type]?.icon || Phone} class="size-3" />
                          {typeConfig[item.interaction_type]?.label || item.interaction_type}
                        </span>
                        {#if item.duration_minutes}
                          <span>{item.duration_minutes} min</span>
                        {/if}
                        <span>
                          <Calendar class="me-1 inline size-3" />
                          {formatRelativeDate(item.follow_up_date)}
                        </span>
                        {#if item.created_by?.name}
                          <span class="flex items-center gap-1">
                            <User class="size-3" />
                            {item.created_by.name}
                          </span>
                        {/if}
                      </div>

                      <!-- Description preview -->
                      {#if item.description}
                        <p class="mt-1.5 line-clamp-2 text-[12px] leading-relaxed text-[var(--text-muted)]">
                          {item.description}
                        </p>
                      {/if}
                    </div>

                    <!-- Action button -->
                    <div class="shrink-0">
                      <Button
                        variant="outline"
                        size="sm"
                        class="whitespace-nowrap text-[11px]"
                        onclick={() => openInteraction(item)}
                      >
                        {$_('followups.log_interaction')}
                      </Button>
                    </div>
                  </div>
                </div>
              {/each}
            </div>
          </section>
        {/if}
      {/each}
    </div>
  {/if}
</div>
