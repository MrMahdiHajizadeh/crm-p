<script>
  import { _ } from '$lib/i18n';
  import { goto } from '$app/navigation';
  import { toast } from 'svelte-sonner';
  import { Loader2, User, Mail, Phone, Briefcase, Building2, Globe, Target, Star, DollarSign, CalendarIcon, MapPin, FileText, Users, Banknote, Percent } from '@lucide/svelte';

  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import { FormShell } from '$lib/components/ui/form-shell/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { Button } from '$lib/components/ui/button/index.js';
  import { StageStepper } from '$lib/components/ui/stage-stepper';
  import PersianDatePicker from '$lib/components/ui/interaction/PersianDatePicker.svelte';
  import { LEAD_STATUSES, LEAD_SOURCES, LEAD_RATINGS, CURRENCY_CODES } from '$lib/constants/filters.js';
  import { INDUSTRIES } from '$lib/constants/lead-choices.js';

  /** @type {{ data: any, form: any }} */
  let { data, form } = $props();

  const lead = $derived(data?.lead);
  const initial = $derived(form?.values || {});

  const displayName = $derived(
    [lead?.first_name, lead?.last_name].filter(Boolean).join(' ') ||
    lead?.email ||
    lead?.title ||
    'سرنخ'
  );

  const statusChoices = LEAD_STATUSES.filter((s) => s.value !== 'ALL');
  const sourceChoices = LEAD_SOURCES.filter((s) => s.value !== 'ALL');
  const ratingChoices = LEAD_RATINGS.filter((r) => r.value !== 'ALL');
  const currencyChoices = CURRENCY_CODES.filter((c) => c.value !== '');
  const industryChoices = INDUSTRIES.filter((i) => i.value);

  // Persian translations for options
  const statusLabels = {
    'ASSIGNED': 'اختصاص داده شده',
    'IN_PROCESS': 'در حال بررسی',
    'CONVERTED': 'تبدیل شده',
    'RECYCLED': 'بازیافت شده',
    'CLOSED': 'بسته شده'
  };
  const sourceLabels = {
    'call': 'تماس تلفنی',
    'email': 'ایمیل',
    'existing customer': 'مشتری فعلی',
    'partner': 'شریک',
    'public relations': 'روابط عمومی',
    'compaign': 'کمپین',
    'other': 'سایر'
  };
  const ratingLabels = {
    'HOT': 'داغ',
    'WARM': 'گرم',
    'COLD': 'سرد'
  };

  const stepperStages = $derived(
    statusChoices.map((s) => ({ value: s.value, label: statusLabels[s.value] || s.label }))
  );
  const normalizedStatus = $derived(
    (fv('status', lead?.status) || '').toString().toUpperCase().replace(/\s+/g, '_')
  );

  let submitting = $state(false);

  /** @type {import('@sveltejs/kit').SubmitFunction} */
  function handleSubmit() {
    submitting = true;
    return async ({ result, update }) => {
      submitting = false;
      if (result.type === 'redirect') {
        toast.success('سرنخ با موفقیت به‌روزرسانی شد');
        await update();
      } else if (result.type === 'failure') {
        toast.error(/** @type {any} */ (result.data)?.error || 'خطا در به‌روزرسانی');
        await update({ reset: false });
      }
    };
  }

  function fv(/** @type {string} */ key, /** @type {any} */ fallback) {
    if (initial[key] !== undefined && initial[key] !== null) return initial[key];
    return fallback ?? '';
  }

  function normalizeStatus(/** @type {any} */ value) {
    return (value || '').toString().toUpperCase().replace(/\s+/g, '_');
  }

  function normalizeRating(/** @type {any} */ value) {
    return (value || '').toString().toUpperCase();
  }

  /** Format a date string to Jalali display */
  function toJalali(dateStr) {
    if (!dateStr) return 'انتخاب تاریخ';
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return 'انتخاب تاریخ';
      return d.toLocaleDateString('fa-IR-u-ca-persian', { month: 'long', day: 'numeric', year: 'numeric' });
    } catch {
      return 'انتخاب تاریخ';
    }
  }
</script>

<svelte:head>
  <title>ویرایش {displayName} - بوتل‌سی‌آرام</title>
</svelte:head>

<PageHeader
  title="ویرایش {displayName}"
  breadcrumb={[
    { label: 'سرنخ‌ها', href: '/leads' },
    { label: displayName, href: lead?.id ? `/leads/${lead.id}` : '/leads' },
    { label: 'ویرایش' }
  ]}
/>

<!-- Stage stepper for status -->
<div class="px-7 pb-4 md:px-8">
  <StageStepper stages={stepperStages} current={normalizedStatus} />
</div>

<FormShell errorMessage={form?.error || ''} useEnhance={handleSubmit}>
  {#snippet children()}
    <!-- Section 1: Basics -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <User class="size-3.5" /> اطلاعات پایه
      </h3>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-title">عنوان <span class="text-[var(--red)]">*</span></Label>
        <Input id="lead-title" name="title" required maxlength="200"
               value={fv('title', lead?.title)} placeholder="عنوان سرنخ" />
      </div>

      <div class="grid grid-cols-[100px_1fr_1fr] gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-salutation">عنوان</Label>
          <select id="lead-salutation" name="salutation"
                  class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
            <option value="" selected={!fv('salutation', lead?.salutation)}></option>
            <option value="Mr." selected={'Mr.' === fv('salutation', lead?.salutation)}>آقا</option>
            <option value="Mrs." selected={'Mrs.' === fv('salutation', lead?.salutation)}>خانم</option>
            <option value="Ms." selected={'Ms.' === fv('salutation', lead?.salutation)}>خانم</option>
            <option value="Dr." selected={'Dr.' === fv('salutation', lead?.salutation)}>دکتر</option>
          </select>
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-first-name">نام</Label>
          <Input id="lead-first-name" name="firstName" maxlength="50"
                 value={fv('firstName', lead?.first_name)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-last-name">نام خانوادگی</Label>
          <Input id="lead-last-name" name="lastName" maxlength="50"
                 value={fv('lastName', lead?.last_name)} />
        </div>
      </div>
    </section>

    <!-- Section 2: Contact -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <Mail class="size-3.5" /> اطلاعات تماس
      </h3>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-email">ایمیل</Label>
          <Input id="lead-email" name="email" type="email" maxlength="254"
                 value={fv('email', lead?.email)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-phone">تلفن</Label>
          <Input id="lead-phone" name="phone" type="tel" maxlength="20"
                 value={fv('phone', lead?.phone)} />
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-job-title">عنوان شغلی</Label>
        <Input id="lead-job-title" name="jobTitle" maxlength="100"
               value={fv('jobTitle', lead?.job_title)} />
      </div>
    </section>

    <!-- Section 3: Company -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <Building2 class="size-3.5" /> شرکت
      </h3>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-company">شرکت</Label>
        <Input id="lead-company" name="company" maxlength="255"
               value={fv('company', lead?.company_name)} />
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-website">وب‌سایت</Label>
          <Input id="lead-website" name="website" type="url" maxlength="255" placeholder="https://"
                 value={fv('website', lead?.website)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-linkedin">لینکدین</Label>
          <Input id="lead-linkedin" name="linkedinUrl" type="url" maxlength="255" placeholder="https://linkedin.com/in/..."
                 value={fv('linkedinUrl', lead?.linkedin_url)} />
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-industry">صنعت</Label>
        <select id="lead-industry" name="industry"
                class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
          <option value="">—</option>
          {#each industryChoices as opt (opt.value)}
            <option value={opt.value} selected={opt.value === fv('industry', lead?.industry)}>{opt.label}</option>
          {/each}
        </select>
      </div>
    </section>

    <!-- Section 4: Classification -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <Target class="size-3.5" /> دسته‌بندی
      </h3>

      <div class="grid grid-cols-3 gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-status">وضعیت</Label>
          <select id="lead-status" name="status"
                  class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
            {#each statusChoices as opt (opt.value)}
              <option value={opt.value} selected={opt.value === normalizeStatus(fv('status', lead?.status))}>{statusLabels[opt.value] || opt.label}</option>
            {/each}
          </select>
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-source">منبع</Label>
          <select id="lead-source" name="source"
                  class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
            <option value="">—</option>
            {#each sourceChoices as opt (opt.value)}
              <option value={opt.value} selected={opt.value === fv('source', lead?.source)}>{sourceLabels[opt.value] || opt.label}</option>
            {/each}
          </select>
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-rating">امتیاز</Label>
          <select id="lead-rating" name="rating"
                  class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
            <option value="">—</option>
            {#each ratingChoices as opt (opt.value)}
              <option value={opt.value} selected={opt.value === normalizeRating(fv('rating', lead?.rating))}>{ratingLabels[opt.value] || opt.label}</option>
            {/each}
          </select>
        </div>
      </div>
    </section>

    <!-- Section 5: Opportunity -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <DollarSign class="size-3.5" /> فرصت فروش
      </h3>

      <div class="grid grid-cols-[1fr_140px] gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-opp-amount">ارزش تخمینی</Label>
          <Input id="lead-opp-amount" name="opportunityAmount" type="number" min="0" step="0.01"
                 value={fv('opportunityAmount', lead?.opportunity_amount)} placeholder="۰" />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-currency">ارز</Label>
          <select id="lead-currency" name="currency"
                  class="flex h-9 w-full rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">
            {#each currencyChoices as c (c.value)}
              <option value={c.value} selected={c.value === fv('currency', lead?.currency || 'TOM')}>{c.value}</option>
            {/each}
          </select>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-probability">احتمال (درصد)</Label>
          <Input id="lead-probability" name="probability" type="number" min="0" max="100" step="1"
                 value={fv('probability', lead?.probability)} placeholder="۰–۱۰۰" />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-close-date">تاریخ بسته شدن</Label>
          <PersianDatePicker name="closeDate" value={fv('closeDate', lead?.close_date)} />
        </div>
      </div>
    </section>

    <!-- Section 6: Address -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <MapPin class="size-3.5" /> آدرس
      </h3>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-address-line">خیابان</Label>
        <Input id="lead-address-line" name="addressLine" maxlength="255"
               value={fv('addressLine', lead?.address_line)} />
      </div>

      <div class="grid grid-cols-[1fr_120px_140px] gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-city">شهر</Label>
          <Input id="lead-city" name="city" maxlength="100"
                 value={fv('city', lead?.city)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-state">استان</Label>
          <Input id="lead-state" name="state" maxlength="100"
                 value={fv('state', lead?.state)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-postcode">کد پستی</Label>
          <Input id="lead-postcode" name="postcode" maxlength="20"
                 value={fv('postcode', lead?.postcode)} />
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-country">کشور</Label>
        <Input id="lead-country" name="country" maxlength="100"
               value={fv('country', lead?.country)} />
      </div>
    </section>

    <!-- Section 7: Activity -->
    <section class="flex flex-col gap-3">
      <h3 class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
        <CalendarIcon class="size-3.5" /> فعالیت
      </h3>

      <div class="grid grid-cols-2 gap-3">
        <div class="flex flex-col gap-1.5">
          <Label for="lead-last-contacted">آخرین تماس</Label>
          <PersianDatePicker name="lastContacted" value={fv('lastContacted', lead?.last_contacted)} />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="lead-next-follow-up">پیگیری بعدی</Label>
          <PersianDatePicker name="nextFollowUp" value={fv('nextFollowUp', lead?.next_follow_up)} />
        </div>
      </div>

      <div class="flex flex-col gap-1.5">
        <Label for="lead-description">یادداشت‌ها</Label>
        <textarea id="lead-description" name="description" rows="5"
                  class="flex w-full resize-y rounded-[var(--r-md)] border border-[var(--border)] bg-[var(--bg-input)] px-3 py-2 text-[13px] text-[var(--text)] outline-none hover:border-[var(--border-strong)] focus-visible:border-[var(--text)] focus-visible:shadow-[0_0_0_3px_var(--focus-ring)]">{fv('description', lead?.description)}</textarea>
      </div>
    </section>
  {/snippet}

  {#snippet actions()}
    <Button type="button" variant="ghost" onclick={() => goto(lead?.id ? `/leads/${lead.id}` : '/leads')}>
      انصراف
    </Button>
    <Button type="submit" disabled={submitting}>
      {#if submitting}<Loader2 class="mr-1 size-3.5 animate-spin" />{/if}
      ذخیره تغییرات
    </Button>
  {/snippet}
</FormShell>
