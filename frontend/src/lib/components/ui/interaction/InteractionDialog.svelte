<script>
  import { _ } from '$lib/i18n';
  import { enhance } from '$app/forms';
  import { invalidateAll } from '$app/navigation';
  import { Button } from '$lib/components/ui/button/index.js';
  import * as Dialog from '$lib/components/ui/dialog/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Textarea } from '$lib/components/ui/textarea/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import * as Select from '$lib/components/ui/select/index.js';
  import { toast } from '$lib/components/ui/toast/index.js';
  import { Calendar, Clock, Phone, Mail, Users, FileText } from '@lucide/svelte';
  import PersianDateTimePicker from './PersianDateTimePicker.svelte';

  /** @type {{
   *   open: boolean,
   *   onClose: () => void,
   *   onSuccess: () => void,
   *   entityType?: string,
   *   entityId?: string,
   *   entityName?: string,
   *   completedInteractionId?: string,
   * }} */
  let { open, onClose, onSuccess, entityType = 'Lead', entityId = '', entityName = '', completedInteractionId = '' } = $props();

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

  // Helper: get local datetime string in YYYY-MM-DDTHH:mm format
  function getLocalDateTimeString(date = new Date()) {
    const pad = (n) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  // Form state
  let interactionType = $state('call');
  let interactionDate = $state(getLocalDateTimeString());
  let durationMinutes = $state(0);
  let subject = $state('');
  let description = $state('');
  let result = $state(undefined);
  // Default follow-up to tomorrow
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  let followUpDate = $state(getLocalDateTimeString(tomorrow));
  // Hidden form ref for use:enhance
  let interactionForm = $state(null);

  function handleSubmit() {
    if (!subject.trim() && !description.trim()) {
      toast.error($_('interaction.form.required'));
      return;
    }
    interactionForm?.requestSubmit();
  }

  function handleClose() {
    onClose?.();
  }

  function handleEnhance() {
    return async ({ result }) => {
      if (result.type === 'success') {
        toast.success($_('interaction.form.saved'));
        onSuccess?.();
        onClose?.();
      } else if (result.type === 'failure') {
        const data = /** @type {any} */ (result).data;
        toast.error(data?.error || $_('interaction.form.error'));
      }
    };
  }
</script>

<Dialog.Root open={open} onOpenChange={(o) => { if (!o) handleClose(); }}>
  <Dialog.Portal>
    <Dialog.Overlay class="fixed inset-0 z-50 bg-black/50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
    <Dialog.Content class="sm:max-w-md rounded-xl border border-[var(--border-faint)] bg-[var(--bg)] p-6 shadow-xl data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 max-h-[85vh] overflow-y-auto">
      <Dialog.Header>
        <Dialog.Title class="text-[15px] font-semibold text-[var(--text)]">
          {$_('interaction.form.title')}
        </Dialog.Title>
        <Dialog.Description class="text-[12px] text-[var(--text-subtle)]">
          {entityName || entityType}
        </Dialog.Description>
      </Dialog.Header>

      <div class="flex flex-col gap-3">
        <!-- Interaction Type -->
        <div class="flex flex-col gap-1">
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
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div class="flex flex-col gap-1.5">
            <Label for="interaction-date" class="text-[12px] font-medium text-[var(--text)]">
              {$_('interaction.form.date')}
            </Label>
            <PersianDateTimePicker
              id="interaction-date"
              value={interactionDate}
              onValueChange={(v) => interactionDate = v}
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
            rows="2"
            class="text-[13px] resize-none"
          />
        </div>

        <!-- Result & Follow-up -->
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
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
            <PersianDateTimePicker
              id="follow-up"
              value={followUpDate}
              onValueChange={(v) => followUpDate = v}
            />
          </div>
        </div>
      </div>

      <Dialog.Footer class="mt-4 flex justify-end gap-2 pt-2 border-t border-[var(--border-faint)]">
        <Button variant="ghost" size="sm" onclick={handleClose}>
          {$_('common.cancel')}
        </Button>
        <Button variant="default" size="sm" onclick={handleSubmit}>
          {$_('interaction.form.save')}
        </Button>
      </Dialog.Footer>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>

<!-- Hidden form for server action -->
<form
  method="POST"
  action="?/createInteraction"
  use:enhance={handleEnhance}
  bind:this={interactionForm}
  class="hidden"
>
  <input type="hidden" name="entity_type" value={entityType} />
  <input type="hidden" name="entity_id" value={entityId} />
  <input type="hidden" name="interaction_type" value={interactionType} />
  <input type="hidden" name="interaction_date" value={interactionDate ? new Date(interactionDate).toISOString() : ''} />
  <input type="hidden" name="duration_minutes" value={durationMinutes > 0 ? String(durationMinutes) : ''} />
  <input type="hidden" name="subject" value={subject} />
  <input type="hidden" name="description" value={description} />
  <input type="hidden" name="result" value={result || ''} />
  <input type="hidden" name="follow_up_date" value={followUpDate ? new Date(followUpDate).toISOString() : ''} />
  {#if completedInteractionId}
    <input type="hidden" name="completed_interaction_id" value={completedInteractionId} />
  {/if}
</form>
