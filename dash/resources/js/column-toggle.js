/**
 * Column Toggle Component
 * Manages column visibility state for resource tables with localStorage persistence.
 */
export function initColumnToggle() {
  const STORAGE_PREFIX = 'dash:columns:';
  const stateRegistry = window.DashColumnToggleStates = window.DashColumnToggleStates || {};

  function storageKey(slug) {
    return STORAGE_PREFIX + slug;
  }

  function loadState(slug, defaults) {
    try {
      const raw = window.localStorage.getItem(storageKey(slug));
      if (raw) {
        const parsed = JSON.parse(raw);
        return { ...defaults, ...parsed };
      }
    } catch (_) {
      // Ignore storage issues (private browsing, etc.)
    }
    return { ...defaults };
  }

  function saveState(slug, state) {
    try {
      window.localStorage.setItem(storageKey(slug), JSON.stringify(state));
    } catch (_) {
      // Ignore persistence failures and keep state in memory
    }
  }

  function applyState(slug, state) {
    const container = document.querySelector('[data-table-container="true"][data-resource-slug="' + slug + '"]');
    if (!container) {
      return;
    }
    Object.keys(state).forEach((column) => {
      const isVisible = state[column] ?? true;
      container.querySelectorAll('[data-column="' + column + '"]').forEach((el) => {
        el.classList.toggle('column-hidden', !isVisible);
      });
    });
  }

  // Export public API
  window.DashColumnToggle = {
    load: loadState,
    save: saveState,
    apply: applyState,
  };

  // Alpine.js integration
  document.addEventListener('alpine:init', () => {
    Alpine.data('columnVisibility', (slug, defaults) => ({
      open: false,
      slug,
      defaults,
      state: {},
      init() {
        this.state = window.DashColumnToggle.load(slug, defaults);
        stateRegistry[slug] = this.state;
        this.apply();
      },
      isVisible(column) {
        return this.state[column] ?? true;
      },
      toggle(column) {
        this.state[column] = !this.isVisible(column);
        this.persist();
      },
      showAll() {
        Object.keys(this.defaults).forEach((col) => {
          this.state[col] = true;
        });
        this.persist();
      },
      hideAll() {
        Object.keys(this.defaults).forEach((col) => {
          this.state[col] = false;
        });
        this.persist();
      },
      reset() {
        this.state = { ...this.defaults };
        this.persist();
      },
      persist() {
        stateRegistry[this.slug] = this.state;
        window.DashColumnToggle.save(this.slug, this.state);
        this.apply();
      },
      apply() {
        window.DashColumnToggle.apply(this.slug, this.state);
      },
    }));
  });

  // HTMX integration - reapply state after partial updates
  document.addEventListener('htmx:afterSwap', (event) => {
    const target = event.target;
    if (window.Alpine && target instanceof Element) {
      window.Alpine.initTree(target);
    }
    if (!(target instanceof Element)) {
      return;
    }
    const slug = target.getAttribute('data-resource-slug');
    if (slug && stateRegistry[slug]) {
      window.DashColumnToggle.apply(slug, stateRegistry[slug]);
    }
  });
}