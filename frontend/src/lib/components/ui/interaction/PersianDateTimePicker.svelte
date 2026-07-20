<script>
  import { Calendar as CalendarIcon, Clock, ChevronDown } from '@lucide/svelte';
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
   *   value: string,
   *   onValueChange: (val: string) => void,
   *   placeholder?: string,
   *   id?: string,
   *   class?: string,
   * }}
   */
  let {
    value = '',
    onValueChange,
    placeholder = 'Ø§Ù†ØªØ®Ø§Ø¨ ØªØ§Ø±ÛŒØ®',
    id = '',
    class: className,
  } = $props();

  function dateToInputFormat(date) {
    if (!date || isNaN(date.getTime())) return '';
    const pad = (n) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  function inputToDate(str) {
    if (!str) return new Date();
    try {
      const d = new Date(str);
      return isNaN(d.getTime()) ? new Date() : d;
    } catch {
      return new Date();
    }
  }

  function dateToDateValue(date) {
    if (!date || isNaN(date.getTime())) return today(getLocalTimeZone());
    return parseDate(
      `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    );
  }

  let currentDate = $derived(inputToDate(value));

  function formatPersian(date) {
    if (!date || isNaN(date.getTime())) return placeholder;
    try {
      return date.toLocaleDateString('fa-IR-u-ca-persian', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      });
    } catch {
      return placeholder;
    }
  }

  let hours = $derived(String(currentDate.getHours()).padStart(2, '0'));
  let minutes = $derived(String(currentDate.getMinutes()).padStart(2, '0'));

  const hourOptions = [];
  for (let h = 0; h < 24; h++) {
    hourOptions.push({ value: String(h).padStart(2, '0'), label: String(h).padStart(2, '0') });
  }
  const minuteOptions = [];
  for (let m = 0; m < 60; m += 5) {
    minuteOptions.push({ value: String(m).padStart(2, '0'), label: String(m).padStart(2, '0') });
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
      const d = inputToDate(value);
      d.setFullYear(gregDate.year, gregDate.month - 1, gregDate.day);
      onValueChange?.(dateToInputFormat(d));
      isOpen = false;
    } catch {
      // ignore
    }
  }

  function handleHourChange(e) {
    const h = parseInt(e?.target?.value, 10);
    if (isNaN(h)) return;
    const d = inputToDate(value);
    d.setHours(h, d.getMinutes(), 0, 0);
    onValueChange?.(dateToInputFormat(d));
  }

  function handleMinuteChange(e) {
    const m = parseInt(e?.target?.value, 10);
    if (isNaN(m)) return;
    const d = inputToDate(value);
    d.setHours(d.getHours(), m, 0, 0);
    onValueChange?.(dateToInputFormat(d));
  }

  // Close on outside click
  function handleWindowClick(e) {
    if (isOpen && pickerEl && !pickerEl.contains(e.target)) {
      isOpen = false;
    }
  }
</script>

<svelte:window onclick={handleWindowClick} />

<div bind:this={pickerEl} class="relative {className || ''}">
  <button
    type="button"
    {id}
    onclick={toggle}
    class={cn(
      'flex h-9 w-full min-w-0 items-center gap-2 rounded-[var(--r-md)] border border-[color:var(--border)] bg-[color:var(--bg-input)] px-3 text-[13px] text-[color:var(--text)] outline-none transition-[border-color,box-shadow] duration-150 hover:border-[color:var(--border-strong)] focus-visible:border-[color:var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]',
    )}
  >
    <CalendarIcon class="size-3.5 shrink-0 text-[var(--text-subtle)]" />
    <span class="flex-1 text-start font-medium">{formatPersian(inputToDate(value))}</span>
    <span class="flex items-center gap-1.5 rounded-md bg-[var(--bg)] px-2 py-0.5 text-[12px] font-semibold tabular-nums text-[var(--text)]">
      <Clock class="size-3 text-[var(--text-subtle)]" />
      {hours}:{minutes}
    </span>
    <ChevronDown class="size-3 text-[var(--text-subtle)] transition-transform {isOpen ? 'rotate-180' : ''}" />
  </button>

  {#if isOpen}
    <div
      class="absolute left-0 top-full z-[9999] mt-1 w-auto min-w-[280px] rounded-xl border border-[var(--border-faint)] bg-[var(--bg)] p-3 shadow-xl"
    >
      <Calendar value={dateToDateValue(inputToDate(value))} onValueChange={handleCalendarChange} />

      <div class="mt-3 flex items-center justify-between gap-2 border-t border-[var(--border-faint)] pt-3">
        <div class="flex items-center gap-1.5 text-[var(--text-subtle)]">
          <Clock class="size-3.5" />
          <span class="text-[11px] font-medium">Ø³Ø§Ø¹Øª</span>
        </div>
        <div class="flex items-center gap-1">
          <div class="relative">
            <select
              value={hours}
              onchange={handleHourChange}
              class="appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-input)] px-3 py-2 ps-7 text-[14px] font-medium text-[var(--text)] outline-none transition-colors hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)] [&>option]:bg-[var(--bg)]"
              style="min-width: 64px;"
            >
              {#each hourOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
            <svg class="pointer-events-none absolute left-1.5 top-1/2 size-3 -translate-y-1/2 text-[var(--text-subtle)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m6 9 6 6 6-6"/>
            </svg>
          </div>
          <span class="text-[16px] font-bold text-[var(--text-muted)]">:</span>
          <div class="relative">
            <select
              value={minutes}
              onchange={handleMinuteChange}
              class="appearance-none rounded-lg border border-[var(--border)] bg-[var(--bg-input)] px-3 py-2 ps-7 text-[14px] font-medium text-[var(--text)] outline-none transition-colors hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)] [&>option]:bg-[var(--bg)]"
              style="min-width: 64px;"
            >
              {#each minuteOptions as opt}
                <option value={opt.value}>{opt.label}</option>
              {/each}
            </select>
            <svg class="pointer-events-none absolute left-1.5 top-1/2 size-3 -translate-y-1/2 text-[var(--text-subtle)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m6 9 6 6 6-6"/>
            </svg>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>
