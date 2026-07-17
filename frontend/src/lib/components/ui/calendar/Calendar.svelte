<script>
  import { Calendar } from 'bits-ui';
  import { ChevronLeft, ChevronRight } from '@lucide/svelte';
  import { cn } from '$lib/utils.js';
  import { today, getLocalTimeZone, PersianCalendar, toCalendar, GregorianCalendar } from '@internationalized/date';

  /** @type {import('@internationalized/date').PersianCalendar} */
  const persianCal = new PersianCalendar();

  /**
   * @type {{
   *   value?: import('@internationalized/date').DateValue | undefined,
   *   onValueChange?: (value: import('@internationalized/date').DateValue | undefined) => void,
   *   class?: string,
   * }}
   */
  let { value = $bindable(), onValueChange, class: className } = $props();

  // Convert Gregorian value to Persian for display
  function toPersian(dv) {
    if (!dv) return undefined;
    try { return toCalendar(dv, persianCal); } catch { return dv; }
  }

  // Convert Persian value back to Gregorian for the parent
  function toGregorian(dv) {
    if (!dv) return undefined;
    try { return toCalendar(dv, new GregorianCalendar()); } catch { return dv; }
  }

  // Placeholder in Persian calendar (defaults to today)
  let placeholder = $state(toPersian(value) || toPersian(today(getLocalTimeZone())));

  // Sync placeholder when value changes (convert Gregorian → Persian)
  $effect(() => {
    if (value) {
      const p = toPersian(value);
      if (p) placeholder = p;
    }
  });

  // Generate year options using Persian year
  const currentPersianYear = toPersian(today(getLocalTimeZone()))?.year || 1405;
  const years = Array.from({ length: 111 }, (_, i) => currentPersianYear - 100 + i);

  // Persian month names indexed by Persian month (1=Farvardin, 12=Esfand)
  const months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  // Persian weekday names (starting from Sunday to match bits-ui Grid)
  const weekdaysPersian = ['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'];
</script>

<Calendar.Root
  type="single"
  locale="fa"
  weekdayFormat="short"
  fixedWeeks={true}
  value={value ? toPersian(value) : undefined}
  bind:placeholder
  calendar={persianCal}
  onValueChange={(dv) => {
    // Convert Persian CalendarDate back to Gregorian before passing to parent
    if (dv) {
      const greg = toGregorian(dv);
      value = greg; // update the bound value (Gregorian)
      onValueChange?.(greg);
    } else {
      value = dv;
      onValueChange?.(dv);
    }
  }}
  class={cn('p-3', className)}
>
  {#snippet children({ months: calendarMonths })}
    <Calendar.Header class="relative flex w-full items-center justify-between gap-1 pb-2">
      <Calendar.PrevButton
        class="inline-flex h-7 w-7 items-center justify-center rounded-md border border-[var(--border-default)] bg-transparent p-0 opacity-50 transition-opacity hover:opacity-100"
      >
        <ChevronLeft class="h-4 w-4" />
      </Calendar.PrevButton>

      <div class="flex items-center gap-1">
        <!-- Month Select -->
        <select
          class="h-7 rounded-md border border-[var(--border-default)] bg-[var(--surface-default)] px-2 text-sm font-medium text-[var(--text-primary)] focus:ring-2 focus:ring-[var(--color-primary-default)] focus:outline-none"
          value={placeholder?.month}
          onchange={(e) => {
            const target = /** @type {HTMLSelectElement} */ (e.target);
            if (placeholder) {
              placeholder = placeholder.set({ month: parseInt(target.value) });
            }
          }}
        >
          {#each months as month, i}
            <option value={i + 1}>{month}</option>
          {/each}
        </select>

        <!-- Year Select -->
        <select
          class="h-7 rounded-md border border-[var(--border-default)] bg-[var(--surface-default)] px-2 text-sm font-medium text-[var(--text-primary)] focus:ring-2 focus:ring-[var(--color-primary-default)] focus:outline-none"
          value={placeholder?.year}
          onchange={(e) => {
            const target = /** @type {HTMLSelectElement} */ (e.target);
            if (placeholder) {
              placeholder = placeholder.set({ year: parseInt(target.value) });
            }
          }}
        >
          {#each years as year}
            <option value={year}>{year}</option>
          {/each}
        </select>
      </div>

      <Calendar.NextButton
        class="inline-flex h-7 w-7 items-center justify-center rounded-md border border-[var(--border-default)] bg-transparent p-0 opacity-50 transition-opacity hover:opacity-100"
      >
        <ChevronRight class="h-4 w-4" />
      </Calendar.NextButton>
    </Calendar.Header>

    {#each calendarMonths as month}
      <Calendar.Grid class="w-full border-collapse space-y-1">
        <Calendar.GridHead>
          <Calendar.GridRow class="flex">
            {#each weekdaysPersian as day}
              <Calendar.HeadCell
                class="w-8 rounded-md text-[0.8rem] font-normal text-[var(--text-secondary)]"
              >
                {day}
              </Calendar.HeadCell>
            {/each}
          </Calendar.GridRow>
        </Calendar.GridHead>
        <Calendar.GridBody>
          {#each month.weeks as week}
            <Calendar.GridRow class="mt-2 flex w-full">
              {#each week as date}
                <Calendar.Cell {date} month={month.value} class="relative p-0 text-center text-sm">
                  <Calendar.Day
                    class="inline-flex h-8 w-8 items-center justify-center rounded-md p-0 text-sm font-normal text-[var(--text-primary)] transition-colors hover:bg-[var(--surface-raised)] focus-visible:ring-2 focus-visible:ring-[var(--color-primary-default)] focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50 data-[disabled]:text-[var(--text-tertiary)] data-[outside-month]:text-[var(--text-tertiary)] data-[outside-month]:opacity-50 data-[selected]:bg-[var(--color-primary-default)] data-[selected]:text-white data-[today]:bg-[var(--surface-raised)] data-[today]:font-semibold"
                  >
                    {date.day}
                  </Calendar.Day>
                </Calendar.Cell>
              {/each}
            </Calendar.GridRow>
          {/each}
        </Calendar.GridBody>
      </Calendar.Grid>
    {/each}
  {/snippet}
</Calendar.Root>
