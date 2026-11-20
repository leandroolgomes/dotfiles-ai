# Recipe: web app (Playwright / Chrome DevTools)

- **Start:** the repo's dev server (`pnpm dev`), wait for the port: `npx wait-on http://localhost:<port>`
  if it's a dependency, else a curl loop.
- **Drive:** the Playwright MCP tools (plugin enabled in dotfiles) or a small script using the repo's
  `@playwright/test` if it has one. Navigate with the map's route, act with its selectors (prefer
  `data-testid`, then roles and labels; avoid brittle CSS paths).
- **Observe:** a screenshot per step, console errors (fail on any `error`), failed network requests,
  and the DOM text you expect.
- **Performance:** a trace (`page.tracing` / Chrome DevTools Performance) and long tasks > 50 ms; compare
  before/after the change on the same steps.
- **Electron:** start with `--remote-debugging-port=9222` and connect over CDP the same way.
- **Stop:** close the browser and kill the dev server.
