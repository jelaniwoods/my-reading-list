import { CSPProvider } from "@base-ui/react/csp-provider"
import * as React from "react"

type Lifecycle = { onReady: () => void; onFailure: (error: Error) => void }

class RenderBoundary extends React.Component<React.PropsWithChildren<Lifecycle>, { failed: boolean }> {
  state = { failed: false }

  static getDerivedStateFromError() {
    return { failed: true }
  }

  componentDidCatch(error: Error) {
    this.props.onFailure(error)
  }

  render() {
    return this.state.failed ? null : this.props.children
  }
}

export function withIslandBoundary<P extends object>(Component: React.ComponentType<P>, nonce?: string) {
  function Committed(props: P & Lifecycle) {
    React.useLayoutEffect(() => props.onReady(), [props.onReady])
    return <Component {...props} />
  }

  return function Island(props: P & Lifecycle) {
    return (
      <RenderBoundary onReady={props.onReady} onFailure={props.onFailure}>
        <CSPProvider nonce={nonce}>
          <Committed {...props} />
        </CSPProvider>
      </RenderBoundary>
    )
  }
}
