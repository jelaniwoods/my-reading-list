import { MenuIcon, XIcon } from "lucide-react"
import * as React from "react"
import { Button } from "@/components/ui/button"
import { Sheet, SheetClose, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"

type Props = {
  html: string
  title: string
  menuLabel: string
  closeLabel: string
}

export default function ResponsiveNavigation({ html, title, menuLabel, closeLabel }: Props) {
  const [open, setOpen] = React.useState(false)

  React.useEffect(() => {
    const desktop = window.matchMedia("(min-width: 64rem)")
    const closeOnDesktop = () => {
      if (desktop.matches) setOpen(false)
    }
    desktop.addEventListener("change", closeOnDesktop)
    return () => desktop.removeEventListener("change", closeOnDesktop)
  }, [])

  return (
    <>
      {/* This HTML is the escaped, authorized Rails navigation partial, never user-supplied markup. */}
      {/* biome-ignore lint/security/noDangerouslySetInnerHtml: Rails renders the links and CSRF-bearing forms. */}
      <div className="app-navigation-desktop app-navigation-content" dangerouslySetInnerHTML={{ __html: html }} />
      <div className="app-navigation-mobile">
        <Sheet open={open} onOpenChange={setOpen}>
          <SheetTrigger render={<Button type="button" variant="ghost" />}>
            <MenuIcon aria-hidden="true" />
            {menuLabel}
          </SheetTrigger>
          <SheetContent side="left" showCloseButton={false} aria-describedby={undefined}>
            <SheetHeader className="pr-16">
              <SheetTitle>{title}</SheetTitle>
              <SheetClose
                render={
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon-sm"
                    className="absolute top-3 right-3"
                    aria-label={closeLabel}
                  />
                }
              >
                <XIcon aria-hidden="true" />
              </SheetClose>
            </SheetHeader>
            {/* biome-ignore lint/security/noDangerouslySetInnerHtml: Same server-rendered partial as the desktop navigation. */}
            <div className="app-navigation-content app-navigation-sheet" dangerouslySetInnerHTML={{ __html: html }} />
          </SheetContent>
        </Sheet>
      </div>
    </>
  )
}
