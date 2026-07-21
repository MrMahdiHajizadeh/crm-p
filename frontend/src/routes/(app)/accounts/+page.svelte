<script>
  import { enhance } from '$app/forms';
  import { invalidateAll, goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { tick, onMount, untrack } from 'svelte';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Plus,
    Building2,
    Users,
    Target,
    Calendar,
    Eye,
    Globe,
    Phone,
    Mail,
    DollarSign,
    Briefcase,
    MapPin,
    FileText,
    Hash,
    Lock,
    Unlock,
    AlertTriangle,
    Tag,
    UserPlus,
    Contact,
    Banknote,
    CheckSquare,
    User
  } from '@lucide/svelte';
  import { PageHeader, FilterStrip, ViewTabs, FilterPill } from '$lib/components/layout';
  import { CrmDrawer } from '$lib/components/ui/crm-drawer';
  import { CommentSection } from '$lib/components/ui/comment-section';
  import { getCurrentUser } from '$lib/api.js';
  import { Button } from '$lib/components/ui/button/index.js';
  import * as DropdownMenu from '$lib/components/ui/dropdown-menu/index.js';
  import { CrmTable } from '$lib/components/ui/crm-table';
  import {
    SearchInput,
    SelectFilter,
    DateRangeFilter,
    TagFilter
  } from '$lib/components/ui/filter';
  import { Pagination } from '$lib/components/ui/pagination';
  import { formatRelativeDate, formatCurrency, getInitials } from '$lib/utils/formatting.js';
  import { COUNTRIES } from '$lib/constants/countries.js';
  import { CURRENCY_CODES } from '$lib/constants/filters.js';
  import { orgSettings } from '$lib/stores/org.js';
  import { _ } from '$lib/i18n';

  // Column visibility configuration
  const STORAGE_KEY = 'accounts-column-config';

  /**
   * @typedef {'text' | 'email' | 'number' | 'date' | 'select' | 'checkbox' | 'relation'} ColumnType
   * @typedef {{ key: string, label: string, type?: ColumnType, width?: string, editable?: boolean, canHide?: boolean, getValue?: (row: any) => any, emptyText?: string, relationIcon?: string, options?: any[], format?: (value: any) => string }} ColumnDef
   */

  // Industry options for drawer
  const industryOptions = [
    { value: 'ADVERTISING', get label() { return $_('industries.advertising'); } },
    { value: 'AGRICULTURE', get label() { return $_('industries.agriculture'); } },
    { value: 'APPAREL & ACCESSORIES', get label() { return $_('industries.apparel_accessories'); } },
    { value: 'AUTOMOTIVE', get label() { return $_('industries.automotive'); } },
    { value: 'BANKING', get label() { return $_('industries.banking'); } },
    { value: 'BIOTECHNOLOGY', get label() { return $_('industries.biotechnology'); } },
    { value: 'BUILDING MATERIALS & EQUIPMENT', get label() { return $_('industries.building_materials_equipment'); } },
    { value: 'CHEMICAL', get label() { return $_('industries.chemical'); } },
    { value: 'COMPUTER', get label() { return $_('industries.computer'); } },
    { value: 'EDUCATION', get label() { return $_('industries.education'); } },
    { value: 'ELECTRONICS', get label() { return $_('industries.electronics'); } },
    { value: 'ENERGY', get label() { return $_('industries.energy'); } },
    { value: 'ENTERTAINMENT & LEISURE', get label() { return $_('industries.entertainment_leisure'); } },
    { value: 'FINANCE', get label() { return $_('industries.finance'); } },
    { value: 'FOOD & BEVERAGE', get label() { return $_('industries.food_beverage'); } },
    { value: 'GROCERY', get label() { return $_('industries.grocery'); } },
    { value: 'HEALTHCARE', get label() { return $_('industries.healthcare'); } },
    { value: 'INSURANCE', get label() { return $_('industries.insurance'); } },
    { value: 'LEGAL', get label() { return $_('industries.legal'); } },
    { value: 'MANUFACTURING', get label() { return $_('industries.manufacturing'); } },
    { value: 'PUBLISHING', get label() { return $_('industries.publishing'); } },
    { value: 'REAL ESTATE', get label() { return $_('industries.real_estate'); } },
    { value: 'SERVICE', get label() { return $_('industries.service'); } },
    { value: 'SOFTWARE', get label() { return $_('industries.software'); } },
    { value: 'SPORTS', get label() { return $_('industries.sports'); } },
    { value: 'TECHNOLOGY', get label() { return $_('industries.technology'); } },
    { value: 'TELECOMMUNICATIONS', get label() { return $_('industries.telecommunications'); } },
    { value: 'TELEVISION', get label() { return $_('industries.television'); } },
    { value: 'TRANSPORTATION', get label() { return $_('industries.transportation'); } },
    { value: 'VENTURE CAPITAL', get label() { return $_('industries.venture_capital'); } }
  ];

  // Country options for drawer
  const countryOptions = COUNTRIES.map((c) => ({ value: c.code, label: c.name }));

  // Currency options for select
  const currencyOptions = CURRENCY_CODES.filter((c) => c.value).map((c) => ({
    value: c.value,
    label: c.label,
    color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
  }));

  // Base drawer columns (using $derived for dynamic currency symbol)
  const baseDrawerColumns = $derived([
    { key: 'name', label: $_('common.name'), type: 'text' },
    {
      key: 'industry',
      label: $_('accounts.industry'),
      type: 'select',
      icon: Briefcase,
      options: industryOptions,
      placeholder: 'Select industry'
    },
    {
      key: 'website',
      label: $_('accounts.website'),
      type: 'text',
      icon: Globe,
      placeholder: 'https://example.com'
    },
    { key: 'phone', label: $_('common.phone'), type: 'text', icon: Phone, placeholder: '+1 (555) 000-0000' },
    {
      key: 'email',
      label: $_('common.email'),
      type: 'email',
      icon: Mail,
      placeholder: 'contact@company.com'
    },
    {
      key: 'annualRevenue',
      label: $_('accounts.revenue'),
      type: 'number',
      icon: DollarSign,
      placeholder: '0'
    },
    {
      key: 'currency',
      label: $_('leads.currency'),
      type: 'select',
      icon: Banknote,
      options: currencyOptions,
      placeholder: 'Select currency'
    },
    {
      key: 'numberOfEmployees',
      label: $_('accounts.employees'),
      type: 'number',
      icon: Users,
      placeholder: '0'
    },
    {
      key: 'addressLine',
      label: $_('accounts.billing_address'),
      type: 'text',
      icon: MapPin,
      placeholder: 'Street address'
    },
    { key: 'city', label: $_('leads.city'), type: 'text', placeholder: 'City' },
    { key: 'state', label: $_('leads.state'), type: 'text', placeholder: 'State/Province' },
    { key: 'postcode', label: $_('leads.postal_code'), type: 'text', placeholder: 'Postal code' },
    {
      key: 'country',
      label: $_('leads.country'),
      type: 'select',
      options: countryOptions,
      placeholder: 'Select country'
    },
    {
      key: 'description',
      label: $_('common.description'),
      type: 'textarea',
      icon: FileText,
      placeholder: 'Add notes about this account...'
    }
  ]);

  /** @type {ColumnDef[]} */
  const columns = [
    {
      key: 'name',
      label: 'common.name',
      type: 'text',
      width: 'w-60',
      canHide: false,
      emptyText: 'Untitled'
    },
    { key: 'industry', label: 'accounts.industry', type: 'text', width: 'w-40', emptyText: '' },
    {
      key: 'annualRevenue',
      label: 'accounts.revenue',
      type: 'number',
      width: 'w-32',
      format: (value, row) => formatCurrency(value, row?.currency || 'TOM', true)
    },
    { key: 'phone', label: $_('common.phone'), type: 'text', width: 'w-36', emptyText: '' },
    {
      key: 'createdAt',
      label: $_('common.created_at'),
      type: 'date',
      width: 'w-36',
      editable: false
    },
    // Hidden by default
    { key: 'website', label: $_('accounts.website'), type: 'text', width: 'w-44', canHide: true, emptyText: '' }
  ];

  // Default visible columns (excludes website; status removed - using tabs instead)
  const DEFAULT_VISIBLE_COLUMNS = ['name', 'industry', 'annualRevenue', 'phone', 'createdAt'];

  // Column visibility state - use defaults (excludes website)
  let visibleColumns = $state([...DEFAULT_VISIBLE_COLUMNS]);
  let currentUser = $state(null);

  // Load column visibility from localStorage
  onMount(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        visibleColumns = JSON.parse(saved);
      } catch (e) {
        console.error('Failed to parse saved columns:', e);
      }
    }
    currentUser = getCurrentUser();
  });

  // Save column visibility when changed
  $effect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(visibleColumns));
    }
  });

  /**
   * Toggle column visibility
   * @param {string} key
   */
  function toggleColumn(key) {
    const col = columns.find((c) => c.key === key);
    if (col?.canHide === false) return;

    if (visibleColumns.includes(key)) {
      visibleColumns = visibleColumns.filter((k) => k !== key);
    } else {
      visibleColumns = [...visibleColumns, key];
    }
  }

  /** @type {{ data: import('./$types').PageData }} */
  let { data } = $props();

  // Computed values from data
  const accounts = $derived(data.accounts || []);
  const pagination = $derived(data.pagination || { page: 1, limit: 10, total: 0, totalPages: 0 });

  // M2M options from API
  const userOptions = $derived(
    (data.users || []).map((u) => ({ value: u.id, label: u.name || u.email || `User ${u.id}` }))
  );
  const contactOptions = $derived(
    (data.contacts || []).map((c) => ({ value: c.id, label: c.name }))
  );
  const tagOptions = $derived(
    (data.tags || []).map((/** @type {any} */ t) => ({
      id: t.id,
      name: t.name,
      color: t.color || 'blue'
    }))
  );

  // Drawer columns with dynamic M2M options
  const drawerColumns = $derived([
    ...baseDrawerColumns,
    {
      key: 'assignedTo',
      label: $_('common.assigned_to'),
      type: 'multiselect',
      icon: UserPlus,
      options: userOptions,
      placeholder: 'Select users',
      emptyText: 'Not assigned'
    },
    {
      key: 'contacts',
      label: $_('contacts.title'),
      type: 'multiselect',
      icon: Contact,
      options: contactOptions,
      placeholder: 'Link contacts',
      emptyText: 'No contacts'
    },
    {
      key: 'tags',
      label: $_('common.tags'),
      type: 'multiselect',
      icon: Tag,
      options: tagOptions,
      placeholder: 'Add tags',
      emptyText: 'No tags'
    },
    {
      key: 'createdBy',
      label: $_('common.created_by'),
      type: 'readonly',
      icon: User,
      getValue: (data) => data.createdBy?.name || data.createdBy?.email || '-'
    }
  ]);

  // Read the URL synchronously at init so deep links (?view=ID / ?action=create)
  // prime the drawer state on the first frame instead of waiting for a $effect tick.
  const initialUrlParams = $page.url.searchParams;
  const initialViewId = initialUrlParams.get('view');
  const initialAction = initialUrlParams.get('action');
  const initialAccount = initialViewId
    ? untrack(
        () =>
          (data.accounts || []).find(
            (/** @type {any} */ a) => a.id === initialViewId
          ) || null
      )
    : null;

  // Drawer state - simplified for unified drawer
  let drawerOpen = $state(initialAction === 'create' || !!initialAccount);
  /** @type {'view' | 'create'} */
  let drawerMode = $state(initialAction === 'create' ? 'create' : 'view');
  /** @type {any} */
  let selectedAccount = $state(initialAccount);
  let drawerLoading = $state(false);
  let isSubmitting = $state(false);

  // Empty account template for create mode
  const emptyAccount = {
    name: '',
    industry: '',
    website: '',
    phone: '',
    email: '',
    description: '',
    addressLine: '',
    city: '',
    state: '',
    postcode: '',
    country: '',
    annualRevenue: '',
    currency: '',
    numberOfEmployees: '',
    assignedTo: [],
    contacts: [],
    tags: []
  };

  // Drawer form data - mutable copy of selectedAccount for editing
  let drawerFormData = $state({ ...emptyAccount });

  // Reset form data when account changes or drawer opens
  $effect(() => {
    if (drawerOpen) {
      if (drawerMode === 'create') {
        drawerFormData = { ...emptyAccount, currency: $orgSettings.default_currency || 'USD' };
      } else if (selectedAccount) {
        drawerFormData = {
          ...selectedAccount,
          currency: selectedAccount.currency || $orgSettings.default_currency || 'USD'
        };
      }
    }
  });

  // Check if account is closed (inactive)
  const isClosed = $derived(selectedAccount?.isActive === false);

  // URL sync for drawer state â€” handles client-side navigation changes after first paint.
  // The initial deep link is already handled synchronously above.
  $effect(() => {
    const viewId = $page.url.searchParams.get('view');
    const action = $page.url.searchParams.get('action');

    if (action === 'create' && !drawerOpen) {
      selectedAccount = null;
      drawerMode = 'create';
      drawerOpen = true;
    } else if (viewId && accounts.length > 0 && !drawerOpen) {
      const account = accounts.find((a) => a.id === viewId);
      if (account) {
        selectedAccount = account;
        drawerMode = 'view';
        drawerOpen = true;
      }
    }
  });

  /**
   * Update URL with drawer state
   * @param {string | null} viewId
   * @param {string | null} action
   * @returns {Promise<void>}
   */
  async function updateUrl(viewId, action) {
    const url = new URL($page.url);
    if (viewId) {
      url.searchParams.set('view', viewId);
      url.searchParams.delete('action');
    } else if (action) {
      url.searchParams.set('action', action);
      url.searchParams.delete('view');
    } else {
      url.searchParams.delete('view');
      url.searchParams.delete('action');
    }
    await goto(url.toString(), { replaceState: true, keepFocus: true });
  }

  /**
   * Open account detail drawer
   * @param {any} account
   */
  function openAccount(account) {
    selectedAccount = account;
    drawerMode = 'view';
    drawerOpen = true;
    updateUrl(account.id, null);
  }

  /**
   * Open create drawer
   */
  function openCreate() {
    selectedAccount = null;
    drawerMode = 'create';
    drawerOpen = true;
    updateUrl(null, 'create');
  }

  /**
   * Close drawer
   * @returns {Promise<void>}
   */
  async function closeDrawer() {
    drawerOpen = false;
    await updateUrl(null, null);
  }

  /**
   * Handle drawer open change
   * @param {boolean} open
   */
  function handleDrawerChange(open) {
    drawerOpen = open;
    if (!open) {
      updateUrl(null, null);
    }
  }

  // Get unique industries from accounts for filter options
  const industries = $derived.by(() => {
    const uniqueIndustries = [...new Set(accounts.map((a) => a.industry).filter(Boolean))];
    return uniqueIndustries.sort();
  });

  // Industry options for filter
  const industryFilterOptions = $derived([
    { value: '', get label() { return $_('filters.all_industries'); } },
    ...industries.map((ind) => ({ value: ind, get label() { return $_('industries.' + ind.toLowerCase().replace(/[^a-z0-9]+/g, '_')); }}))
  ]);

  // URL-based filter state from server
  const filters = $derived(data.filters);

  // Count active filters
  const activeFiltersCount = $derived.by(() => {
    let count = 0;
    if (filters.search) count++;
    if (filters.industry) count++;
    if (filters.assigned_to?.length > 0) count++;
    if (filters.tags?.length > 0) count++;
    if (filters.created_at_gte || filters.created_at_lte) count++;
    return count;
  });

  /**
   * Update URL with new filters
   * @param {Record<string, any>} newFilters
   */
  async function updateFilters(newFilters) {
    const url = new URL($page.url);
    // Clear existing filter params (preserve view/action)
    ['search', 'industry', 'assigned_to', 'tags', 'created_at_gte', 'created_at_lte'].forEach(
      (key) => url.searchParams.delete(key)
    );
    // Set new params
    Object.entries(newFilters).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        value.forEach((v) => url.searchParams.append(key, v));
      } else if (value && value !== 'ALL') {
        url.searchParams.set(key, value);
      }
    });
    await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
  }

  /**
   * Clear all filters
   */
  function clearFilters() {
    updateFilters({});
  }

  /**
   * Handle page change
   * @param {number} newPage
   */
  async function handlePageChange(newPage) {
    const url = new URL($page.url);
    url.searchParams.set('page', newPage.toString());
    await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
  }

  /**
   * Handle limit change
   * @param {number} newLimit
   */
  async function handleLimitChange(newLimit) {
    const url = new URL($page.url);
    url.searchParams.set('limit', newLimit.toString());
    url.searchParams.set('page', '1'); // Reset to first page
    await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
  }

  // Accounts are already filtered server-side, apply chip filter for active/closed
  let statusChipFilter = $state('ALL');

  const filteredAccounts = $derived.by(() => {
    if (statusChipFilter === 'active') {
      return accounts.filter((a) => a.isActive !== false);
    } else if (statusChipFilter === 'closed') {
      return accounts.filter((a) => a.isActive === false);
    }
    return accounts;
  });

  // Active row (highlighted in the table) â€” seeded from ?view= so the deep-linked row
  // is highlighted immediately on first paint.
  /** @type {string | null} */
  let activeRowId = $state(initialViewId || null);

  // Visible column count for the toggle button
  const visibleColumnCount = $derived(visibleColumns.length);
  const totalColumnCount = $derived(columns.length);

  // Status counts for filter chips
  const activeCount = $derived(accounts.filter((a) => a.isActive !== false).length);
  const closedCount = $derived(accounts.filter((a) => a.isActive === false).length);

  // Form references for server actions
  /** @type {HTMLFormElement} */
  let createForm;
  /** @type {HTMLFormElement} */
  let updateForm;
  /** @type {HTMLFormElement} */
  let deleteForm;
  /** @type {HTMLFormElement} */
  let deactivateForm;
  /** @type {HTMLFormElement} */
  let activateForm;

  // Form data state - aligned with API fields
  let formState = $state({
    accountId: '',
    name: '',
    email: '',
    phone: '',
    website: '',
    industry: '',
    description: '',
    address_line: '',
    city: '',
    state: '',
    postcode: '',
    country: '',
    annual_revenue: '',
    currency: '',
    number_of_employees: '',
    assigned_to: '[]',
    contacts: '[]',
    tags: '[]'
  });

  /**
   * Get initials for avatar
   * @param {any} account
   */
  function getAccountInitials(account) {
    return getInitials(account.name, 1);
  }

  /**
   * Handle field change from CrmDrawer - just updates local state
   * @param {string} field
   * @param {any} value
   */
  function handleDrawerFieldChange(field, value) {
    // Update local form data only - no auto-save
    drawerFormData = { ...drawerFormData, [field]: value };
  }

  /**
   * Handle save for view/edit mode
   */
  async function handleDrawerUpdate() {
    if (drawerMode !== 'view' || !selectedAccount || isClosed) return;

    isSubmitting = true;
    formState.accountId = selectedAccount.id;
    formState.name = drawerFormData.name || '';
    formState.email = drawerFormData.email || '';
    formState.phone = drawerFormData.phone || '';
    formState.website = drawerFormData.website || '';
    formState.industry = drawerFormData.industry || '';
    formState.description = drawerFormData.description || '';
    formState.address_line = drawerFormData.addressLine || '';
    formState.city = drawerFormData.city || '';
    formState.state = drawerFormData.state || '';
    formState.postcode = drawerFormData.postcode || '';
    formState.country = drawerFormData.country || '';
    formState.annual_revenue = drawerFormData.annualRevenue?.toString() || '';
    formState.currency = drawerFormData.currency || '';
    formState.number_of_employees = drawerFormData.numberOfEmployees?.toString() || '';
    formState.assigned_to = JSON.stringify(drawerFormData.assignedTo || []);
    formState.contacts = JSON.stringify(drawerFormData.contacts || []);
    formState.tags = JSON.stringify(drawerFormData.tags || []);

    await tick();
    updateForm.requestSubmit();
  }

  /**
   * Handle save for create mode
   */
  async function handleDrawerSave() {
    if (drawerMode !== 'create') return;

    isSubmitting = true;
    formState.name = drawerFormData.name || '';
    formState.email = drawerFormData.email || '';
    formState.phone = drawerFormData.phone || '';
    formState.website = drawerFormData.website || '';
    formState.industry = drawerFormData.industry || '';
    formState.description = drawerFormData.description || '';
    formState.address_line = drawerFormData.addressLine || '';
    formState.city = drawerFormData.city || '';
    formState.state = drawerFormData.state || '';
    formState.postcode = drawerFormData.postcode || '';
    formState.country = drawerFormData.country || '';
    formState.annual_revenue = drawerFormData.annualRevenue?.toString() || '';
    formState.currency = drawerFormData.currency || '';
    formState.number_of_employees = drawerFormData.numberOfEmployees?.toString() || '';
    formState.assigned_to = JSON.stringify(drawerFormData.assignedTo || []);
    formState.contacts = JSON.stringify(drawerFormData.contacts || []);
    formState.tags = JSON.stringify(drawerFormData.tags || []);

    await tick();
    createForm.requestSubmit();
  }

  /**
   * Handle account delete
   */
  async function handleDelete() {
    if (!selectedAccount) return;
    if (!confirm(`Are you sure you want to delete "${selectedAccount.name}"?`)) return;

    formState.accountId = selectedAccount.id;
    await tick();
    deleteForm.requestSubmit();
  }

  /**
   * Handle account close (deactivate)
   */
  async function handleClose() {
    if (!selectedAccount) return;

    formState.accountId = selectedAccount.id;
    await tick();
    deactivateForm.requestSubmit();
  }

  /**
   * Handle account reopen (activate)
   */
  async function handleReopen() {
    if (!selectedAccount) return;

    formState.accountId = selectedAccount.id;
    await tick();
    activateForm.requestSubmit();
  }

  /**
   * Create enhance handler for form actions
   * @param {string} successMessage
   * @param {boolean} shouldCloseDrawer
   */
  function createEnhanceHandler(successMessage, shouldCloseDrawer = false) {
    return () => {
      return async ({ result, update }) => {
        await update();
        isSubmitting = false;
        if (result.type === 'success') {
          toast.success(successMessage);
          if (shouldCloseDrawer) {
            // Close drawer state locally
            drawerOpen = false;
            selectedAccountId = null;
            // Update URL and refresh data in one atomic goto
            const url = new URL($page.url);
            url.searchParams.delete('view');
            url.searchParams.delete('action');
            await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
          } else {
            await invalidateAll();
          }
        } else if (result.type === 'failure') {
          toast.error(result.data?.error || 'Operation failed');
        } else if (result.type === 'error') {
          toast.error('An unexpected error occurred');
        }
      };
    };
  }

  /**
   * Navigate to add contact
   */
  function handleAddContact() {
    if (selectedAccount) {
      goto(`/contacts?action=create&accountId=${selectedAccount.id}`);
    }
  }

  /**
   * Navigate to add opportunity
   */
  function handleAddOpportunity() {
    if (selectedAccount) {
      goto(`/opportunities?action=create&accountId=${selectedAccount.id}`);
    }
  }

  /**
   * Navigate to add ticket
   */
  function handleAddTicket() {
    if (selectedAccount) {
      goto(`/tickets?action=create&accountId=${selectedAccount.id}`);
    }
  }

  /**
   * Navigate to add task
   */
  function handleAddTask() {
    if (selectedAccount) {
      goto(`/tasks?action=create&accountId=${selectedAccount.id}`);
    }
  }
</script>

<svelte:head>
  <title>{$_('accounts.title')} - {$_('app.name')}</title>
</svelte:head>

<div class="flex flex-col">
<PageHeader title={$_('accounts.title')} subtitle="{filteredAccounts.length} of {accounts.length} accounts">
  {#snippet actions()}
    <div class="flex items-center gap-2">
      <!-- Status Filter Chips -->
      <div class="flex gap-1">
        <button
          type="button"
          onclick={() => (statusChipFilter = 'ALL')}
          class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
          'ALL'
            ? 'bg-[var(--color-primary-default)] text-white'
            : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
        >
          All
          <span
            class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'ALL'
              ? 'bg-[var(--color-primary-dark)] text-white/90'
              : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
          >
            {accounts.length}
          </span>
        </button>
        <button
          type="button"
          onclick={() => (statusChipFilter = 'active')}
          class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
          'active'
            ? 'bg-[var(--color-success-default)] text-white'
            : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
        >
          Active
          <span
            class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'active'
              ? 'bg-[var(--color-success-dark)] text-white/90'
              : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
          >
            {activeCount}
          </span>
        </button>
        <button
          type="button"
          onclick={() => (statusChipFilter = 'closed')}
          class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
          'closed'
            ? 'bg-[var(--text-secondary)] text-white'
            : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
        >
          Closed
          <span
            class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'closed'
              ? 'bg-[var(--text-tertiary)] text-white/90'
              : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
          >
            {closedCount}
          </span>
        </button>
      </div>

      <!-- Column Visibility Dropdown -->
      <DropdownMenu.Root>
        <DropdownMenu.Trigger asChild>
          {#snippet child({ props })}
            <Button {...props} variant="outline" size="sm" class="gap-2">
              <Eye class="h-4 w-4" />
              Columns
              {#if visibleColumnCount < totalColumnCount}
                <span
                  class="rounded-full bg-[var(--color-primary-light)] px-1.5 py-0.5 text-xs font-medium text-[var(--color-primary-default)]"
                >
                  {visibleColumnCount}/{totalColumnCount}
                </span>
              {/if}
            </Button>
          {/snippet}
        </DropdownMenu.Trigger>
        <DropdownMenu.Content align="end" class="w-48">
          <DropdownMenu.Label>Toggle columns</DropdownMenu.Label>
          <DropdownMenu.Separator />
          {#each columns as column (column.key)}
            <DropdownMenu.CheckboxItem
              class=""
              checked={visibleColumns.includes(column.key)}
              onCheckedChange={() => toggleColumn(column.key)}
              disabled={column.canHide === false}
            >
              {column.label}
            </DropdownMenu.CheckboxItem>
          {/each}
        </DropdownMenu.Content>
      </DropdownMenu.Root>
      <Button onclick={openCreate} disabled={false}>
        <Plus class="me-2 h-4 w-4" />
        New Account
      </Button>
    </div>
  {/snippet}
  {#snippet tabs()}
    <ViewTabs views={[{ id: 'all', label: 'All', count: pagination.total }]} active="all" />
  {/snippet}
</PageHeader>

<div class="flex-1">
  <FilterStrip>
    <SearchInput
      value={filters.search}
      onchange={(value) => updateFilters({ ...filters, search: value })}
      placeholder="Search accounts..."
    />
    <SelectFilter
      label="Industry"
      options={industryFilterOptions}
      value={filters.industry}
      onchange={(value) => updateFilters({ ...filters, industry: value })}
    />
    <DateRangeFilter
      label="Created"
      startDate={filters.created_at_gte}
      endDate={filters.created_at_lte}
      onchange={(start, end) =>
        updateFilters({ ...filters, created_at_gte: start, created_at_lte: end })}
    />
    <TagFilter
      tags={tagOptions}
      value={filters.tags}
      onchange={(ids) => updateFilters({ ...filters, tags: ids })}
    />
    {#if activeFiltersCount > 0}
      <FilterPill label="Clear all" dashed onclick={clearFilters} />
    {/if}
    {#snippet meta()}
      <span>{filteredAccounts.length} of {pagination.total} accounts</span>
    {/snippet}
  </FilterStrip>
  <!-- Accounts Table -->
  {#if filteredAccounts.length === 0}
    <div class="flex flex-col items-center justify-center py-16 text-center">
      <div
        class="mb-4 flex size-16 items-center justify-center rounded-[var(--radius-xl)] bg-[var(--surface-sunken)]"
      >
        <Building2 class="size-8 text-[var(--text-tertiary)]" />
      </div>
      <h3 class="text-lg font-medium text-[var(--text-primary)]">No accounts found</h3>
      <p class="mt-1 text-sm text-[var(--text-secondary)]">
        Try adjusting your filters or create a new account
      </p>
    </div>
  {:else}
    <!-- Desktop Table using CrmTable -->
    <div class="hidden md:block">
      <CrmTable
        data={filteredAccounts}
        {columns}
        bind:visibleColumns
        bind:activeRowId
        onRowClick={(row) => openAccount(row)}
      >
        {#snippet emptyState()}
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <div
              class="mb-4 flex size-16 items-center justify-center rounded-[var(--radius-xl)] bg-[var(--surface-sunken)]"
            >
              <Building2 class="size-8 text-[var(--text-tertiary)]" />
            </div>
            <h3 class="text-lg font-medium text-[var(--text-primary)]">No accounts found</h3>
          </div>
        {/snippet}
      </CrmTable>
    </div>

    <!-- Mobile Card View -->
    <div class="divide-y divide-[var(--border-default)] md:hidden">
      {#each filteredAccounts as account (account.id)}
        <button
          type="button"
          class="flex w-full items-start gap-4 p-4 text-start transition-colors hover:bg-[var(--surface-sunken)] {!account.isActive
            ? 'opacity-60'
            : ''}"
          onclick={() => openAccount(account)}
        >
          <div
            class="flex size-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)] bg-[var(--color-primary-default)] text-sm font-medium text-white"
          >
            {getAccountInitials(account)}
          </div>
          <div class="min-w-0 flex-1">
            <div class="flex items-start justify-between gap-2">
              <div>
                <p class="font-medium text-[var(--text-primary)]">{account.name}</p>
                <div class="mt-1 flex items-center gap-1.5">
                  {#if account.isActive !== false}
                    <span
                      class="inline-flex items-center rounded-full bg-[var(--color-success-light)] px-2.5 py-1 text-xs font-medium text-[var(--color-success-default)] dark:bg-[var(--color-success-default)]/15"
                    >
                      Active
                    </span>
                  {:else}
                    <span
                      class="inline-flex items-center rounded-full bg-[var(--surface-sunken)] px-2.5 py-1 text-xs font-medium text-[var(--text-secondary)]"
                    >
                      Closed
                    </span>
                  {/if}
                </div>
              </div>
            </div>
            <div
              class="mt-2 flex flex-wrap items-center gap-3 text-sm text-[var(--text-secondary)]"
            >
              {#if account.industry}
                <span>{account.industry}</span>
              {/if}
              <div class="flex items-center gap-1">
                <Users class="size-3.5 text-[var(--text-tertiary)]" />
                <span>{account.contactCount || 0}</span>
              </div>
              <div class="flex items-center gap-1">
                <Target class="size-3.5 text-[var(--text-tertiary)]" />
                <span>{account.opportunityCount || 0}</span>
              </div>
              <div class="flex items-center gap-1">
                <Calendar class="size-3.5 text-[var(--text-tertiary)]" />
                <span>{formatRelativeDate(account.createdAt)}</span>
              </div>
            </div>
          </div>
        </button>
      {/each}
    </div>
  {/if}

  <!-- Pagination -->
  <Pagination
    page={pagination.page}
    limit={pagination.limit}
    total={pagination.total}
    onPageChange={handlePageChange}
    onLimitChange={handleLimitChange}
  />
</div>

</div>

<!-- Account Drawer -->
<CrmDrawer
  bind:open={drawerOpen}
  onOpenChange={handleDrawerChange}
  data={drawerFormData}
  columns={drawerColumns}
  titleKey="name"
  titlePlaceholder="Account name"
  headerLabel="Account"
  mode={drawerMode}
  loading={drawerLoading || isSubmitting}
  fullPageHref={drawerMode !== 'create' && /** @type {any} */ (drawerFormData)?.id ? `/accounts/${/** @type {any} */ (drawerFormData).id}` : ''}
  onFieldChange={handleDrawerFieldChange}
  onDelete={handleDelete}
  onClose={closeDrawer}
>
  {#snippet activitySection()}
    <!-- Closed account warning -->
    {#if isClosed && drawerMode !== 'create'}
      <div
        class="mb-4 rounded-[var(--radius-lg)] border border-[var(--color-negative-light)] bg-[var(--color-negative-light)] p-3 dark:border-[var(--color-negative-default)]/30 dark:bg-[var(--color-negative-default)]/10"
      >
        <div class="flex gap-2">
          <AlertTriangle class="mt-0.5 size-4 shrink-0 text-[var(--color-negative-default)]" />
          <div>
            <p class="text-sm font-medium text-[var(--color-negative-default)]">
              This account is closed
            </p>
            <p class="mt-0.5 text-xs text-[var(--color-negative-default)]/80">
              Reopen the account to make changes
            </p>
          </div>
        </div>
      </div>
    {/if}

    <!-- Related entity stats (view mode only) -->
    {#if drawerMode !== 'create' && selectedAccount}
      <div class="mb-4">
        <p class="mb-2 text-xs font-medium tracking-wider text-[var(--text-tertiary)] uppercase">
          Related
        </p>
        <div class="grid grid-cols-2 gap-2 sm:grid-cols-4">
          <div class="rounded-[var(--radius-lg)] bg-[var(--surface-sunken)] p-2 text-center">
            <div class="flex items-center justify-center gap-1 text-[var(--text-tertiary)]">
              <Users class="size-3.5" />
            </div>
            <p class="mt-0.5 text-lg font-semibold text-[var(--text-primary)]">
              {selectedAccount.contactCount || 0}
            </p>
            <p class="text-[10px] text-[var(--text-secondary)]">Contacts</p>
          </div>
          <div class="rounded-[var(--radius-lg)] bg-[var(--surface-sunken)] p-2 text-center">
            <div class="flex items-center justify-center gap-1 text-[var(--text-tertiary)]">
              <Target class="size-3.5" />
            </div>
            <p class="mt-0.5 text-lg font-semibold text-[var(--text-primary)]">
              {selectedAccount.opportunityCount || 0}
            </p>
            <p class="text-[10px] text-[var(--text-secondary)]">Opportunities</p>
          </div>
          <div class="rounded-[var(--radius-lg)] bg-[var(--surface-sunken)] p-2 text-center">
            <div class="flex items-center justify-center gap-1 text-[var(--text-tertiary)]">
              <AlertTriangle class="size-3.5" />
            </div>
            <p class="mt-0.5 text-lg font-semibold text-[var(--text-primary)]">
              {selectedAccount.ticketCount || 0}
            </p>
            <p class="text-[10px] text-[var(--text-secondary)]">Tickets</p>
          </div>
          <div class="rounded-[var(--radius-lg)] bg-[var(--surface-sunken)] p-2 text-center">
            <div class="flex items-center justify-center gap-1 text-[var(--text-tertiary)]">
              <CheckSquare class="size-3.5" />
            </div>
            <p class="mt-0.5 text-lg font-semibold text-[var(--text-primary)]">
              {selectedAccount.taskCount || 0}
            </p>
            <p class="text-[10px] text-[var(--text-secondary)]">Tasks</p>
          </div>
        </div>
      </div>

      <!-- Quick actions (for active accounts only) -->
      {#if !isClosed}
        <div class="mb-4">
          <p class="mb-2 text-xs font-medium tracking-wider text-[var(--text-tertiary)] uppercase">
            Quick Actions
          </p>
          <div class="flex gap-2">
            <Button variant="outline" size="sm" onclick={handleAddContact} class="flex-1">
              <Users class="me-1.5 h-3.5 w-3.5" />
              Add Contact
            </Button>
            <Button variant="outline" size="sm" onclick={handleAddOpportunity} class="flex-1">
              <Target class="me-1.5 h-3.5 w-3.5" />
              Add Opportunity
            </Button>
          </div>
          <div class="mt-2 flex gap-2">
            <Button variant="outline" size="sm" onclick={handleAddTicket} class="flex-1">
              <AlertTriangle class="me-1.5 h-3.5 w-3.5" />
              Add Ticket
            </Button>
            <Button variant="outline" size="sm" onclick={handleAddTask} class="flex-1">
              <CheckSquare class="me-1.5 h-3.5 w-3.5" />
              Add Task
            </Button>
          </div>
        </div>
      {/if}

      <!-- Metadata -->
      <div>
        <p class="mb-2 text-xs font-medium tracking-wider text-[var(--text-tertiary)] uppercase">
          Details
        </p>
        <div class="grid grid-cols-2 gap-3 text-sm">
          <div>
            <p class="text-xs text-[var(--text-tertiary)]">Owner</p>
            <p class="font-medium text-[var(--text-primary)]">
              {selectedAccount.owner?.name || 'Unassigned'}
            </p>
          </div>
          <div>
            <p class="text-xs text-[var(--text-tertiary)]">Created</p>
            <p class="font-medium text-[var(--text-primary)]">
              {formatRelativeDate(selectedAccount.createdAt)}
            </p>
          </div>
        </div>
      </div>

      <!-- Comments Section -->
      <div class="mt-6 border-t border-[var(--border-default)] pt-4">
        <CommentSection
          entityId={selectedAccount.id}
          entityType="accounts"
          initialComments={selectedAccount.comments || []}
          currentUserEmail={currentUser?.email}
          isAdmin={currentUser?.organizations?.some((o) => o.role === 'ADMIN')}
        />
      </div>
    {/if}
  {/snippet}

  {#snippet footerActions()}
    {#if drawerMode === 'create'}
      <Button variant="outline" onclick={closeDrawer} disabled={isSubmitting}>Cancel</Button>
      <Button onclick={handleDrawerSave} disabled={isSubmitting || !drawerFormData.name?.trim()}>
        {isSubmitting ? 'Creating...' : 'Create Account'}
      </Button>
    {:else if isClosed}
      <Button variant="outline" onclick={closeDrawer} disabled={isSubmitting}>Cancel</Button>
      <Button
        variant="outline"
        class="text-[var(--color-success-default)] hover:text-[var(--color-success-dark)]"
        onclick={handleReopen}
        disabled={isSubmitting}
      >
        <Unlock class="me-1.5 size-4" />
        Reopen Account
      </Button>
    {:else}
      <Button variant="outline" onclick={closeDrawer} disabled={isSubmitting}>Cancel</Button>
      <Button
        variant="ghost"
        class="text-[var(--color-primary-default)] hover:text-[var(--color-primary-dark)]"
        onclick={handleClose}
        disabled={isSubmitting}
      >
        <Lock class="me-1.5 size-4" />
        Close Account
      </Button>
      <Button onclick={handleDrawerUpdate} disabled={isSubmitting || !drawerFormData.name?.trim()}>
        {isSubmitting ? 'Saving...' : 'Save'}
      </Button>
    {/if}
  {/snippet}
</CrmDrawer>

<!-- Hidden forms for server actions -->
<form
  method="POST"
  action="?/create"
  bind:this={createForm}
  use:enhance={createEnhanceHandler('Account created successfully', true)}
  class="hidden"
>
  <input type="hidden" name="name" value={formState.name} />
  <input type="hidden" name="email" value={formState.email} />
  <input type="hidden" name="phone" value={formState.phone} />
  <input type="hidden" name="website" value={formState.website} />
  <input type="hidden" name="industry" value={formState.industry} />
  <input type="hidden" name="description" value={formState.description} />
  <input type="hidden" name="address_line" value={formState.address_line} />
  <input type="hidden" name="city" value={formState.city} />
  <input type="hidden" name="state" value={formState.state} />
  <input type="hidden" name="postcode" value={formState.postcode} />
  <input type="hidden" name="country" value={formState.country} />
  <input type="hidden" name="annual_revenue" value={formState.annual_revenue} />
  <input type="hidden" name="currency" value={formState.currency} />
  <input type="hidden" name="number_of_employees" value={formState.number_of_employees} />
  <input type="hidden" name="assigned_to" value={formState.assigned_to} />
  <input type="hidden" name="contacts" value={formState.contacts} />
  <input type="hidden" name="tags" value={formState.tags} />
</form>

<form
  method="POST"
  action="?/update"
  bind:this={updateForm}
  use:enhance={createEnhanceHandler('Account updated successfully', true)}
  class="hidden"
>
  <input type="hidden" name="accountId" value={formState.accountId} />
  <input type="hidden" name="name" value={formState.name} />
  <input type="hidden" name="email" value={formState.email} />
  <input type="hidden" name="phone" value={formState.phone} />
  <input type="hidden" name="website" value={formState.website} />
  <input type="hidden" name="industry" value={formState.industry} />
  <input type="hidden" name="description" value={formState.description} />
  <input type="hidden" name="address_line" value={formState.address_line} />
  <input type="hidden" name="city" value={formState.city} />
  <input type="hidden" name="state" value={formState.state} />
  <input type="hidden" name="postcode" value={formState.postcode} />
  <input type="hidden" name="country" value={formState.country} />
  <input type="hidden" name="annual_revenue" value={formState.annual_revenue} />
  <input type="hidden" name="currency" value={formState.currency} />
  <input type="hidden" name="number_of_employees" value={formState.number_of_employees} />
  <input type="hidden" name="assigned_to" value={formState.assigned_to} />
  <input type="hidden" name="contacts" value={formState.contacts} />
  <input type="hidden" name="tags" value={formState.tags} />
</form>

<form
  method="POST"
  action="?/delete"
  bind:this={deleteForm}
  use:enhance={createEnhanceHandler('Account deleted successfully', true)}
  class="hidden"
>
  <input type="hidden" name="accountId" value={formState.accountId} />
</form>

<form
  method="POST"
  action="?/deactivate"
  bind:this={deactivateForm}
  use:enhance={createEnhanceHandler('Account closed successfully', true)}
  class="hidden"
>
  <input type="hidden" name="accountId" value={formState.accountId} />
</form>

<form
  method="POST"
  action="?/activate"
  bind:this={activateForm}
  use:enhance={createEnhanceHandler('Account reopened successfully')}
  class="hidden"
>
  <input type="hidden" name="accountId" value={formState.accountId} />
</form>
