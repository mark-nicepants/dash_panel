/**
 * Column Toggle Component
 * Manages column visibility state for resource tables with localStorage persistence.
 * Uses DashWire's generic storage utilities.
 */
export function initColumnToggle() {
  /**
   * Apply column visibility state to a table.
   * Toggles 'column-hidden' class on elements with data-column attribute.
   */
  function applyState(slug, state) {
    const container = document.querySelector(`[data-resource-slug="${slug}"]`);
    if (!container) {
      return;
    }
    Object.keys(state).forEach((column) => {
      const isVisible = state[column] ?? true;
      container.querySelectorAll(`[data-column="${column}"]`).forEach((el) => {
        el.classList.toggle('column-hidden', !isVisible);
      });
    });
  }

  // Register Alpine.js component
  document.addEventListener('alpine:init', () => {
    Alpine.data('columnVisibility', (slug, defaults) => ({
      open: false,
      slug,
      defaults,
      state: {},
      init() {
        // Use DashWire's generic storage utilities
        this.state = window.DashWire.storage.load(`columns:${slug}`, defaults);
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
        window.DashWire.storage.save(`columns:${this.slug}`, this.state);
        this.apply();
      },
      apply() {
        applyState(this.slug, this.state);
      },
    }));
  });
}
