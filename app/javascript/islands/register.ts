import type { Application } from "@hotwired/stimulus"
import type { ComponentType } from "react"
import { TurboMount } from "turbo-mount"
import { registerComponent } from "turbo-mount/react"
import ConfirmSubmit from "./ConfirmSubmit"
import FlashToasts from "./FlashToasts"
import FlashToastsController from "./FlashToastsController"
import { withIslandBoundary } from "./IslandBoundary"
import IslandController from "./IslandController"
import ResponsiveNavigation from "./ResponsiveNavigation"

export function registerIslands(application: Application) {
  const nonce = document.querySelector<HTMLMetaElement>('meta[name="csp-nonce"]')?.content
  const turboMount = new TurboMount({ application })
  registerComponent(
    turboMount,
    "ConfirmSubmit",
    withIslandBoundary(ConfirmSubmit, nonce) as ComponentType,
    IslandController,
  )
  registerComponent(
    turboMount,
    "ResponsiveNavigation",
    withIslandBoundary(ResponsiveNavigation, nonce) as ComponentType,
    IslandController,
  )
  registerComponent(
    turboMount,
    "FlashToasts",
    withIslandBoundary(FlashToasts, nonce) as ComponentType,
    FlashToastsController,
  )
  return turboMount
}
