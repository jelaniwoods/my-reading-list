import { readFile, rm } from "node:fs/promises"
import { build, context } from "esbuild"

const production = process.env.RAILS_ENV === "production" || process.env.NODE_ENV === "production"
const watch = process.argv.includes("--watch")
const output = "app/assets/builds/application.js"

const options = {
  entryPoints: ["app/javascript/application.js"],
  bundle: true,
  format: "esm",
  minify: production,
  outfile: output,
  publicPath: "/assets",
  sourcemap: !production,
  plugins: [
    {
      name: "sonner-external-css",
      setup(builder) {
        builder.onLoad({ filter: /sonner\/dist\/index\.mjs$/ }, async ({ path }) => {
          const source = await readFile(path, "utf8")
          const injection = /^__insertCSS\(.+\);$/gm
          if (source.match(injection)?.length !== 1) {
            throw new Error("Sonner CSS packaging changed; review the external stylesheet integration")
          }
          // The same upstream CSS is in our stylesheet bundle; omit its runtime copy without a CSP nonce.
          return { contents: source.replace(injection, ""), loader: "js" }
        })
      },
    },
  ],
}

if (production) await rm(`${output}.map`, { force: true })

if (watch) {
  const buildContext = await context(options)
  await buildContext.watch()
  console.log("Watching JavaScript…")
} else {
  await build(options)
}
