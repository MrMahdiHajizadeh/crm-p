<script>
  import { locale, dir } from '$lib/i18n';
  import { onMount } from 'svelte';

  let { children } = $props();

  $effect(() => {
    const d = $dir;
    const isRtl = d === 'rtl';
    if (typeof document !== 'undefined') {
      document.documentElement.dir = d;
      document.documentElement.lang = isRtl ? 'fa' : 'en';
    }
  });

  let loaded = $state(false);
  onMount(() => { loaded = true; });
</script>

{@render children()}
