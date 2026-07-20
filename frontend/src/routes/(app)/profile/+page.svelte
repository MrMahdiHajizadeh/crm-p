<script>
  import { enhance } from '$app/forms';
  import { User, Mail, Phone, Building2, Calendar, Edit, Save, X, Check } from '@lucide/svelte';
  import { validatePhoneNumber, formatPhoneNumber } from '$lib/utils/phone.js';
  import { formatDate, getInitials } from '$lib/utils/formatting.js';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';
  import { Separator } from '$lib/components/ui/separator/index.js';
  import { SectionCard } from '$lib/components/ui/section-card/index.js';
  import * as Avatar from '$lib/components/ui/avatar/index.js';
  import { _ } from '$lib/i18n';

  /** @type {{ data: import('./$types').PageData, form: import('./$types').ActionData }} */
  let { data, form } = $props();

  let isEditing = $state(false);
  let isSubmitting = $state(false);
  let phoneError = $state('');
  let formattedDisplayPhone = $state('');

  // Form data state - initialized by $effect below
  let formData = $state({
    name: '',
    phone: ''
  });

  // Reset form data when not editing or when data changes
  $effect(() => {
    if (!isEditing) {
      formData = {
        name: data.user.name || '',
        phone: data.user.phone || ''
      };
      phoneError = '';
    }
  });

  // Format phone for display (async, resolved into state)
  $effect(() => {
    if (data.user.phone) {
      formatPhoneNumber(data.user.phone).then((f) => (formattedDisplayPhone = f));
    } else {
      formattedDisplayPhone = '';
    }
  });

  // Validate phone number on input
  async function validatePhone() {
    if (!formData.phone.trim()) {
      phoneError = '';
      return;
    }

    const validation = await validatePhoneNumber(formData.phone);
    if (!validation.isValid) {
      phoneError = validation.error || $_('profile.invalid_phone');
    } else {
      phoneError = '';
    }
  }

  function toggleEdit() {
    isEditing = !isEditing;
    if (!isEditing) {
      // Reset form data when canceling edit
      formData = {
        name: data.user.name || '',
        phone: data.user.phone || ''
      };
      phoneError = '';
    }
  }

  // Handle form submission
  function handleSubmit() {
    isSubmitting = true;
    return async (
      /** @type {{ result: any, update: () => Promise<void> }} */ { result, update }
    ) => {
      isSubmitting = false;
      if (result.type === 'success') {
        isEditing = false;
      }
      await update();
    };
  }
</script>

<svelte:head>
  <title>{$_('profile.title')} - {$_('app.name')}</title>
</svelte:head>

<PageHeader title={$_('profile.title')} subtitle={$_('profile.subtitle')}>
  {#snippet actions()}
    <Button
      variant={isEditing ? 'outline' : 'default'}
      onclick={toggleEdit}
      disabled={isSubmitting}
    >
      {#if isEditing}
        <X class="me-2 h-4 w-4" />
        {$_('common.cancel')}
      {:else}
        <Edit class="me-2 h-4 w-4" />
        {$_('profile.edit_profile')}
      {/if}
    </Button>
  {/snippet}
</PageHeader>

<div class="flex-1 space-y-6 p-4 md:p-6">
  <!-- Success/Error Messages -->
  {#if form?.success}
    <SectionCard
      padded={false}
      class="border-[var(--color-success-default)]/20 bg-[var(--color-success-light)] p-4"
    >
      <div class="flex items-center gap-3">
        <div
          class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[var(--color-success-light)] dark:bg-[var(--color-success-default)]/20"
        >
          <Check class="h-4 w-4 text-[var(--color-success-default)]" />
        </div>
        <p class="text-sm font-medium text-[var(--color-success-default)]">
          {form.message}
        </p>
      </div>
    </SectionCard>
  {/if}

  {#if form?.error}
    <SectionCard
      padded={false}
      class="border-[var(--color-negative-default)]/20 bg-[var(--color-negative-light)] p-4"
    >
      <div class="flex items-center gap-3">
        <div
          class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[var(--color-negative-light)] dark:bg-[var(--color-negative-default)]/20"
        >
          <X class="h-4 w-4 text-[var(--color-negative-default)]" />
        </div>
        <p class="text-sm font-medium text-[var(--color-negative-default)]">
          {form.error}
        </p>
      </div>
    </SectionCard>
  {/if}

  <div class="mx-auto max-w-3xl space-y-6">
    <!-- Profile Header Card -->
    <SectionCard padded={false} class="p-6">
      <div class="flex flex-col items-center gap-6 sm:flex-row sm:items-start">
          <!-- Avatar -->
          <Avatar.Root class="h-20 w-20 text-xl">
            {#if data.user.profilePhoto}
              <Avatar.Image
                src={data.user.profilePhoto}
                alt={data.user.name || $_('profile.photo')}
                class=""
              />
            {/if}
            <Avatar.Fallback class="bg-[var(--color-primary-default)] text-white">
              {getInitials(data.user.name)}
            </Avatar.Fallback>
          </Avatar.Root>

          <!-- User Info -->
          <div class="flex-1 text-center sm:text-start">
            <h2 class="text-foreground text-xl font-semibold">
              {data.user.name || $_('profile.unnamed_user')}
            </h2>
            <p class="text-muted-foreground">{data.user.email || data.user.phone || ''}</p>
            <div class="mt-3">
              <Badge variant={data.user.isActive ? 'default' : 'destructive'}>
                {data.user.isActive ? $_('common.active') : $_('common.inactive')}
              </Badge>
            </div>
          </div>
        </div>
    </SectionCard>

    <!-- Profile Information Card -->
    <SectionCard>
      {#snippet title()}
        <div class="flex min-w-0 flex-col gap-0.5">
          <h3 class="truncate text-[16px] font-medium leading-[1.3] text-[color:var(--text-primary)]">
            {$_('profile.information')}
            </h3>
            <p class="text-[12px] text-[color:var(--text-muted)]">
              {isEditing
                ? $_('profile.edit_subtitle')
                : $_('profile.view_subtitle')}
          </p>
        </div>
      {/snippet}
        {#if isEditing}
          <!-- Edit Form -->
          <form method="POST" action="?/updateProfile" use:enhance={handleSubmit} class="space-y-6">
            <div class="grid gap-6 sm:grid-cols-2">
              <!-- Name -->
              <div class="sm:col-span-2">
                <Label for="name" class="">{$_('profile.full_name')}</Label>
                <Input
                  type="text"
                  id="name"
                  name="name"
                  bind:value={formData.name}
                  placeholder={$_('profile.name_placeholder')}
                  maxlength={255}
                  class="mt-1.5"
                />
              </div>

              <!-- Email (read-only) -->
              <div>
                <Label for="email" class="">{$_('profile.email_address')}</Label>
                <Input
                  type="email"
                  id="email"
                  value={data.user.email || ''}
                  disabled
                  class="bg-muted mt-1.5"
                />
                <p class="text-muted-foreground mt-1 text-xs">{$_('profile.email_cannot_change')}</p>
              </div>

              <!-- Phone -->
              <div>
                <Label for="phone" class="">{$_('profile.phone_number')}</Label>
                <Input
                  type="tel"
                  id="phone"
                  name="phone"
                  bind:value={formData.phone}
                  oninput={validatePhone}
                  placeholder={$_('profile.phone_placeholder')}
                  class="mt-1.5"
                />
                {#if phoneError}
                  <p class="text-destructive mt-1 text-sm">{phoneError}</p>
                {/if}
              </div>
            </div>

            <Separator />

            <div class="flex justify-end gap-3">
              <Button type="button" variant="outline" onclick={toggleEdit} disabled={isSubmitting}>
                {$_('common.cancel')}
              </Button>
              <Button type="submit" disabled={isSubmitting || !!phoneError}>
                {#if isSubmitting}
                  <svg class="me-2 h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  {$_('common.saving')}
                {:else}
                  <Save class="me-2 h-4 w-4" />
                  {$_('profile.save_changes')}
                {/if}
              </Button>
            </div>
          </form>
        {:else}
          <!-- View Mode -->
          <div class="grid gap-6 sm:grid-cols-2">
            <!-- Email -->
            <div class="space-y-1">
              <div class="text-muted-foreground flex items-center gap-2 text-sm font-medium">
                <Mail class="h-4 w-4" />
                {$_('profile.email_address')}
              </div>
              <p class="text-foreground">{data.user.email || data.user.phone || ''}</p>
            </div>

            <!-- Phone -->
            <div class="space-y-1">
              <div class="text-muted-foreground flex items-center gap-2 text-sm font-medium">
                <Phone class="h-4 w-4" />
                {$_('profile.phone_number')}
              </div>
              <p class="text-foreground">
                {formattedDisplayPhone || data.user.phone || $_('common.not_provided')}
              </p>
            </div>

            <!-- Last Login -->
            <div class="space-y-1">
              <div class="text-muted-foreground flex items-center gap-2 text-sm font-medium">
                <Calendar class="h-4 w-4" />
                {$_('profile.last_login')}
              </div>
              <p class="text-foreground">{formatDate(data.user.lastLogin)}</p>
            </div>

            <!-- Member Since -->
            <div class="space-y-1">
              <div class="text-muted-foreground flex items-center gap-2 text-sm font-medium">
                <Calendar class="h-4 w-4" />
                {$_('profile.member_since')}
              </div>
              <p class="text-foreground">{formatDate(data.user.createdAt)}</p>
            </div>
          </div>
        {/if}
    </SectionCard>

    <!-- Organizations Card -->
    {#if data.user.organizations && data.user.organizations.length > 0}
      <SectionCard>
        {#snippet title()}
          <div class="flex min-w-0 flex-col gap-0.5">
            <h3 class="truncate text-[16px] font-medium leading-[1.3] text-[color:var(--text-primary)]">
              {$_('profile.organizations')}
            </h3>
            <p class="text-[12px] text-[color:var(--text-muted)]">
              {$_('profile.organizations_subtitle')}
            </p>
          </div>
        {/snippet}
        <div class="space-y-4">
          {#each data.user.organizations as userOrg}
            <div class="bg-muted/30 flex items-center justify-between rounded-lg border p-4">
              <div class="flex items-center gap-3">
                <div
                  class="flex h-10 w-10 items-center justify-center rounded-lg bg-[var(--color-primary-default)]"
                >
                  <Building2 class="h-5 w-5 text-white" />
                </div>
                <div>
                  <h4 class="text-foreground font-medium">
                    {userOrg.organization.name}
                  </h4>
                  <p class="text-muted-foreground text-sm">
                    {$_('profile.joined')} {formatDate(userOrg.joinedAt)}
                  </p>
                </div>
              </div>
              <Badge variant={userOrg.role === 'ADMIN' ? 'default' : 'secondary'}>
                {userOrg.role}
              </Badge>
            </div>
          {/each}
        </div>
      </SectionCard>
    {/if}
  </div>
</div>
