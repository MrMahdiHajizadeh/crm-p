<script>
  import { _ } from '$lib/i18n';
  import { Button } from '$lib/components/ui/button/index.js';
  import * as Dialog from '$lib/components/ui/dialog/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Textarea } from '$lib/components/ui/textarea/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import * as Select from '$lib/components/ui/select/index.js';
  import { apiRequest } from '$lib/api-helpers.js';
  import { toast } from '$lib/components/ui/toast/index.js';
  import { Calendar, Clock, Phone, Mail, Users, FileText } from '@lucide/svelte';

  /** @type {{
   *   open: boolean,
   *   onClose: () => void,
   *   onSuccess: () => void,
   *   entityType?: string,
   *   entityId?: string,
   *   entityName?: string,
   * }} */
  let { open, onClose, onSuccess, entityType = 'Lead', entityId = '', entityName = '' } = $props();

  // Interaction type options
  const interactionTypes = [
    { value: 'call', label: $_('interaction.types.call'), icon: Phone },
    { value: 'email', label: $_('interaction.types.email'), icon: Mail },
    { value: 'meeting', label: $_('interaction.types.meeting'), icon: Users },
    { value: 'note', label: $_('interaction.types.note'), icon: FileText },
  ];

  const resultOptions = [
    { value: 'completed', label: $_('interaction.results.completed') },
    { value: 'no_answer', label: $_('interaction.results.no_answer') },
    { value: 'follow_up_required', label: $_('interaction.results.follow_up_required') },
    { value: 'not_interested', label: $_('interaction.results.not_interested') },
    { value: 'left_voicemail', label: $_('interaction.results.left_voicemail') },
    { value: 'scheduled', label: $_('interaction.results.scheduled') },
  ];

  // Form state
  let interactionType = $state('call');
  let interactionDate = $state(new Date().toISOString().slice(0, 16));
  let durationMinutes = $state(0);
  let subject = $state('');
  let description = $state('');
  let result = $state(undefined);
  let followUpDate = $state('');
  let saving = $state(false);

  function resetForm() {
    interactionType = 'call';
    interactionDate = new Date().toISOString().slice(0, 16);
    durationMinutes = 0;
    subject = '';
    description = '';
    result = undefined;
    followUpDate = '';
  }

  async function handleSubmit() {
    if (!subject.trim() && !description.trim()) {
      toast.error($_('interaction.form.required'));
      return;
    }

    saving = true;
    try {
      const payload = {
        entity_type: entityType,
        entity_id: entityId,
        interaction_type: interactionType,
        interaction_date: new Date(interactionDate).toISOString(),
        duration_minutes: durationMinutes > 0 ? durationMinutes : null,
        subject: subject.trim(),
        description: description.trim(),
        result: result || null,
        follow_up_date: followUpDate ? new Date(followUpDate).toISOString() : null,
      };

      await apiRequest('/leads/interactions/', {
        method: 'POST',
        body: payload,
      });

      toast.success($_('interaction.form.saved'));
      resetForm();
      onSuccess?.();
      onClose?.();
    } catch (err) {
      toast.error(/** @type {any} */ (err)?.message || $_('interaction.form.error'));
    } finally {
      saving = false;
    }
  }

  function handleClose() {
    resetForm();
    onClose?.();
  }
</script>

<Dialog.Root open={open} onOpenChange={(o) => { if (!o) handleClose(); }}>
  <Dialog.Portal>
    <Dialog.Overlay class="fixed inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
    <Dialog.Content class="fixed left-[50%] top-[50%] z-50 w-full max-w-lg translate-x-[-50%] translate-y-[-50%] rounded-xl border border-[var(--border-faint)] bg-[var(--bg)] p-6 shadow-xl data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95">
      <Dialog.Header>
        <Dialog.Title class="text-[15px] font-semibold text-[var(--text)]">
          {$_('interaction.form.title')}
        </Dialog.Title>
        <Dialog.Description class="text-[12px] text-[var(--text-subtle)]">
          {entityName || entityType}
        </Dialog.Description>
      </Dialog.Header>

      <div class="mt-4 flex flex-col gap-4">
        <!-- Interaction Type -->
        <div class="flex flex-col gap-1.5">
          <Label for="interaction-type" class="text-[12px] font-medium text-[var(--text)]">
            {$_('interaction.form.type')}
          </Label>
          <div class="flex gap-2">
            {#each interactionTypes as it}
              <button
                type="button"
                onclick={() => interactionType = it.value}
                class="flex items-center gap-1.5 rounded-lg border px-3 py-2 text-[12px] transition-colors {interactionType === it.value
                  ? 'border-[var(--color-primary-default)] bg-[var(--color-primary-light)] text-[var(--color-primary-default)]'
                  : 'border-[var(--border-faint)] text-[var(--text-muted)] hover:border-[var(--border)] hover:text-[var(--text)]'}"
              >
                <svelte:component this={it.icon} class="size-3.5" />
                {it.label}
              </button>
            {/each}
          </div>
        </div>

        <!-- Date & Duration -->
        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1.5">
            <Label for="interaction-date" class="text-[12px] font-medium text-[var(--text)]">
              {$_('interaction.form.date')}
            </Label>
            <Input
              id="interaction-date"
              type="datetime-local"
              bind:value={interactionDate}
              class="text-[13px]"
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="duration" class="text-[12px] font-medium text-[var(--text)]">
              {$_('interaction.form.duration')}
            </Label>
            <Input
              id="duration"
              type="number"
              min="0"
              bind:value={durationMinutes}
              placeholder="0"
              class="text-[13px]"
            />
          </div>
        </div>

        <!-- Subject -->
        <div class="flex flex-col gap-1.5">
          <Label for="subject" class="text-[12px] font-medium text-[var(--text)]">
            {$_('interaction.form.subject')}
          </Label>
          <Input
            id="subject"
            type="text"
            bind:value={subject}
            placeholder={$_('interaction.form.subject_placeholder')}
            class="text-[13px]"
          />
        </div>

        <!-- Description -->
        <div class="flex flex-col gap-1.5">
          <Label for="description" class="text-[12px] font-medium text-[var(--text)]">
            {$_('interaction.form.description')}
          </Label>
          <Textarea
            id="description"
            bind:value={description}
            placeholder={$_('interaction.form.description_placeholder')}
            rows="3"
            class="text-[13px] resize-none"
          />
        </div>

        <!-- Result & Follow-up -->
        <div class="grid grid-cols-2 gap-3">
          <div class="flex flex-col gap-1.5">
            <Label for="result" class="text-[12px] font-medium text-[var(--text)]">
              {$_('interaction.form.result')}
            </Label>
            <Select.Root type="single" bind:value={result}>
              <Select.Trigger class="w-full text-[13px]">
                {resultOptions.find((o) => o.value === result)?.label || $_('interaction.form.select_result')}
              </Select.Trigger>
              <Select.Content>
                {#each resultOptions as opt}
                  <Select.Item value={opt.value}>{opt.label}</Select.Item>
                {/each}
              </Select.Content>
            </Select.Root>
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="follow-up" class="text-[12px] font-medium text-[var(--text)]">
              {$_('interaction.form.follow_up')}
            </Label>
            <Input
              id="follow-up"
              type="datetime-local"
              bind:value={followUpDate}
              class="text-[13px]"
            />
          </div>
        </div>
      </div>

      <Dialog.Footer class="mt-6 flex justify-end gap-2">
        <Button variant="ghost" size="sm" onclick={handleClose}>
          {$_('common.cancel')}
        </Button>
        <Button variant="default" size="sm" onclick={handleSubmit} disabled={saving}>
          {saving ? $_('common.saving') : $_('interaction.form.save')}
        </Button>
      </Dialog.Footer>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>
