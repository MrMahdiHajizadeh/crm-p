<script>
  import { _ } from '$lib/i18n';
  import { Users, TrendingUp, UserRound, Building2, Calendar } from '@lucide/svelte';
  import { resolve } from '$app/paths';

  /** @type {{ teamPerformance?: import('$lib/types').TeamPerformance | null, isAdmin?: boolean }} */
  let { teamPerformance = null, isAdmin = false } = $props();

  const myStats = $derived(teamPerformance?.my_stats ?? null);
  const teamMembers = $derived(teamPerformance?.team_members ?? []);
  const hasTeam = $derived(isAdmin && teamMembers.length > 0);
</script>

{#if myStats}
  <div
    class="rounded-[var(--radius-xl)] border border-[var(--border-default)] bg-[var(--surface-raised)] p-6 shadow-[var(--shadow-sm)] dark:bg-[var(--surface-raised)]/80 dark:backdrop-blur-sm"
  >
    <!-- Header -->
    <div class="mb-5 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div
          class="flex size-9 items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-primary-light)] dark:bg-[var(--color-primary-default)]/15"
        >
          <TrendingUp class="size-5 text-[var(--color-primary-default)]" />
        </div>
        <h2 class="text-base font-semibold tracking-tight text-[var(--text-primary)]">
          {$_('dashboard.team_performance.my_title')}
        </h2>
      </div>
    </div>

    <!-- My Stats Cards -->
    <div class="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
      <!-- Leads -->
      <div
        class="rounded-[var(--radius-lg)] border border-[var(--lead-hot)]/20 bg-[var(--lead-hot-bg)] px-4 py-3.5 dark:bg-[var(--lead-hot)]/10"
      >
        <p class="text-[10px] font-semibold tracking-wider text-[var(--lead-hot)] uppercase">
          {$_('dashboard.team_performance.leads')}
        </p>
        <p class="mt-1 text-xl font-bold tabular-nums text-[var(--text-primary)]">
          {myStats.leads_count ?? 0}
        </p>
      </div>

      <!-- Contacts -->
      <div
        class="rounded-[var(--radius-lg)] border border-[var(--activity-call)]/20 bg-[var(--activity-call)]/5 px-4 py-3.5 dark:bg-[var(--activity-call)]/10"
      >
        <p class="text-[10px] font-semibold tracking-wider text-[var(--activity-call)] uppercase">
          {$_('dashboard.team_performance.contacts')}
        </p>
        <p class="mt-1 text-xl font-bold tabular-nums text-[var(--text-primary)]">
          {myStats.contacts_count ?? 0}
        </p>
      </div>

      <!-- Accounts -->
      <div
        class="rounded-[var(--radius-lg)] border border-[var(--stage-qualified)]/20 bg-[var(--stage-qualified-bg)] px-4 py-3.5 dark:bg-[var(--stage-qualified)]/10"
      >
        <p class="text-[10px] font-semibold tracking-wider text-[var(--stage-qualified)] uppercase">
          {$_('dashboard.team_performance.accounts')}
        </p>
        <p class="mt-1 text-xl font-bold tabular-nums text-[var(--text-primary)]">
          {myStats.accounts_count ?? 0}
        </p>
      </div>

      <!-- Follow-ups (total) -->
      <div
        class="rounded-[var(--radius-lg)] border border-[var(--color-success-default)]/20 bg-[var(--color-success-light)] px-4 py-3.5 dark:bg-[var(--color-success-default)]/10"
      >
        <p class="text-[10px] font-semibold tracking-wider text-[var(--color-success-default)] uppercase">
          {$_('dashboard.team_performance.followups')}
        </p>
        <p class="mt-1 text-xl font-bold tabular-nums text-[var(--text-primary)]">
          {myStats.followups_total ?? 0}
        </p>
        <!-- Time breakdown -->
        <div class="mt-1.5 flex gap-2 text-[10px] text-[var(--text-tertiary)]">
          <span>
            {$_('dashboard.team_performance.today')}: {myStats.followups_today ?? 0}
          </span>
          <span>
            {$_('dashboard.team_performance.this_week')}: {myStats.followups_week ?? 0}
          </span>
          <span>
            {$_('dashboard.team_performance.this_month')}: {myStats.followups_month ?? 0}
          </span>
        </div>
      </div>
    </div>

    <!-- Team Table (Admin only) -->
    {#if hasTeam}
      <div class="border-t border-[var(--border-default)]/50 pt-5">
        <div class="mb-3 flex items-center gap-2">
          <Users class="size-4 text-[var(--text-secondary)]" />
          <h3 class="text-sm font-semibold text-[var(--text-primary)]">
            {$_('dashboard.team_performance.team_title')}
          </h3>
          <span class="text-xs text-[var(--text-tertiary)]">({teamMembers.length})</span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-[var(--border-default)]/50 text-left">
                <th class="whitespace-nowrap px-3 py-2 text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.member')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.leads')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.contacts')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.accounts')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.followups_today')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.followups_week')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.followups_month')}
                </th>
                <th class="whitespace-nowrap px-3 py-2 text-center text-xs font-semibold text-[var(--text-secondary)]">
                  {$_('dashboard.team_performance.followups_total')}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[var(--border-default)]/20">
              {#each teamMembers as member (member.user_id)}
                <tr class="transition-colors hover:bg-[var(--color-primary-light)] dark:hover:bg-[var(--color-primary-default)]/5">
                  <td class="whitespace-nowrap px-3 py-2.5">
                    <div class="flex items-center gap-2">
                      <div class="flex size-7 items-center justify-center rounded-full bg-[var(--color-primary-light)] text-xs font-bold text-[var(--color-primary-default)] dark:bg-[var(--color-primary-default)]/15">
                        {member.user_name?.charAt(0) || '?'}
                      </div>
                      <div>
                        <p class="text-sm font-medium text-[var(--text-primary)]">
                          {member.user_name}
                        </p>
                        <p class="text-[10px] text-[var(--text-tertiary)]">
                          {member.user_email}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.leads_count ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.contacts_count ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.accounts_count ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.followups_today ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.followups_week ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.followups_month ?? 0}
                  </td>
                  <td class="whitespace-nowrap px-3 py-2.5 text-center font-semibold tabular-nums text-[var(--text-primary)]">
                    {member.stats.followups_total ?? 0}
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      </div>
    {/if}
  </div>
{/if}
