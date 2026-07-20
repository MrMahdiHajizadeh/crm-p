<script>
  import { _ } from '$lib/i18n';
  import { enhance } from '$app/forms';
  import { invalidateAll } from '$app/navigation';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Plus,
    Copy,
    Check,
    Trash2,
    KeyRound,
    ChevronDown,
    ChevronRight,
    TriangleAlert
  } from '@lucide/svelte';
  import { PageHeader } from '$lib/components/layout';
  import { Button } from '$lib/components/ui/button/index.js';
  import { Input } from '$lib/components/ui/input/index.js';
  import { Label } from '$lib/components/ui/label/index.js';
  import * as Table from '$lib/components/ui/table/index.js';
  import { Badge } from '$lib/components/ui/badge/index.js';

  /** @type {{ data: any, form: any }} */
  let { data, form } = $props();

  const tokens = $derived(data.tokens || []);
  // Real, ready-to-paste API host (e.g. https://api.bottlecrm.io). The MCP
  // client appends /api/... itself, so this is exactly BCRM_BASE_URL.
  const baseUrl = $derived(data.baseUrl || 'https://api.bottlecrm.io');

  let formName = $state('');
  let formExpiresAt = $state('');
  let creating = $state(false);

  // Copy-once panel state � populated only from the create action result.
  let copied = $state(false);
  /** @type {string} */
  let confirmingId = $state('');
  let helpOpen = $state(false);
  let configCopied = $state(false);
  let selectedClient = $state('claude');

  // The just-created raw token if we have it, else a paste-your-token hint. We
  // can only ever show the real token in the same response that created it.
  const tokenValue = $derived(form?.created?.token || 'bcrm_pat_�paste-your-token');

  /**
   * MCP clients we give a ready-to-paste config for. Claude Desktop, Cursor and
   * Gemini CLI share the identical `mcpServers` JSON schema (only the config
   * file differs); Codex CLI uses TOML.
   */
  const CLIENTS = [
    { id: 'claude', label: 'Claude Desktop', lang: 'json', file: 'claude_desktop_config.json � Settings ? Developer ? Edit Config' },
    { id: 'cursor', label: 'Cursor', lang: 'json', file: '~/.cursor/mcp.json (global) or .cursor/mcp.json (per project)' },
    { id: 'codex', label: 'Codex CLI', lang: 'toml', file: '~/.codex/config.toml' },
    { id: 'gemini', label: 'Gemini CLI', lang: 'json', file: '~/.gemini/settings.json' }
  ];

  /** @param {string} base @param {string} token */
  function jsonConfig(base, token) {
    return `{
  "mcpServers": {
    "bottlecrm": {
      "command": "uvx",
      "args": ["bcrm-mcp"],
      "env": {
        "BCRM_BASE_URL": "${base}",
        "BCRM_TOKEN": "${token}"
      }
    }
  }
}`;
  }

  /** @param {string} base @param {string} token */
  function tomlConfig(base, token) {
    return `[mcp_servers.bottlecrm]
command = "uvx"
args = ["bcrm-mcp"]

[mcp_servers.bottlecrm.env]
BCRM_BASE_URL = "${base}"
BCRM_TOKEN = "${token}"`;
  }

  const selectedClientMeta = $derived(
    CLIENTS.find((c) => c.id === selectedClient) || CLIENTS[0]
  );
  const configSnippet = $derived(
    selectedClientMeta.lang === 'toml'
      ? tomlConfig(baseUrl, tokenValue)
      : jsonConfig(baseUrl, tokenValue)
  );

  $effect(() => {
    if (form?.created?.token) {
      // Reset the create form after a successful creation.
      formName = '';
      formExpiresAt = '';
      copied = false;
      // Surface the connect instructions immediately � the config now carries
      // the real token, which the user can only copy from this one response.
      helpOpen = true;
    } else if (form?.revoked) {
      toast.success('Token revoked');
      confirmingId = '';
    } else if (form?.error) {
      const message = typeof form.error === 'string' ? form.error : JSON.stringify(form.error);
      toast.error(message);
    }
  });

  /** @param {string} value */
  async function copyToClipboard(value) {
    try {
      await navigator.clipboard.writeText(value);
      copied = true;
      toast.success('Token copied to clipboard');
      setTimeout(() => (copied = false), 2000);
    } catch {
      toast.error('Could not copy � select and copy manually');
    }
  }

  /** @param {string} value */
  async function copyConfig(value) {
    try {
      await navigator.clipboard.writeText(value);
      configCopied = true;
      toast.success('Config copied to clipboard');
      setTimeout(() => (configCopied = false), 2000);
    } catch {
      toast.error('Could not copy � select and copy manually');
    }
  }

  /** @param {string | null | undefined} value */
  function formatDate(value) {
    if (!value) return 'Never';
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return 'Never';
    return d.toLocaleDateString('fa-IR-u-ca-persian', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  }

  /** @param {any} token */
  function isRevoked(token) {
    return !!token.revoked_at;
  }
</script>

<svelte:head>
  <title>{$_('settings.api_tokens')} - {$_('app.name')}</title>
</svelte:head>

<PageHeader
  title={$_('settings.api_tokens')}
  subtitle={$_('settings.api_tokens_subtitle')}
/>

<div class="flex-1 p-4 md:p-6 lg:p-8">
  <div class="mx-auto max-w-4xl space-y-6">
    {#if data.loadError}
      <div
        class="rounded-lg border border-[var(--color-danger-default)] bg-[var(--color-danger-light)] p-4 text-sm text-[var(--color-danger-default)]"
      >
        {data.loadError}
      </div>
    {/if}

    <!-- Copy-once panel: only shown immediately after a create action. -->
    {#if form?.created?.token}
      <section
        class="rounded-lg border border-amber-300 bg-amber-50 p-4 dark:border-amber-700 dark:bg-amber-900/30"
      >
        <div class="flex items-start gap-2">
          <TriangleAlert class="mt-0.5 h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
          <div class="min-w-0 flex-1 space-y-2">
        <h2 class="text-sm font-medium text-amber-900 dark:text-amber-200">
          {$_('settings.token_created', { name: form.created.name })}
        </h2>
            <p class="text-sm text-amber-800 dark:text-amber-300">
              {$_('settings.copy_token_now')}
            </p>
            <div class="flex items-center gap-2">
              <code
                class="min-w-0 flex-1 overflow-x-auto rounded-md border border-amber-300 bg-white px-3 py-2 font-mono text-xs text-[var(--text-primary)] dark:border-amber-700 dark:bg-slate-900"
              >
                {form.created.token}
              </code>
              <Button
                type="button"
                size="sm"
                class="gap-1"
                onclick={() => copyToClipboard(form.created.token)}
              >
                {#if copied}
                  <Check class="h-4 w-4" />
                  {$_('common.copied')}
                {:else}
                  <Copy class="h-4 w-4" />
                  {$_('common.copy')}
                {/if}
              </Button>
            </div>
          </div>
        </div>
      </section>
    {/if}

    <!-- Create token -->
    <section class="rounded-lg border border-[var(--border-default)] bg-[var(--surface-default)]">
      <header class="border-b border-[var(--border-default)] p-4">
        <h2 class="text-base font-medium text-[var(--text-primary)]">{$_('settings.create_token')}</h2>
        <p class="text-sm text-[var(--text-secondary)]">
          {$_('settings.create_token_hint')}
        </p>
      </header>
      <form
        method="POST"
        action="?/create"
        use:enhance={() => {
          creating = true;
          return async ({ update }) => {
            await update({ reset: false });
            creating = false;
            await invalidateAll();
          };
        }}
        class="flex flex-col gap-4 p-4 sm:flex-row sm:items-end"
      >
        <div class="flex-1 space-y-1.5">
          <Label for="name">{$_('common.name')} *</Label>
          <Input id="name" name="name" required bind:value={formName} placeholder={$_('settings.token_name_placeholder')} />
        </div>
        <div class="space-y-1.5">
          <Label for="expires_at">{$_('settings.expires_optional')}</Label>
          <Input id="expires_at" name="expires_at" type="date" bind:value={formExpiresAt} />
        </div>
        <Button type="submit" class="gap-2" disabled={creating}>
          <Plus class="h-4 w-4" />
          {creating ? $_('common.creating') : $_('settings.create_token')}
        </Button>
      </form>
    </section>

    <!-- Existing tokens -->
    <section class="rounded-lg border border-[var(--border-default)] bg-[var(--surface-default)]">
      <header class="border-b border-[var(--border-default)] p-4">
        <h2 class="text-base font-medium text-[var(--text-primary)]">{$_('settings.your_tokens')}</h2>
        <p class="text-sm text-[var(--text-secondary)]">
          {$_('settings.your_tokens_hint')}
        </p>
      </header>

      {#if tokens.length === 0}
        <div class="p-6 text-center text-sm text-[var(--text-secondary)]">
          {$_('settings.no_tokens')}
        </div>
      {:else}
        <Table.Root>
          <Table.Header>
            <Table.Row>
              <Table.Head>{$_('common.name')}</Table.Head>
              <Table.Head>{$_('settings.prefix')}</Table.Head>
              <Table.Head>{$_('settings.last_used')}</Table.Head>
              <Table.Head>{$_('settings.expires')}</Table.Head>
              <Table.Head>{$_('settings.created')}</Table.Head>
              <Table.Head>{$_('common.status')}</Table.Head>
              <Table.Head class="text-end">{$_('common.actions')}</Table.Head>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {#each tokens as token (token.id)}
              <Table.Row>
                <Table.Cell class="font-medium text-[var(--text-primary)]">
                  {token.name}
                </Table.Cell>
                <Table.Cell>
                  <code class="font-mono text-xs text-[var(--text-secondary)]">
                    {token.token_prefix}
                  </code>
                </Table.Cell>
                <Table.Cell class="text-sm text-[var(--text-secondary)]">
                  {formatDate(token.last_used_at)}
                </Table.Cell>
                <Table.Cell class="text-sm text-[var(--text-secondary)]">
                  {formatDate(token.expires_at)}
                </Table.Cell>
                <Table.Cell class="text-sm text-[var(--text-secondary)]">
                  {formatDate(token.created_at)}
                </Table.Cell>
                <Table.Cell>
                  {#if isRevoked(token)}
                    <Badge variant="secondary">{$_('common.revoked')}</Badge>
                  {:else}
                    <Badge variant="outline">{$_('common.active')}</Badge>
                  {/if}
                </Table.Cell>
                <Table.Cell class="text-end">
                  {#if !isRevoked(token)}
                    {#if confirmingId === token.id}
                      <form
                        method="POST"
                        action="?/revoke"
                        use:enhance={() => {
                          return async ({ update }) => {
                            await update({ reset: false });
                            await invalidateAll();
                          };
                        }}
                        class="inline-flex items-center gap-1"
                      >
                        <input type="hidden" name="id" value={token.id} />
                        <Button type="submit" variant="destructive" size="sm" class="gap-1">
                          <Check class="h-3.5 w-3.5" />
                          {$_('common.confirm')}
                        </Button>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onclick={() => (confirmingId = '')}
                        >
                          {$_('common.cancel')}
                        </Button>
                      </form>
                    {:else}
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        class="gap-1 text-[var(--color-danger-default)]"
                        onclick={() => (confirmingId = token.id)}
                      >
                        <Trash2 class="h-3.5 w-3.5" />
                        {$_('common.revoke')}
                      </Button>
                    {/if}
                  {:else}
                    <span class="text-xs text-[var(--text-secondary)]">�</span>
                  {/if}
                </Table.Cell>
              </Table.Row>
            {/each}
          </Table.Body>
        </Table.Root>
      {/if}
    </section>

    <!-- Help: connect your AI -->
    <section class="rounded-lg border border-[var(--border-default)] bg-[var(--surface-default)]">
      <button
        type="button"
        onclick={() => (helpOpen = !helpOpen)}
        class="flex w-full items-center gap-2 p-4 text-start"
      >
        {#if helpOpen}
          <ChevronDown class="h-4 w-4 text-[var(--text-secondary)]" />
        {:else}
          <ChevronRight class="h-4 w-4 text-[var(--text-secondary)]" />
        {/if}
        <KeyRound class="h-4 w-4 text-[var(--text-secondary)]" />
        <span class="text-base font-medium text-[var(--text-primary)]"> {$_('settings.connect_ai')} </span>
      </button>
      {#if helpOpen}
        <div class="space-y-3 border-t border-[var(--border-default)] p-4">
          <!-- Client picker -->
          <div class="flex flex-wrap gap-2">
            {#each CLIENTS as client (client.id)}
              <Button
                type="button"
                size="sm"
                variant={selectedClient === client.id ? 'default' : 'outline'}
                onclick={() => (selectedClient = client.id)}
              >
                {client.label}
              </Button>
            {/each}
          </div>

          <p class="text-sm text-[var(--text-secondary)]">
            Add this to
            <code class="font-mono text-xs text-[var(--text-primary)]">{selectedClientMeta.file}</code
            >, then restart {selectedClientMeta.label}.
            {#if form?.created?.token}
              The token below is yours � it's shown only this once.
            {:else}
              Replace <code class="font-mono text-xs">BCRM_TOKEN</code> with a token you created above.
            {/if}
          </p>

          <div class="relative">
            <Button
              type="button"
              size="sm"
              variant="outline"
              class="absolute right-2 top-2 gap-1"
              onclick={() => copyConfig(configSnippet)}
            >
              {#if configCopied}
                <Check class="h-3.5 w-3.5" />
                Copied
              {:else}
                <Copy class="h-3.5 w-3.5" />
                Copy
              {/if}
            </Button>
            <pre
              class="overflow-x-auto rounded-md border border-[var(--border-default)] bg-[var(--surface-muted)] p-3 pe-20 font-mono text-xs text-[var(--text-primary)]">{configSnippet}</pre>
          </div>

          <p class="text-xs text-[var(--text-secondary)]">
            Requires <a
              href="https://docs.astral.sh/uv/"
              target="_blank"
              rel="noopener noreferrer"
              class="underline">uv</a
            >
            (provides <code class="font-mono">uvx</code>) on your machine. The agent acts as you and
            inherits your role � it can't see or do anything you can't.
          </p>
        </div>
      {/if}
    </section>
  </div>
</div>
