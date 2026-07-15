import Toast from './toast.svelte';
import { writable } from 'svelte/store';

export const toasts = writable([]);

let counter = 0;

export function showToast(message, type = 'info', duration = 4000) {
  const id = ++counter;
  toasts.update((t) => [...t, { id, message, type, duration }]);
  if (duration > 0) {
    setTimeout(() => {
      toasts.update((t) => t.filter((toast) => toast.id !== id));
    }, duration);
  }
  return id;
}

export const toast = {
  success: (msg) => showToast(msg, 'success'),
  error: (msg) => showToast(msg, 'error', 6000),
  info: (msg) => showToast(msg, 'info'),
};
