# Agent instructions — iOS Foundation Core

This repository owns the schema-independent Hotwire Native iOS shell used by
First Draft's Compiler. Keep Core product-independent: application identity,
routes, tabs, path rules, assets, and optional native capabilities belong to
explicit Compiler replacement seams.

## Working rules

- Use the installed Xcode toolchain and the shared scheme for verification.
- Run `bin/ios doctor`, `bin/ios lint`, `bin/ios build`, and `bin/ios test`.
- Keep builds unsigned and repeatable from those source-owned commands.
- Pin Swift package dependencies exactly and commit `Package.resolved`.
- Test a behavioral change red before trusting it green.
- Keep safe-area ownership in UIKit/Hotwire Native. Do not combine Rails
  `viewport-fit=cover` and generic `env(safe-area-inset-*)` padding with
  automatic native adjustment; a composed smoke must prove any edge-to-edge
  replacement.
- Do not add accounts, push, signing, distribution, universal links, or other
  capabilities to Core.
- Update `FOUNDATION.md` when a Core/generated replacement seam changes.
