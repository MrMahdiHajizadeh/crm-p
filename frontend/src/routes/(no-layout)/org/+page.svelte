<script>
  import '../../../app.css';
  import { _ } from '$lib/i18n';
  import imgLogo from '$lib/assets/images/logo.png';
  import { Building2, LogOut, Plus, ChevronRight, Users, Shield } from '@lucide/svelte';
  import { enhance } from '$app/forms';

  let { data = { orgs: [] } } = $props();
  let orgs = $derived(data?.orgs ?? []);

  let loading = $state(false);
  let selectedOrgId = $state(null);
</script>

<svelte:head>
  <title>{$_('org.page_title')}</title>
</svelte:head>

<div class="flex min-h-screen flex-col bg-[var(--surface-sunken)]">
  <header class="border-b border-[var(--border-default)] bg-[var(--surface-default)]">
    <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
      <div class="flex items-center gap-3">
        <img src={imgLogo} alt={$_('app.name')} class="h-8 w-auto" />
        <span class="text-lg font-semibold text-[var(--text-primary)]">{$_('app.name')}</span>
      </div>
      <a
        href="/logout"
        class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-[var(--text-secondary)] transition-colors hover:bg-[var(--surface-raised)] hover:text-[var(--text-primary)]"
      >
        <LogOut class="h-4 w-4" />
        <span class="hidden sm:inline">{$_('org.sign_out')}</span>
      </a>
    </div>
  </header>

  <main class="flex flex-1 items-start justify-center px-6 py-12">
    <div class="w-full max-w-2xl">
      <div class="mb-8 text-center">
        <h1 class="text-2xl font-bold text-[var(--text-primary)]">{$_('org.title')}</h1>
        <p class="mt-2 text-[var(--text-secondary)]">{$_('org.subtitle')}</p>
      </div>

      {#if orgs.length > 0}
        <div class="space-y-3">
          {#each orgs as org (org.id)}
            <form
              method="POST"
              action="?/selectOrg"
              use:enhance={() => {
                loading = true;
                selectedOrgId = org.id;
                // Store org_id immediately for client-side API compatibility
                if (typeof window !== 'undefined') {
                  localStorage.setItem('org_id', org.id);
                }
                return async ({ update }) => {
                  await update();
                  loading = false;
                  selectedOrgId = null;
                };
              }}
            >
              <input type="hidden" name="org_id" value={org.id} />
              <input type="hidden" name="org_name" value={org.name} />
              <button
                type="submit"
                disabled={loading}
                class="group w-full rounded-xl border border-[var(--border-default)] bg-[var(--surface-default)] p-5 text-start shadow-sm transition-all hover:border-[var(--border-strong)] hover:shadow-md focus:ring-2 focus:ring-[var(--color-primary-default)] focus:ring-offset-2 focus:outline-none disabled:opacity-60"
              >
                <div class="flex items-center gap-4">
                  <div
                    class="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[var(--color-primary-light)] text-[var(--color-primary-default)] transition-colors group-hover:bg-[var(--color-primary-default)]/20"
                  >
                    <Building2 class="h-6 w-6" />
                  </div>

                  <div class="min-w-0 flex-1">
                    <h3 class="truncate font-semibold text-[var(--text-primary)]">{org.name}</h3>
                    <div class="mt-1 flex items-center gap-3 text-sm text-[var(--text-secondary)]">
                      <span class="inline-flex items-center gap-1 capitalize">
                        <Users class="h-3.5 w-3.5" />
                        {org.role?.toLowerCase() === 'admin' ? $_('org.role_admin') : $_('org.role_member')}
                      </span>
                    </div>
                  </div>

                  <div class="shrink-0">
                    {#if loading && selectedOrgId === org.id}
                      <div
                        class="h-5 w-5 animate-spin rounded-full border-2 border-[var(--border-default)] border-t-[var(--color-primary-default)]"
                      ></div>
                    {:else}
                      <ChevronRight
                        class="h-5 w-5 text-[var(--text-tertiary)] transition-transform group-hover:translate-x-0.5 group-hover:text-[var(--text-secondary)]"
                      />
                    {/if}
                  </div>
                </div>
              </button>
            </form>
          {/each}
        </div>

        <!-- Single-org system: only one organization is allowed -->
      {:else}
        <div
          class="rounded-xl border border-[var(--border-default)] bg-[var(--surface-default)] p-12 text-center shadow-sm"
        >
          <div
            class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-[var(--surface-sunken)]"
          >
            <Building2 class="h-8 w-8 text-[var(--text-tertiary)]" />
          </div>
          <h3 class="text-lg font-semibold text-[var(--text-primary)]">{$_('org.empty_title')}</h3>
          <p class="mt-2 text-[var(--text-secondary)]">{$_('org.empty_desc')}</p>
          <a
            href="/org/new"
            class="mt-6 inline-flex items-center gap-2 rounded-lg bg-[var(--color-primary-default)] px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[var(--color-primary-dark)]"
          >
            <Plus class="h-4 w-4" />
            {$_('org.create_org')}
          </a>
        </div>
      {/if}

      <div class="mt-8 flex items-center justify-center gap-2 text-sm text-[var(--text-secondary)]">
        <Shield class="h-4 w-4" />
        <span>{$_('org.trust')}</span>
      </div>
    </div>
  </main>
</div>
