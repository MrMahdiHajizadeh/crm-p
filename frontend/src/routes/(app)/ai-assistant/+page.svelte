<script>
  import { _ } from '$lib/i18n';
  import { onMount, tick } from 'svelte';
  import { browser } from '$app/environment';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Sparkles,
    Plus,
    Trash2,
    Send,
    Bot,
    User,
    ChevronRight,
    ChevronLeft,
    ChevronDown,
    Database,
    ShieldCheck,
    MessageSquare,
    Loader2,
    Settings,
    HelpCircle,
    BarChart3,
    Clock,
    Target,
    Users,
    DollarSign,
    Menu,
    X,
    FileText,
    TrendingUp,
    History,
    Search,
    Eye,
    ShieldAlert
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { apiRequest as clientApi } from '$lib/api.js';

  /** @type {{ data: any }} */
  let { data } = $props();

  let sessions = $state(/** @type {any[]} */ (data.sessions || []));
  let currentSessionId = $state(/** @type {string | null} */ (null));
  let messages = $state(/** @type {any[]} */ ([]));
  let promptInput = $state('');
  let isSending = $state(false);
  let isLoadingHistory = $state(false);

  // Top History Dropdown Toggle & Admin Oversight Filter
  let showHistoryDropdown = $state(false);
  let activeTab = $state('my_chats'); // 'my_chats' | 'all_team'

  // Track which message reasoning drawers are expanded
  let expandedEvidence = $state(/** @type {{ [key: string]: boolean }} */ ({}));

  let chatContainer = $state(/** @type {HTMLElement | null} */ (null));

  const aiSettings = $derived(data.aiSettings || {});

  onMount(() => {
    sessions = data.sessions || [];
    if (sessions.length > 0 && !currentSessionId) {
      selectSession(sessions[0].id);
    }
  });

  async function scrollToBottom() {
    await tick();
    if (chatContainer) {
      chatContainer.scrollTop = chatContainer.scrollHeight;
    }
  }

  async function fetchSessions(tab = 'my_chats') {
    activeTab = tab;
    try {
      const url = tab === 'all_team' ? '/ai/sessions/?all_team=true' : '/ai/sessions/';
      const res = await clientApi(url);
      sessions = res || [];
    } catch (err) {
      toast.error('خطا در دریافت لیست گفتگوها');
    }
  }

  async function createNewSession() {
    try {
      const res = await clientApi('/ai/sessions/', {
        method: 'POST',
        body: { title: 'گفتگوی جدید' }
      });
      sessions = [res, ...sessions];
      await selectSession(res.id);
      showHistoryDropdown = false;
    } catch (err) {
      toast.error('خطا در ایجاد گفتگوی جدید');
    }
  }

  async function selectSession(sessionId) {
    currentSessionId = sessionId;
    showHistoryDropdown = false;
    isLoadingHistory = true;
    try {
      const res = await clientApi(`/ai/sessions/${sessionId}/`);
      messages = res.messages || [];
      scrollToBottom();
    } catch (err) {
      console.error(err);
      toast.error('خطا در بارگذاری تاریخچه گفتگو');
    } finally {
      isLoadingHistory = false;
    }
  }

  async function deleteSession(sessionId, e) {
    e.stopPropagation();
    if (!confirm('آیا از حذف این گفتگو اطمینان دارید؟')) return;

    try {
      await clientApi(`/ai/sessions/${sessionId}/`, { method: 'DELETE' });
      sessions = sessions.filter((s) => s.id !== sessionId);
      if (currentSessionId === sessionId) {
        currentSessionId = sessions.length > 0 ? sessions[0].id : null;
        if (currentSessionId) {
          selectSession(currentSessionId);
        } else {
          messages = [];
        }
      }
      toast.success('گفتگو حذف شد');
    } catch (err) {
      toast.error('خطا در حذف گفتگو');
    }
  }

  async function sendMessage(textToSend = null) {
    const prompt = (textToSend || promptInput).trim();
    if (!prompt || isSending) return;

    if (!currentSessionId) {
      await createNewSession();
    }

    const tempUserMsg = {
      id: 'temp-' + Date.now(),
      role: 'user',
      content: prompt,
      created_at: new Date().toISOString()
    };

    messages = [...messages, tempUserMsg];
    promptInput = '';
    isSending = true;
    scrollToBottom();

    try {
      const res = await clientApi(`/ai/sessions/${currentSessionId}/message/`, {
        method: 'POST',
        body: { prompt }
      });

      messages = [...messages, res];

      const sessIdx = sessions.findIndex((s) => s.id === currentSessionId);
      if (sessIdx !== -1 && prompt.length > 0) {
        sessions[sessIdx].title = prompt.slice(0, 35) + (prompt.length > 35 ? '...' : '');
      }

      scrollToBottom();
    } catch (err) {
      console.error(err);
      toast.error(err?.message || 'خطا در دریافت پاسخ از هوش مصنوعی');
      messages = messages.filter((m) => m.id !== tempUserMsg.id);
    } finally {
      isSending = false;
    }
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }

  function toggleEvidence(msgId) {
    expandedEvidence[msgId] = !expandedEvidence[msgId];
  }

  const promptSuggestions = [
    {
      title: '🔍 جستجوی سرنخ با شماره یا ایمیل',
      prompt: 'اطلاعات کامل سرنخ با شماره 0912 یا ایمیل مورد نظرم رو پیدا کن و سوابقشو بگو.'
    },
    {
      title: '👤 جستجوی مخاطب یا شرکت با نام',
      prompt: 'مشخصات شرکت یا مخاطبی با نام عمارت یا حسینی چیست؟ تمام جزییاتش رو استخراج کن.'
    },
    {
      title: '💼 تحلیل فرصت‌های فروش',
      prompt: 'تحلیل جامع ارزش مالی پایپ‌لاین فرصت‌های فروش و مراحل پیشرفت معامله‌ها چیست؟'
    },
    {
      title: '⚠️ پیگیری‌ها و وظایف معوق',
      prompt: 'کدام وظایف و پیگیری‌ها عقب افتاده یا معوق شده‌اند؟ لیست موارد مهم با استدلال کامل داده‌ها را بگو.'
    }
  ];

  function formatMarkdown(text) {
    if (!text) return '';

    let content = text.replace(/\r\n/g, '\n');

    const tableRegex = /\|(.+)\|[\n]+\|[-:| ]+\|[\n]+((?:\|.+\|[\n]*)+)/g;
    content = content.replace(tableRegex, (match, headerRow, bodyRows) => {
      const headers = headerRow.split('|').map(h => h.trim()).filter(Boolean);
      const rows = bodyRows.trim().split('\n').map(r => r.split('|').map(c => c.trim()).filter(Boolean));

      let tableHtml = '<div class="overflow-x-auto my-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-1"><table class="w-full text-right text-xs border-collapse">';
      tableHtml += '<thead><tr class="border-b border-[var(--border-subtle)] bg-[var(--bg-muted)]/60 text-amber-400 font-bold">';
      headers.forEach(h => { tableHtml += `<th class="p-2.5">${h}</th>`; });
      tableHtml += '</tr></thead><tbody>';

      rows.forEach((row, i) => {
        if (row.length === 0) return;
        tableHtml += `<tr class="border-b border-[var(--border-faint)]/50 ${i % 2 === 0 ? 'bg-[var(--bg-elevated)]/40' : ''}">`;
        row.forEach(cell => { tableHtml += `<td class="p-2.5 text-[var(--text-primary)]">${cell}</td>`; });
        tableHtml += '</tr>';
      });

      tableHtml += '</tbody></table></div>';
      return tableHtml;
    });

    let formatted = content
      .replace(/### (.*?)(?:\n|$)/g, '<h3 class="text-base font-bold text-amber-400 my-2 flex items-center gap-1.5"><span class="size-2 rounded-full bg-amber-500"></span>$1</h3>')
      .replace(/#### (.*?)(?:\n|$)/g, '<h4 class="text-sm font-bold text-[var(--text-primary)] my-2 text-amber-300">$1</h4>')
      .replace(/\*\*(.*?)\*\*/g, '<strong class="font-bold text-[var(--text-primary)]">$1</strong>')
      .replace(/`([^`]+)`/g, '<code class="bg-amber-500/10 text-amber-300 px-1.5 py-0.5 rounded text-xs font-mono">$1</code>')
      .replace(/\*(.*?)\*/g, '<em class="text-amber-200/80">$1</em>')
      .replace(/> (.*?)(?:\n|$)/g, '<blockquote class="border-r-4 border-amber-500 bg-amber-500/10 px-3.5 py-2 my-2 text-xs rounded-l-lg text-[var(--text-secondary)]">$1</blockquote>')
      .replace(/- (.*?)(?:\n|$)/g, '<li class="ms-4 list-disc text-xs sm:text-sm text-[var(--text-primary)] my-1">$1</li>')
      .replace(/\n/g, '<br />');

    return formatted;
  }
</script>

<svelte:head>
  <title>دستیار هوشمند و جستجوگر CRM - عمارت CRM</title>
</svelte:head>

<!-- FULL-WIDTH CHAT CONTAINER -->
<div class="flex h-screen flex-col overflow-hidden bg-[var(--bg)]">
  <!-- TOP NAVIGATION & CONTROLS BAR -->
  <header class="sticky top-0 z-30 flex items-center justify-between border-b border-[var(--border-subtle)] bg-[var(--bg-elevated)] px-4 py-3 sm:px-8 shadow-sm">
    
    <!-- Right side (RTL): Title & Bot Status -->
    <div class="flex items-center gap-3">
      <div class="flex size-10 items-center justify-center rounded-2xl bg-amber-500 text-black shadow-md">
        <Bot class="size-6" />
      </div>
      <div>
        <h1 class="text-sm sm:text-base font-bold text-[var(--text-primary)]">دستیار هوشمند و جستجوگر دیتابیس CRM</h1>
        <p class="text-[11px] text-[var(--text-tertiary)] flex items-center gap-1.5">
          <span class="size-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>جستجوی سراسری تمام فیلدها • مدل: <strong class="text-amber-400">{aiSettings.model_name || 'CRM Search & Data Engine'}</strong></span>
        </p>
      </div>
    </div>

    <!-- Left side (RTL): Top History Trigger & New Chat Actions -->
    <div class="flex items-center gap-2.5">
      <!-- New Chat Quick Action -->
      <Button
        onclick={createNewSession}
        size="sm"
        class="gap-1.5 bg-amber-500 text-black hover:bg-amber-400 font-bold text-xs rounded-xl shadow-sm"
      >
        <Plus class="size-4" />
        <span class="hidden sm:inline">گفتگوی جدید</span>
      </Button>

      <!-- TOP HISTORY DROPDOWN TRIGGER BUTTON WITH ADMIN OVERSIGHT TAB -->
      <div class="relative">
        <Button
          type="button"
          onclick={() => (showHistoryDropdown = !showHistoryDropdown)}
          variant="outline"
          size="sm"
          class="gap-2 text-xs border-[var(--border-subtle)] hover:border-amber-500/50 rounded-xl bg-[var(--bg-subtle)]"
        >
          <History class="size-4 text-amber-400" />
          <span>تاریخچه گفتگوها</span>
          <ChevronDown class="size-3.5 text-[var(--text-tertiary)] transition-transform {showHistoryDropdown ? 'rotate-180' : ''}" />
        </Button>

        <!-- TOP HISTORY DROPDOWN MENU POPOVER -->
        {#if showHistoryDropdown}
          <div
            role="button"
            tabindex="0"
            onclick={() => (showHistoryDropdown = false)}
            onkeydown={(e) => e.key === 'Escape' && (showHistoryDropdown = false)}
            class="fixed inset-0 z-40 bg-black/20"
          ></div>

          <div
            class="absolute left-0 mt-2 z-50 w-80 sm:w-96 rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-3 shadow-2xl space-y-2.5 animate-in fade-in slide-in-from-top-2"
          >
            <!-- Header Tabs for Admins (My Chats vs All Team Member Chats) -->
            <div class="flex items-center justify-between border-b border-[var(--border-subtle)] pb-2 px-1">
              <div class="flex items-center gap-1 bg-[var(--bg-subtle)] p-1 rounded-xl">
                <button
                  type="button"
                  onclick={() => fetchSessions('my_chats')}
                  class="px-2.5 py-1 text-[11px] font-bold rounded-lg transition-all {activeTab === 'my_chats' ? 'bg-amber-500 text-black shadow-sm' : 'text-[var(--text-tertiary)] hover:text-[var(--text-primary)]'}"
                >
                  گفتگوهای من
                </button>
                <button
                  type="button"
                  onclick={() => fetchSessions('all_team')}
                  class="px-2.5 py-1 text-[11px] font-bold rounded-lg transition-all flex items-center gap-1 {activeTab === 'all_team' ? 'bg-amber-500 text-black shadow-sm' : 'text-[var(--text-tertiary)] hover:text-[var(--text-primary)]'}"
                >
                  <Eye class="size-3" />
                  گفتگوهای اعضای تیم
                </button>
              </div>

              <Button
                variant="ghost"
                size="sm"
                onclick={createNewSession}
                class="text-[11px] text-amber-400 hover:text-amber-300 p-1"
              >
                + جدید
              </Button>
            </div>

            <!-- Sessions List -->
            <div class="max-h-80 overflow-y-auto space-y-1 pe-1">
              {#each sessions as session (session.id)}
                <div
                  role="button"
                  tabindex="0"
                  onclick={() => selectSession(session.id)}
                  onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && selectSession(session.id)}
                  class="group flex items-center justify-between rounded-xl px-3 py-2.5 text-xs font-medium cursor-pointer transition-all {currentSessionId === session.id ? 'bg-amber-500/15 text-amber-400 font-bold border border-amber-500/30' : 'text-[var(--text-secondary)] hover:bg-[var(--bg-muted)] hover:text-[var(--text-primary)]'}"
                >
                  <div class="flex flex-col gap-0.5 truncate max-w-[85%]">
                    <div class="flex items-center gap-2 truncate">
                      <MessageSquare class="size-3.5 shrink-0 text-amber-400 opacity-80" />
                      <span class="truncate">{session.title || 'گفتگوی جدید'}</span>
                    </div>
                    {#if activeTab === 'all_team'}
                      <span class="text-[10px] text-amber-400/80 ps-5 font-normal">
                        توسط: {session.user_name} ({session.user_phone})
                      </span>
                    {/if}
                  </div>
                  <button
                    type="button"
                    onclick={(e) => deleteSession(session.id, e)}
                    class="opacity-0 group-hover:opacity-100 p-1 text-rose-400 hover:text-rose-300 transition-opacity"
                    title="حذف گفتگو"
                  >
                    <Trash2 class="size-3.5" />
                  </button>
                </div>
              {:else}
                <div class="p-6 text-center text-xs text-[var(--text-tertiary)] space-y-1">
                  <MessageSquare class="size-6 mx-auto text-[var(--text-subtle)] opacity-50" />
                  <p>هیچ گفتگویی یافت نشد.</p>
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </div>
    </div>
  </header>

  <!-- MESSAGES STREAM CONTAINER (FULL WIDTH MAX-W-5XL CENTERED) -->
  <div bind:this={chatContainer} class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-6">
    <div class="mx-auto max-w-5xl space-y-6">
      {#if isLoadingHistory}
        <div class="flex flex-col items-center justify-center py-20 gap-3 text-xs text-[var(--text-subtle)]">
          <Loader2 class="size-7 animate-spin text-amber-500" />
          <span>در حال جستجوی اطلاعات و رکوردهای دیتابیس CRM...</span>
        </div>
      {:else if messages.length === 0}
        <!-- Welcome Prompt Suggestion Cards -->
        <div class="py-8 space-y-6">
          <div class="text-center space-y-3">
            <div class="inline-flex size-16 items-center justify-center rounded-2xl bg-gradient-to-br from-amber-500/20 to-amber-500/5 border border-amber-500/30 text-amber-400 shadow-md">
              <Sparkles class="size-8" />
            </div>
            <h2 class="text-xl font-bold text-[var(--text-primary)]">جستجو یا گزارش مورد نظرتان را بنویسید</h2>
            <p class="text-xs sm:text-sm text-[var(--text-secondary)] leading-relaxed max-w-xl mx-auto">
              می‌توانید شماره تلفن (مانند 0912)، نام سرنخ، ایمیل، نام شرکت یا سابقه پیگیری خاصی را جستجو کنید تا <strong>تمام مشخصات ثبت شده در دیتابیس همراه با دلیل</strong> بازیابی شود.
            </p>
          </div>

          <div class="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
            {#each promptSuggestions as item}
              <button
                type="button"
                onclick={() => sendMessage(item.prompt)}
                class="group flex flex-col text-right gap-1.5 rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-4.5 transition-all hover:border-amber-500/50 hover:shadow-lg hover:-translate-y-0.5"
              >
                <div class="flex items-center justify-between">
                  <span class="text-xs sm:text-sm font-bold text-[var(--text-primary)] group-hover:text-amber-400 transition-colors">{item.title}</span>
                  <ChevronLeft class="size-4 text-[var(--text-tertiary)] group-hover:text-amber-400 transition-colors" />
                </div>
                <span class="text-[11px] text-[var(--text-tertiary)] leading-relaxed">{item.prompt}</span>
              </button>
            {/each}
          </div>
        </div>
      {:else}
        <!-- Message Bubbles Stream -->
        {#each messages as msg (msg.id)}
          <div class="flex flex-col gap-2 {msg.role === 'user' ? 'items-start' : 'items-start'}">
            <!-- Role Header -->
            <div class="flex items-center gap-2 text-[11px] font-medium text-[var(--text-tertiary)] px-1">
              {#if msg.role === 'user'}
                <div class="flex size-5 items-center justify-center rounded-full bg-amber-500/20 text-amber-400">
                  <User class="size-3" />
                </div>
                <span class="text-amber-400 font-bold">سوال / درخواست کاربر</span>
              {:else}
                <div class="flex size-5 items-center justify-center rounded-full bg-amber-500 text-black font-bold">
                  <Bot class="size-3" />
                </div>
                <span class="text-[var(--text-primary)] font-bold">دستیار گزارش‌دهی و جستجوی CRM</span>
              {/if}
            </div>

            <!-- Bubble Content -->
            {#if msg.role === 'user'}
              <div class="max-w-[90%] sm:max-w-[80%] rounded-2xl border border-amber-500/30 bg-amber-500/10 p-4 text-xs sm:text-sm text-amber-200 leading-relaxed shadow-sm">
                <p class="whitespace-pre-wrap font-medium">{msg.content}</p>
              </div>
            {:else}
              <div class="w-full rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-5 text-xs sm:text-sm text-[var(--text-primary)] leading-relaxed shadow-md space-y-4">
                <div class="prose prose-invert max-w-none space-y-3">
                  {@html formatMarkdown(msg.content)}
                </div>

                <!-- EXPANDABLE DATA EVIDENCE & RATIONALE -->
                {#if msg.reasoning || msg.data_evidence}
                  <div class="mt-4 border-t border-[var(--border-subtle)] pt-3">
                    <button
                      type="button"
                      onclick={() => toggleEvidence(msg.id)}
                      class="flex items-center justify-between w-full rounded-xl border border-amber-500/20 bg-gradient-to-r from-amber-500/10 to-transparent px-4 py-2.5 text-xs font-bold text-amber-400 hover:border-amber-500/40 transition-all"
                    >
                      <div class="flex items-center gap-2">
                        <Database class="size-4 text-amber-400" />
                        <span>دلیل، منطق و شواهد استخراج‌شده از دیتابیس (DB Evidence)</span>
                      </div>
                      {#if expandedEvidence[msg.id]}
                        <ChevronDown class="size-4" />
                      {:else}
                        <ChevronRight class="size-4" />
                      {/if}
                    </button>

                    {#if expandedEvidence[msg.id]}
                      <div class="mt-3 space-y-3 rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] p-4 text-xs leading-relaxed">
                        {#if msg.reasoning}
                          <div class="space-y-1">
                            <span class="font-bold text-amber-400 flex items-center gap-1.5">
                              <TrendingUp class="size-3.5" />
                              منطق و دلیل تحلیل داده‌ها:
                            </span>
                            <p class="text-[11px] text-[var(--text-secondary)] leading-relaxed">{msg.reasoning}</p>
                          </div>
                        {/if}

                        {#if msg.data_evidence}
                          <div class="space-y-2.5 pt-3 border-t border-[var(--border-subtle)]">
                            <span class="font-bold text-[var(--text-primary)] flex items-center gap-1.5">
                              <BarChart3 class="size-3.5 text-blue-400" />
                              آمار و مستندات دیتابیس:
                            </span>

                            <div class="grid grid-cols-2 gap-2.5 sm:grid-cols-4 text-[11px]">
                              <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-2.5 space-y-1">
                                <span class="text-[10px] text-[var(--text-tertiary)]">کل سرنخ‌ها</span>
                                <p class="text-sm font-bold text-amber-400">{msg.data_evidence.leads?.total || 0}</p>
                              </div>
                              <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-2.5 space-y-1">
                                <span class="text-[10px] text-[var(--text-tertiary)]">مخاطبین سیستم</span>
                                <p class="text-sm font-bold text-purple-400">{msg.data_evidence.contacts_count || 0}</p>
                              </div>
                              <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-2.5 space-y-1">
                                <span class="text-[10px] text-[var(--text-tertiary)]">فرصت‌های فروش</span>
                                <p class="text-sm font-bold text-emerald-400">{msg.data_evidence.opportunities?.total_count || 0}</p>
                              </div>
                              <div class="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-2.5 space-y-1">
                                <span class="text-[10px] text-[var(--text-tertiary)]">وظایف عقب‌افتاده</span>
                                <p class="text-sm font-bold text-rose-400">{msg.data_evidence.tasks?.overdue || 0}</p>
                              </div>
                            </div>
                          </div>
                        {/if}
                      </div>
                    {/if}
                  </div>
                {/if}
              </div>
            {/if}
          </div>
        {/each}

        {#if isSending}
          <div class="flex items-center gap-3 text-xs text-amber-400 bg-amber-500/10 border border-amber-500/30 rounded-2xl p-4 w-fit shadow-sm">
            <Loader2 class="size-5 animate-spin shrink-0 text-amber-500" />
            <span>در حال جستجوی دقیق در تمام فیلدها و استخراج مشخصات از دیتابیس CRM...</span>
          </div>
        {/if}
      {/if}
    </div>
  </div>

  <!-- PROMPT INPUT FOOTER (FULL WIDTH MAX-W-5XL CENTERED) -->
  <footer class="border-t border-[var(--border-subtle)] bg-[var(--bg-elevated)] p-3.5 sm:px-8 shadow-lg">
    <div class="mx-auto max-w-5xl space-y-2">
      <div class="relative flex items-center rounded-2xl border border-[var(--border-subtle)] bg-[var(--bg-subtle)] focus-within:border-amber-500/70 focus-within:ring-1 focus-within:ring-amber-500/30 transition-all">
        <textarea
          bind:value={promptInput}
          onkeydown={handleKeyDown}
          placeholder="شماره تلفن، نام مخاطب، شرکت، ایمیل یا سوال خود را جهت جستجو در دیتابیس بنویسید..."
          rows="1"
          class="w-full resize-none bg-transparent px-4 py-3.5 text-xs sm:text-sm text-[var(--text-primary)] placeholder:text-[var(--text-tertiary)] focus:outline-none"
        ></textarea>
        <Button
          onclick={() => sendMessage()}
          disabled={!promptInput.trim() || isSending}
          class="me-2 size-10 shrink-0 bg-amber-500 text-black hover:bg-amber-400 disabled:opacity-40 rounded-xl shadow-md"
          size="icon"
        >
          {#if isSending}
            <Loader2 class="size-5 animate-spin" />
          {:else}
            <Send class="size-5" />
          {/if}
        </Button>
      </div>
      <p class="text-center text-[10px] text-[var(--text-tertiary)]">
        جستجو در تمام فیلدهای دیتابیس (سرنخ‌ها، مخاطبین، شرکت‌ها، پیگیری‌ها) همراه با استدلال و شواهد انجام می‌شود.
      </p>
    </div>
  </footer>
</div>
