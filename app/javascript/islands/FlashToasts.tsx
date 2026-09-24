import { useEffect } from "react"
import { toast } from "sonner"
import { Toaster } from "../components/ui/sonner"

type Props = {
  message: { id: string; text: string } | null
  label: string
  dismissLabel: string
  onConsume: (id: string) => void
}

export default function FlashToasts({ message, label, dismissLabel, onConsume }: Props) {
  useEffect(() => {
    if (!message) return
    const id = toast.success(message.text, { id: message.id, toasterId: "application-flash" })
    onConsume(message.id)
    return () => {
      toast.dismiss(id)
    }
  }, [message, onConsume])

  return (
    <Toaster
      id="application-flash"
      position="bottom-right"
      duration={5000}
      visibleToasts={1}
      closeButton
      containerAriaLabel={label}
      toastOptions={{ closeButtonAriaLabel: dismissLabel }}
      offset={{ bottom: "max(1.5rem, env(safe-area-inset-bottom))", right: "1.5rem" }}
      mobileOffset={{ bottom: "max(1rem, env(safe-area-inset-bottom))", left: "1rem", right: "1rem" }}
    />
  )
}
