<script>
  import '../../../../app.css';
  import { _ } from '$lib/i18n';
  import imgLogo from '$lib/assets/images/logo.png';
  import { enhance } from '$app/forms';
  import { goto } from '$app/navigation';
  import { Building2, ArrowLeft, Check, AlertCircle, Sparkles } from '@lucide/svelte';

  let { form } = $props();

  let isSubmitting = $state(false);

  $effect(() => {
    if (form?.data) {
      const timer = setTimeout(() => {
        goto('/org');
      }, 1500);
      return () => clearTimeout(timer);
    }
  });
</script>

<svelte:head>
  <title>{$_('org.create_page_title')}</title>
</svelte:head>

<div class="flex min-h-screen flex-col bg-[var(--surface-sunken)]">
  <header class="border-b border-[var(--border-default)] bg-[var(--surface-default)]">
    <div class="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
      <div class="flex items-center gap-3">
        <img src={imgLogo} alt={$_('app.name')} class="h-8 w-auto" />
        <span class="text-lg font-semibold text-[var(--text-primary)]">{$_('app.name')}</span>
      </div>
      <a
        href="/org"
        class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-[var(--text-secondary)] transition-colors hover:bg-[var(--surface-raised)] hover:text-[var(--text-primary)]"
      >
        <ArrowLeft class="h-4 w-4" />
        <span>{$_('org.back')}</span>
      </a>
    </div>
  </header>

  <main class="flex flex-1 items-start justify-center px-6 py-12">
    <div class="w-full max-w-md">
      <div class="mb-8 text-center">
        <div
          class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--color-primary-light)]"
        >
          <Sparkles class="h-6 w-6 text-[var(--color-primary-default)]" />
        </div>
        <h1 class="text-2xl font-bold text-[var(--text-primary)]">{$_('org.create_title')}</h1>
        <p class="mt-2 text-[var(--text-secondary)]">{$_('org.create_subtitle')}</p>
      </div>

      <div
        class="rounded-xl border border-[var(--border-default)] bg-[var(--surface-default)] p-6 shadow-sm"
      >
        <form
          action="/org/new"
          method="POST"
          use:enhance={() => {
            isSubmitting = true;
            return async ({ update }) => {
              await update();
              isSubmitting = false;
            };
          }}
          class="space-y-5"
        >
          <div class="space-y-2">
            <label for="org_name" class="block text-sm font-medium text-[var(--text-secondary)]">
              {$_('org.name_label')}
            </label>
            <input
              type="text"
              id="org_name"
              name="org_name"
              required
              disabled={isSubmitting || !!form?.data}
              class="w-full rounded-lg border border-[var(--border-default)] px-4 py-2.5 text-[var(--text-primary)] placeholder-[var(--text-tertiary)] transition-colors focus:border-[var(--color-primary-default)] focus:ring-2 focus:ring-[var(--color-primary-default)]/20 focus:outline-none disabled:bg-[var(--surface-sunken)] disabled:text-[var(--text-secondary)]"
              placeholder={$_('org.name_placeholder')}
            />
            <p class="text-xs text-[var(--text-secondary)]">{$_('org.name_hint')}</p>
          </div>

          {#if form?.error}
            <div
              class="flex items-start gap-3 rounded-lg border border-[var(--color-negative-default)]/20 bg-[var(--color-negative-light)] p-4"
            >
              <AlertCircle class="h-5 w-5 shrink-0 text-[var(--color-negative-default)]" />
              <div>
                <p class="text-sm font-medium text-[var(--color-negative-default)]">
                  {$_('org.error_title')}
                </p>
                <p class="mt-1 text-sm text-[var(--color-negative-default)]/80">
                  {form.error.name || $_('common.error')}
                </p>
              </div>
            </div>
          {/if}

          {#if form?.data}
            <div
              class="flex items-start gap-3 rounded-lg border border-[var(--color-success-default)]/20 bg-[var(--color-success-light)] p-4"
            >
              <Check class="h-5 w-5 shrink-0 text-[var(--color-success-default)]" />
              <div>
                <p class="text-sm font-medium text-[var(--color-success-default)]">
                  {$_('org.success_title')}
                </p>
                <p class="mt-1 text-sm text-[var(--color-success-default)]/80">
                  {$_('org.success_redirect')}
                </p>
              </div>
            </div>
          {/if}

          <button
            type="submit"
            disabled={isSubmitting || !!form?.data}
            class="flex w-full items-center justify-center gap-2 rounded-lg bg-[var(--color-primary-default)] px-4 py-2.5 font-medium text-white transition-colors hover:bg-[var(--color-primary-dark)] focus:ring-2 focus:ring-[var(--color-primary-default)] focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
          >
            {#if isSubmitting}
              <div
                class="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white"
              ></div>
              <span>{$_('org.creating')}</span>
            {:else if form?.data}
              <Check class="h-4 w-4" />
              <span>{$_('org.created')}</span>
            {:else}
              <Building2 class="h-4 w-4" />
              <span>{$_('org.submit')}</span>
            {/if}
          </button>
        </form>
      </div>

      <p class="mt-6 text-center text-sm text-[var(--text-secondary)]">{$_('org.invite_hint')}</p>
    </div>
  </main>
</div>
