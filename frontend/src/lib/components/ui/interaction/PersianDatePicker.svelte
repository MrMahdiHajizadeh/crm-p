<script>
  import { Calendar as CalendarIcon, ChevronDown } from '@lucide/svelte';
  import { Calendar } from '$lib/components/ui/calendar/index.js';
  import { cn } from '$lib/utils.js';
  import {
    today,
    getLocalTimeZone,
    toCalendar,
    GregorianCalendar,
    parseDate,
  } from '@internationalized/date';

  /** @type {{
   *   name: string,
   *   value?: string,
   *   id?: string,
   *   class?: string,
   * }}
   */
  let {
    name,
    value = '',
    id = '',
    class: className,
  } = $props();

  function dateToDisplay(dateStr) {
    if (!dateStr) return 'انتخاب تاریخ';
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return 'انتخاب تاریخ';
      return d.toLocaleDateString('fa-IR-u-ca-persian', { month: 'long', day: 'numeric', year: 'numeric' });
    } catch {
      return 'انتخاب تاریخ';
    }
  }

  function toDateValue(dateStr) {
    if (!dateStr) return today(getLocalTimeZone());
    try {
      const parts = dateStr.split('T')[0].split('-');
      if (parts.length !== 3) return today(getLocalTimeZone());
      return parseDate(`${parts[0]}-${parts[1].padStart(2, '0')}-${parts[2].padStart(2, '0')}`);
    } catch {
      return today(getLocalTimeZone());
    }
  }

  let isOpen = $state(false);
  let pickerEl = $state(null);

  function toggle() {
    isOpen = !isOpen;
  }

  function handleCalendarChange(dateValue) {
    if (!dateValue) return;
    try {
      const gregDate = toCalendar(dateValue, new GregorianCalendar());
      const month = String(gregDate.month).padStart(2, '0');
      const day = String(gregDate.day).padStart(2, '0');
      value = `${gregDate.year}-${month}-${day}`;
      isOpen = false;
    } catch {
      // ignore
    }
  }

  function handleWindowClick(e) {
    if (isOpen && pickerEl && !pickerEl.contains(e.target)) {
      isOpen = false;
    }
  }

  function handleClear() {
    value = '';
    isOpen = false;
  }
</script>

<svelte:window onclick={handleWindowClick} />

<div bind:this={pickerEl} class="relative {className || ''}">
  <!-- Hidden input for form submission (name is used for form data) -->
  <input type="hidden" {name} value={value} />

  <button
    type="button"
    {id}
    onclick={toggle}
    class={cn(
      'flex h-9 w-full min-w-0 items-center gap-2 rounded-[var(--r-md)] border border-[color:var(--border)] bg-[color:var(--bg-input)] px-3 text-[13px] text-[color:var(--text)] outline-none transition-[border-color,box-shadow] duration-150 hover:border-[color:var(--border-strong)] focus-visible:border-[color:var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]',
    )}
  >
    <CalendarIcon class="size-3.5 shrink-0 text-[var(--text-subtle)]" />
    <span class="flex-1 text-start font-medium">{dateToDisplay(value)}</span>
    <ChevronDown class="size-3 text-[var(--text-subtle)] transition-transform {isOpen ? 'rotate-180' : ''}" />
  </button>

  {#if isOpen}
    <div
      class="absolute left-0 top-full z-[9999] mt-1 w-auto min-w-[280px] rounded-xl border border-[var(--border-faint)] bg-[var(--bg)] p-3 shadow-xl"
    >
      <Calendar value={toDateValue(value)} onValueChange={handleCalendarChange} />
      {#if value}
        <button
          type="button"
          onclick={handleClear}
          class="mt-2 w-full rounded-lg border border-[var(--border-faint)] px-3 py-1.5 text-[12px] text-[var(--text-muted)] transition-colors hover:bg-[var(--bg-elevated)] hover:text-[var(--text)]"
        >
          پاک کردن تاریخ
        </button>
      {/if}
    </div>
  {/if}
</div>