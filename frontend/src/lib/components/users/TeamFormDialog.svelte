<script>
  import { invalidateAll } from '$app/navigation';
  import { toast } from '$lib/components/ui/toast/index.js';
  import * as Dialog from '$lib/components/ui/dialog/index.js';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { _ } from '$lib/i18n';

  let {
    open = $bindable(false),
    team = null,
    users = [],
    onClose
  } = $props();

  let formName = $state('');
  let formDescription = $state('');
  let formUsers = $state([]);
  let submitting = $state(false);

  $effect(() => {
    if (open) {
      formName = team?.name || '';
      formDescription = team?.description || '';
      formUsers = team?.userIds || [];
      submitting = false;
    }
  });

  const isEditing = $derived(!!team?.id);
  const dialogTitle = $derived(isEditing ? $_('users.team_dialog_title_edit') : $_('users.team_dialog_title_create'));
  const dialogDesc = $derived(isEditing ? $_('users.team_dialog_desc_edit') : $_('users.team_dialog_desc_create'));
  const submitLabel = $derived(isEditing ? $_('users.team_dialog_submit_edit') : $_('users.team_dialog_submit_create'));

  function handleClose() {
    open = false;
    onClose?.();
  }

  function toggleUser(userId) {
    formUsers = formUsers.includes(userId)
      ? formUsers.filter((id) => id !== userId)
      : [...formUsers, userId];
  }

  async function handleSubmit() {
    if (!formName.trim() || submitting) return;
    submitting = true;

    try {
      const body = {
        name: formName.trim(),
        description: formDescription,
        users: formUsers
      };

      let res;
      if (isEditing) {
        res = await fetch(`/users/teams`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...body, team_id: team.id })
        });
      } else {
        res = await fetch(`/users/teams`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
      }

      if (res.ok) {
        const msgKey = isEditing ? 'users.team_updated' : 'users.team_created';
        toast.success($_(msgKey));
        open = false;
        onClose?.();
        invalidateAll();
      } else {
        const data = await res.json().catch(() => ({}));
        toast.error(data?.error || data?.errors?.[0] || $_('common.error_occurred'));
      }
    } catch (err) {
      toast.error(err?.message || $_('common.error_occurred'));
    } finally {
      submitting = false;
    }
  }
</script>

<Dialog.Root bind:open onOpenChange={(o) => !o && handleClose()}>
  <Dialog.Content class="sm:max-w-[500px]">
    <Dialog.Header>
      <Dialog.Title>{dialogTitle}</Dialog.Title>
      <Dialog.Description>{dialogDesc}</Dialog.Description>
    </Dialog.Header>

    <div class="space-y-4">
      <input type="hidden" name="users" value={JSON.stringify(formUsers)} />
      {#if isEditing}
        <input type="hidden" name="team_id" value={team?.id} />
      {/if}

      <div class="space-y-2">
        <Label for="team-name">{$_('users.team_dialog_name_label')}</Label>
        <Input
          id="team-name"
          name="name"
          bind:value={formName}
          placeholder={$_('users.team_dialog_name_placeholder')}
          required
        />
      </div>

      <div class="space-y-2">
        <Label for="team-description">{$_('users.team_dialog_description_label')}</Label>
        <textarea
          id="team-description"
          name="description"
          bind:value={formDescription}
          placeholder={$_('users.team_dialog_description_placeholder')}
          rows="3"
          class="border-input bg-background ring-offset-background placeholder:text-muted-foreground focus-visible:ring-ring flex min-h-[80px] w-full rounded-md border px-3 py-2 text-sm focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none"
        ></textarea>
      </div>

      <div class="space-y-2">
        <Label>{$_('users.team_dialog_assign_members')}</Label>
        <div class="max-h-48 space-y-1 overflow-y-auto rounded-md border p-2">
          {#each users as user (user.id)}
            <label class="flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 hover:bg-muted/50">
              <input
                type="checkbox"
                checked={formUsers.includes(user.id)}
                onchange={() => toggleUser(user.id)}
                class="h-4 w-4 rounded border-gray-300"
              />
              <span class="text-sm">{user.name || user.email || user.phone || user.id}</span>
              {#if user.email}
                <span class="text-muted-foreground text-xs">{user.email}</span>
              {/if}
            </label>
          {:else}
            <p class="text-muted-foreground py-2 text-center text-sm">{$_('users.team_dialog_no_members')}</p>
          {/each}
        </div>
        <p class="text-muted-foreground text-xs">
          {$_('users.team_dialog_members_note')}
        </p>
      </div>

      <Dialog.Footer class="gap-2 sm:gap-0">
        <Button type="button" variant="outline" disabled={submitting} onclick={handleClose}>
          {$_('common.cancel')}
        </Button>
        <Button disabled={!formName.trim() || submitting} onclick={handleSubmit}>
          {submitLabel}
        </Button>
      </Dialog.Footer>
    </div>
  </Dialog.Content>
</Dialog.Root>
