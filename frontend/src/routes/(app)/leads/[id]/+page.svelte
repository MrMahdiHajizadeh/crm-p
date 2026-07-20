<script>
  import { _ } from '$lib/i18n';
  import { page } from '$app/stores';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Phone, Mail, Building2, Globe, MapPin, FileText,
    ArrowLeft, Pencil, Calendar, Target, DollarSign, Percent,
    MessageSquare, Phone as PhoneIcon, Clock, History, Eye, User
  } from '@lucide/svelte';
  import { LinkedinIcon as Linkedin } from '$lib/components/icons';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';
  import { PageHeader } from '$lib/components/layout';
  import { CommentSection } from '$lib/components/ui/comment-section';
  import { formatDate, formatRelativeDate } from '$lib/utils/formatting.js';
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { apiRequest as clientApi } from '$lib/api.js';
  import { invalidateAll } from '$app/navigation';
  import InteractionDialog from '$lib/components/ui/interaction/InteractionDialog.svelte';

  /** @type {{ data: import('./$types').PageData }} */
  let { data } = $props();

  const lead = $derived(data.lead || {});
  const comments = $derived(data.comments || []);
  const interactions = $derived(data.interactions || []);

  // Record VIEW activity on mount
  onMount(() => {
    if (browser && lead.id) {
      clientApi(`/leads/${lead.id}/`, { method: 'GET' }).catch(() => {});
    }
  });

  const statusLabels = {
    assigned: $_('filters.assigned'),
    'in process': $_('filters.in_process'),
    converted: $_('filters.converted'),
    recycled: $_('filters.recycled'),
    closed: $_('filters.closed')
  };

  const ratingLabels = {
    hot: $_('filters.hot'),
    warm: $_('filters.warm'),
    cold: $_('filters.cold')
  };

  const interactionTypeIcons = {
    call: PhoneIcon,
    email: Mail,
    meeting: MessageSquare,
    note: FileText,
  };

  const displayName = $derived(
    [lead.first_name, lead.last_name].filter(Boolean).join(' ') || lead.title || 'Lead'
  );

  let interactionDialogOpen = $state(false);
  let expandedInteraction = $state(null);
</script>

<svelte:head>
  <title>{displayName} - BottleCRM</title>
</svelte:head>

<PageHeader
  title={displayName}
  subtitle={lead.company_name || lead.company?.name || ''}
  breadcrumb={[
    { label: $_('leads.title'), href: '/leads' },
    { label: displayName }
  ]}
/>

<div class="px-7 pb-8 md:px-8 space-y-6">
  <!-- Action buttons -->
  <div class="flex items-center gap-2">
    <Button variant="outline" size="sm" href="/leads">
      <ArrowLeft class="me-1.5 size-4" />
      {$_('common.back')}
    </Button>
    <Button variant="outline" size="sm" href="/leads/{lead.id}/edit">
      <Pencil class="me-1.5 size-4" />
      {$_('common.edit')}
    </Button>
    <Button variant="default" size="sm" onclick={() => interactionDialogOpen = true}>
      <MessageSquare class="me-1.5 size-4" />
      {$_('followups.log_interaction')}
    </Button>
  </div>

  <!-- Status badges -->
  <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
    <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-4">
      <p class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('common.status')}</p>
      <Badge variant="secondary" class="mt-1 text-xs">
        {statusLabels[lead.status] || lead.status || '—'}
      </Badge>
    </div>
    <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-4">
      <p class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('leads.rating')}</p>
      <p class="mt-1 text-sm font-medium text-[var(--text)]">
        {ratingLabels[lead.rating] || lead.rating || '—'}
      </p>
    </div>
    <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-4">
      <p class="text-[11px] font-medium text-[var(--text-subtle)]">{$_('leads.source')}</p>
      <p class="mt-1 text-sm font-medium text-[var(--text)]">{lead.source || '—'}</p>
    </div>
  </div>

  <!-- Contact details -->
  <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-5">
    <h3 class="mb-4 text-sm font-semibold text-[var(--text)]">{$_('common.details')}</h3>
    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
      {#if lead.email}
        <div class="flex items-center gap-3 text-sm">
          <Mail class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('common.email')}:</span>
          <span class="text-[var(--text)]">{lead.email}</span>
        </div>
      {/if}
      {#if lead.phone}
        <div class="flex items-center gap-3 text-sm">
          <Phone class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('common.phone')}:</span>
          <span class="text-[var(--text)]">{lead.phone}</span>
        </div>
      {/if}
      {#if lead.company_name}
        <div class="flex items-center gap-3 text-sm">
          <Building2 class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('leads.company')}:</span>
          <span class="text-[var(--text)]">{lead.company_name}</span>
        </div>
      {/if}
      {#if lead.website}
        <div class="flex items-center gap-3 text-sm">
          <Globe class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('leads.website')}:</span>
          <a href={lead.website} target="_blank" class="text-[var(--color-primary-default)] hover:underline">{lead.website}</a>
        </div>
      {/if}
      {#if lead.linkedin_url}
        <div class="flex items-center gap-3 text-sm">
          <Linkedin class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('leads.linkedin')}:</span>
          <a href={lead.linkedin_url} target="_blank" class="text-[var(--color-primary-default)] hover:underline">{lead.linkedin_url}</a>
        </div>
      {/if}
      {#if lead.address_line || lead.city}
        <div class="flex items-center gap-3 text-sm">
          <MapPin class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('common.address')}:</span>
          <span class="text-[var(--text)]">{[lead.address_line, lead.city, lead.state].filter(Boolean).join(', ') || '—'}</span>
        </div>
      {/if}
      {#if lead.description}
        <div class="flex items-start gap-3 text-sm md:col-span-2">
          <FileText class="mt-0.5 size-4 shrink-0 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('common.description')}:</span>
          <span class="text-[var(--text)]">{lead.description}</span>
        </div>
      {/if}
    </div>
  </div>

  <!-- Dates & amounts -->
  <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-5">
    <h3 class="mb-4 text-sm font-semibold text-[var(--text)]">{$_('common.date')}</h3>
    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="flex items-center gap-3 text-sm">
        <Calendar class="size-4 text-[var(--text-subtle)]" />
        <span class="text-[var(--text-muted)]">{$_('common.created_at')}:</span>
        <span class="text-[var(--text)]">{formatDate(lead.created_at || lead.created_on)}</span>
      </div>
      {#if lead.close_date}
        <div class="flex items-center gap-3 text-sm">
          <Target class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('leads.close_date')}:</span>
          <span class="text-[var(--text)]">{formatDate(lead.close_date)}</span>
        </div>
      {/if}
      {#if lead.opportunity_amount}
        <div class="flex items-center gap-3 text-sm">
          <DollarSign class="size-4 text-[var(--text-subtle)]" />
          <span class="text-[var(--text-muted)]">{$_('leads.opportunity_amount')}:</span>
          <span class="text-[var(--text)]">{lead.opportunity_amount}</span>
        </div>
      {/if}
    </div>
  </div>

  <!-- Comments -->
  <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-5">
    <CommentSection
      comments={comments}
      entityType="leads"
      entityId={lead.id}
      commentPermission={data.commentPermission}
    />
  </div>

  <!-- Activity Timeline (Interactions) -->
  {#if interactions.length > 0}
    <div class="rounded-xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-5">
      <h3 class="mb-4 flex items-center gap-2 text-sm font-semibold text-[var(--text)]">
        <History class="size-4" />
        {$_('followups.log_interaction')} ({interactions.length})
      </h3>
      <div class="space-y-1">
        {#each interactions as interaction (interaction.id)}
          {@const Icon = interactionTypeIcons[interaction.interaction_type] || Clock}
          {@const isExpanded = expandedInteraction === interaction.id}
          <div
            role="button"
            tabindex="0"
            onclick={() => expandedInteraction = isExpanded ? null : interaction.id}
            onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); expandedInteraction = isExpanded ? null : interaction.id; } }}
            class="cursor-pointer rounded-lg p-3 transition-colors hover:bg-[var(--bg-hover)]"
          >
            <div class="flex gap-3">
              <div class="flex size-8 shrink-0 items-center justify-center rounded-full bg-[var(--color-primary-light)]">
                <Icon class="size-4 text-[var(--color-primary-default)]" />
              </div>
              <div class="min-w-0 flex-1">
                <div class="flex items-start justify-between gap-2">
                  <p class="text-sm font-medium text-[var(--text)]">
                    {interaction.subject || $_('interaction.form.title')}
                  </p>
                  <span class="shrink-0 text-[11px] text-[var(--text-subtle)]">
                    {formatDate(interaction.interaction_date || interaction.created_at)}
                  </span>
                </div>
                {#if !isExpanded}
                  {#if interaction.created_by?.name}
                    <p class="mt-0.5 text-[11px] text-[var(--text-subtle)] flex items-center gap-1">
                      <User class="size-3" />
                      {interaction.created_by.name}
                    </p>
                  {/if}
                  {#if interaction.result}
                    <Badge variant="secondary" class="mt-1 text-[10px]">{interaction.result}</Badge>
                  {/if}
                {/if}
                {#if isExpanded}
                  <div class="mt-3 space-y-2 border-t border-[var(--border-faint)] pt-3">
                    {#if interaction.description}
                      <p class="text-[13px] text-[var(--text-muted)]">{interaction.description}</p>
                    {/if}
                    <div class="flex flex-wrap gap-3 text-[12px] text-[var(--text-subtle)]">
                      {#if interaction.interaction_type}
                        <span>{$_('interaction.form.type')}: {$_('interaction.types.' + interaction.interaction_type) || interaction.interaction_type}</span>
                      {/if}
                      {#if interaction.result}
                        <span>{$_('interaction.form.result')}: {interaction.result}</span>
                      {/if}
                      {#if interaction.duration_minutes}
                        <span>{$_('interaction.form.duration')}: {interaction.duration_minutes}</span>
                      {/if}
                      {#if interaction.follow_up_date}
                        <span>{$_('interaction.form.follow_up')}: {formatDate(interaction.follow_up_date)}</span>
                      {/if}
                      {#if interaction.created_by?.name}
                        <span class="flex items-center gap-1">
                          <User class="size-3" />
                          {interaction.created_by.name}
                        </span>
                      {/if}
                    </div>
                  </div>
                {/if}
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>

<InteractionDialog
  bind:open={interactionDialogOpen}
  entityType="Lead"
  entityId={lead.id}
  entityName={displayName}
  onClose={() => interactionDialogOpen = false}
  onSuccess={() => { interactionDialogOpen = false; invalidateAll(); }}
/>
