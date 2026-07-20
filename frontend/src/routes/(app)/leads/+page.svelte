<script>
  import { _ } from '$lib/i18n';
  import { enhance, deserialize } from '$app/forms';
  import { invalidateAll, goto } from '$app/navigation';
  import { tick, onMount, untrack } from 'svelte';
  import { toast } from '$lib/components/ui/toast/index.js';
  import {
    Plus,
    Phone,
    Mail,
    Building2,
    User,
    Calendar,
    Eye,
    Star,
    Globe,
    Briefcase,
    Target,
    DollarSign,
    Percent,
    MapPin,
    FileText,
    Users,
    UserPlus,
    Tag,
    MessageSquare,
    Loader2,
    ArrowRightCircle,
    Banknote,
    AlertTriangle,
    RotateCw,
    X
  } from '@lucide/svelte';
  import { LinkedinIcon as Linkedin } from '$lib/components/icons';
  import { page } from '$app/stores';
  import { SearchInput, SelectFilter, DateRangeFilter, TagFilter } from '$lib/components/ui/filter';
  import { Pagination } from '$lib/components/ui/pagination';
  import { Button } from '$lib/components/ui/button/index.js';
  import { PageHeader, FilterStrip, ViewTabs, FilterPill } from '$lib/components/layout';
  import { INDUSTRIES, COUNTRIES } from '$lib/constants/lead-choices.js';
  import { CURRENCY_CODES } from '$lib/constants/filters.js';
  import * as DropdownMenu from '$lib/components/ui/dropdown-menu/index.js';
  import {
    formatRelativeDate,
    formatDate,
    getNameInitials,
    getInitials
  } from '$lib/utils/formatting.js';
  import {
    leadStatusOptions,
    leadRatingOptions,
    getOptionStyle,
    getOptionLabel,
    getOptionBgColor
  } from '$lib/utils/table-helpers.js';
  import CrmTable from '$lib/components/ui/crm-table/CrmTable.svelte';
  import CrmDrawer from '$lib/components/ui/crm-drawer/CrmDrawer.svelte';
  import { CommentSection } from '$lib/components/ui/comment-section';
  import { Timeline, TimelineItem } from '$lib/components/ui/timeline';
  import InteractionDialog from '$lib/components/ui/interaction/InteractionDialog.svelte';
  import * as Sheet from '$lib/components/ui/sheet/index.js';
  import { getCurrentUser, leads as leadsApi } from '$lib/api.js';
  import { browser } from '$app/environment';
  import { orgSettings } from '$lib/stores/org.js';
  import { ViewToggle } from '$lib/components/ui/view-toggle';
  import { LeadKanban } from '$lib/components/ui/lead-kanban';

  // Column visibility configuration
  const STORAGE_KEY = 'leads-column-config';

  /**
   * @typedef {'text' | 'email' | 'number' | 'date' | 'select' | 'checkbox' | 'relation'} ColumnType
   * @typedef {{ key: string, label: string, type?: ColumnType, width?: string, editable?: boolean, canHide?: boolean, getValue?: (row: any) => any, emptyText?: string, relationIcon?: string, options?: any[] }} ColumnDef
   */

  // Reactive translated options for status/rating (hardcoded English labels
  // in table-helpers.js don't support i18n, so we derive them here).
  const translatedStatusOptions = $derived(
    leadStatusOptions.map((opt) => ({
      ...opt,
      label: $_(`filters.${opt.value.toLowerCase()}`) || opt.label
    }))
  );
  const translatedRatingOptions = $derived(
    leadRatingOptions.map((opt) => ({
      ...opt,
      label: $_(`filters.${opt.value.toLowerCase()}`) || opt.label
    }))
  );

  // Reactive translated industry options
  const translatedIndustries = $derived(
    INDUSTRIES.map((ind) => ({
      ...ind,
      label: ind.value
        ? $_('industries.' + ind.value.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '')) || ind.label
        : $_('industries.select_industry') || ind.label
    }))
  );

  /** @type {ColumnDef[]} */
  const columns = [
    { key: 'title', label: 'leads.title', type: 'text', width: 'w-[200px]', canHide: false, editable: false, emptyText: 'common.untitled' },
    { key: 'name', label: 'leads.name', type: 'text', width: 'w-[180px]', editable: false, canHide: true, getValue: (row) => `${row.firstName || ''} ${row.lastName || ''}`.trim(), emptyText: '' },
    { key: 'company', label: 'leads.company', type: 'relation', width: 'w-40', relationIcon: 'building', getValue: (row) => (typeof row.company === 'object' ? row.company?.name : row.company), emptyText: '' },
    { key: 'email', label: 'common.email', type: 'email', width: 'w-52', editable: false, emptyText: '' },
    { key: 'status', label: 'common.status', type: 'select', width: 'w-36', options: translatedStatusOptions },
    { key: 'rating', label: 'leads.rating', type: 'select', width: 'w-28', options: translatedRatingOptions },
    { key: 'createdAt', label: 'common.created_at', type: 'date', width: 'w-36', editable: false },
    { key: 'phone', label: 'common.phone', type: 'text', width: 'w-36', canHide: true, editable: false, emptyText: '' },
    { key: 'jobTitle', label: 'leads.job_title', type: 'text', width: 'w-36', canHide: true, editable: false, emptyText: '' },
    { key: 'leadSource', label: 'leads.source', type: 'select', width: 'w-28', canHide: true },
    { key: 'industry', label: 'leads.industry', type: 'select', width: 'w-32', canHide: true, options: translatedIndustries.map((i) => ({ ...i, color: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300' })) },
    { key: 'owner', label: 'common.assigned_to', type: 'relation', width: 'w-36', canHide: true, relationIcon: 'user', getValue: (row) => row.owner?.name || '', emptyText: '' }
  ];

  // Default visible columns (7 columns: Title, Name, Company, Email, Status, Rating, Created)
  const DEFAULT_VISIBLE_COLUMNS = [
    'title',
    'name',
    'company',
    'email',
    'status',
    'rating',
    'createdAt'
  ];
  let visibleColumns = $state([...DEFAULT_VISIBLE_COLUMNS]);

  // Source options for leads - using design system tokens
  const sourceOptions = [
    {
      value: 'call',
      label: $_('filters.call'),
      color:
        'bg-[var(--activity-call)]/10 text-[var(--activity-call)] dark:bg-[var(--activity-call)]/15'
    },
    {
      value: 'email',
      label: $_('filters.email'),
      color:
        'bg-[var(--activity-email)]/10 text-[var(--activity-email)] dark:bg-[var(--activity-email)]/15'
    },
    {
      value: 'existing customer',
      label: $_('filters.existing_customer'),
      color:
        'bg-[var(--color-success-light)] text-[var(--color-success-default)] dark:bg-[var(--color-success-default)]/15'
    },
    {
      value: 'partner',
      label: $_('filters.partner'),
      color:
        'bg-[var(--color-primary-light)] text-[var(--color-primary-default)] dark:bg-[var(--color-primary-default)]/15'
    },
    {
      value: 'public relations',
      label: $_('filters.public_relations'),
      color:
        'bg-[var(--activity-meeting)]/10 text-[var(--activity-meeting)] dark:bg-[var(--activity-meeting)]/15'
    },
    {
      value: 'campaign',
      label: $_('filters.campaign'),
      color:
        'bg-[var(--stage-qualified)]/10 text-[var(--stage-qualified)] dark:bg-[var(--stage-qualified)]/15'
    },
    {
      value: 'other',
      label: $_('filters.other'),
      color:
        'bg-[var(--surface-sunken)] text-[var(--text-secondary)] dark:bg-[var(--surface-sunken)]'
    }
  ];

  // Salutation options - using design system tokens
  const salutationOptions = [
    {
      value: 'Mr',
      label: 'Mr',
      color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
    },
    {
      value: 'Mrs',
      label: 'Mrs',
      color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
    },
    {
      value: 'Ms',
      label: 'Ms',
      color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
    },
    {
      value: 'Dr',
      label: 'Dr',
      color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
    },
    {
      value: 'Prof',
      label: 'Prof',
      color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
    }
  ];

  // Currency options for select - using design system tokens
  const currencyOptions = CURRENCY_CODES.filter((c) => c.value).map((c) => ({
    value: c.value,
    label: c.label,
    color: 'bg-[var(--surface-sunken)] text-[var(--text-secondary)]'
  }));

  // Full drawer columns for NotionDrawer (all lead fields)
  // Using $derived so currency symbol updates with org settings
  const drawerColumns = $derived([
    // Contact Information
    {
      key: 'salutation',
      label: $_('leads.salutation'),
      type: 'select',
      icon: User,
      options: salutationOptions
    },
    {
      key: 'firstName',
      label: $_('leads.first_name'),
      type: 'text',
      icon: User,
      placeholder: $_('leads.first_name'),
      essential: true
    },
    {
      key: 'lastName',
      label: $_('leads.last_name'),
      type: 'text',
      icon: User,
      placeholder: $_('leads.last_name'),
      essential: true
    },
    {
      key: 'email',
      label: $_('common.email'),
      type: 'email',
      icon: Mail,
      placeholder: $_('common.email'),
      essential: true
    },
    {
      key: 'phone',
      label: $_('common.phone'),
      type: 'text',
      icon: Phone,
      placeholder: $_('common.phone'),
      essential: true
    },
    {
      key: 'jobTitle',
      label: $_('leads.job_title'),
      type: 'text',
      icon: Briefcase,
      placeholder: $_('leads.job_title')
    },
    {
      key: 'company',
      label: $_('leads.company'),
      type: 'text',
      icon: Building2,
      getValue: (/** @type {any} */ row) =>
        typeof row.company === 'object' ? row.company?.name : row.company,
      placeholder: $_('leads.company'),
      essential: true
    },
    {
      key: 'website',
      label: $_('leads.website'),
      type: 'text',
      icon: Globe,
      placeholder: $_('leads.website')
    },
    {
      key: 'linkedinUrl',
      label: $_('leads.linkedin'),
      type: 'text',
      icon: Linkedin,
      placeholder: $_('leads.linkedin')
    },
    // Lead Details
    {
      key: 'status',
      label: $_('leads.lead_status'),
      type: 'select',
      icon: Briefcase,
      options: translatedStatusOptions,
      essential: true
    },
    {
      key: 'rating',
      label: $_('leads.rating'),
      type: 'select',
      icon: Star,
      options: translatedRatingOptions
    },
    // Metadata
    {
      key: 'createdAt',
      label: $_('common.created_at'),
      type: 'date',
      icon: Calendar,
      editable: false,
      hideOnCreate: true
    },
    {
      key: 'leadSource',
      label: $_('leads.source'),
      type: 'select',
      icon: Target,
      options: sourceOptions
    },
    {
      key: 'industry',
      label: $_('leads.industry'),
      type: 'select',
      icon: Building2,
      options: translatedIndustries.map((i) => ({
        ...i,
        color: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
      }))
    },
    // Deal Information
    {
      key: 'opportunityAmount',
      label: $_('leads.opportunity_amount'),
      type: 'number',
      icon: DollarSign,
      placeholder: '0',
      essential: true
    },
    {
      key: 'currency',
      label: $_('leads.currency'),
      type: 'select',
      icon: Banknote,
      options: currencyOptions,
      placeholder: $_('filters.select_currency'),
      essential: true
    },
    {
      key: 'probability',
      label: $_('leads.probability'),
      type: 'number',
      icon: Percent,
      placeholder: '0-100'
    },
    {
      key: 'closeDate',
      label: $_('leads.close_date'),
      type: 'date',
      icon: Calendar,
      placeholder: $_('leads.close_date'),
      hideOnCreate: true
    },
    // Activity
    {
      key: 'lastContacted',
      label: $_('leads.last_contacted'),
      type: 'date',
      icon: Calendar,
      placeholder: $_('leads.last_contacted'),
      hideOnCreate: true
    },
    {
      key: 'nextFollowUp',
      label: $_('leads.next_follow_up'),
      type: 'date',
      icon: Calendar,
      placeholder: $_('leads.next_follow_up')
    },
    // Address
    {
      key: 'addressLine',
      label: $_('common.address'),
      type: 'text',
      icon: MapPin,
      placeholder: $_('leads.street')
    },
    {
      key: 'city',
      label: $_('common.city'),
      type: 'text',
      icon: MapPin,
      placeholder: $_('common.city')
    },
    {
      key: 'state',
      label: $_('common.state'),
      type: 'text',
      icon: MapPin,
      placeholder: $_('common.state')
    },
    {
      key: 'postcode',
      label: $_('common.postal_code'),
      type: 'text',
      icon: MapPin,
      placeholder: $_('common.postal_code')
    },
    {
      key: 'country',
      label: $_('common.country'),
      type: 'select',
      icon: Globe,
      options: COUNTRIES.map((c) => ({
        ...c,
        color: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
      })),
      essential: true
    },
    // Notes
    {
      key: 'description',
      label: $_('common.notes'),
      type: 'textarea',
      icon: FileText,
      placeholder: $_('common.notes')
    },
    // Assignment (multi-select fields - options populated dynamically)
    {
      key: 'assignedTo',
      label: $_('common.assigned_to'),
      type: 'multiselect',
      icon: Users,
      options: []
    },
    {
      key: 'teams',
      label: $_('common.teams'),
      type: 'multiselect',
      icon: Users,
      options: []
    },
    {
      key: 'contacts',
      label: $_('common.contacts'),
      type: 'multiselect',
      icon: UserPlus,
      options: []
    },
    {
      key: 'tags',
      label: $_('common.tags'),
      type: 'multiselect',
      icon: Tag,
      options: []
    },
    // System fields
    {
      key: 'createdBy',
      label: $_('common.created_by'),
      type: 'readonly',
      icon: User,
      getValue: (data) => data.createdBy?.name || data.createdBy?.email || '-'
    }
  ]);

  /**
   * Load column visibility from localStorage
   */
  function loadColumnVisibility() {
    if (typeof window === 'undefined') return;
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        // Filter to only include valid column keys
        visibleColumns = parsed.filter((key) => columns.some((c) => c.key === key));
      }
    } catch (e) {
      console.error('Failed to load column visibility:', e);
    }
  }

  // Auto-refresh every 30s for real-time sync across all org members
  let refreshInterval;
  $effect(() => {
    // Only run in browser, clean up on destroy
    if (typeof window !== 'undefined') {
      loadColumnVisibility();
      currentUser = getCurrentUser();
      refreshInterval = setInterval(() => {
        invalidateAll();
      }, 30000);
      return () => {
        if (refreshInterval) clearInterval(refreshInterval);
      };
    }
  });

  // Save to localStorage when column visibility changes
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

  /** @type {{ data: any }} */
  let { data } = $props();

  // Computed values
  const leads = $derived(data.leads || []);
  const pagination = $derived(data.pagination || { page: 1, limit: 10, total: 0, totalPages: 0 });
  const viewMode = $derived(data.viewMode || 'table');
  const kanbanData = $derived(data.kanbanData || null);

  // Total lead count - use kanban data when in kanban mode for accurate count
  const totalLeadCount = $derived(
    viewMode === 'kanban' && kanbanData ? kanbanData.total_leads : pagination.total
  );

  // Lazy-loaded form options (only fetched when drawer opens)
  let formOptions = $state(
    /** @type {{ users: any[], teamsList: any[], contactsList: any[], tagsList: any[] }} */ ({
      users: [],
      teamsList: [],
      contactsList: [],
      tagsList: []
    })
  );
  let formOptionsLoaded = $state(false);
  let formOptionsLoading = $state(false);
  let formOptionsError = $state('');

  /**
   * Load form options for drawer - uses pre-loaded server data
   */
  function loadFormOptions() {
    if (formOptionsLoaded || formOptionsLoading) return;

    formOptionsLoading = true;
    formOptionsError = '';
    try {
      // Use pre-loaded data from server (avoids client-side auth issues)
      const serverFormOptions = data.formOptions || { users: [], teams: [], contacts: [] };

      const users = serverFormOptions.users.map((/** @type {any} */ u) => ({
        value: u.id,
        label: u.name || u.email || 'Unknown'
      }));

      const teamsList = serverFormOptions.teams.map((/** @type {any} */ t) => ({
        value: t.id,
        label: t.name || 'Unknown'
      }));

      const contactsList = serverFormOptions.contacts.map((/** @type {any} */ c) => ({
        value: c.id,
        label: c.name || c.email || 'Unknown'
      }));

      // Tags are already loaded in the page data
      const tagsList = (data.tags || []).map((/** @type {any} */ t) => ({
        value: t.id,
        label: t.name || 'Unknown'
      }));

      formOptions = { users, teamsList, contactsList, tagsList };
      formOptionsLoaded = true;
    } catch (err) {
      console.error('Failed to load form options:', err);
      formOptionsError = 'Couldn�t load options';
    } finally {
      formOptionsLoading = false;
    }
  }

  function retryLoadFormOptions() {
    formOptionsLoaded = false;
    formOptionsLoading = false;
    formOptionsError = '';
    loadFormOptions();
  }

  // Read the URL synchronously at init so deep links (?view=ID / ?action=create)
  // prime the drawer state on the first frame instead of waiting for a $effect tick.
  const initialUrlParams = $page.url.searchParams;
  const initialViewId = initialUrlParams.get('view');
  const initialAction = initialUrlParams.get('action');
  const initialLead = initialViewId
    ? untrack(
        () => (data.leads || []).find((/** @type {any} */ l) => l.id === initialViewId) || null
      )
    : null;

  /** @type {string | null} */
  let activeRowId = $state(initialViewId || null);

  // Drawer state (NotionDrawer for view/create)
  let drawerOpen = $state(initialAction === 'create' || !!initialLead);
  /** @type {'view' | 'create'} */
  let drawerMode = $state(initialAction === 'create' ? 'create' : 'view');
  let drawerLoadError = $state('');
  /** @type {any} */
  let drawerLoadErrorLead = $state(null);
  /** @type {any} */
  let drawerData = $state(initialLead);

  // If we're opening the drawer from a deep link, kick off the form-option load
  // up front so multi-selects have data when the drawer mounts.
  if (untrack(() => drawerOpen)) {
    loadFormOptions();
  }
  let drawerLoading = $state(false);
  let isSaving = $state(false);
  let currentUser = $state(null);

  // Timeline state for drawer
  let drawerInteractions = $state(/** @type {any[]} */ ([]));
  let drawerInteractionsLoading = $state(false);
  let interactionDialogOpen = $state(false);
  let interactionDialogEntityName = $state('');

  // Selected timeline item for detail slide panel
  let selectedTimelineItem = $state(/** @type {any | null} */ (null));
  let timelineDetailOpen = $state(false);

  function openTimelineDetail(item) {
    selectedTimelineItem = item;
    timelineDetailOpen = true;
  }

  function closeTimelineDetail() {
    timelineDetailOpen = false;
    selectedTimelineItem = null;
  }

  async function fetchDrawerInteractions(leadId) {
    if (!leadId) return;
    drawerInteractionsLoading = true;
    try {
      const formData = new FormData();
      formData.append('leadId', leadId);
      const resp = await fetch('?/getInteractions', { method: 'POST', body: formData });
      const text = await resp.text();
      const result = deserialize(text);
      if (result.type === 'success' && result.data?.interactions) {
        drawerInteractions = result.data.interactions;
      } else if (result.type === 'failure') {
        console.error('Failed to fetch interactions:', result.data?.error);
        drawerInteractions = [];
      }
    } catch (err) {
      console.error('Failed to fetch interactions:', err);
      drawerInteractions = [];
    } finally {
      drawerInteractionsLoading = false;
    }
  }

  // Combined timeline from interactions + comments for drawer
  const drawerTimelineItems = $derived.by(() => {
    /** @type {Array<{ id: string, ts: string, kind: string, payload: any }>} */
    const items = [];
    for (const c of (drawerData?.comments || [])) {
      items.push({ id: `comment-${c.id}`, ts: c.commented_on || c.created_at || '', kind: 'comment', payload: c });
    }
    for (const i of drawerInteractions) {
      items.push({ id: `interaction-${i.id}`, ts: i.interaction_date || i.created_at || '', kind: 'interaction', payload: i });
    }
    if (drawerData?.createdAt) {
      items.push({ id: `created-${drawerData.id}`, ts: drawerData.createdAt, kind: 'created', payload: drawerData });
    }
    return items.sort((a, b) => new Date(b.ts).getTime() - new Date(a.ts).getTime());
  });

  // For create mode - temporary form data
  let createFormData = $state(
    /** @type {Record<string, any>} */ ({
      title: '',
      salutation: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      jobTitle: '',
      company: '',
      website: '',
      linkedinUrl: '',
      status: 'ASSIGNED',
      rating: '',
      leadSource: '',
      industry: '',
      opportunityAmount: '',
      probability: '',
      closeDate: '',
      lastContacted: '',
      nextFollowUp: '',
      addressLine: '',
      city: '',
      state: '',
      postcode: '',
      country: '',
      description: '',
      assignedTo: [],
      teams: [],
      contacts: [],
      tags: []
    })
  );

  // Current drawer data (either selected lead or create form data)
  const currentDrawerData = $derived(drawerMode === 'create' ? createFormData : drawerData);

  // Drawer columns with dynamic options for multi-selects
  const drawerColumnsWithOptions = $derived(
    drawerColumns.map((col) => {
      const multiselectExtras = {
        loading: formOptionsLoading,
        loadingError: formOptionsError,
        onRetry: retryLoadFormOptions
      };
      if (col.key === 'assignedTo')
        return { ...col, options: formOptions.users || [], ...multiselectExtras };
      if (col.key === 'teams')
        return { ...col, options: formOptions.teamsList || [], ...multiselectExtras };
      if (col.key === 'contacts')
        return { ...col, options: formOptions.contactsList || [], ...multiselectExtras };
      if (col.key === 'tags')
        return { ...col, options: formOptions.tagsList || [], ...multiselectExtras };
      return col;
    })
  );

  // URL sync
  $effect(() => {
    const viewId = $page.url.searchParams.get('view');
    const action = $page.url.searchParams.get('action');

    if (action === 'create') {
      drawerData = null;
      drawerMode = 'create';
      drawerOpen = true;
      // Lazy load form options when drawer opens via URL
      loadFormOptions();
    } else if (viewId && leads.length > 0) {
      const lead = leads.find((l) => l.id === viewId);
      if (lead) {
        drawerData = lead;
        drawerMode = 'view';
        drawerOpen = true;
        // Lazy load form options when drawer opens via URL
        loadFormOptions();
        // Fetch interactions for timeline
        drawerInteractions = [];
        fetchDrawerInteractions(lead.id);
      }
    }
  });

  /**
   * Update URL
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
    await goto(url.toString(), { replaceState: true, noScroll: true });
  }

  /**
   * Transform API lead data (snake_case) to frontend format (camelCase)
   * @param {any} lead - Raw lead data from API
   * @returns {any} Transformed lead data
   */
  function transformLeadData(lead) {
    return {
      id: lead.id,
      firstName: lead.first_name,
      lastName: lead.last_name,
      title: lead.title,
      salutation: lead.salutation,
      jobTitle: lead.job_title,
      company: lead.company_name,
      email: lead.email,
      phone: lead.phone,
      website: lead.website,
      linkedinUrl: lead.linkedin_url,
      status: lead.status ? lead.status.toUpperCase().replace(/ /g, '_') : 'ASSIGNED',
      leadSource: lead.source,
      industry: lead.industry,
      rating: lead.rating,
      opportunityAmount: lead.opportunity_amount,
      currency: lead.currency || null,
      probability: lead.probability,
      closeDate: lead.close_date,
      addressLine: lead.address_line,
      city: lead.city,
      state: lead.state,
      postcode: lead.postcode,
      country: lead.country,
      lastContacted: lead.last_contacted,
      nextFollowUp: lead.next_follow_up,
      description: lead.description,
      isConverted: lead.status === 'converted',
      isActive: lead.is_active,
      createdAt: lead.created_at,
      updatedAt: lead.updated_at || lead.created_at,
      owner: lead.assigned_to?.[0]
        ? {
            id: lead.assigned_to[0].id,
            name:
              lead.assigned_to[0].user?.email ||
              lead.assigned_to[0].user_details?.email ||
              'Unknown',
            email: lead.assigned_to[0].user?.email || lead.assigned_to[0].user_details?.email
          }
        : lead.created_by
          ? { id: lead.created_by.id, name: lead.created_by.email, email: lead.created_by.email }
          : null,
      assignedTo: (lead.assigned_to || []).map((/** @type {any} */ u) => u.id),
      teams: (lead.teams || []).map((/** @type {any} */ t) => t.id),
      contacts: (lead.contacts || []).map((/** @type {any} */ c) => c.id),
      tags: (lead.tags || []).map((/** @type {any} */ t) => t.id),
      comments: lead.lead_comments || [],
      attachments: lead.lead_attachment || []
    };
  }

  /**
   * Open drawer for viewing/editing a lead
   * @param {any} lead
   * @param {boolean} [fromKanban=false] - Whether the lead data is from kanban (needs full fetch)
   */
  async function openLead(lead, fromKanban = false) {
    drawerMode = 'view';
    drawerOpen = true;
    drawerLoadError = '';
    drawerLoadErrorLead = null;
    updateUrl(lead.id, null);
    // Load form options (uses pre-loaded server data)
    loadFormOptions();
    // Reset and fetch interactions
    drawerInteractions = [];
    fetchDrawerInteractions(lead.id);

    // If from kanban, we need to fetch full lead data since kanban cards have minimal data
    if (fromKanban) {
      drawerLoading = true;
      try {
        // Use server action to fetch lead (avoids client-side auth issues)
        const formData = new FormData();
        formData.append('leadId', lead.id);

        const response = await fetch('?/getLead', {
          method: 'POST',
          body: formData
        });

        const responseText = await response.text();
        const result = deserialize(responseText);

        // SvelteKit form actions return { type: 'success'|'failure'|'error', data: {...} }
        if (result.type === 'success' && result.data?.lead) {
          drawerData = result.data.lead;
        } else if (result.type === 'failure') {
          console.error('Server action failed:', result.data);
          const errorMsg = /** @type {{ error?: string }} */ (result.data)?.error;
          throw new Error(errorMsg || 'Failed to fetch lead');
        } else if (result.type === 'error') {
          console.error('Server action error:', result.error);
          throw new Error(result.error?.message || 'Failed to fetch lead');
        } else {
          // Handle unexpected response format
          console.warn('Unexpected response format:', result);
          throw new Error('Failed to fetch lead');
        }
      } catch (err) {
        console.error('Failed to fetch lead details:', err);
        toast.error('Failed to load lead details');
        // Fall back to what we have (minimal kanban data transformed) and
        // surface a banner so the user knows fields below are incomplete
        drawerData = {
          id: lead.id,
          title: lead.title || lead.full_name,
          company: lead.company_name,
          email: lead.email,
          rating: lead.rating,
          opportunityAmount: lead.opportunity_amount,
          currency: lead.currency,
          status: lead.status ? lead.status.toUpperCase().replace(/ /g, '_') : 'ASSIGNED'
        };
        drawerLoadError = 'Couldn�t load full details. Showing limited data.';
        drawerLoadErrorLead = lead;
      } finally {
        drawerLoading = false;
      }
    } else {
      // Lead data is already in the correct format (from table view)
      drawerData = lead;
    }
  }

  /**
   * Open drawer for creating a new lead
   */
  function openCreate() {
    // Reset create form data
    createFormData = {
      title: '',
      salutation: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      jobTitle: '',
      company: '',
      website: '',
      linkedinUrl: '',
      status: 'ASSIGNED',
      rating: '',
      leadSource: '',
      industry: '',
      opportunityAmount: '',
      probability: '',
      closeDate: '',
      lastContacted: '',
      nextFollowUp: '',
      addressLine: '',
      city: '',
      state: '',
      postcode: '',
      country: '',
      description: '',
      assignedTo: [],
      teams: [],
      contacts: [],
      tags: []
    };
    drawerData = null;
    drawerMode = 'create';
    drawerOpen = true;
    updateUrl(null, 'create');
    // Lazy load form options when drawer opens
    loadFormOptions();
  }

  /**
   * Close drawer
   * @returns {Promise<void>}
   */
  async function closeDrawer() {
    drawerOpen = false;
    drawerData = null;
    await updateUrl(null, null);
  }

  /**
   * Change view mode (table/kanban)
   * @param {'table' | 'kanban'} mode
   */
  async function setViewMode(mode) {
    const url = new URL($page.url);
    url.searchParams.set('viewMode', mode);
    // Reset to first page when switching views
    url.searchParams.set('page', '1');
    await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
  }

  /**
   * Handle kanban status change (drag-drop)
   * @param {string} leadId
   * @param {string} newStatus
   * @param {string} _columnId
   * @param {string | null} aboveLeadId
   * @param {string | null} belowLeadId
   */
  async function handleKanbanStatusChange(leadId, newStatus, _columnId, aboveLeadId, belowLeadId) {
    // Convert column ID (status) to proper format
    // Column IDs are: "assigned", "in process", "recycled", "closed"
    const status = newStatus;

    // Populate form and submit
    kanbanFormState.leadId = leadId;
    kanbanFormState.status = status;
    kanbanFormState.aboveLeadId = aboveLeadId || '';
    kanbanFormState.belowLeadId = belowLeadId || '';

    await tick();
    updateStatusForm.requestSubmit();
  }

  /**
   * Handle drawer open change
   * @param {boolean} open
   */
  function handleDrawerChange(open) {
    drawerOpen = open;
    if (!open) {
      drawerData = null;
      updateUrl(null, null);
    }
  }

  /**
   * Handle row change from NotionTable (inline editing)
   * @param {any} row
   * @param {string} field
   * @param {any} value
   */
  async function handleRowChange(row, field, value) {
    await handleQuickEdit(row, field, value);
  }

  /**
   * Handle field change from CrmDrawer - just updates local state
   * @param {string} field
   * @param {any} value
   */
  function handleDrawerFieldChange(field, value) {
    if (drawerMode === 'create') {
      // For create mode, just update the form data
      createFormData = { ...createFormData, [field]: value };
    } else if (drawerData) {
      // For edit mode, just update local data - no auto-save
      drawerData = { ...drawerData, [field]: value };
    }
  }

  /**
   * Handle save for view/edit mode
   */
  async function handleDrawerUpdate() {
    if (drawerMode !== 'view' || !drawerData) return;

    isSaving = true;
    // Populate form state with current drawer data
    const currentState = leadToFormState(drawerData);
    Object.assign(formState, currentState);

    await tick();
    updateForm.requestSubmit();
  }

  /**
   * Handle title change from NotionDrawer
   * @param {string} value
   */
  async function handleTitleChange(value) {
    if (drawerMode === 'create') {
      // Parse the name into firstName and lastName
      const parts = value.trim().split(' ');
      createFormData = {
        ...createFormData,
        title: value,
        firstName: parts[0] || '',
        lastName: parts.slice(1).join(' ') || ''
      };
    } else if (drawerData) {
      // For existing leads, update title
      await handleQuickEdit(drawerData, 'title', value);
    }
  }

  /**
   * Handle delete from NotionDrawer
   */
  async function handleDrawerDelete() {
    if (!drawerData) return;
    const lead = drawerData;
    closeDrawer();
    await handleRowDelete(lead);
  }

  /**
   * Handle convert from NotionDrawer
   */
  async function handleDrawerConvert() {
    if (!drawerData) return;
    formState.leadId = drawerData.id;
    await tick();
    convertForm.requestSubmit();
  }

  /**
   * Handle create new lead
   */
  async function handleCreateLead() {
    if (!createFormData.title?.trim()) {
      toast.error($_('leads.title_required') || 'Lead title is required');
      return;
    }

    isSaving = true;
    try {
      // Build payload in Django snake_case format for the REST API
      const payload = {
        title: createFormData.title,
        salutation: createFormData.salutation || undefined,
        first_name: createFormData.firstName || undefined,
        last_name: createFormData.lastName || undefined,
        email: createFormData.email || undefined,
        phone: createFormData.phone || undefined,
        job_title: createFormData.jobTitle || undefined,
        company_name: createFormData.company || undefined,
        website: createFormData.website || undefined,
        linkedin_url: createFormData.linkedinUrl || undefined,
        status: (createFormData.status || 'ASSIGNED').toLowerCase().replace(/_/g, ' '),
        source: (createFormData.leadSource || '').toLowerCase() || undefined,
        rating: createFormData.rating || undefined,
        industry: createFormData.industry || undefined,
        opportunity_amount: createFormData.opportunityAmount ? parseFloat(createFormData.opportunityAmount) : undefined,
        currency: createFormData.currency || $orgSettings.default_currency || 'USD',
        probability: createFormData.probability ? parseInt(createFormData.probability) : undefined,
        close_date: createFormData.closeDate || undefined,
        address_line: createFormData.addressLine || undefined,
        city: createFormData.city || undefined,
        state: createFormData.state || undefined,
        postcode: createFormData.postcode || undefined,
        country: createFormData.country || undefined,
        last_contacted: createFormData.lastContacted || undefined,
        next_follow_up: createFormData.nextFollowUp || undefined,
        description: createFormData.description || undefined,
        assigned_to: createFormData.assignedTo || [],
        teams: createFormData.teams || [],
        contacts: createFormData.contacts || [],
        tags: createFormData.tags || []
      };

      // Clean up undefined values
      Object.keys(payload).forEach(key => {
        if (payload[key] === undefined) delete payload[key];
      });

      await leadsApi.create(payload);

      toast.success($_('notifications.lead_created') || 'Lead created successfully');
      drawerOpen = false;
      drawerData = null;
      const url = new URL($page.url);
      url.searchParams.delete('view');
      url.searchParams.delete('action');
      await goto(url.toString(), { replaceState: true, noScroll: true, invalidateAll: true });
    } catch (err) {
      toast.error(err.message || 'Failed to create lead');
      console.error('Create lead error:', err);
    } finally {
      isSaving = false;
    }
  }

  // URL-based filter state from server
  const filters = $derived(data.filters);
  const filterOptions = $derived(data.filterOptions);

  // Count active filters (excluding status since it's handled via chips in header)
  const activeFiltersCount = $derived.by(() => {
    let count = 0;
    if (filters.search) count++;
    if (filters.source) count++;
    if (filters.rating) count++;
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
    [
      'search',
      'status',
      'source',
      'rating',
      'assigned_to',
      'tags',
      'created_at_gte',
      'created_at_lte'
    ].forEach((key) => url.searchParams.delete(key));
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

  // Status counts for filter chips
  const openStatuses = ['ASSIGNED', 'IN_PROCESS'];
  const lostStatuses = ['CLOSED', 'RECYCLED'];
  const openStatusIds = ['assigned', 'in process'];
  const lostStatusIds = ['closed', 'recycled'];

  // Calculate counts from kanban data or table data depending on view mode
  const openCount = $derived.by(() => {
    if (viewMode === 'kanban' && kanbanData?.columns) {
      return kanbanData.columns
        .filter((/** @type {any} */ c) => openStatusIds.includes(c.id))
        .reduce((/** @type {number} */ sum, /** @type {any} */ c) => sum + c.lead_count, 0);
    }
    return leads.filter((/** @type {any} */ l) => openStatuses.includes(l.status)).length;
  });
  const lostCount = $derived.by(() => {
    if (viewMode === 'kanban' && kanbanData?.columns) {
      return kanbanData.columns
        .filter((/** @type {any} */ c) => lostStatusIds.includes(c.id))
        .reduce((/** @type {number} */ sum, /** @type {any} */ c) => sum + c.lead_count, 0);
    }
    return leads.filter((/** @type {any} */ l) => lostStatuses.includes(l.status)).length;
  });

  // Status chip filter state (quick filter from UI)
  let statusChipFilter = $state('ALL');

  // Leads are already filtered server-side, just apply chip filter if active
  const filteredLeads = $derived.by(() => {
    let filtered = leads;
    if (statusChipFilter === 'open') {
      filtered = filtered.filter((/** @type {any} */ l) => openStatuses.includes(l.status));
    } else if (statusChipFilter === 'lost') {
      filtered = filtered.filter((/** @type {any} */ l) => lostStatuses.includes(l.status));
    }
    return filtered;
  });

  // Form references for server actions
  /** @type {HTMLFormElement} */
  let createForm;
  /** @type {HTMLFormElement} */
  let updateForm;
  /** @type {HTMLFormElement} */
  let deleteForm;
  /** @type {HTMLFormElement} */
  let convertForm;
  /** @type {HTMLFormElement} */
  let updateStatusForm;

  // Kanban form state (for drag-drop status updates)
  let kanbanFormState = $state({
    leadId: '',
    status: '',
    aboveLeadId: '',
    belowLeadId: ''
  });
  // Form data state
  let formState = $state({
    leadId: '',
    // Core Information
    salutation: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    title: '',
    jobTitle: '',
    website: '',
    linkedinUrl: '',
    // Sales Pipeline
    status: '',
    source: '',
    industry: '',
    rating: '',
    opportunityAmount: '',
    currency: '',
    probability: '',
    closeDate: '',
    // Address
    addressLine: '',
    city: '',
    state: '',
    postcode: '',
    country: '',
    // Activity
    lastContacted: '',
    nextFollowUp: '',
    description: '',
    // Assignment
    ownerId: '',
    assignedTo: /** @type {string[]} */ ([]),
    teams: /** @type {string[]} */ ([]),
    contacts: /** @type {string[]} */ ([]),
    tags: /** @type {string[]} */ ([])
  });

  /**
   * Get full name
   * @param {any} lead
   */
  function getFullName(lead) {
    const parts = [lead.firstName, lead.lastName].filter(Boolean);
    return parts.length > 0 ? parts.join(' ') : (lead.title || '');
  }

  /**
   * Get initials for lead
   * @param {any} lead
   */
  function getLeadInitials(lead) {
    return getNameInitials(lead.firstName, lead.lastName);
  }

  /**
   * Handle form submit from drawer
   * @param {any} formData
   */
  async function handleFormSubmit(formData) {
    // Populate form state
    // Core Information
    formState.firstName = formData.first_name || '';
    formState.lastName = formData.last_name || '';
    formState.email = formData.email || '';
    formState.phone = formData.phone || '';
    formState.company = formData.company_name || '';
    formState.title = formData.title || '';
    formState.jobTitle = formData.job_title || '';
    formState.website = formData.website || '';
    formState.linkedinUrl = formData.linkedin_url || '';
    // Sales Pipeline
    formState.status = formData.status || '';
    formState.source = formData.source || '';
    formState.industry = formData.industry || '';
    formState.rating = formData.rating || '';
    formState.opportunityAmount = formData.opportunity_amount || '';
    formState.currency = formData.currency || $orgSettings.default_currency || 'USD';
    formState.probability = formData.probability || '';
    formState.closeDate = formData.close_date || '';
    // Address
    formState.addressLine = formData.address_line || '';
    formState.city = formData.city || '';
    formState.state = formData.state || '';
    formState.postcode = formData.postcode || '';
    formState.country = formData.country || '';
    // Activity
    formState.lastContacted = formData.last_contacted || '';
    formState.nextFollowUp = formData.next_follow_up || '';
    formState.description = formData.description || '';

    await tick();

    if (drawerMode === 'view' && drawerData) {
      // Edit mode
      formState.leadId = drawerData.id;
      // Use existing owner when editing (form doesn't have owner selection)
      formState.ownerId = drawerData.owner?.id || '';
      await tick();
      updateForm.requestSubmit();
    } else {
      // Create mode
      formState.ownerId = '';
      createForm.requestSubmit();
    }
  }

  /**
   * Handle lead delete
   */
  async function handleDelete() {
    if (!drawerData) return;
    if (!confirm(`Are you sure you want to delete ${getFullName(drawerData)}?`)) return;

    formState.leadId = drawerData.id;
    await tick();
    deleteForm.requestSubmit();
  }

  /**
   * Handle lead convert
   */
  async function handleConvert() {
    if (!drawerData) return;

    formState.leadId = drawerData.id;
    await tick();
    convertForm.requestSubmit();
  }

  /**
   * Handle lead delete from row action
   * @param {any} lead
   */
  async function handleRowDelete(lead) {
    if (!confirm(`Are you sure you want to delete ${getFullName(lead)}?`)) return;

    formState.leadId = lead.id;
    await tick();
    deleteForm.requestSubmit();
  }

  /**
   * Convert lead to form state for quick edit
   * @param {any} lead
   */
  function leadToFormState(lead) {
    return {
      leadId: lead.id,
      salutation: lead.salutation || '',
      firstName: lead.firstName || '',
      lastName: lead.lastName || '',
      email: lead.email || '',
      phone: lead.phone || '',
      company: typeof lead.company === 'object' ? lead.company?.name || '' : lead.company || '',
      title: lead.title || '',
      jobTitle: lead.jobTitle || '',
      website: lead.website || '',
      linkedinUrl: lead.linkedinUrl || '',
      status: lead.status || '',
      source: lead.leadSource || '',
      industry: lead.industry || '',
      rating: lead.rating || '',
      opportunityAmount: lead.opportunityAmount || '',
      probability: lead.probability || '',
      closeDate: lead.closeDate || '',
      addressLine: lead.addressLine || '',
      city: lead.city || '',
      state: lead.state || '',
      postcode: lead.postcode || '',
      country: lead.country || '',
      lastContacted: lead.lastContacted || '',
      nextFollowUp: lead.nextFollowUp || '',
      description: lead.description || '',
      ownerId: lead.owner?.id || '',
      assignedTo: lead.assignedTo || [],
      teams: lead.teams || [],
      contacts: lead.contacts || [],
      tags: lead.tags || []
    };
  }

  /**
   * Handle quick edit from cell
   * @param {any} lead
   * @param {string} field
   * @param {string} value
   */
  async function handleQuickEdit(lead, field, value) {
    // Populate form state with current lead data
    const currentState = leadToFormState(lead);

    // Update the specific field
    currentState[field] = value;

    // Copy to form state
    Object.assign(formState, currentState);

    await tick();
    updateForm.requestSubmit();
  }

  /**
   * Create enhance handler for form actions
   * @param {string} successMessage
   * @param {boolean} shouldCloseDrawer
   */
  function createEnhanceHandler(successMessage, shouldCloseDrawer = true) {
    return () => {
      return async ({ result, update }) => {
        await update();
        isSaving = false;
        if (result.type === 'success') {
          toast.success(successMessage);
          if (shouldCloseDrawer) {
            // Close drawer state locally
            drawerOpen = false;
            drawerData = null;
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
</script>

<svelte:head>
  <title>Leads - BottleCRM</title>
</svelte:head>

<div
  class="flex flex-col"
  class:h-svh={viewMode === 'kanban'}
  class:overflow-hidden={viewMode === 'kanban'}
>
  <PageHeader
    title="Leads"
    subtitle="{viewMode === 'kanban'
      ? totalLeadCount
      : filteredLeads.length} of {totalLeadCount} leads"
  >
    {#snippet actions()}
      <div class="flex items-center gap-2">
        <!-- View Toggle -->
        <ViewToggle view={viewMode} onchange={setViewMode} />

        <div class="mx-1 h-6 w-px bg-[var(--border-default)]"></div>

        <!-- Status Filter Chips - Using design system tokens -->
        <div class="flex gap-1">
          <button
            type="button"
            onclick={() => (statusChipFilter = 'ALL')}
            class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
            'ALL'
              ? 'bg-[var(--text-primary)] text-[var(--surface-default)]'
              : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
          >
            All
            <span
              class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'ALL'
                ? 'bg-[var(--text-secondary)] text-[var(--surface-default)]'
                : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
            >
              {totalLeadCount}
            </span>
          </button>
          <button
            type="button"
            onclick={() => (statusChipFilter = 'open')}
            class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
            'open'
              ? 'bg-[var(--color-primary-default)] text-white'
              : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
          >
            Open
            <span
              class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'open'
                ? 'bg-[var(--color-primary-hover)] text-white/90'
                : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
            >
              {openCount}
            </span>
          </button>
          <button
            type="button"
            onclick={() => (statusChipFilter = 'lost')}
            class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium transition-colors {statusChipFilter ===
            'lost'
              ? 'bg-[var(--stage-lost)] text-white'
              : 'bg-[var(--surface-sunken)] text-[var(--text-secondary)] hover:bg-[var(--surface-raised)]'}"
          >
            Lost
            <span
              class="rounded-full px-1.5 py-0.5 text-xs {statusChipFilter === 'lost'
                ? 'bg-[var(--stage-lost)]/80 text-white/90'
                : 'bg-[var(--border-default)] text-[var(--text-tertiary)]'}"
            >
              {lostCount}
            </span>
          </button>
        </div>

        <div class="mx-1 h-6 w-px bg-[var(--border-default)]"></div>

        <!-- Column Visibility (only for table view) -->
        {#if viewMode === 'table'}
          <DropdownMenu.Root>
            <DropdownMenu.Trigger asChild>
              {#snippet child({ props })}
                <Button {...props} variant="outline" size="sm" class="gap-2">
                  <Eye class="h-4 w-4" />
                  Columns
                  {#if visibleColumns.length < columns.length}
                    <span
                      class="rounded-full bg-[var(--color-primary-light)] px-1.5 py-0.5 text-xs font-medium text-[var(--color-primary-default)] dark:bg-[var(--color-primary-default)]/15"
                    >
                      {visibleColumns.length}/{columns.length}
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
                  disabled={column.canHide === false}
                  onCheckedChange={() => toggleColumn(column.key)}
                >
                  {column.label}
                </DropdownMenu.CheckboxItem>
              {/each}
            </DropdownMenu.Content>
          </DropdownMenu.Root>
        {/if}

        <Button onclick={openCreate}>
          <Plus class="me-2 h-4 w-4" />
          New Lead
        </Button>
      </div>
    {/snippet}
    {#snippet tabs()}
      <ViewTabs views={[{ id: 'all', label: 'All', count: totalLeadCount }]} active="all" />
    {/snippet}
  </PageHeader>

  <div class="flex flex-1 flex-col" class:min-h-0={viewMode === 'kanban'}>
    <FilterStrip>
      <SearchInput
        value={filters.search}
        placeholder="Search leads..."
        showLabel={false}
        onchange={(value) => updateFilters({ ...filters, search: value })}
        class="w-64"
      />
      <SelectFilter
        label="Source"
        options={filterOptions.sources}
        value={filters.source || 'ALL'}
        onchange={(value) => updateFilters({ ...filters, source: value })}
        class="w-40"
      />
      <SelectFilter
        label="Rating"
        options={filterOptions.ratings}
        value={filters.rating || 'ALL'}
        onchange={(value) => updateFilters({ ...filters, rating: value })}
        class="w-32"
      />
      <DateRangeFilter
        label="Created"
        startDate={filters.created_at_gte}
        endDate={filters.created_at_lte}
        onchange={(start, end) =>
          updateFilters({ ...filters, created_at_gte: start, created_at_lte: end })}
        class="w-56"
      />
      <TagFilter
        tags={data.tags || []}
        value={filters.tags}
        onchange={(ids) => updateFilters({ ...filters, tags: ids })}
      />
      {#if activeFiltersCount > 0}
        <FilterPill label="Clear all" dashed onclick={clearFilters} />
      {/if}
      {#snippet meta()}
        <span>{filteredLeads.length} of {pagination.total} leads</span>
      {/snippet}
    </FilterStrip>

    <!-- Content: Table or Kanban -->
    {#if viewMode === 'kanban'}
      <!-- Kanban View -->
      <div class="flex min-h-0 flex-1 flex-col">
        <LeadKanban
          data={kanbanData}
          loading={!kanbanData}
          onStatusChange={handleKanbanStatusChange}
          onCardClick={(lead) => goto(`/leads/${lead.id}`)}
        />
      </div>
    {:else}
      <!-- Table View -->
      {#if filteredLeads.length === 0}
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <div
            class="mb-4 flex size-16 items-center justify-center rounded-[var(--radius-xl)] bg-[var(--surface-sunken)]"
          >
            <User class="size-8 text-[var(--text-tertiary)]" />
          </div>
          <h3 class="text-lg font-medium text-[var(--text-primary)]">No leads found</h3>
          <p class="mt-1 text-sm text-[var(--text-secondary)]">Create a new lead to get started</p>
        </div>
      {:else}
        <!-- Desktop Table using CrmTable -->
        <div class="hidden md:block">
          <CrmTable
            data={filteredLeads}
            {columns}
            bind:visibleColumns
            bind:activeRowId
            onRowChange={handleRowChange}
            onRowClick={(row) => goto(`/leads/${row.id}`)}
          >
            {#snippet emptyState()}
              <div class="flex flex-col items-center justify-center py-16 text-center">
                <div
                  class="mb-4 flex size-12 items-center justify-center rounded-[var(--radius-lg)] bg-[var(--surface-sunken)]"
                >
                  <User class="size-6 text-[var(--text-tertiary)]" />
                </div>
                <h3 class="text-lg font-medium text-[var(--text-primary)]">No leads found</h3>
              </div>
            {/snippet}
          </CrmTable>
        </div>

        <!-- Mobile Card View -->
        <div class="divide-y divide-[var(--border-default)]/50 md:hidden">
          {#each filteredLeads as lead (lead.id)}
            <button
              type="button"
              class="flex w-full items-start gap-3 px-4 py-3 text-start transition-colors hover:bg-[var(--color-primary-light)] dark:hover:bg-[var(--color-primary-default)]/5"
              onclick={() => goto(`/leads/${lead.id}`)}
            >
              <div class="min-w-0 flex-1">
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <p class="text-sm font-medium text-[var(--text-primary)]">
                      {getFullName(lead)}
                    </p>
                    {#if lead.company}
                      <p class="text-sm text-[var(--text-secondary)]">
                        {typeof lead.company === 'object' ? lead.company.name : lead.company}
                      </p>
                    {/if}
                  </div>
                  <span
                    class="shrink-0 rounded-full px-2 py-0.5 text-xs font-medium {getOptionStyle(
                      lead.status,
                      translatedStatusOptions
                    )}"
                  >
                    {getOptionLabel(lead.status, translatedStatusOptions)}
                  </span>
                </div>
                <div
                  class="mt-2 flex flex-wrap items-center gap-3 text-xs text-[var(--text-secondary)]"
                >
                  {#if lead.rating}
                    <span
                      class="rounded-full px-2 py-0.5 {getOptionStyle(
                        lead.rating,
                        translatedRatingOptions
                      )}"
                    >
                      {getOptionLabel(lead.rating, translatedRatingOptions)}
                    </span>
                  {/if}
                  <span>{formatRelativeDate(lead.createdAt)}</span>
                </div>
              </div>
            </button>
          {/each}

          <!-- Mobile new row button -->
          <button
            type="button"
            onclick={openCreate}
            class="flex w-full items-center gap-2 px-4 py-3 text-sm text-[var(--text-secondary)] transition-colors hover:bg-[var(--surface-raised)] hover:text-[var(--text-primary)]"
          >
            <Plus class="h-4 w-4" />
            New
          </button>
        </div>
      {/if}

      <!-- Pagination (only for table view) -->
      <Pagination
        page={pagination.page}
        limit={pagination.limit}
        total={pagination.total}
        onPageChange={handlePageChange}
        onLimitChange={handleLimitChange}
      />
    {/if}
  </div>
</div>

<!-- Lead Drawer -->
<CrmDrawer
  bind:open={drawerOpen}
  onOpenChange={handleDrawerChange}
  data={currentDrawerData}
  columns={drawerColumnsWithOptions}
  titleKey="title"
  titlePlaceholder={drawerMode === 'create' ? $_('leads.title') : $_('common.untitled')}
  headerLabel={drawerMode === 'create' ? $_('leads.create') : $_('leads.title')}
  mode={drawerMode}
  loading={drawerLoading}
  fullPageHref={drawerMode !== 'create' && drawerData?.id ? `/leads/${drawerData.id}` : ''}
  onFieldChange={handleDrawerFieldChange}
  onDelete={drawerMode !== 'create' ? handleDrawerDelete : undefined}
  onClose={closeDrawer}
>
  {#snippet banner()}
    {#if drawerLoadError}
      <div
        role="alert"
        class="mx-4 mt-3 flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[12px] text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/40 dark:text-amber-200"
      >
        <AlertTriangle class="mt-0.5 size-3.5 shrink-0" aria-hidden="true" />
        <div class="flex-1">
          <p class="font-medium">{drawerLoadError}</p>
          {#if drawerLoadErrorLead}
            <button
              type="button"
              onclick={() => drawerLoadErrorLead && openLead(drawerLoadErrorLead, true)}
              class="mt-1 inline-flex items-center gap-1 text-[11px] font-semibold underline-offset-2 hover:underline"
            >
              <RotateCw class="size-3" aria-hidden="true" />
              Retry
            </button>
          {/if}
        </div>
      </div>
    {/if}
  {/snippet}

  {#snippet metaSection()}
    {#if drawerData}
      <div
        class="flex flex-wrap items-center gap-x-2 gap-y-1 text-[12px] text-[color:var(--text-muted)]"
      >
        {#if drawerData.owner}
          <div class="flex items-center gap-1.5">
            <span
              class="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[color:var(--color-primary-light)] text-[10px] font-semibold text-[color:var(--color-primary-default)]"
              aria-hidden="true"
            >
              {getInitials(drawerData.owner.name || drawerData.owner.email) || '?'}
            </span>
            <span class="text-[color:var(--text)] font-medium">
              {drawerData.owner.name || drawerData.owner.email}
            </span>
          </div>
        {/if}
        {#if drawerData.createdAt}
          <span aria-hidden="true">�</span>
          <span title={new Date(drawerData.createdAt).toLocaleString('fa-IR-u-ca-persian')}>
            Created {formatDate(drawerData.createdAt)}
          </span>
        {/if}
        {#if drawerData.updatedAt && drawerData.updatedAt !== drawerData.createdAt}
          <span aria-hidden="true">�</span>
          <span title={new Date(drawerData.updatedAt).toLocaleString('fa-IR-u-ca-persian')}>
            Updated {formatRelativeDate(drawerData.updatedAt)}
          </span>
        {/if}
      </div>
    {/if}
  {/snippet}

  {#snippet activitySection()}
    {#if drawerMode !== 'create' && drawerData}
      <!-- Log Interaction Button -->
      <div class="mb-3 flex items-center justify-between px-5">
        <h4 class="text-[11px] font-semibold uppercase tracking-wider text-[var(--text-subtle)]">
          ??????
        </h4>
        <Button
          variant="ghost"
          size="sm"
          class="text-[11px]"
          onclick={() => {
            interactionDialogEntityName = drawerData?.title || '';
            interactionDialogOpen = true;
          }}
        >
          <Plus class="me-1 size-3" />
          ??? ?????
        </Button>
      </div>

      {#if drawerInteractionsLoading}
        <div class="space-y-3 px-5 pb-4">
          {#each [1, 2, 3] as _}
            <div class="h-12 w-full animate-pulse rounded-lg bg-[var(--surface-sunken)]"></div>
          {/each}
        </div>
      {:else}
        <Timeline isEmpty={drawerTimelineItems.length === 0}>
          {#each drawerTimelineItems as item (item.id)}
            {#if item.kind === 'interaction'}
              {@const i = item.payload}
              <li class="flex items-start gap-3 py-3.5 first:pt-0 last:pb-0 list-none">
                <button
                  type="button"
                  onclick={() => { selectedTimelineItem = item; timelineDetailOpen = true; }}
                  class="flex items-start gap-3 w-full text-end group"
                >
                  <div
                    aria-hidden="true"
                    class="flex size-7 shrink-0 items-center justify-center rounded-full border {i.interaction_type === 'call' ? 'bg-[color:var(--green)]/12 border-[color:var(--green)]/30 text-[color:var(--green)]' : i.interaction_type === 'email' ? 'bg-[color:var(--violet-soft)] border-[color:var(--violet)]/30 text-[color:var(--violet-soft-text)]' : 'bg-[color:var(--bg-elevated)] border-[color:var(--border-faint)] text-[color:var(--text-muted)]'}"
                  >
                    {#if i.interaction_type === 'call'}
                      <Phone class="size-3.5" />
                    {:else if i.interaction_type === 'email'}
                      <Mail class="size-3.5" />
                    {:else if i.interaction_type === 'meeting'}
                      <Users class="size-3.5" />
                    {:else}
                      <FileText class="size-3.5" />
                    {/if}
                  </div>
                  <div class="min-w-0 flex-1 text-end">
                    <div class="text-[13px] leading-[1.55] text-[color:var(--text-muted)] [&_strong]:font-medium [&_strong]:text-[color:var(--text)]">
                      <strong>{i.created_by?.name || i.created_by?.email || '?????'}</strong>
                      {i.subject ? ` � ${i.subject}` : ''}
                      {#if i.duration_minutes}
                        <span class="text-[var(--text-subtle)]"> ({i.duration_minutes} ?????)</span>
                      {/if}
                      {#if i.result}
                        <span class="ms-1.5 inline-flex items-center rounded-full bg-[var(--bg-elevated)] px-2 py-0.5 text-[10px] text-[var(--text-muted)]">
                          {i.result_display || i.result}
                        </span>
                      {/if}
                      {#if i.follow_up_date}
                        <span class="ms-1.5 text-[11px] text-[var(--text-subtle)]">
                          ? {formatDate(i.follow_up_date)}
                        </span>
                      {/if}
                    </div>
                    {#if i.description}
                      <blockquote class="mt-2 rounded-[var(--r-md)] border border-[color:var(--border-faint)] bg-[color:var(--bg-elevated)] px-3 py-2 text-[12px] leading-[1.5] text-[color:var(--text)]">
                        {i.description}
                      </blockquote>
                    {/if}
                    {#if item.ts}
                      <p class="mt-1.5 text-[11px] leading-none text-[color:var(--text-subtle)]">{formatRelativeDate(item.ts)}</p>
                    {/if}
                  </div>
                </button>
              </li>
            {:else if item.kind === 'comment'}
              <TimelineItem
                variant="violet"
                time={item.ts ? formatRelativeDate(item.ts) : ''}
                quote={item.payload.comment || ''}
              >
                {#snippet icon()}<MessageSquare class="size-3.5" />{/snippet}
                {#snippet text()}
                  <strong>{item.payload.commented_by_user || item.payload.commented_by?.name || '?????'}</strong> ??? ???
                {/snippet}
              </TimelineItem>
            {:else if item.kind === 'created'}
              <TimelineItem variant="success" time={item.ts ? formatRelativeDate(item.ts) : ''}>
                {#snippet icon()}<Calendar class="size-3.5" />{/snippet}
                {#snippet text()}???? ????? ??{/snippet}
              </TimelineItem>
            {/if}
          {/each}
        </Timeline>

        <!-- Interaction Detail Slide Panel -->
        {#if timelineDetailOpen && selectedTimelineItem?.kind === 'interaction'}
          {@const i = selectedTimelineItem.payload}
          <div
            class="fixed inset-y-0 right-0 z-[100] w-full animate-in slide-in-from-right data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right sm:max-w-md"
          >
            <div class="flex h-full flex-col border-l border-[var(--border-faint)] bg-[var(--bg)] shadow-xl">
              <!-- Header -->
              <div class="flex items-center justify-between border-b border-[var(--border-faint)] px-5 py-4">
                <div class="flex items-center gap-2">
                  <span class="rounded-md bg-[var(--bg-elevated)] px-2 py-1 text-[11px] font-semibold uppercase tracking-wider text-[var(--text-muted)]">
                    ?????? ?????
                  </span>
                </div>
                <button
                  type="button"
                  onclick={closeTimelineDetail}
                  class="flex h-7 w-7 items-center justify-center rounded-lg text-[var(--text-muted)] transition-colors hover:bg-[var(--bg-elevated)] hover:text-[var(--text)]"
                >
                  <X class="size-3.5" />
                </button>
              </div>

              <!-- Content -->
              <div class="flex-1 overflow-y-auto px-5 py-5">
                <div class="space-y-5">
                  <!-- Type badge -->
                  <div class="flex items-center gap-2">
                    <span class="inline-flex items-center gap-1.5 rounded-full border border-[var(--border-faint)] bg-[var(--bg-elevated)] px-3 py-1.5 text-[13px] font-medium text-[var(--text)]">
                      {#if i.interaction_type === 'call'}
                        <Phone class="size-3.5" />
                      {:else if i.interaction_type === 'email'}
                        <Mail class="size-3.5" />
                      {:else if i.interaction_type === 'meeting'}
                        <Users class="size-3.5" />
                      {:else}
                        <FileText class="size-3.5" />
                      {/if}
                      {i.interaction_type_display || i.interaction_type}
                    </span>
                    {#if i.result}
                      <span class="inline-flex items-center rounded-full bg-[var(--bg-elevated)] px-2.5 py-1 text-[11px] font-medium text-[var(--text-muted)]">
                        {i.result_display || i.result}
                      </span>
                    {/if}
                  </div>

                  <!-- Subject -->
                  {#if i.subject}
                    <div>
                      <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">?????</p>
                      <p class="mt-1 text-[14px] font-semibold text-[var(--text)]">{i.subject}</p>
                    </div>
                  {/if}

                  <!-- Description -->
                  {#if i.description}
                    <div>
                      <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">???????</p>
                      <p class="mt-1 text-[13px] leading-relaxed text-[var(--text)]">{i.description}</p>
                    </div>
                  {/if}

                  <!-- Details grid -->
                  <div class="grid grid-cols-2 gap-4">
                    {#if i.created_by?.name || i.created_by?.email}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">?????????</p>
                        <p class="mt-1 text-[13px] font-medium text-[var(--text)]">{i.created_by.name || i.created_by.email}</p>
                      </div>
                    {/if}
                    {#if i.interaction_date}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">????? ?????</p>
                        <p class="mt-1 text-[13px] text-[var(--text)]">{formatDate(i.interaction_date)}</p>
                      </div>
                    {/if}
                    {#if i.duration_minutes}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">??? ????</p>
                        <p class="mt-1 text-[13px] font-medium text-[var(--text)]">{i.duration_minutes} ?????</p>
                      </div>
                    {/if}
                    {#if i.follow_up_date}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">?????? ????</p>
                        <p class="mt-1 text-[13px] text-[var(--text)]">
                          <Calendar class="ms-1 inline size-3" />
                          {formatDate(i.follow_up_date)}
                        </p>
                      </div>
                    {/if}
                    {#if i.created_at}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">???? ???</p>
                        <p class="mt-1 text-[13px] text-[var(--text)]">{formatRelativeDate(i.created_at)}</p>
                      </div>
                    {/if}
                    {#if selectedTimelineItem?.ts}
                      <div>
                        <p class="text-[11px] font-medium uppercase tracking-wider text-[var(--text-subtle)]">????</p>
                        <p class="mt-1 text-[13px] text-[var(--text)]">{formatRelativeDate(selectedTimelineItem.ts)}</p>
                      </div>
                    {/if}
                  </div>
                </div>
              </div>
            </div>
          </div>
        {/if}

        <!-- Comment input at bottom -->
        <div class="mt-4 border-t border-[var(--border-faint)] pt-3">
          <CommentSection
            entityId={drawerData.id}
            entityType="leads"
            initialComments={drawerData.comments || []}
            currentUserEmail={currentUser?.email}
            isAdmin={currentUser?.organizations?.some((o) => o.role === 'ADMIN')}
          />
        </div>
      {/if}
    {/if}
  {/snippet}

  {#snippet footerActions()}
    {#if drawerMode === 'create'}
      <Button variant="outline" onclick={closeDrawer}>{$_('common.cancel')}</Button>
      <Button onclick={handleCreateLead} disabled={isSaving}>
        {#if isSaving}
          <Loader2 class="me-2 h-4 w-4 animate-spin" />
          {$_('common.saving')}
        {:else}
          {$_('leads.create')}
        {/if}
      </Button>
    {:else}
      <Button variant="outline" onclick={closeDrawer} disabled={isSaving}>{$_('common.cancel')}</Button>
      {#if drawerData?.status !== 'converted'}
        <Button variant="outline" onclick={handleDrawerConvert} disabled={isSaving}>
          <ArrowRightCircle class="me-2 h-4 w-4" />
          {$_('leads.convert')}
        </Button>
      {/if}
      <Button onclick={handleDrawerUpdate} disabled={isSaving}>
        {#if isSaving}
          <Loader2 class="me-2 h-4 w-4 animate-spin" />
          Saving...
        {:else}
          Save
        {/if}
      </Button>
    {/if}
  {/snippet}
</CrmDrawer>

<!-- Interaction Dialog for logging interactions from drawer -->
<InteractionDialog
  open={interactionDialogOpen}
  entityType="Lead"
  entityId={drawerData?.id || ''}
  entityName={interactionDialogEntityName}
  onClose={() => { interactionDialogOpen = false; }}
  onSuccess={() => {
    interactionDialogOpen = false;
    if (drawerData?.id) fetchDrawerInteractions(drawerData.id);
  }}
/>

<!-- Hidden forms for server actions -->
<form
  method="POST"
  action="?/create"
  bind:this={createForm}
  use:enhance={createEnhanceHandler('Lead created successfully')}
  class="hidden"
>
  <!-- Core Information -->
  <input type="hidden" name="salutation" value={formState.salutation} />
  <input type="hidden" name="firstName" value={formState.firstName} />
  <input type="hidden" name="lastName" value={formState.lastName} />
  <input type="hidden" name="email" value={formState.email} />
  <input type="hidden" name="phone" value={formState.phone} />
  <input type="hidden" name="company" value={formState.company} />
  <input type="hidden" name="title" value={formState.title} />
  <input type="hidden" name="jobTitle" value={formState.jobTitle} />
  <input type="hidden" name="website" value={formState.website} />
  <input type="hidden" name="linkedinUrl" value={formState.linkedinUrl} />
  <!-- Sales Pipeline -->
  <input type="hidden" name="status" value={formState.status} />
  <input type="hidden" name="source" value={formState.source} />
  <input type="hidden" name="industry" value={formState.industry} />
  <input type="hidden" name="rating" value={formState.rating} />
  <input type="hidden" name="opportunityAmount" value={formState.opportunityAmount} />
  <input type="hidden" name="currency" value={formState.currency} />
  <input type="hidden" name="probability" value={formState.probability} />
  <input type="hidden" name="closeDate" value={formState.closeDate} />
  <!-- Address -->
  <input type="hidden" name="addressLine" value={formState.addressLine} />
  <input type="hidden" name="city" value={formState.city} />
  <input type="hidden" name="state" value={formState.state} />
  <input type="hidden" name="postcode" value={formState.postcode} />
  <input type="hidden" name="country" value={formState.country} />
  <!-- Activity -->
  <input type="hidden" name="lastContacted" value={formState.lastContacted} />
  <input type="hidden" name="nextFollowUp" value={formState.nextFollowUp} />
  <input type="hidden" name="description" value={formState.description} />
  <!-- Assignment -->
  <input type="hidden" name="ownerId" value={formState.ownerId} />
  <input type="hidden" name="assignedTo" value={JSON.stringify(formState.assignedTo)} />
  <input type="hidden" name="teams" value={JSON.stringify(formState.teams)} />
  <input type="hidden" name="contacts" value={JSON.stringify(formState.contacts)} />
  <input type="hidden" name="tags" value={JSON.stringify(formState.tags)} />
  <button type="submit" class="hidden" aria-hidden="true"></button>
</form>

<form
  method="POST"
  action="?/update"
  bind:this={updateForm}
  use:enhance={createEnhanceHandler('Lead updated successfully')}
  class="hidden"
>
  <input type="hidden" name="leadId" value={formState.leadId} />
  <!-- Core Information -->
  <input type="hidden" name="salutation" value={formState.salutation} />
  <input type="hidden" name="firstName" value={formState.firstName} />
  <input type="hidden" name="lastName" value={formState.lastName} />
  <input type="hidden" name="email" value={formState.email} />
  <input type="hidden" name="phone" value={formState.phone} />
  <input type="hidden" name="company" value={formState.company} />
  <input type="hidden" name="title" value={formState.title} />
  <input type="hidden" name="jobTitle" value={formState.jobTitle} />
  <input type="hidden" name="website" value={formState.website} />
  <input type="hidden" name="linkedinUrl" value={formState.linkedinUrl} />
  <!-- Sales Pipeline -->
  <input type="hidden" name="status" value={formState.status} />
  <input type="hidden" name="source" value={formState.source} />
  <input type="hidden" name="industry" value={formState.industry} />
  <input type="hidden" name="rating" value={formState.rating} />
  <input type="hidden" name="opportunityAmount" value={formState.opportunityAmount} />
  <input type="hidden" name="currency" value={formState.currency} />
  <input type="hidden" name="probability" value={formState.probability} />
  <input type="hidden" name="closeDate" value={formState.closeDate} />
  <!-- Address -->
  <input type="hidden" name="addressLine" value={formState.addressLine} />
  <input type="hidden" name="city" value={formState.city} />
  <input type="hidden" name="state" value={formState.state} />
  <input type="hidden" name="postcode" value={formState.postcode} />
  <input type="hidden" name="country" value={formState.country} />
  <!-- Activity -->
  <input type="hidden" name="lastContacted" value={formState.lastContacted} />
  <input type="hidden" name="nextFollowUp" value={formState.nextFollowUp} />
  <input type="hidden" name="description" value={formState.description} />
  <!-- Assignment -->
  <input type="hidden" name="ownerId" value={formState.ownerId} />
  <input type="hidden" name="assignedTo" value={JSON.stringify(formState.assignedTo)} />
  <input type="hidden" name="teams" value={JSON.stringify(formState.teams)} />
  <input type="hidden" name="contacts" value={JSON.stringify(formState.contacts)} />
  <input type="hidden" name="tags" value={JSON.stringify(formState.tags)} />
  <button type="submit" class="hidden" aria-hidden="true"></button>
</form>

<form
  method="POST"
  action="?/delete"
  bind:this={deleteForm}
  use:enhance={createEnhanceHandler('Lead deleted successfully')}
  class="hidden"
>
  <input type="hidden" name="leadId" value={formState.leadId} />
  <button type="submit" class="hidden" aria-hidden="true"></button>
</form>

<form
  method="POST"
  action="?/convert"
  bind:this={convertForm}
  use:enhance={createEnhanceHandler('Lead converted successfully')}
  class="hidden"
>
  <input type="hidden" name="leadId" value={formState.leadId} />
  <button type="submit" class="hidden" aria-hidden="true"></button>
</form>

<form
  method="POST"
  action="?/updateStatus"
  bind:this={updateStatusForm}
  use:enhance={createEnhanceHandler('Lead status updated successfully', false)}
  class="hidden"
>
  <input type="hidden" name="leadId" bind:value={kanbanFormState.leadId} />
  <input type="hidden" name="status" bind:value={kanbanFormState.status} />
  <input type="hidden" name="aboveLeadId" bind:value={kanbanFormState.aboveLeadId} />
  <input type="hidden" name="belowLeadId" bind:value={kanbanFormState.belowLeadId} />
  <button type="submit" class="hidden" aria-hidden="true"></button>
</form>
