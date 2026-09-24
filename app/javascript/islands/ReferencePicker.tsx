import { cn } from "cn"
import * as React from "react"
import { Button } from "@/components/ui/button"
import {
  Combobox,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxInput,
  ComboboxItem,
  ComboboxList,
  ComboboxTrigger,
} from "@/components/ui/combobox"
import { Label } from "@/components/ui/label"

type Props = {
  name: string
  id: string
  value: string | null
  options: { value: string; label: string }[]
  label: string
  error?: string | null
  required: boolean
  disabled: boolean
  copy: { placeholder: string; search: string; options: string; empty: string; clear: string }
  onValueChange: (value: string) => void
}

export default function ReferencePicker({
  name,
  id,
  value,
  options,
  label,
  error,
  required,
  disabled,
  copy,
  onValueChange,
}: Props) {
  const [open, setOpen] = React.useState(false)
  const [selectedValue, setSelectedValue] = React.useState(String(value ?? ""))
  const trigger = React.useRef<HTMLButtonElement>(null)
  const items = React.useMemo(
    () => (required ? options : [{ value: "", label: copy.clear }, ...options]),
    [options, required, copy.clear],
  )
  const selected = options.find((option) => option.value === selectedValue) ?? null
  const errorId = `${id}-error`
  const labelId = `${id}-label`

  return (
    <div
      className="field"
      data-island="reference-picker"
      onInvalid={(event) => {
        event.preventDefault()
        trigger.current?.focus()
        setOpen(true)
      }}
    >
      <Label id={labelId} htmlFor={id}>
        {label}
      </Label>
      <Combobox
        name={name}
        items={items}
        value={selected}
        required={required}
        disabled={disabled}
        open={open}
        onOpenChange={setOpen}
        autoHighlight
        onValueChange={(option) => {
          const nextValue = option?.value ?? ""
          setSelectedValue(nextValue)
          onValueChange(nextValue)
        }}
      >
        <ComboboxTrigger
          id={id}
          ref={trigger}
          aria-labelledby={labelId}
          aria-describedby={error ? errorId : undefined}
          aria-invalid={Boolean(error)}
          render={
            <Button
              type="button"
              variant="outline"
              className={cn("w-full min-w-0 justify-between font-normal", !selected && "text-muted-foreground")}
            />
          }
        >
          <span className="truncate">{selected?.label ?? copy.placeholder}</span>
        </ComboboxTrigger>
        <ComboboxContent className="min-w-0 max-w-[calc(100vw-2rem)]" aria-label={copy.options}>
          <ComboboxInput showTrigger={false} aria-label={copy.search} placeholder={copy.search} />
          <ComboboxEmpty>{copy.empty}</ComboboxEmpty>
          <ComboboxList aria-label={copy.options}>
            {(option) => (
              <ComboboxItem key={option.value} value={option}>
                <span className="min-w-0 flex-1 truncate">{option.label}</span>
              </ComboboxItem>
            )}
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
      {error && (
        <p id={errorId} className="field-errors">
          {error}
        </p>
      )}
    </div>
  )
}
