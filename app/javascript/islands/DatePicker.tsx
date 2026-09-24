import { CalendarIcon } from "lucide-react"
import * as React from "react"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"

type Props = {
  name: string
  id: string
  value: string | null
  min?: string | null
  max?: string | null
  label: string
  error?: string | null
  required: boolean
  disabled: boolean
  locale: string
  copy: { open: string; calendar: string; previous: string; next: string; today: string; selected: string }
  onValueChange: (value: string) => void
}

function localDate(value: string): Date | undefined {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return undefined
  const [year, month, day] = value.split("-").map(Number)
  const date = new Date(0)
  date.setHours(0, 0, 0, 0)
  date.setFullYear(year, month - 1, day)
  return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day ? date : undefined
}

function railsDate(date: Date): string {
  return `${String(date.getFullYear()).padStart(4, "0")}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`
}

export default function DatePicker({
  name,
  id,
  value,
  min,
  max,
  label,
  error,
  required,
  disabled,
  locale,
  copy,
  onValueChange,
}: Props) {
  const [open, setOpen] = React.useState(false)
  const [selectedValue, setSelectedValue] = React.useState(value ?? "")
  const errorId = `${id}-error`
  const selectedDate = localDate(selectedValue)
  const minimum = min ? localDate(min) : undefined
  const maximum = max ? localDate(max) : undefined
  const month = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" })
  const weekday = new Intl.DateTimeFormat(locale, { weekday: "short" })
  const fullDate = new Intl.DateTimeFormat(locale, { dateStyle: "full" })

  function select(nextValue: string) {
    setSelectedValue(nextValue)
    onValueChange(nextValue)
  }

  return (
    <div className="field" data-island="date-picker">
      <Label htmlFor={id}>{label}</Label>
      <div className="flex min-w-0 items-center gap-2">
        <Input
          id={id}
          name={name}
          type="date"
          value={selectedValue}
          min={min ?? undefined}
          max={max ?? undefined}
          required={required}
          disabled={disabled}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? errorId : undefined}
          onChange={(event) => select(event.target.value)}
        />
        <Popover open={open} onOpenChange={setOpen}>
          <PopoverTrigger
            render={<Button type="button" variant="outline" size="icon" disabled={disabled} aria-label={copy.open} />}
          >
            <CalendarIcon className="size-4" aria-hidden="true" />
          </PopoverTrigger>
          <PopoverContent
            align="end"
            collisionPadding={8}
            className="w-auto max-w-[calc(100vw-2rem)] overflow-auto p-0 hotwire-native:max-w-[calc(100vw-1rem)]"
            aria-label={copy.calendar}
          >
            <Calendar
              className="hotwire-native:px-0.5"
              mode="single"
              selected={selectedDate}
              defaultMonth={selectedDate}
              startMonth={minimum}
              endMonth={maximum}
              disabled={[...(minimum ? [{ before: minimum }] : []), ...(maximum ? [{ after: maximum }] : [])]}
              formatters={{
                formatCaption: (date) => month.format(date),
                formatWeekdayName: (date) => weekday.format(date),
              }}
              labels={{
                labelPrevious: () => copy.previous,
                labelNext: () => copy.next,
                labelGrid: (date) => month.format(date),
                labelWeekday: (date) => fullDate.format(date),
                labelDayButton: (date, modifiers) =>
                  [fullDate.format(date), modifiers.today && copy.today, modifiers.selected && copy.selected]
                    .filter(Boolean)
                    .join(", "),
              }}
              onSelect={(date) => {
                select(date ? railsDate(date) : "")
                setOpen(false)
              }}
              autoFocus
            />
          </PopoverContent>
        </Popover>
      </div>
      {error && (
        <p id={errorId} className="field-errors">
          {error}
        </p>
      )}
    </div>
  )
}
