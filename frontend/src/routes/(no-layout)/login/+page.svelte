<script>
  import '../../../app.css';
  import { enhance } from '$app/forms';
  import { goto } from '$app/navigation';
  import { _ } from '$lib/i18n';
  import imgLogo from '$lib/assets/images/logo.png';
  import { ArrowRight, Smartphone, Lock, AlertCircle } from '@lucide/svelte';

  let { form } = $props();

  let isSubmitting = $state(false);

  $effect(() => {
    if (form?.success) {
      goto('/org');
    }
  });
</script>

<svelte:head>
  <title>{$_('login.page_title')}</title>
  <meta name="description" content={$_('login.description')} />
</svelte:head>

<div class="login-page">
  <div class="login-wrapper">
    <a href="/" class="logo">
      <img src={imgLogo} alt="" class="logo-icon" />
      <span class="logo-text">{$_('app.name')}</span>
    </a>

    <div class="login-card">
      <h1 class="login-title">{$_('login.title')}</h1>

      <form method="POST" use:enhance class="login-form">
        <div class="input-group">
          <label for="phone" class="input-label">تلفن همراه</label>
          <div class="input-wrapper">
            <Smartphone class="input-icon" size={18} />
            <input
              type="tel"
              id="phone"
              name="phone"
              placeholder="مثال: 09120000000"
              class="text-input"
              required
              autocomplete="username"
              disabled={isSubmitting}
            />
          </div>
        </div>

        <div class="input-group">
          <label for="password" class="input-label">رمز عبور</label>
          <div class="input-wrapper">
            <Lock class="input-icon" size={18} />
            <input
              type="password"
              id="password"
              name="password"
              placeholder="رمز عبور خود را وارد کنید"
              class="text-input"
              required
              autocomplete="current-password"
              disabled={isSubmitting}
            />
          </div>
        </div>

        {#if form?.error}
          <div class="error-box">
            <AlertCircle size={16} />
            <span>{form.error}</span>
          </div>
        {/if}

        <button type="submit" class="submit-btn" disabled={isSubmitting}>
          {#if isSubmitting}
            <span class="spinner"></span>
            <span>در حال ورود...</span>
          {:else}
            <span>ورود</span>
            <ArrowRight size={18} />
          {/if}
        </button>
      </form>
    </div>
  </div>
</div>

<style>
  .login-page {
    min-height: 100vh;
    min-height: 100dvh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f5f8fa;
    padding: 2rem;
  }

  .login-wrapper {
    width: 100%;
    max-width: 400px;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .logo {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    text-decoration: none;
    margin-bottom: 2rem;
  }

  .logo-icon {
    width: 40px;
    height: 40px;
    object-fit: contain;
  }

  .logo-text {
    font-size: 1.5rem;
    font-weight: 700;
    color: #33475b;
    letter-spacing: -0.02em;
  }

  .login-card {
    width: 100%;
    background: #fff;
    border-radius: 8px;
    padding: 2.5rem 2rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 4px 12px rgba(0,0,0,0.05);
  }

  .login-title {
    font-size: 1.5rem;
    font-weight: 600;
    color: #33475b;
    text-align: center;
    margin: 0 0 1.5rem;
  }

  .login-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .input-group {
    display: flex;
    flex-direction: column;
    gap: 0.375rem;
  }

  .input-label {
    font-size: 0.8125rem;
    font-weight: 600;
    color: #516f90;
  }

  .input-wrapper {
    position: relative;
    display: flex;
    align-items: center;
  }

  :global(.input-icon) {
    position: absolute;
    left: 12px;
    color: #cbd6e2;
    pointer-events: none;
  }

  .text-input {
    width: 100%;
    height: 48px;
    padding: 0 2.5rem 0 1rem;
    border: 1px solid #cbd6e2;
    border-radius: 6px;
    font-size: 1rem;
    color: #33475b;
    background: #fff;
    outline: none;
    transition: border-color 0.15s ease;
    box-sizing: border-box;
    direction: ltr;
    text-align: left;
  }

  .text-input:focus {
    border-color: #ff7a59;
  }

  .text-input:disabled {
    opacity: 0.6;
  }

  .error-box {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: #fff0f0;
    border: 1px solid #ffd4d4;
    border-radius: 6px;
    color: #c0392b;
    font-size: 0.875rem;
  }

  .submit-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    width: 100%;
    height: 48px;
    background: #ff7a59;
    border: none;
    border-radius: 6px;
    color: #fff;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: background-color 0.15s ease;
    margin-top: 0.5rem;
  }

  .submit-btn:hover {
    background: #ff5c35;
  }

  .submit-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .spinner {
    width: 18px;
    height: 18px;
    border: 2px solid rgba(255,255,255,0.3);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin 0.7s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  :global(.dark) .login-page {
    background: #1a1a1a;
  }

  :global(.dark) .login-card {
    background: #2d2d2d;
    box-shadow: 0 1px 3px rgba(0,0,0,0.2), 0 4px 12px rgba(0,0,0,0.15);
  }

  :global(.dark) .logo-text {
    color: #fff;
  }

  :global(.dark) .login-title {
    color: #fff;
  }

  :global(.dark) .text-input {
    background: #1a1a1a;
    border-color: #404040;
    color: #fff;
  }

  :global(.dark) .text-input:focus {
    border-color: #ff7a59;
  }

  :global(.dark) .input-label {
    color: #999;
  }

  :global(.dark) .submit-btn {
    background: #fff;
    color: #1a1a1a;
  }

  :global(.dark) .submit-btn:hover {
    background: #e0e0e0;
  }

  :global(.dark) .error-box {
    background: #3d1f1f;
    border-color: #5c3030;
    color: #ff6b6b;
  }
</style>
