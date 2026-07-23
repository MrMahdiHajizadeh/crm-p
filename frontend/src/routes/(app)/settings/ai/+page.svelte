<script>
  import { _ } from '$lib/i18n';
  import { enhance } from '$app/forms';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Sparkles,
    KeyRound,
    Globe,
    Cpu,
    Network,
    Eye,
    EyeOff,
    CheckCircle2,
    ShieldCheck,
    Loader2
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import { Switch } from '$lib/components/ui/switch/index.js';

  /** @type {{ data: any, form: any }} */
  let { data, form } = $props();

  const aiSettings = $derived(data.aiSettings || {});

  let showApiKey = $state(false);
  let isLoading = $state(false);
  let apiKey = $state('');
  let apiUrl = $state('https://api.openai.com/v1');
  let modelName = $state('gpt-4o-mini');
  let proxyUrl = $state('');
  let isActive = $state(true);

  $effect.pre(() => {
    if (data.aiSettings) {
      apiUrl = data.aiSettings.api_url || 'https://api.openai.com/v1';
      modelName = data.aiSettings.model_name || 'gpt-4o-mini';
      proxyUrl = data.aiSettings.proxy_url || '';
      isActive = data.aiSettings.is_active ?? true;
    }
  });

  $effect(() => {
    if (form?.success) {
      toast.success('تنظیمات هوش مصنوعی با موفقیت بروزرسانی شد');
    } else if (form?.error) {
      toast.error(form.error);
    }
  });

  const popularModels = [
    { value: 'gpt-4o-mini', label: 'GPT-4o Mini (توصیه‌شده - سریع و کم‌هزینه)' },
    { value: 'gpt-4o', label: 'GPT-4o (دقت بالا و استدلال عمیق)' },
    { value: 'deepseek-chat', label: 'DeepSeek Chat (بسیار قدرتمند و بهینه)' },
    { value: 'gemini-1.5-flash', label: 'Gemini 1.5 Flash (سرعت فوق‌العاده)' },
    { value: 'claude-3-5-sonnet', label: 'Claude 3.5 Sonnet' }
  ];
</script>

<svelte:head>
  <title>تنظیمات هوش مصنوعی - عمارت CRM</title>
</svelte:head>

<PageHeader
  title="تنظیمات دستیار هوشمند و مدل‌های AI"
  subtitle="پیکربندی API Key، سرور پروکسی، کلید ارتباطی و مدل‌های هوش مصنوعی برای گزارش‌دهی خودکار"
  breadcrumb={[
    { label: $_('sidebar.settings'), href: '/settings/organization' },
    { label: 'تنظیمات هوش مصنوعی' }
  ]}
/>

<div class="px-4 pb-12 sm:px-7 md:px-8 max-w-4xl space-y-6">
  <!-- Informational Banner -->
  <div class="relative overflow-hidden rounded-2xl border border-amber-500/30 bg-gradient-to-r from-amber-500/10 via-[var(--bg-elevated)] to-[var(--bg-elevated)] p-6 shadow-sm">
    <div class="flex items-start gap-4">
      <div class="flex size-11 shrink-0 items-center justify-center rounded-xl bg-amber-500 text-black">
        <Sparkles class="size-6" />
      </div>
      <div class="space-y-1 text-xs sm:text-sm">
        <h3 class="font-bold text-[var(--text-primary)] text-base">دستیار گزارش‌دهی هوشمند بر اساس دیتابیس CRM</h3>
        <p class="text-[var(--text-secondary)] leading-relaxed">
          دستیار هوشمند با دسترسی خواندن (Read-Only) به دیتابیس اختصاصی سازمان شما، قادر است آمار سرنخ‌ها، عملکرد تیم فروش، پیگیری‌ها و تحلیل‌های مالی را پردازش کرده و همراه با <strong>دلیل و شواهد عددی</strong> گزارش دهد.
        </p>
      </div>
    </div>
  </div>

  <form
    method="POST"
    action="?/update"
    use:enhance={() => {
      isLoading = true;
      return async ({ update }) => {
        isLoading = false;
        await update();
      };
    }}
    class="space-y-6 rounded-2xl border border-[var(--border-faint)] bg-[var(--bg-elevated)] p-6 shadow-sm"
  >
    <!-- Toggle Active Status -->
    <div class="flex items-center justify-between border-b border-[var(--border-faint)] pb-5">
      <div class="space-y-0.5">
        <Label class="text-sm font-bold text-[var(--text-primary)]">فعال‌سازی دستیار هوشمند AI</Label>
        <p class="text-xs text-[var(--text-subtle)]">دسترسی ادمین‌ها به صفحه چت و گزارش‌دهی هوشمند</p>
      </div>
      <Switch name="is_active" bind:checked={isActive} />
    </div>

    <!-- API Key Input -->
    <div class="space-y-2">
      <Label for="api_key" class="flex items-center gap-2 text-xs font-bold text-[var(--text-primary)]">
        <KeyRound class="size-4 text-amber-500" />
        <span>کلید ارتباطی (API Key)</span>
      </Label>

      {#if aiSettings.api_key_masked}
        <div class="flex items-center gap-2 text-xs text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 rounded-lg p-2.5">
          <ShieldCheck class="size-4 shrink-0" />
          <span>کلید فعال فعلی: <strong>{aiSettings.api_key_masked}</strong></span>
        </div>
      {/if}

      <div class="relative">
        <Input
          id="api_key"
          name="api_key"
          type={showApiKey ? 'text' : 'password'}
          placeholder="مثال: sk-proj-... یا کلید سرویس مورد نظر"
          bind:value={apiKey}
          class="pe-10 font-mono text-xs"
        />
        <button
          type="button"
          onclick={() => (showApiKey = !showApiKey)}
          class="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-subtle)] hover:text-[var(--text-primary)]"
        >
          {#if showApiKey}
            <EyeOff class="size-4" />
          {:else}
            <Eye class="size-4" />
          {/if}
        </button>
      </div>
      <p class="text-[11px] text-[var(--text-subtle)]">
        اگر کلید وارد نشود، سیستم از <strong>موتور تحلیل داخلی CRM</strong> برای پاسخ‌گویی بر اساس دیتابیس استفاده خواهد نمود.
      </p>
    </div>

    <!-- Proxy Configuration -->
    <div class="space-y-2 rounded-xl border border-[var(--border-faint)] bg-[var(--bg-subtle)] p-4">
      <Label for="proxy_url" class="flex items-center gap-2 text-xs font-bold text-[var(--text-primary)]">
        <Network class="size-4 text-blue-500" />
        <span>آدرس پروکسی (Proxy URL) - اختیاری</span>
      </Label>
      <Input
        id="proxy_url"
        name="proxy_url"
        type="text"
        placeholder="مثال: http://127.0.0.1:7890 یا socks5://127.0.0.1:1080"
        bind:value={proxyUrl}
        class="font-mono text-xs"
      />
      <p class="text-[11px] text-[var(--text-subtle)] leading-relaxed">
        برای کشورها یا شبکه‌هایی که دسترسی به سرویس‌های هوش مصنوعی (مانند OpenAI) با محدودیت روبه‌رو است، می‌توانید آدرس پروکسی HTTP یا SOCKS5 اختصاصی خود را وارد نمایید.
      </p>
    </div>

    <!-- Custom API Base URL -->
    <div class="space-y-2">
      <Label for="api_url" class="flex items-center gap-2 text-xs font-bold text-[var(--text-primary)]">
        <Globe class="size-4 text-purple-500" />
        <span>آدرس پایه API (Base URL)</span>
      </Label>
      <Input
        id="api_url"
        name="api_url"
        type="text"
        placeholder="https://api.openai.com/v1"
        bind:value={apiUrl}
        class="font-mono text-xs"
      />
      <p class="text-[11px] text-[var(--text-subtle)]">
        مسیریابی پیش‌فرض OpenAI است. همچنین می‌توانید از OpenRouter (https://openrouter.ai/api/v1)، DeepSeek (https://api.deepseek.com/v1) یا مدل‌های محلی استفاده کنید.
      </p>
    </div>

    <!-- Model Name Selection -->
    <div class="space-y-2">
      <Label for="model_name" class="flex items-center gap-2 text-xs font-bold text-[var(--text-primary)]">
        <Cpu class="size-4 text-emerald-500" />
        <span>نام مدل (Model Identifier)</span>
      </Label>
      <Input
        id="model_name"
        name="model_name"
        type="text"
        placeholder="gpt-4o-mini"
        bind:value={modelName}
        class="font-mono text-xs"
      />

      <div class="flex flex-wrap gap-2 pt-1">
        {#each popularModels as item}
          <button
            type="button"
            onclick={() => (modelName = item.value)}
            class="rounded-lg border border-[var(--border-faint)] bg-[var(--bg-subtle)] px-2.5 py-1 text-[11px] font-medium text-[var(--text-secondary)] hover:border-amber-500/50 hover:text-amber-400 transition-colors"
          >
            {item.label}
          </button>
        {/each}
      </div>
    </div>

    <!-- Submit Button -->
    <div class="flex items-center justify-end pt-4 border-t border-[var(--border-faint)]">
      <Button type="submit" disabled={isLoading} class="gap-2 bg-amber-500 font-medium text-black hover:bg-amber-400">
        {#if isLoading}
          <Loader2 class="size-4 animate-spin" />
          <span>در حال ذخیره...</span>
        {:else}
          <CheckCircle2 class="size-4" />
          <span>ذخیره تنظیمات هوش مصنوعی</span>
        {/if}
      </Button>
    </div>
  </form>
</div>
