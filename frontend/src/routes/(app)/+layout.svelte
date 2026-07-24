<script>
  import '../../app.css';
  import { navigating } from '$app/stores';
  import { AppShell } from '$lib/components/layout/index.js';
  import Toast from '$lib/components/ui/toast/toast.svelte';
  import { initOrgSettings } from '$lib/stores/org.js';

  let { data, children } = $props();

  // Initialize org settings store from server data
  $effect(() => {
    if (data.org_settings) {
      initOrgSettings(data.org_settings);
    }
    // Sync auth data to localStorage for client-side API compatibility
    if (typeof window !== 'undefined') {
      if (data.org_id) {
        localStorage.setItem('org_id', data.org_id);
      }
      if (data.jwt_access) {
        localStorage.setItem('access_token', data.jwt_access);
      }
    }
  });
</script>

{#if $navigating}
  <div class="fixed top-0 left-0 right-0 z-[9999] h-1 bg-gradient-to-r from-amber-500 via-orange-500 to-amber-300 animate-pulse shadow-md"></div>
{/if}

<AppShell user={data.user} profile={data.profile} org_name={data.org_name} org_settings={data.org_settings}>
  <main class="relative flex-1">
    <div class="mx-auto w-full max-w-[1600px]">
      {@render children()}
    </div>
  </main>
</AppShell>

<Toast />
