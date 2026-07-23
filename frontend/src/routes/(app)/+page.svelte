<script>
  import { _, locale } from '$lib/i18n';
  import {
    Users,
    Target,
    Building,
    Clock,
    Plus,
    Activity,
    CheckCircle2,
    AlertCircle,
    Flame,
    UserPlus,
    CheckSquare,
    ChevronLeft,
    Sparkles,
    Shield,
    BarChart3,
    Trophy,
    PieChart,
    TrendingUp,
    X,
    LineChart
  } from '@lucide/svelte';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';

  let { data } = $props();

  const user = $derived(data.user || {});
  const metrics = $derived(data.metrics || {});
  const recentData = $derived(data.recentData || {});
  const urgentCounts = $derived(data.urgentCounts || {});
  const statusBreakdown = $derived(data.statusBreakdown || []);
  const hotLeads = $derived(data.hotLeads || []);
  const teamPerformance = $derived(data.teamPerformance || null);

  const teamMembers = $derived(teamPerformance?.team_members || []);
  const topPerformer = $derived(teamPerformance?.top_performer || null);
  const currentUserMember = $derived(teamPerformance?.currentUserMember || null);

  // Timeframe filter state for team performance report ('total' | 'month' | 'week' | 'today')
  let selectedTimeframe = $state('total');

  // Active modal member for detailed multivariate trend inspection
  let activeTrendModalMember = $state(null);

  const todayDate = $derived(
    new Date().toLocaleDateString($locale === 'fa' ? 'fa-IR-u-ca-persian' : 'en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  );

  const C = 251.327; // Circumference for SVG circle with r=40
  const staffColors = [
    '#f59e0b', // Amber
    '#3b82f6', // Blue
    '#10b981', // Emerald
    '#a855f7', // Purple
    '#ec4899', // Pink
    '#06b6d4', // Cyan
    '#f97316', // Orange
    '#8b5cf6'  // Violet
  ];

  // Helper function to build Pie/Donut Chart segments
  function getPieSegments(members, type, timeframe) {
    let cumulative = 0;
    return members
      .map((m, idx) => {
        const share =
          type === 'leads'
            ? timeframe === 'today'
              ? m.leads.shareToday
              : timeframe === 'week'
                ? m.leads.shareWeek
                : timeframe === 'month'
                  ? m.leads.shareMonth
                  : m.leads.shareTotal
            : timeframe === 'today'
              ? m.followups.shareToday
              : timeframe === 'week'
                ? m.followups.shareWeek
                : timeframe === 'month'
                  ? m.followups.shareMonth
                  : m.followups.shareTotal;

        const count =
          type === 'leads'
            ? timeframe === 'today'
              ? m.leads.today
              : timeframe === 'week'
                ? m.leads.week
                : timeframe === 'month'
                  ? m.leads.month
                  : m.leads.total
            : timeframe === 'today'
              ? m.followups.today
              : timeframe === 'week'
                ? m.followups.week
                : timeframe === 'month'
                  ? m.followups.month
                  : m.followups.total;

        const color = staffColors[idx % staffColors.length];
        const dashLength = (share / 100) * C;
        const offset = cumulative;
        cumulative += dashLength;

        return {
          name: m.user_name || 'کارشناس',
          share,
          count,
          color,
          dashLength,
          offset
        };
      })
      .filter((item) => item.share > 0);
  }

  const leadPieSegments = $derived(getPieSegments(teamMembers, 'leads', selectedTimeframe));
  const followupPieSegments = $derived(getPieSegments(teamMembers, 'followups', selectedTimeframe));

  const totalPieLeads = $derived(leadPieSegments.reduce((sum, item) => sum + item.count, 0));
  const totalPieFollowups = $derived(followupPieSegments.reduce((sum, item) => sum + item.count, 0));

  // Build SVG Path string for multivariate inline sparkline (REVERSED CURVE ORIENTATION)
  function buildSparklinePath(values, width = 120, height = 36, maxVal = 1) {
    if (!values || values.length === 0) return '';
    const safeMax = Math.max(1, maxVal);
    // Reverse points to flip curve orientation horizontally
    const reversedValues = [...values].reverse();
    const points = reversedValues.map((val, i) => {
      const x = 4 + i * ((width - 8) / (reversedValues.length - 1));
      const y = (height - 6) - (val / safeMax) * (height - 12);
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    });
    return `M ${points.join(' L ')}`;
  }

  // Get max across all series for a member's multivariate sparkline scaling
  function getMemberMaxVal(member) {
    if (!member?.trends) return 1;
    const leads = member.trends.leads || [];
    const followups = member.trends.followups || [];
    const contacts = member.trends.contacts || [];
    return Math.max(1, ...leads, ...followups, ...contacts);
  }

  // Status color mapping for leads
  function getStatusBadge(status) {
    switch ((status || '').toLowerCase()) {
      case 'new':
      case 'جدید':
        return { label: 'جدید', class: 'bg-blue-500/15 text-blue-400 border-blue-500/30' };
      case 'assigned':
      case 'ارجاع شده':
        return { label: 'ارجاع شده', class: 'bg-purple-500/15 text-purple-400 border-purple-500/30' };
      case 'in process':
      case 'در حال بررسی':
        return { label: 'در حال بررسی', class: 'bg-amber-500/15 text-amber-400 border-amber-500/30' };
      case 'converted':
      case 'تبدیل شده':
        return { label: 'تبدیل شده', class: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30' };
      case 'closed':
      case 'بسته شده':
      case 'bounced':
        return { label: 'بسته شده', class: 'bg-rose-500/15 text-rose-400 border-rose-500/30' };
      default:
        return { label: status || 'نامشخص', class: 'bg-gray-500/15 text-gray-400 border-gray-500/30' };
    }
  }

  // Format date helper (Solar Jalali for Persian locale)
  function formatDate(dateStr) {
    if (!dateStr) return '—';
    try {
      return new Date(dateStr).toLocaleDateString($locale === 'fa' ? 'fa-IR-u-ca-persian' : 'en-US', {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric'
      });
    } catch {
      return dateStr;
    }
  }
</script>

<svelte:head>
  <title>{$_('dashboard.page_title')} - Emarat CRM</title>
</svelte:head>

<div class="min-h-screen space-y-8 p-4 md:p-8">
  <!-- Error Alert -->
  {#if data.error}
    <div
      class="flex items-center gap-4 rounded-xl border border-rose-500/20 bg-rose-500/10 p-5 backdrop-blur-sm"
    >
      <div class="flex size-10 items-center justify-center rounded-lg bg-rose-500/20">
        <AlertCircle class="size-5 text-rose-400" />
      </div>
      <div>
        <p class="text-sm font-medium text-rose-300">{$_('dashboard.loading_error')}</p>
        <p class="text-xs text-rose-400/80">{data.error}</p>
      </div>
    </div>
  {:else}
    <!-- Executive Welcome Banner -->
    <div
      class="relative overflow-hidden rounded-2xl border border-[var(--border-subtle)] bg-gradient-to-r from-[var(--bg-subtle)] via-[var(--bg-subtle)] to-[var(--bg-muted)] p-6 md:p-8 shadow-sm"
    >
      <div class="pointer-events-none absolute -right-16 -top-16 size-64 rounded-full bg-amber-500/10 blur-3xl"></div>
      <div class="pointer-events-none absolute -left-16 -bottom-16 size-64 rounded-full bg-blue-500/10 blur-3xl"></div>

      <div class="relative flex flex-col justify-between gap-6 md:flex-row md:items-center">
        <div class="space-y-2">
          <div class="flex items-center gap-2 text-xs font-semibold text-amber-500">
            <Sparkles class="size-4" />
            <span>داشبورد مدیریتی عمارت CRM</span>
            <span class="text-[var(--text-tertiary)]">•</span>
            <span class="text-[var(--text-tertiary)]">{todayDate}</span>
          </div>
          <h1 class="text-2xl font-bold tracking-tight text-[var(--text-primary)] md:text-3xl">
            سلام، {user?.name || user?.email?.split('@')[0] || 'کاربر گرامی'} 👋
          </h1>
          <p class="text-xs text-[var(--text-secondary)] md:text-sm">
            تحلیل عملکرد شخصی و سازمانی با نمودارهای چند متغیره زمان‌بندی‌شده
          </p>
        </div>

        <!-- Quick Actions -->
        <div class="flex flex-wrap items-center gap-3">
          <Button href="/leads" class="gap-2 bg-amber-500 font-medium text-black hover:bg-amber-400">
            <Plus class="size-4" />
            <span>سرنخ جدید</span>
          </Button>
          <Button href="/contacts" variant="outline" class="gap-2 border-[var(--border-subtle)]">
            <UserPlus class="size-4" />
            <span>مخاطب جدید</span>
          </Button>
          <Button href="/follow-ups" variant="outline" class="gap-2 border-[var(--border-subtle)]">
            <Clock class="size-4" />
            <span>پیگیری‌ها</span>
          </Button>
        </div>
      </div>
    </div>

    <!-- PERSONAL PERFORMANCE PROFILE CARD FOR CURRENT USER (VISIBLE TO ALL USERS) -->
    {#if currentUserMember}
      {@const myMaxVal = getMemberMaxVal(currentUserMember)}
      {@const myLeadsPath = buildSparklinePath(currentUserMember.trends?.leads || [], 180, 48, myMaxVal)}
      {@const myFollowupsPath = buildSparklinePath(currentUserMember.trends?.followups || [], 180, 48, myMaxVal)}
      {@const myContactsPath = buildSparklinePath(currentUserMember.trends?.contacts || [], 180, 48, myMaxVal)}

      <div class="relative overflow-hidden rounded-2xl border border-amber-500/30 bg-gradient-to-r from-amber-500/10 via-[var(--bg-subtle)] to-[var(--bg-subtle)] p-6 shadow-md">
        <div class="mb-4 flex flex-col justify-between gap-4 sm:flex-row sm:items-center border-b border-[var(--border-subtle)] pb-4">
          <div class="flex items-center gap-3">
            <div class="flex size-11 items-center justify-center rounded-xl bg-amber-500 font-bold text-black text-lg">
              {(currentUserMember.user_name || 'U').charAt(0).toUpperCase()}
            </div>
            <div>
              <div class="flex items-center gap-2">
                <h2 class="text-base font-bold text-[var(--text-primary)]">شناسنامه و روند کارکرد شما ({currentUserMember.user_name})</h2>
                <span class="inline-flex items-center rounded-md border px-2 py-0.5 text-[11px] font-medium {currentUserMember.activityBadgeClass}">
                  {currentUserMember.activityLevel}
                </span>
              </div>
              <p class="text-xs text-[var(--text-secondary)]">سهم شما از سرنخ‌ها، پیگیری‌ها و روند کارکرد در طول زمان</p>
            </div>
          </div>

          <Badge class="w-fit border-amber-500/30 bg-amber-500/20 text-amber-300 px-3 py-1 text-xs">
            امتیاز عملکرد شخصی: {currentUserMember.totalActivityScore}
          </Badge>
        </div>

        <div class="grid grid-cols-1 gap-6 md:grid-cols-3 lg:grid-cols-4 items-center">
          <!-- My Lead Share Bar -->
          <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-3.5 space-y-2">
            <div class="flex items-center justify-between text-xs">
              <span class="text-[var(--text-secondary)] font-medium">سهم سرنخ‌های شما</span>
              <span class="font-bold text-amber-400">{currentUserMember.leads?.total || 0} ({currentUserMember.leads?.shareTotal || 0}%)</span>
            </div>
            <div class="h-2 w-full overflow-hidden rounded-full bg-[var(--bg-subtle)]">
              <div class="h-full bg-amber-500 transition-all" style="width: {Math.max(4, currentUserMember.leads?.shareTotal || 0)}%"></div>
            </div>
          </div>

          <!-- My Follow-up Share Bar -->
          <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-3.5 space-y-2">
            <div class="flex items-center justify-between text-xs">
              <span class="text-[var(--text-secondary)] font-medium">سهم پیگیری‌های شما</span>
              <span class="font-bold text-emerald-400">{currentUserMember.followups?.total || 0} ({currentUserMember.followups?.shareTotal || 0}%)</span>
            </div>
            <div class="h-2 w-full overflow-hidden rounded-full bg-[var(--bg-subtle)]">
              <div class="h-full bg-emerald-500 transition-all" style="width: {Math.max(4, currentUserMember.followups?.shareTotal || 0)}%"></div>
            </div>
          </div>

          <!-- Contacts & Accounts Stat -->
          <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-3.5 flex items-center justify-around text-center text-xs">
            <div>
              <span class="text-[11px] text-[var(--text-tertiary)]">مخاطبان من</span>
              <p class="text-base font-bold text-purple-400">{currentUserMember.stats?.contacts_count || 0}</p>
            </div>
            <div class="h-8 w-px bg-[var(--border-subtle)]"></div>
            <div>
              <span class="text-[11px] text-[var(--text-tertiary)]">شرکت‌های من</span>
              <p class="text-base font-bold text-cyan-400">{currentUserMember.stats?.accounts_count || 0}</p>
            </div>
          </div>

          <!-- My Personal Multivariate Sparkline Trend Chart -->
          <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-3 flex flex-col items-center justify-center space-y-1">
            <div class="flex items-center justify-between w-full text-[10px] text-[var(--text-tertiary)] px-1">
              <span>روند کارکرد شخصی</span>
              <button type="button" onclick={() => (activeTrendModalMember = currentUserMember)} class="text-amber-400 hover:underline">مشاهده کامل</button>
            </div>

            <!-- SVG Sparkline -->
            <button
              type="button"
              onclick={() => (activeTrendModalMember = currentUserMember)}
              class="w-full flex justify-center py-1"
              title="برای مشاهده کامل روندها کلیک کنید"
            >
              <svg viewBox="0 0 180 48" style="direction: ltr;" class="h-11 w-44 overflow-visible">
                <!-- Leads Path (Amber) -->
                <path d={myLeadsPath} fill="none" stroke="#f59e0b" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                <!-- Followups Path (Emerald) -->
                <path d={myFollowupsPath} fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="3 1" />
                <!-- Contacts Path (Blue) -->
                <path d={myContactsPath} fill="none" stroke="#3b82f6" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    {/if}

    <!-- KPI Metric Cards Grid -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <!-- Active Leads -->
      <div
        class="group relative overflow-hidden rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-5 transition-all hover:border-blue-500/40 hover:shadow-md"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-[var(--text-secondary)]">سرنخ‌های فعال</span>
          <div class="flex size-9 items-center justify-center rounded-lg bg-blue-500/10 text-blue-400">
            <Target class="size-5" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline justify-between">
          <span class="text-3xl font-bold tracking-tight text-[var(--text-primary)]">
            {metrics.totalLeads || 0}
          </span>
          <a href="/leads" class="flex items-center gap-1 text-xs font-medium text-blue-400 hover:underline">
            <span>مشاهده</span>
            <ChevronLeft class="size-3" />
          </a>
        </div>
        <div class="mt-2 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
          <span class="inline-block size-2 rounded-full bg-blue-500"></span>
          <span>ورودی‌های اختصاص داده‌شده</span>
        </div>
      </div>

      <!-- Urgent Follow-ups & Tasks -->
      <div
        class="group relative overflow-hidden rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-5 transition-all hover:border-amber-500/40 hover:shadow-md"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-[var(--text-secondary)]">پیگیری‌های امروز و معوق</span>
          <div class="flex size-9 items-center justify-center rounded-lg bg-amber-500/10 text-amber-400">
            <Clock class="size-5" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline justify-between">
          <span class="text-3xl font-bold tracking-tight text-[var(--text-primary)]">
            {(urgentCounts.followups_today || 0) + (urgentCounts.overdue_tasks || 0)}
          </span>
          <a href="/follow-ups" class="flex items-center gap-1 text-xs font-medium text-amber-400 hover:underline">
            <span>بررسی</span>
            <ChevronLeft class="size-3" />
          </a>
        </div>
        <div class="mt-2 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
          {#if (urgentCounts.overdue_tasks || 0) > 0}
            <span class="font-medium text-rose-400">{urgentCounts.overdue_tasks} وظیفه عقب‌افتاده</span>
          {:else}
            <span class="text-emerald-400">برنامه‌ها بروز هستند</span>
          {/if}
        </div>
      </div>

      <!-- Total Contacts -->
      <div
        class="group relative overflow-hidden rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-5 transition-all hover:border-purple-500/40 hover:shadow-md"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-[var(--text-secondary)]">مخاطبین سیستم</span>
          <div class="flex size-9 items-center justify-center rounded-lg bg-purple-500/10 text-purple-400">
            <Users class="size-5" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline justify-between">
          <span class="text-3xl font-bold tracking-tight text-[var(--text-primary)]">
            {metrics.totalContacts || 0}
          </span>
          <a href="/contacts" class="flex items-center gap-1 text-xs font-medium text-purple-400 hover:underline">
            <span>فهرست</span>
            <ChevronLeft class="size-3" />
          </a>
        </div>
        <div class="mt-2 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
          <span class="inline-block size-2 rounded-full bg-purple-500"></span>
          <span>اشخاص ثبت‌شده</span>
        </div>
      </div>

      <!-- Accounts / Companies -->
      <div
        class="group relative overflow-hidden rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-5 transition-all hover:border-emerald-500/40 hover:shadow-md"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-[var(--text-secondary)]">شرکت‌ها و حساب‌ها</span>
          <div class="flex size-9 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-400">
            <Building class="size-5" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline justify-between">
          <span class="text-3xl font-bold tracking-tight text-[var(--text-primary)]">
            {metrics.totalAccounts || 0}
          </span>
          <a href="/accounts" class="flex items-center gap-1 text-xs font-medium text-emerald-400 hover:underline">
            <span>لیست</span>
            <ChevronLeft class="size-3" />
          </a>
        </div>
        <div class="mt-2 flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
          <span class="inline-block size-2 rounded-full bg-emerald-500"></span>
          <span>مجموعه‌های تجاری</span>
        </div>
      </div>
    </div>

    <!-- Visualized Lead Status Distribution Section -->
    <div class="rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between">
        <div class="flex items-center gap-2.5">
          <div class="flex size-8 items-center justify-center rounded-lg bg-blue-500/15 text-blue-400">
            <PieChart class="size-4" />
          </div>
          <div>
            <h3 class="text-base font-semibold text-[var(--text-primary)]">توزیع و وضعیت سرنخ‌ها در جریان کار</h3>
            <p class="text-xs text-[var(--text-tertiary)]">تحلیل بصری مراحل پیشرفت سرنخ‌های مجموعه</p>
          </div>
        </div>
      </div>

      <!-- Multi-color Stacked Bar -->
      <div class="my-4 flex h-4 w-full overflow-hidden rounded-full bg-[var(--bg-muted)] p-0.5">
        {#each statusBreakdown as item}
          {#if item.count > 0}
            <div
              class="h-full transition-all hover:opacity-80 {item.color}"
              style="width: {Math.max(4, item.percent)}%"
              title="{item.label}: {item.count} ({item.percent}%)"
            ></div>
          {/if}
        {/each}
      </div>

      <!-- Status Breakdown Legend Badges -->
      <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {#each statusBreakdown as item}
          <div class="flex items-center justify-between rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/40 p-3">
            <div class="flex items-center gap-2">
              <span class="size-2.5 rounded-full {item.color}"></span>
              <span class="text-xs font-medium text-[var(--text-secondary)]">{item.label}</span>
            </div>
            <div class="text-left">
              <span class="font-bold text-[var(--text-primary)]">{item.count}</span>
              <span class="text-[10px] text-[var(--text-tertiary)] ms-1">({item.percent}%)</span>
            </div>
          </div>
        {/each}
      </div>
    </div>

    <!-- ADMIN EXCLUSIVE: Interactive Timeframe & Pie Chart Visualizer -->
    <div class="rounded-2xl border border-amber-500/20 bg-[var(--bg-subtle)] p-6 shadow-sm">
      <div class="mb-6 flex flex-col justify-between gap-4 lg:flex-row lg:items-center">
        <div class="flex items-center gap-3">
          <div class="flex size-10 items-center justify-center rounded-xl bg-amber-500/15 text-amber-400">
            <PieChart class="size-5" />
          </div>
          <div>
            <h2 class="text-lg font-bold text-[var(--text-primary)]">نمودارهای دایره‌ای (Pie Chart) سهم کارشناسان</h2>
            <p class="text-xs text-[var(--text-secondary)]">تحلیل بصری سهم سرنخ‌ها و پیگیری‌ها به تفکیک امروز، این هفته، این ماه و کل</p>
          </div>
        </div>

        <!-- Interactive Timeframe Filter Tabs -->
        <div class="flex items-center gap-1 rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/60 p-1">
          <button
            type="button"
            onclick={() => (selectedTimeframe = 'today')}
            class="rounded-lg px-3 py-1.5 text-xs font-medium transition-all {selectedTimeframe === 'today' ? 'bg-amber-500 font-bold text-black shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'}"
          >
            امروز
          </button>
          <button
            type="button"
            onclick={() => (selectedTimeframe = 'week')}
            class="rounded-lg px-3 py-1.5 text-xs font-medium transition-all {selectedTimeframe === 'week' ? 'bg-amber-500 font-bold text-black shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'}"
          >
            این هفته
          </button>
          <button
            type="button"
            onclick={() => (selectedTimeframe = 'month')}
            class="rounded-lg px-3 py-1.5 text-xs font-medium transition-all {selectedTimeframe === 'month' ? 'bg-amber-500 font-bold text-black shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'}"
          >
            این ماه
          </button>
          <button
            type="button"
            onclick={() => (selectedTimeframe = 'total')}
            class="rounded-lg px-3 py-1.5 text-xs font-medium transition-all {selectedTimeframe === 'total' ? 'bg-amber-500 font-bold text-black shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'}"
          >
            کل (تجمعی)
          </button>
        </div>
      </div>

      <!-- Donut / Pie Charts Grid (Side by Side) -->
      <div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2">
        <!-- Lead Share Pie Chart Card -->
        <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/40 p-5">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-[var(--text-primary)]">
              سهم از کل سرنخ‌ها
              <span class="text-amber-400">({selectedTimeframe === 'today' ? 'امروز' : selectedTimeframe === 'week' ? 'این هفته' : selectedTimeframe === 'month' ? 'این ماه' : 'کل'})</span>
            </h3>
            <span class="text-xs font-bold text-[var(--text-secondary)]">{totalPieLeads} سرنخ</span>
          </div>

          <div class="flex flex-col items-center justify-center gap-6 sm:flex-row">
            <!-- SVG Donut Chart for Leads -->
            <div class="relative flex size-44 shrink-0 items-center justify-center">
              <svg viewBox="0 0 100 100" class="size-full -rotate-90">
                {#each leadPieSegments as seg}
                  <circle
                    cx="50"
                    cy="50"
                    r="40"
                    fill="transparent"
                    stroke={seg.color}
                    stroke-width="12"
                    stroke-dasharray="{seg.dashLength} {C}"
                    stroke-dashoffset={-seg.offset}
                    class="transition-all duration-500 hover:opacity-80"
                  />
                {/each}
              </svg>
              <div class="absolute flex flex-col items-center text-center">
                <span class="text-2xl font-bold text-[var(--text-primary)]">{totalPieLeads}</span>
                <span class="text-[10px] text-[var(--text-tertiary)]">سرنخ</span>
              </div>
            </div>

            <!-- Pie Chart Legend List -->
            <div class="w-full space-y-2 text-xs">
              {#each leadPieSegments as item}
                <div class="flex items-center justify-between border-b border-[var(--border-subtle)]/40 pb-1.5">
                  <div class="flex items-center gap-2">
                    <span class="size-2.5 rounded-full" style="background-color: {item.color}"></span>
                    <span class="font-medium text-[var(--text-primary)]">{item.name}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-[var(--text-primary)]">{item.count}</span>
                    <span class="text-[10px] font-semibold text-amber-400">({item.share}%)</span>
                  </div>
                </div>
              {:else}
                <p class="py-4 text-center text-[11px] text-[var(--text-tertiary)]">سرنخی در این بازه ثبت نشده است.</p>
              {/each}
            </div>
          </div>
        </div>

        <!-- Follow-up Share Pie Chart Card -->
        <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/40 p-5">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-[var(--text-primary)]">
              سهم از کل پیگیری‌ها
              <span class="text-emerald-400">({selectedTimeframe === 'today' ? 'امروز' : selectedTimeframe === 'week' ? 'این هفته' : selectedTimeframe === 'month' ? 'این ماه' : 'کل'})</span>
            </h3>
            <span class="text-xs font-bold text-[var(--text-secondary)]">{totalPieFollowups} پیگیری</span>
          </div>

          <div class="flex flex-col items-center justify-center gap-6 sm:flex-row">
            <!-- SVG Donut Chart for Followups -->
            <div class="relative flex size-44 shrink-0 items-center justify-center">
              <svg viewBox="0 0 100 100" class="size-full -rotate-90">
                {#each followupPieSegments as seg}
                  <circle
                    cx="50"
                    cy="50"
                    r="40"
                    fill="transparent"
                    stroke={seg.color}
                    stroke-width="12"
                    stroke-dasharray="{seg.dashLength} {C}"
                    stroke-dashoffset={-seg.offset}
                    class="transition-all duration-500 hover:opacity-80"
                  />
                {/each}
              </svg>
              <div class="absolute flex flex-col items-center text-center">
                <span class="text-2xl font-bold text-[var(--text-primary)]">{totalPieFollowups}</span>
                <span class="text-[10px] text-[var(--text-tertiary)]">پیگیری</span>
              </div>
            </div>

            <!-- Pie Chart Legend List -->
            <div class="w-full space-y-2 text-xs">
              {#each followupPieSegments as item}
                <div class="flex items-center justify-between border-b border-[var(--border-subtle)]/40 pb-1.5">
                  <div class="flex items-center gap-2">
                    <span class="size-2.5 rounded-full" style="background-color: {item.color}"></span>
                    <span class="font-medium text-[var(--text-primary)]">{item.name}</span>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="font-bold text-[var(--text-primary)]">{item.count}</span>
                    <span class="text-[10px] font-semibold text-emerald-400">({item.share}%)</span>
                  </div>
                </div>
              {:else}
                <p class="py-4 text-center text-[11px] text-[var(--text-tertiary)]">پیگیری در این بازه ثبت نشده است.</p>
              {/each}
            </div>
          </div>
        </div>
      </div>

      <!-- Top Performer Highlight -->
      {#if topPerformer}
        <div class="mb-6 flex items-center justify-between rounded-xl border border-amber-500/30 bg-gradient-to-r from-amber-500/10 via-amber-500/5 to-transparent p-4">
          <div class="flex items-center gap-3">
            <div class="flex size-10 items-center justify-center rounded-full bg-amber-500 text-black">
              <Trophy class="size-5" />
            </div>
            <div>
              <span class="text-[11px] font-semibold uppercase text-amber-400">کارشناس برتر</span>
              <h3 class="text-base font-bold text-[var(--text-primary)]">{topPerformer.user_name}</h3>
              <p class="text-xs text-[var(--text-tertiary)]">
                {topPerformer.leads?.total || 0} سرنخ تحت مدیریت • {topPerformer.followups?.total || 0} پیگیری ثبت‌شده
              </p>
            </div>
          </div>
          <Badge class="border-amber-500/30 bg-amber-500/20 text-amber-300">
            امتیاز فعالیت: {topPerformer.totalActivityScore}
          </Badge>
        </div>
      {/if}

      <!-- Visualized Team Members Table with Individual Multivariate Sparkline Chart Column -->
      <div class="overflow-x-auto">
        <table class="w-full text-right text-xs">
          <thead>
            <tr class="border-b border-[var(--border-subtle)] text-[var(--text-tertiary)]">
              <th class="pb-3 pt-2 font-semibold">نام کارشناس</th>
              <th class="pb-3 pt-2 font-semibold">نقش</th>
              <th class="pb-3 pt-2 font-semibold">وضعیت فعالیت</th>
              <!-- Multivariate Trend Line Column -->
              <th class="pb-3 pt-2 font-semibold">
                روند کارکرد در طول زمان
                <div class="flex items-center gap-2 text-[9px] font-normal text-[var(--text-tertiary)]">
                  <span class="flex items-center gap-1 text-amber-400"><span class="size-1.5 rounded-full bg-amber-500"></span> سرنخ‌ها</span>
                  <span class="flex items-center gap-1 text-emerald-400"><span class="size-1.5 rounded-full bg-emerald-500"></span> پیگیری‌ها</span>
                  <span class="flex items-center gap-1 text-blue-400"><span class="size-1.5 rounded-full bg-blue-500"></span> مخاطبان</span>
                </div>
              </th>
              <!-- Equal Share Column 1: Lead Share -->
              <th class="pb-3 pt-2 font-semibold">
                سهم سرنخ‌ها
                <span class="text-[10px] text-amber-400">
                  ({selectedTimeframe === 'today' ? 'امروز' : selectedTimeframe === 'week' ? 'این هفته' : selectedTimeframe === 'month' ? 'این ماه' : 'کل'})
                </span>
              </th>
              <!-- Equal Share Column 2: Followup Share -->
              <th class="pb-3 pt-2 font-semibold">
                سهم پیگیری‌ها
                <span class="text-[10px] text-emerald-400">
                  ({selectedTimeframe === 'today' ? 'امروز' : selectedTimeframe === 'week' ? 'این هفته' : selectedTimeframe === 'month' ? 'این ماه' : 'کل'})
                </span>
              </th>
              <th class="pb-3 pt-2 font-semibold">مخاطبین</th>
              <th class="pb-3 pt-2 font-semibold">شرکت‌ها</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[var(--border-subtle)] text-[var(--text-secondary)]">
            {#each teamMembers as member}
              {@const maxVal = getMemberMaxVal(member)}
              {@const leadsPath = buildSparklinePath(member.trends?.leads || [], 120, 36, maxVal)}
              {@const followupsPath = buildSparklinePath(member.trends?.followups || [], 120, 36, maxVal)}
              {@const contactsPath = buildSparklinePath(member.trends?.contacts || [], 120, 36, maxVal)}

              {@const leadCount = selectedTimeframe === 'today' ? member.leads.today : selectedTimeframe === 'week' ? member.leads.week : selectedTimeframe === 'month' ? member.leads.month : member.leads.total}
              {@const leadShare = selectedTimeframe === 'today' ? member.leads.shareToday : selectedTimeframe === 'week' ? member.leads.shareWeek : selectedTimeframe === 'month' ? member.leads.shareMonth : member.leads.shareTotal}

              {@const followupCount = selectedTimeframe === 'today' ? member.followups.today : selectedTimeframe === 'week' ? member.followups.week : selectedTimeframe === 'month' ? member.followups.shareMonth : member.followups.shareTotal}
              {@const followupShare = selectedTimeframe === 'today' ? member.followups.shareToday : selectedTimeframe === 'week' ? member.followups.shareWeek : selectedTimeframe === 'month' ? member.followups.shareMonth : member.followups.shareTotal}

              <tr class="transition-colors hover:bg-[var(--bg-muted)]/40">
                <td class="py-3.5">
                  <div class="flex items-center gap-2.5">
                    <div class="flex size-8 shrink-0 items-center justify-center rounded-full bg-amber-500/15 font-bold text-amber-400">
                      {(member.user_name || 'U').charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p class="font-semibold text-[var(--text-primary)]">{member.user_name}</p>
                      <p class="text-[11px] text-[var(--text-tertiary)]">{member.user_email}</p>
                    </div>
                  </div>
                </td>
                <td class="py-3.5">
                  <span class="inline-flex items-center rounded-md border px-2 py-0.5 text-[11px] font-medium {member.role === 'ADMIN' ? 'bg-amber-500/15 text-amber-400 border-amber-500/30' : 'bg-blue-500/15 text-blue-400 border-blue-500/30'}">
                    {member.role === 'ADMIN' ? 'مدیر' : 'کارشناس'}
                  </span>
                </td>
                <td class="py-3.5">
                  <span class="inline-flex items-center rounded-md border px-2 py-0.5 text-[11px] font-medium {member.activityBadgeClass}">
                    {member.activityLevel}
                  </span>
                </td>

                <!-- INDIVIDUAL MULTIVARIATE TREND SVG SPARKLINE COLUMN -->
                <td class="py-3.5 min-w-[130px]">
                  <button
                    type="button"
                    onclick={() => (activeTrendModalMember = member)}
                    class="group relative flex items-center justify-center rounded-lg border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-1.5 transition-colors hover:border-amber-500/50 hover:bg-[var(--bg-muted)]"
                    title="برای مشاهده جزئیات نمودار تفکیکی کلیک کنید"
                  >
                    <svg viewBox="0 0 120 36" style="direction: ltr;" class="h-9 w-28 overflow-visible">
                      <!-- Leads Trend Line (Amber) -->
                      <path d={leadsPath} fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                      <!-- Followups Trend Line (Emerald) -->
                      <path d={followupsPath} fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="3 1" />
                      <!-- Contacts Trend Line (Blue) -->
                      <path d={contactsPath} fill="none" stroke="#3b82f6" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                  </button>
                </td>

                <!-- Equal Share Visual Bar 1: Lead Share -->
                <td class="py-3.5 min-w-[140px]">
                  <div class="flex items-center gap-2">
                    <div class="h-2 w-16 overflow-hidden rounded-full bg-[var(--bg-muted)]">
                      <div class="h-full bg-amber-500" style="width: {Math.max(4, leadShare)}%"></div>
                    </div>
                    <span class="font-bold text-[var(--text-primary)]">{leadCount}</span>
                    <span class="text-[10px] text-amber-400">({leadShare}%)</span>
                  </div>
                </td>

                <!-- Equal Share Visual Bar 2: Followup Share -->
                <td class="py-3.5 min-w-[140px]">
                  <div class="flex items-center gap-2">
                    <div class="h-2 w-16 overflow-hidden rounded-full bg-[var(--bg-muted)]">
                      <div class="h-full bg-emerald-500" style="width: {Math.max(4, followupShare)}%"></div>
                    </div>
                    <span class="font-bold text-[var(--text-primary)]">{followupCount}</span>
                    <span class="text-[10px] text-emerald-400">({followupShare}%)</span>
                  </div>
                </td>

                <td class="py-3.5 font-medium">{member.stats?.contacts_count || 0}</td>
                <td class="py-3.5 font-medium">{member.stats?.accounts_count || 0}</td>
              </tr>
            {:else}
              <tr>
                <td colspan="8" class="py-6 text-center text-[var(--text-tertiary)]">
                  اطلاعات کارکرد اعضای تیم در دسترس نیست.
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    </div>

    <!-- DETAILED INDIVIDUAL MULTIVARIATE TREND MODAL / DRAWER -->
    {#if activeTrendModalMember}
      {@const modalMax = getMemberMaxVal(activeTrendModalMember)}
      {@const mLeadsPath = buildSparklinePath(activeTrendModalMember.trends?.leads || [], 500, 160, modalMax)}
      {@const mFollowupsPath = buildSparklinePath(activeTrendModalMember.trends?.followups || [], 500, 160, modalMax)}
      {@const mContactsPath = buildSparklinePath(activeTrendModalMember.trends?.contacts || [], 500, 160, modalMax)}

      <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm">
        <div class="relative w-full max-w-2xl rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-2xl space-y-6">
          <div class="flex items-center justify-between border-b border-[var(--border-subtle)] pb-4">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-xl bg-amber-500/15 text-amber-400">
                <LineChart class="size-5" />
              </div>
              <div>
                <h3 class="text-base font-bold text-[var(--text-primary)]">
                  تحلیل روند کارکرد {activeTrendModalMember.user_name}
                </h3>
                <p class="text-xs text-[var(--text-secondary)]">{activeTrendModalMember.user_email}</p>
              </div>
            </div>
            <button
              type="button"
              onclick={() => (activeTrendModalMember = null)}
              class="rounded-lg p-1.5 text-[var(--text-tertiary)] hover:bg-[var(--bg-muted)] hover:text-[var(--text-primary)]"
            >
              <X class="size-5" />
            </button>
          </div>

          <!-- Trend Legend & Summary -->
          <div class="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-4 text-xs">
            <div class="flex items-center gap-2">
              <span class="size-3 rounded-full bg-amber-500"></span>
              <span class="font-medium text-[var(--text-primary)]">روند سرنخ‌ها: {activeTrendModalMember.leads?.total || 0}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="size-3 rounded-full bg-emerald-500"></span>
              <span class="font-medium text-[var(--text-primary)]">روند پیگیری‌ها: {activeTrendModalMember.followups?.total || 0}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="size-3 rounded-full bg-blue-500"></span>
              <span class="font-medium text-[var(--text-primary)]">روند مخاطبان: {activeTrendModalMember.stats?.contacts_count || 0}</span>
            </div>
          </div>

          <!-- Large Detailed Chart Canvas -->
          <div class="relative rounded-xl border border-[var(--border-subtle)] bg-gradient-to-b from-[var(--bg-muted)]/30 to-transparent p-6">
            <div class="relative h-44 w-full">
              <svg viewBox="0 0 500 160" style="direction: ltr;" class="size-full overflow-visible">
                <!-- Grid Lines -->
                <line x1="0" y1="40" x2="500" y2="40" stroke="currentColor" stroke-opacity="0.1" />
                <line x1="0" y1="80" x2="500" y2="80" stroke="currentColor" stroke-opacity="0.1" />
                <line x1="0" y1="120" x2="500" y2="120" stroke="currentColor" stroke-opacity="0.1" />

                <!-- Lines -->
                <path d={mLeadsPath} fill="none" stroke="#f59e0b" stroke-width="3" stroke-linecap="round" />
                <path d={mFollowupsPath} fill="none" stroke="#10b981" stroke-width="3" stroke-linecap="round" stroke-dasharray="4 2" />
                <path d={mContactsPath} fill="none" stroke="#3b82f6" stroke-width="2.5" stroke-linecap="round" />
              </svg>
            </div>

            <!-- Periods X-Axis Label (Matching Reversed Curve Alignment) -->
            <div class="mt-4 flex justify-between border-t border-[var(--border-subtle)] pt-2 text-[10px] text-[var(--text-tertiary)] font-medium" style="direction: ltr;">
              {#each (activeTrendModalMember.trends?.periods || []) as period}
                <span>{period}</span>
              {/each}
            </div>
          </div>

          <div class="flex justify-end">
            <Button variant="outline" onclick={() => (activeTrendModalMember = null)}>
              بستن
            </Button>
          </div>
        </div>
      </div>
    {/if}

    <!-- Main Content Layout (2 Columns) -->
    <div class="grid grid-cols-1 gap-8 lg:grid-cols-3">
      <!-- Right Main Column (2 Columns wide) -->
      <div class="space-y-8 lg:col-span-2">
        <!-- Hot Leads Panel -->
        {#if hotLeads.length > 0}
          <div class="rounded-2xl border border-amber-500/20 bg-[var(--bg-subtle)] p-6 shadow-sm">
            <div class="mb-5 flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <div class="flex size-8 items-center justify-center rounded-lg bg-amber-500/15 text-amber-400">
                  <Flame class="size-4" />
                </div>
                <div>
                  <h3 class="text-base font-semibold text-[var(--text-primary)]">سرنخ‌های داغ (اولویت بالا)</h3>
                  <p class="text-xs text-[var(--text-tertiary)]">فرصت‌های با بیشترین شانس تبدیل سریع</p>
                </div>
              </div>
              <a href="/leads" class="text-xs font-medium text-amber-400 hover:underline">مشاهده همه</a>
            </div>

            <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {#each hotLeads.slice(0, 4) as lead}
                <div class="flex flex-col justify-between rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/50 p-4 transition-colors hover:border-amber-500/40">
                  <div class="space-y-1">
                    <div class="flex items-center justify-between">
                      <span class="font-semibold text-[var(--text-primary)]">
                        {lead.first_name || ''} {lead.last_name || 'سرنخ'}
                      </span>
                      <Badge class="border-amber-500/30 bg-amber-500/15 text-amber-400">HOT 🔥</Badge>
                    </div>
                    {#if lead.company}
                      <p class="text-xs text-[var(--text-secondary)]">{lead.company}</p>
                    {/if}
                  </div>
                  <div class="mt-3 flex items-center justify-between border-t border-[var(--border-subtle)] pt-3 text-xs text-[var(--text-tertiary)]">
                    <span>آخرین تماس: {formatDate(lead.last_contacted)}</span>
                    <a href="/leads" class="font-medium text-amber-400 hover:underline">ارتباط</a>
                  </div>
                </div>
              {/each}
            </div>
          </div>
        {/if}

        <!-- Recent Leads Table -->
        <div class="rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-sm">
          <div class="mb-5 flex items-center justify-between">
            <div class="flex items-center gap-2.5">
              <div class="flex size-8 items-center justify-center rounded-lg bg-blue-500/15 text-blue-400">
                <Target class="size-4" />
              </div>
              <div>
                <h3 class="text-base font-semibold text-[var(--text-primary)]">آخرین سرنخ‌های ثبت‌شده</h3>
                <p class="text-xs text-[var(--text-tertiary)]">ورودی‌های اخیر سیستم عمارت CRM</p>
              </div>
            </div>
            <a href="/leads" class="text-xs font-medium text-blue-400 hover:underline">مدیریت سرنخ‌ها</a>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-right text-xs">
              <thead>
                <tr class="border-b border-[var(--border-subtle)] text-[var(--text-tertiary)]">
                  <th class="pb-3 pt-1 font-medium">نام سرنخ</th>
                  <th class="pb-3 pt-1 font-medium">شرکت / سازمان</th>
                  <th class="pb-3 pt-1 font-medium">وضعیت</th>
                  <th class="pb-3 pt-1 font-medium">تاریخ ثبت</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-[var(--border-subtle)] text-[var(--text-secondary)]">
                {#each (recentData.leads || []).slice(0, 7) as lead}
                  {@const badge = getStatusBadge(lead.status)}
                  <tr class="transition-colors hover:bg-[var(--bg-muted)]/40">
                    <td class="py-3 font-medium text-[var(--text-primary)]">
                      <a href="/leads" class="hover:text-blue-400">
                        {lead.title || 'بدون عنوان'}
                      </a>
                    </td>
                    <td class="py-3">{lead.company || 'شخص حقیقی'}</td>
                    <td class="py-3">
                      <span class="inline-flex items-center rounded-md border px-2 py-0.5 text-[11px] font-medium {badge.class}">
                        {badge.label}
                      </span>
                    </td>
                    <td class="py-3 text-[var(--text-tertiary)]">{formatDate(lead.createdAt)}</td>
                  </tr>
                {:else}
                  <tr>
                    <td colspan="4" class="py-6 text-center text-[var(--text-tertiary)]">
                      هیچ سرنخ جدیدی ثبت نشده است
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>

        <!-- Upcoming Tasks & Follow-ups -->
        <div class="rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-sm">
          <div class="mb-5 flex items-center justify-between">
            <div class="flex items-center gap-2.5">
              <div class="flex size-8 items-center justify-center rounded-lg bg-emerald-500/15 text-emerald-400">
                <CheckSquare class="size-4" />
              </div>
              <div>
                <h3 class="text-base font-semibold text-[var(--text-primary)]">وظایف و اقدام‌های پیش‌رو</h3>
                <p class="text-xs text-[var(--text-tertiary)]">برنامه کاری و کارهای اختصاص‌یافته</p>
              </div>
            </div>
            <a href="/follow-ups" class="text-xs font-medium text-emerald-400 hover:underline">دیدن همه</a>
          </div>

          <div class="space-y-3">
            {#each (recentData.tasks || []).slice(0, 4) as task}
              <div class="flex items-center justify-between rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-muted)]/40 p-3.5">
                <div class="flex items-center gap-3">
                  <div class="flex size-7 items-center justify-center rounded-md bg-emerald-500/10 text-emerald-400">
                    <CheckCircle2 class="size-4" />
                  </div>
                  <div>
                    <span class="text-xs font-medium text-[var(--text-primary)]">{task.subject}</span>
                    {#if task.dueDate}
                      <p class="text-[11px] text-[var(--text-tertiary)]">مهلت: {formatDate(task.dueDate)}</p>
                    {/if}
                  </div>
                </div>
                <Badge class="border-[var(--border-subtle)] bg-[var(--bg-subtle)] text-[var(--text-secondary)]">
                  {task.priority || 'عادی'}
                </Badge>
              </div>
            {:else}
              <p class="py-4 text-center text-xs text-[var(--text-tertiary)]">وظیفه معوق یا جدیدی برای شما تعریف نشده است.</p>
            {/each}
          </div>
        </div>
      </div>

      <!-- Left Side Column (1 Column wide) -->
      <div class="space-y-8">
        <!-- Quick Stats Summary Card -->
        <div class="rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-sm">
          <h3 class="mb-4 text-sm font-semibold text-[var(--text-primary)]">خلاصه وضعیت سیستم</h3>
          <div class="space-y-4">
            <div class="flex items-center justify-between text-xs">
              <span class="text-[var(--text-secondary)]">سرنخ‌های داغ</span>
              <span class="font-bold text-amber-400">{urgentCounts.hot_leads || 0}</span>
            </div>
            <div class="h-1.5 w-full overflow-hidden rounded-full bg-[var(--bg-muted)]">
              <div class="h-full bg-amber-500" style="width: {Math.min(100, ((urgentCounts.hot_leads || 0) / Math.max(1, metrics.totalLeads || 1)) * 100)}%"></div>
            </div>

            <div class="flex items-center justify-between text-xs">
              <span class="text-[var(--text-secondary)]">وظایف امروز</span>
              <span class="font-bold text-blue-400">{urgentCounts.tasks_due_today || 0}</span>
            </div>
            <div class="h-1.5 w-full overflow-hidden rounded-full bg-[var(--bg-muted)]">
              <div class="h-full bg-blue-500" style="width: {Math.min(100, ((urgentCounts.tasks_due_today || 0) / 10) * 100)}%"></div>
            </div>

            <div class="flex items-center justify-between text-xs">
              <span class="text-[var(--text-secondary)]">پیگیری‌های امروز</span>
              <span class="font-bold text-emerald-400">{urgentCounts.followups_today || 0}</span>
            </div>
            <div class="h-1.5 w-full overflow-hidden rounded-full bg-[var(--bg-muted)]">
              <div class="h-full bg-emerald-500" style="width: {Math.min(100, ((urgentCounts.followups_today || 0) / 10) * 100)}%"></div>
            </div>
          </div>
        </div>

        <!-- Live Activity Feed -->
        <div class="rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-6 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <Activity class="size-4 text-blue-400" />
              <h3 class="text-sm font-semibold text-[var(--text-primary)]">آخرین فعالیت‌های ثبت‌شده</h3>
            </div>
            <span class="text-[10px] text-[var(--text-tertiary)]">زنده</span>
          </div>

          <div class="relative space-y-4 pr-2">
            {#each (recentData.activities || []).slice(0, 5) as activity}
              <div class="flex items-start gap-3 text-xs">
                <div class="mt-0.5 flex size-2 shrink-0 rounded-full bg-blue-400"></div>
                <div class="space-y-0.5">
                  <p class="font-medium text-[var(--text-primary)]">
                    <span class="text-blue-400">{activity.user?.name || 'کاربر'}</span> {activity.description || activity.action}
                  </p>
                  <span class="text-[10px] text-[var(--text-tertiary)]">{activity.humanizedTime || formatDate(activity.timestamp)}</span>
                </div>
              </div>
            {:else}
              <p class="py-4 text-center text-xs text-[var(--text-tertiary)]">هنوز فعالیتی ثبت نشده است.</p>
            {/each}
          </div>
        </div>

        <!-- Quick Access Box -->
        <div class="rounded-2xl border border-blue-500/20 bg-blue-500/5 p-6 backdrop-blur-sm">
          <div class="flex items-center gap-3">
            <Shield class="size-5 text-blue-400" />
            <div>
              <h4 class="text-xs font-semibold text-[var(--text-primary)]">عمارت CRM</h4>
              <p class="text-[11px] text-[var(--text-secondary)]">سامانه یکپارچه مدیریت سرنخ‌ها و مخاطبین</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>
