import IslandController from "./IslandController"

type Message = { id: string; text: string }

export default class FlashToastsController extends IslandController {
  get componentProps() {
    const message = (this.propsValue as { message: Message | null }).message
    return {
      ...super.componentProps,
      message: message?.id === this.element.getAttribute("data-consumed-toast") ? null : message,
      onConsume: this.consume,
    }
  }

  consume = (id: string) => {
    // This marker survives Turbo's snapshot; a restored page must not replay a delivered toast.
    this.element.setAttribute("data-consumed-toast", id)
    this.element.querySelector("[data-transient-message]")?.remove()
  }
}
