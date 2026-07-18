<script>
  import '../../../app.css';
  import { enhance } from '$app/forms';
  import { goto } from '$app/navigation';
  import { _ } from '$lib/i18n';
  import imgLogo from '$lib/assets/images/logo.png';
  import { ArrowRight, Smartphone, Lock, AlertCircle, MessageSquareText } from '@lucide/svelte';

  let { form, data } = $props();

  let isSubmitting = $state(false);
  let loginMode = $state('password'); // 'password' | 'otp' | 'verify'
  let otpPhone = $state('');
  let otpSent = $state(false);

  $effect(() => {
    if (form?.success && !form?.otpRequired) {
      // Sync tokens to localStorage for client-side api.js compatibility
      if (form?.tokens) {
        if (typeof window !== 'undefined') {
          localStorage.setItem('access_token', form.tokens.access);
          localStorage.setItem('refresh_token', form.tokens.refresh);
        }
      }
      goto('/org');
    }
  });

  // Watch form for OTP sent status changes
  $effect(() => {
    if (form?.otpSent) {
      otpSent = true;
      isSubmitting = false;
    }
    if (form?.error) {
      isSubmitting = false;
    }
  });

  function switchToOtp() {
    loginMode = 'otp';
    otpPhone = '';
    otpSent = false;
  }

  function switchToPassword() {
    loginMode = 'password';
    otpSent = false;
  }

  function handleOtpRequest() {
    isSubmitting = true;
    // The form submission is handled by use:enhance
  }
</script>

<svelte:head>
  <title>{$_('login.page_title')}</title>
  <meta name="description" content={$_('login.description')} />
</svelte:head>

<div class="login-page">
  <div class="login-wrapper">
    <a href="/" class="logo">
      <img src={imgLogo} alt={$_('app.name')} class="logo-icon" />
      <span class="logo-text">{$_('app.name')}</span>
    </a>

    <div class="login-card">
      <h1 class="login-title">
        {loginMode === 'password' ? $_('login.title') : $_('login.otp_title')}
      </h1>

      <!-- Tab switcher -->
      <div class="mode-switcher">
        <button
          type="button"
          class="mode-btn"
          class:active={loginMode === 'password'}
          onclick={switchToPassword}
        >
          <Lock size={14} />
          {$_('login.password_tab')}
        </button>
        <button
          type="button"
          class="mode-btn"
          class:active={loginMode === 'otp' || loginMode === 'verify'}
          onclick={switchToOtp}
        >
          <MessageSquareText size={14} />
          {$_('login.otp_tab')}
        </button>
      </div>

      {#if loginMode === 'password'}
        <form method="POST" action="?/password" use:enhance class="login-form">
          <div class="input-group">
            <label for="phone" class="input-label">{$_('login.phone_label')}</label>
            <div class="input-wrapper">
              <Smartphone class="input-icon" size={18} />
              <input
                type="tel"
                id="phone"
                name="phone"
                placeholder={$_('login.phone_placeholder')}
                class="text-input"
                required
                autocomplete="username"
                disabled={isSubmitting}
              />
            </div>
          </div>

          <div class="input-group">
            <label for="password" class="input-label">{$_('login.password_label')}</label>
            <div class="input-wrapper">
              <Lock class="input-icon" size={18} />
              <input
                type="password"
                id="password"
                name="password"
                placeholder={$_('login.password_placeholder')}
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
              <span>{$_('login.submitting_login')}</span>
            {:else}
              <span>{$_('login.submit_login')}</span>
              <ArrowRight size={18} />
            {/if}
          </button>
        </form>
      {:else if loginMode === 'otp'}
        <form method="POST" action="?/requestOTP" use:enhance class="login-form">
          <div class="input-group">
            <label for="otp-phone" class="input-label">{$_('login.phone_label')}</label>
            <div class="input-wrapper">
              <Smartphone class="input-icon" size={18} />
              <input
                type="tel"
                id="otp-phone"
                name="phone"
                placeholder={$_('login.phone_placeholder')}
                class="text-input"
                required
                autocomplete="username"
                bind:value={otpPhone}
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

          {#if otpSent}
            <div class="success-box">
              <span>{$_('login.otp_code_sent')}</span>
            </div>
            {#if otpPhone}
              <p class="hint-text">{$_('login.otp_code_hint', { phone: otpPhone })}</p>
            {/if}
          {:else}
            <button type="submit" class="submit-btn" onclick={handleOtpRequest} disabled={isSubmitting}>
              {#if isSubmitting}
                <span class="spinner"></span>
                <span>{$_('login.sending_code')}</span>
              {:else}
                <span>{$_('login.submit_send_code')}</span>
                <ArrowRight size={18} />
              {/if}
            </button>
          {/if}
        </form>

        {#if otpSent}
          <form method="POST" action="?/verifyOTP" use:enhance class="login-form" style="margin-top: 1rem">
            <input type="hidden" name="phone" value={otpPhone} />
            <div class="input-group">
              <label for="otp-code" class="input-label">{$_('login.otp_code_label')}</label>
              <div class="input-wrapper">
                <MessageSquareText class="input-icon" size={18} />
                <input
                  type="text"
                  id="otp-code"
                  name="code"
                  placeholder={$_('login.otp_code_placeholder')}
                  class="text-input"
                  required
                  maxlength="6"
                  pattern="[0-9]{6}"
                  autocomplete="one-time-code"
                  disabled={isSubmitting}
                />
              </div>
            </div>
            <button type="submit" class="submit-btn" disabled={isSubmitting}>
              {#if isSubmitting}
                <span class="spinner"></span>
                <span>{$_('login.submitting_login')}</span>
              {:else}
                <span>{$_('login.submit_login')}</span>
                <ArrowRight size={18} />
              {/if}
            </button>
          </form>
        {/if}
      {/if}
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

  .mode-switcher {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
    background: #f0f4f8;
    border-radius: 8px;
    padding: 3px;
  }

  .mode-btn {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.375rem;
    padding: 0.625rem 0.75rem;
    border: none;
    border-radius: 6px;
    font-size: 0.8125rem;
    font-weight: 500;
    color: #516f90;
    background: transparent;
    cursor: pointer;
    transition: all 0.15s ease;
  }

  .mode-btn.active {
    background: #fff;
    color: #33475b;
    box-shadow: 0 1px 2px rgba(0,0,0,0.06);
    font-weight: 600;
  }

  .mode-btn:hover:not(.active) {
    color: #33475b;
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

  .success-box {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: #f0fff4;
    border: 1px solid #d4ffd4;
    border-radius: 6px;
    color: #27ae60;
    font-size: 0.875rem;
    font-weight: 500;
  }

  .hint-text {
    font-size: 0.8125rem;
    color: #516f90;
    text-align: center;
    margin: 0.5rem 0 0;
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
