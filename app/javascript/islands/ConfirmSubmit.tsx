import { Trash2Icon } from "lucide-react"
import * as React from "react"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Button } from "@/components/ui/button"

type Props = {
  title: string
  description: string
  triggerLabel: string
  confirmLabel: string
  cancelLabel: string
  disabled: boolean
  size: React.ComponentProps<typeof Button>["size"]
  onConfirm: () => void
}

export default function ConfirmSubmit({
  title,
  description,
  triggerLabel,
  confirmLabel,
  cancelLabel,
  disabled,
  size,
  onConfirm,
}: Props) {
  const [submitting, setSubmitting] = React.useState(false)
  const [open, setOpen] = React.useState(false)
  const cancel = React.useRef<HTMLButtonElement>(null)
  return (
    <AlertDialog open={open} onOpenChange={setOpen}>
      <AlertDialogTrigger
        render={<Button type="button" variant="ghost" size={size} disabled={disabled || submitting} />}
      >
        <Trash2Icon className="size-4" data-icon="inline-start" aria-hidden="true" />
        {triggerLabel}
      </AlertDialogTrigger>
      <AlertDialogContent initialFocus={cancel}>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel ref={cancel} type="button">
            {cancelLabel}
          </AlertDialogCancel>
          <AlertDialogAction
            type="button"
            disabled={submitting}
            onClick={() => {
              if (submitting) return
              setSubmitting(true)
              setOpen(false)
              onConfirm()
            }}
          >
            {confirmLabel}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
