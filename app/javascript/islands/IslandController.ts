import { TurboMountController } from "turbo-mount"

type FieldProps = {
  value?: string | null
  disabled?: boolean
  required?: boolean
  label?: string
  error?: string | null
  options?: { label: string; value: string }[]
}

export default class IslandController extends TurboMountController {
  connect() {
    super.connect()
    document.addEventListener("turbo:before-cache", this.beforeCache)
    document.addEventListener("turbo:render", this.afterRender)
    this.element.addEventListener("turbo:before-morph-element", this.beforeMorph)
    this.element.addEventListener("change", this.fallbackChanged)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
    document.removeEventListener("turbo:render", this.afterRender)
    this.element.removeEventListener("turbo:before-morph-element", this.beforeMorph)
    this.element.removeEventListener("change", this.fallbackChanged)
    super.disconnect()
    this.showFallback()
  }

  propsValueChanged() {
    this.syncFallback()
    super.propsValueChanged()
  }

  get componentProps() {
    return {
      ...this.propsValue,
      onValueChange: this.valueChanged,
      onConfirm: this.confirm,
      onReady: this.showEnhanced,
      onFailure: this.failed,
    }
  }

  valueChanged = (value: string) => {
    const props = this.propsValue as FieldProps
    if (props.value !== value) this.setComponentProps({ ...props, value })
    const input = this.element.querySelector<HTMLInputElement | HTMLSelectElement>("[data-island-input]")
    if (input) input.value = value
  }

  fallbackChanged = (event: Event) => {
    const input = event.target
    if (
      (input instanceof HTMLInputElement || input instanceof HTMLSelectElement) &&
      input.matches("[data-island-input]") &&
      !input.disabled
    ) {
      this.valueChanged(input.value)
    }
  }

  confirm = () => {
    const form = this.element.querySelector("[data-island-fallback] form")
    if (!(form instanceof HTMLFormElement)) throw new Error("ConfirmSubmit requires its Rails DELETE form")
    form.requestSubmit()
  }

  showEnhanced = () => {
    const fallback = this.element.querySelector<HTMLElement>("[data-island-fallback]")
    if (fallback) fallback.hidden = true
    this.element.querySelectorAll<HTMLInputElement>("[data-island-input]").forEach((input) => {
      input.disabled = true
    })
    this.element.setAttribute("data-island-enhanced", "true")
  }

  showFallback() {
    this.element.setAttribute("data-island-enhanced", "false")
    this.syncFallback()
    const fallback = this.element.querySelector<HTMLElement>("[data-island-fallback]")
    if (fallback) fallback.hidden = false
  }

  // Turbo Mount preserves an island during morphs; keep its native recovery UI current too.
  syncFallback() {
    const props = this.propsValue as FieldProps
    const input = this.element.querySelector<HTMLInputElement | HTMLSelectElement>("[data-island-input]")
    if (input) {
      if (input instanceof HTMLSelectElement && props.options) {
        input.replaceChildren(
          new Option("", ""),
          ...props.options.map((option) => new Option(option.label, option.value)),
        )
      }
      input.value = String(props.value ?? "")
      input.required = Boolean(props.required)
      input.disabled = Boolean(props.disabled) || this.element.getAttribute("data-island-enhanced") === "true"
      input.setAttribute("aria-invalid", String(Boolean(props.error)))
    }
    const label = this.element.querySelector("[data-island-label]")
    if (label && props.label) label.textContent = props.label
    const errors = this.element.querySelector<HTMLElement>("[data-island-errors]")
    if (errors) {
      errors.textContent = props.error ?? ""
      errors.hidden = !props.error
      if (input && props.error) input.setAttribute("aria-describedby", errors.id)
      else input?.removeAttribute("aria-describedby")
    }
  }

  failed = (error: Error) => {
    this.showFallback()
    this.application.handleError(
      error,
      `Could not enhance ${this.componentValue}; the Rails control remains available`,
      {
        controller: this,
      },
    )
  }

  // Remove portals and scroll locks before Turbo snapshots the ordinary Rails fallback.
  beforeCache = () => {
    this.umountComponent()
    this.showFallback()
  }

  // A cached page morph can preserve the controller and unchanged props after unmounting.
  afterRender = () => {
    if (this.element.isConnected) super.connect()
  }

  beforeMorph = (event: Event) => {
    if (event.target !== this.element) return
    const replacement = (event as CustomEvent<{ newElement: Element }>).detail.newElement
    const nextFallback = replacement.querySelector<HTMLElement>("[data-island-fallback]")
    const currentFallback = this.element.querySelector<HTMLElement>("[data-island-fallback]")
    if (!nextFallback || !currentFallback) return
    const fallback = nextFallback.cloneNode(true) as HTMLElement
    fallback.hidden = currentFallback.hidden
    if (fallback.hidden) {
      fallback.querySelectorAll<HTMLInputElement>("[data-island-input]").forEach((input) => {
        input.disabled = true
      })
    }
    currentFallback.replaceWith(fallback)
  }
}
