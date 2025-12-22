/**
 * Web component that handles column hover highlighting for calendar grids.
 * When hovering anywhere in the grid, finds the day column at that position
 * and highlights all cells in that column with data-col-hovered attribute.
 * Works even when hovering over reservation cards that span multiple columns.
 */
class CalendarColumnHover extends HTMLElement {
  constructor() {
    super()
    this._currentHoveredCol = null
    this._currentHoveredElement = null
    this._handleMouseMove = this._handleMouseMove.bind(this)
    this._handleMouseLeave = this._handleMouseLeave.bind(this)
  }

  connectedCallback() {
    this.addEventListener("mousemove", this._handleMouseMove)
    this.addEventListener("mouseleave", this._handleMouseLeave)
  }

  disconnectedCallback() {
    this.removeEventListener("mousemove", this._handleMouseMove)
    this.removeEventListener("mouseleave", this._handleMouseLeave)
    this._clearHover()
  }

  _handleMouseMove(event) {
    // Find all elements at the current mouse position
    const elementsAtPoint = document.elementsFromPoint(event.clientX, event.clientY)

    // Find the day column element (either directly hovered or underneath)
    const dayColElement = elementsAtPoint.find(el =>
      el.hasAttribute("data-day-col") && this.contains(el)
    )

    if (!dayColElement) {
      this._clearHover()
      return
    }

    // Update current element highlight
    if (dayColElement !== this._currentHoveredElement) {
      this._clearCurrentElement()
      this._currentHoveredElement = dayColElement
      dayColElement.setAttribute("data-hover-current", "")
    }

    const col = dayColElement.dataset.dayCol
    if (col === this._currentHoveredCol) return

    this._clearColumnHover()
    this._currentHoveredCol = col
    this._setColumnHover(col)
  }

  _handleMouseLeave() {
    this._clearHover()
  }

  _setColumnHover(col) {
    const elements = this.querySelectorAll(`[data-day-col="${col}"]`)
    elements.forEach(el => el.setAttribute("data-col-hovered", ""))
  }

  _clearCurrentElement() {
    if (this._currentHoveredElement) {
      this._currentHoveredElement.removeAttribute("data-hover-current")
      this._currentHoveredElement = null
    }
  }

  _clearColumnHover() {
    if (!this._currentHoveredCol) return
    const elements = this.querySelectorAll("[data-col-hovered]")
    elements.forEach(el => el.removeAttribute("data-col-hovered"))
    this._currentHoveredCol = null
  }

  _clearHover() {
    this._clearCurrentElement()
    this._clearColumnHover()
  }
}

// Register the custom element
if (!customElements.get("calendar-column-hover")) {
  customElements.define("calendar-column-hover", CalendarColumnHover)
}

export default CalendarColumnHover
