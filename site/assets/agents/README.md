# agents

Six agent marks used by the "Set up with your coding agent" module, in order:
`codex.svg`, `claude-code.svg`, `cursor.svg`, `opencode.svg`, `pi.svg`, `gemini-cli.svg`.

- Source: [LobeHub icons](https://github.com/lobehub/lobe-icons) (static SVGs, fetched at
  build time and stored locally). Fetched from
  `https://unpkg.com/@lobehub/icons-static-svg@latest/icons/<slug>.svg`; Codex/Claude/Gemini
  use their `-color` variants, Cursor/OpenCode/Pi are the monochrome marks.
- The marks are rendered at 22px (desktop) / 20px (mobile) via `<img alt="">`, with the
  agent name provided as visually-hidden text and a native `title` tooltip. No hotlinking:
  the page loads these files, so there are no runtime third-party image requests.

**Trademarks** belong to their respective owners (OpenAI/Codex, Anthropic/Claude, Cursor,
OpenCode, Pi, Google/Gemini). They are used here only to identify compatible tools. If you
re-distribute, confirm each owner's brand guidelines.

> The **Pi** mark is from LobeHub's icon set; confirm it is the intended "Pi" agent and
> replace with the official mark if not.
