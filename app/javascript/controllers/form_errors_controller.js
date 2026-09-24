import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  focus(event) {
    const input = document.getElementById(event.currentTarget.hash.slice(1))
    const enhanced = input?.closest('[data-island-enhanced="true"]')
    const target = enhanced ? document.getElementById(input.dataset.enhancedId) : input
    const label = target?.labels?.[0]
    if (!label || target.disabled) return
    event.preventDefault()
    label.scrollIntoView()
    target.focus({ preventScroll: true })
  }
}
