<script>
  import { page } from '$app/stores';
  import { _ } from '$lib/i18n';
  import ErrorPage from '$lib/components/ErrorPage.svelte';
</script>

<svelte:head>
  <title>{$page.status} {$page.status === 404 ? $_('errors.not_found') : $_('errors.error')} | BottleCRM</title>
</svelte:head>

<ErrorPage status={$page.status} message={$page.error?.message ?? ''} />
