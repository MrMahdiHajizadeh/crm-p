<script>
  import '../../app.css';
  import { AppShell } from '$lib/components/layout/index.js';
  import Toast from '$lib/components/ui/toast/toast.svelte';
  import { initOrgSettings } from '$lib/stores/org.js';

  let { data, children } = $props();

  // Initialize org settings store from server data
  $effect(() => {
    if (data.org_settings) {
      initOrgSettings(data.org_settings);
    }
  });
</script>

<AppShell user={data.user} org_name={data.org_name} org_settings={data.org_settings}>
  <main class="relative flex-1">
    {@render children()}
  </main>
</AppShell>

<Toast />
