import { writable, derived } from 'svelte/store';
import en from './en.json';
import fa from './fa.json';

const locales = { en, fa };

function resolve(obj, path) {
  return path.split('.').reduce((acc, part) => acc?.[part], obj);
}

export const locale = writable('fa');
export const dir = derived(locale, ($locale) => ($locale === 'fa' ? 'rtl' : 'ltr'));

export const _ = derived(locale, ($locale) => {
  return (key, params = {}) => {
    let text = resolve(locales[$locale], key) ?? resolve(locales.en, key) ?? key;
    Object.entries(params).forEach(([k, v]) => {
      text = String(text).replace(`{{${k}}}`, v);
    });
    return text;
  };
});
