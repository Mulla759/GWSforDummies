# GWS for Dummies — Redesign Direction

## Goal

Redesign the current landing page into a quiet, elegant, one-page product manual.

The site should feel like a carefully typeset sheet of paper with a useful tool embedded inside it: calm, human, precise, and fast. It should not feel like a generic AI/SaaS template.

**North star:** a small, trustworthy open-source utility presented with the restraint of a personal design studio.

## Starting point

The original page had useful copy and a clear product, but the dark background, glow, blue gradient, pills, and repeated cards made it feel like a generic AI/SaaS template. The redesign has now corrected most of that baseline problem with a paper palette, editorial layout, persistent navigation, embedded documentation, and a human contact surface.

Do not regress to the old visual language while adding polish. The remaining work is about making the product behavior feel alive and tightening the new system.

## Reference synthesis

Use the references as a system, not as pages to clone.

| Reference | Borrow | Do not borrow |
| --- | --- | --- |
| [Minimum](https://desengs.com/minimum/) | Restraint, white space, confidence in small amounts of content | Random minimalism with no product hierarchy |
| [Imran Studio](https://www.imran.studio/) | Persistent left rail, quiet labels, generous vertical spacing, narrow readable copy | The very long portfolio taxonomy |
| [Dogancan](https://www.dogancan.dev/) | Compact personal introduction, copy-email feedback, understated link treatment | Resume-style content density |
| [Jay Suthar](https://sutharjay.com/) | Short functional labels, plain-spoken links, small editorial image moments | A bare list with too little product explanation |
| [Paul Faivret](https://www.paulfaivret.com/) | Primary page flow: statement → explanation → large visual → repeat; thin dividers; broad media frames | Portfolio carousels or excessive project length |
| [Abdullahi’s Gravatar](https://gravatar.com/tremendousdelectablye2bab3e728) | Profile image and verified identity details for the contact area | The Gravatar card styling |

## Current live iteration audit — September 14, 2026

**Overall grade: 8.3 / 10**

This is a strong redesign and a large improvement over the original. The grade is based on a live desktop inspection of `https://gws-for-dummies.vercel.app/` plus the supplied workflow-visual frame. It is a design/implementation review, not a complete Lighthouse or device-lab audit.

| Area | Grade | Assessment |
| --- | ---: | --- |
| Visual direction | `9.0` | The warm paper canvas, ink typography, thin lines, and limited blue accent feel intentional and much more elegant. |
| Hierarchy and copy | `8.8` | The hero communicates the outcome quickly, and the safety promise is unusually clear. |
| Navigation | `8.7` | The sticky rail is simple and useful. The blue square active state fits the system. |
| Feature presentation | `8.2` | The stacked rows and proof tables are clearer than the old card grid, though several rows still feel structurally similar. |
| Product storytelling | `7.2` | The terminal proof helps, but the larger abstract workflow graphic does not yet explain how messages move through the agents. |
| Motion and interaction | `6.8` | Copy and hover states are present, but the page has no memorable product-behavior moment yet. Existing `500ms` entrance transitions can also feel slower than the rest of the interface. |
| Accessibility and trust | `8.8` | Skip navigation, semantic headings, visible safety language, copy feedback, and portrait alt text are strong. The explanatory workflow still needs an accessible static description. |
| Performance discipline | `8.5` | The page is visually light and avoids animation libraries. Final scoring still needs a production Lighthouse run and mobile verification. |

### What is working now

- The site no longer looks “vibe coded.” It has a coherent design opinion.
- The hero is confident without relying on decorative imagery.
- The left rail gives the page an identity and keeps Docs and Contact reachable.
- The command row makes the first action obvious.
- Feature labels such as `PREDICTABLE`, `UNDOABLE`, `READ-ONLY`, and `IDEMPOTENT` build trust efficiently.
- The feature tables feel like product evidence rather than marketing cards.
- The Docs and Contact sections complete the story on one route.
- The restrained blue square is becoming a useful motion and state motif.

### What still holds it back

1. **The workflow visual is too abstract.** The pale boxes and lines match the palette, but they currently look like a loading skeleton. A visitor cannot tell what is moving, who is acting, or what was produced.
2. **The page needs one signature interaction.** The animation described below should become that moment. Do not add motion everywhere else.
3. **Some vertical gaps are slightly overextended.** Keep the editorial breathing room, but tighten the gap before `What it does` and before `Docs` by roughly `24–40px` if the page still feels slow after the workflow animation is added.
4. **Deep-linked section positioning needs verification.** Loading `#features` can leave the section heading too low in the first viewport. Apply a consistent `scroll-margin-top` and test direct hash loads.
5. **Entrance transitions are a little long.** Reduce generic reveal motion from `500ms` to about `320–380ms`; reserve the longer timeline only for the explanatory workflow.
6. **Arrow semantics should be consistent.** Use `↗` only for external destinations. Use `↓`, `→`, or no arrow for in-page links.

### Highest-priority next pass

1. Replace the static workflow placeholder with the agentic trickle animation below.
2. Fix direct anchor positioning and verify the active rail state on load.
3. Shorten generic reveal transitions.
4. Run mobile, keyboard, reduced-motion, and Lighthouse checks.

## Core design principles

1. **Paper, not dashboard.** Use an off-white canvas, ink-like text, faint rules, and almost no filled containers.
2. **One page, one story.** Overview, documentation, and contact remain on the same route and are reached through anchor navigation.
3. **Explain before decorating.** Every visual must demonstrate a product outcome or create useful pacing.
4. **Buttons say the result.** Use labels such as “Copy the setup command” and “Open the full runbook,” not “Learn more.”
5. **One accent color.** Blue marks actions and focus. It is not a background effect.
6. **Human at the end.** The contact section should make the project feel maintained by a real person.
7. **Fast by construction.** Prefer HTML and CSS over animation or component libraries.

## Page architecture

### Desktop shell

Use a two-column page grid:

- **Left rail:** `200–220px`, sticky, top aligned, never boxed.
- **Content column:** `minmax(0, 880px)` with a maximum width of about `920px`.
- **Outer gutter:** `32px` minimum, growing on wide screens.
- **Reading measure:** body copy should usually stop at `58–68ch`, even when media extends wider.

The left rail contains:

```text
GWS for Dummies

Overview
What it does
Docs
Contact me

GitHub ↗
```

Requirements:

- “GWS for Dummies” is the home/overview link and strongest item.
- Active section is shown with darker text plus a small 1px rule or square marker. Do not use a pill.
- Use hash links: `#overview`, `#features`, `#docs`, and `#contact`.
- Update the active item with `IntersectionObserver`; do not attach a scroll listener that fires every frame.
- Keep the rail visually quiet. Inactive items use muted gray.

### Mobile shell

- Replace the side rail with a compact sticky top bar.
- Left: “GWS for Dummies.” Right: `Docs` and `Contact`.
- Do not add a hamburger for only two destinations.
- Allow normal document scrolling; navigation should jump to the same anchors.

## Recommended one-page flow

### 1. Overview / hero

Use a large text statement with substantial empty space above and below it.

**Eyebrow**

`GMAIL · TASKS · CALENDAR`

**Headline**

> Turn a crowded inbox into a system you can understand.

**Supporting copy**

> GWS for Dummies lets you tell an AI coding agent what you want in plain English. It uses the Google Workspace CLI to label mail, create Tasks and Calendar events, and prepare useful recaps without sending, trashing, or deleting anything.

**Primary action row**

- `Copy the setup command`
- `Read the docs ↓`

Below the copy, add a single thin rule with a small square position marker. This can subtly move as the user travels through the page, echoing Paul Faivret’s pacing without copying his exact treatment.

### 2. Setup command

Keep the current “Give this to your agent” idea, but remove the large glowing card.

Present it as a paper-like command row:

```text
Give this to your agent
Paste one line into Codex, Claude Code, or another coding agent.

set up gws for dummies — https://gws-for-dummies.vercel.app/llms.txt    [Copy]
```

Style:

- White or `--paper-subtle` background.
- One 1px border, `8px` radius maximum.
- Monospace only for the command.
- The button has an explicit accessible name: “Copy the setup command.”
- After activation, change the label to `Copied ✓` for about 1.6 seconds and announce it through `aria-live="polite"`.
- Keyboard focus must be clearly visible.

### 3. Product proof image

Add one wide visual directly after setup. This is the first major rhythm break.

Preferred content, in order:

1. A real terminal or agent screenshot showing the setup command and a successful triage result.
2. A composed screenshot pairing a clean inbox label list with Tasks/Calendar output.
3. Only if product imagery is unavailable, use a restrained editorial stock image of a calm desk, paper inbox, or organized work surface.

The frame should be approximately `16:9`, softly rounded (`10–12px`), and should not have a fake browser chrome, neon glow, or heavy shadow. Add a small caption beneath it.

### 3A. Signature agentic trickle animation

Use the supplied pale workflow frame as the location and visual base for one restrained animation. This is the only complex motion moment on the page.

#### What the animation should communicate

A few messages enter a queue. The orchestrator reads each one, decides what it means, and hands it to the correct specialist. The specialists produce a label, a Task, or a Calendar event. The sequence ends by confirming that nothing was sent or deleted.

The visitor should understand the system without reading the surrounding paragraph:

```text
incoming messages → triage orchestrator → label agent / task agent / calendar agent → audited result
```

This is a product explanation, not an abstract loading animation.

#### Composition

Keep the existing rounded paper frame and thin-line language.

- **Left third — inbox queue:** three stacked message rows. Use short believable subjects such as `Invoice received`, `Action required`, and `Meeting moved`.
- **Center — orchestrator:** one narrow rectangular node labeled `triage orchestrator`. It may contain a tiny two-line activity log.
- **Right third — specialist outputs:** three quiet rectangular destinations labeled `label agent`, `task agent`, and `calendar agent`.
- **Bottom edge — audit line:** a single status row that ends with `✓ nothing sent, trashed, or deleted`.
- Connect areas with thin `--line` paths. Use the blue square as the moving data packet. Do not add circles, robot avatars, dotted particle clouds, or branching neon lines.

The diagram should remain approximately `878 × 307px` in the current desktop content area. Implement it responsively with an SVG `viewBox`, not hard-coded viewport pixels.

#### Text pop-ups

Show small paper tooltips as the agents work. These are the important storytelling layer.

Use a maximum of two at once:

```text
24 messages found
Reading sender + intent…
Finance → label agent
Invoice → task agent
Meeting → calendar agent
Safety check passed
```

Tooltip styling:

- `11–12px` monospace.
- `--paper` background, `1px solid var(--line)`, `6px` radius.
- Small `6px 8px` padding.
- No heavy shadow; use at most `0 4px 14px rgb(0 0 0 / 0.05)`.
- Enter with opacity plus `translateY(4px)`; exit with opacity only.
- Never scale, bounce, blur, or float continuously.

#### Storyboard and timing

Run the sequence once when at least 35% of the figure enters the viewport. Total duration should be about `8.4 seconds`.

| Time | Phase | Motion and copy |
| ---: | --- | --- |
| `0.0–0.7s` | Wake | The frame fades from `0.75` to full opacity. The first blue square appears beside the inbox queue. |
| `0.7–2.0s` | Trickle in | Three message rows arrive one at a time, `180–240ms` apart. Small blue squares travel toward the orchestrator. Show `24 messages found`. |
| `2.0–3.2s` | Read | The orchestrator border changes from `--line` to a low-opacity blue. Its two activity lines fill from left to right. Show `Reading sender + intent…`. |
| `3.2–5.8s` | Route | Route the three examples one at a time. Each blue square follows one path to the correct specialist while the matching pop-up appears: `Finance → label agent`, `Invoice → task agent`, then `Meeting → calendar agent`. |
| `5.8–7.1s` | Produce | Each destination reveals a compact result: `Finance`, `Reply to invoice · Fri`, and `Tue · 10:00`. Use a tiny blue square/check as confirmation. |
| `7.1–8.4s` | Audit | Draw the bottom rule from left to right and reveal `✓ nothing sent, trashed, or deleted`. Hold on this completed state. |

Do **not** loop automatically. The final resolved state is the most informative state, so leave it visible. Add a small `Replay flow` text button in the upper-right corner of the figure for anyone who wants to see it again.

#### Motion behavior

- Use ease-out for entrances and a near-linear curve for packets traveling along paths.
- Packet travel: `520–700ms` per route.
- Tooltip transition: `160ms`.
- Node activation: `180–220ms`.
- Audit-line draw: `500–650ms`.
- Pause the animation when the document is hidden.
- If the figure leaves the viewport mid-run, pause it; resume when visible rather than restarting.
- Clicking `Replay flow` resets to the initial frame and starts the sequence again.
- Do not tie progress to page scroll. Scroll-scrubbing will make the explanation harder to follow.

#### Implementation direction

Use an inline SVG plus a very small state controller. Do not use Canvas, video, GIF, Lottie, GSAP, or Framer Motion.

Recommended component:

```text
AgenticFlowFigure
├── InboxQueue
├── OrchestratorNode
├── RoutePaths
├── SpecialistNodes
├── StatusPopups
├── AuditLine
└── ReplayButton
```

Use one root state value:

```text
idle → ingest → classify → route-label → route-task → route-calendar → audit → complete
```

Implementation rules:

- Render the entire semantic figure on the server; JavaScript only advances `data-phase` on the root.
- Use `IntersectionObserver` with a threshold near `0.35` to start once.
- Use one ordered array of phase durations rather than scattered independent timers.
- Clean up every timer and observer on unmount.
- Drive SVG and tooltip changes from `[data-phase="..."]` selectors and CSS transitions.
- For curved paths, animate small square packets with SVG `<animateMotion>` or a short Web Animations API routine. Keep all orchestration local to this component.
- Never generate random positions or timings. The sequence must be deterministic.
- Keep the added client-side code small; the animation must not become the largest JavaScript feature on the page.
- Add a static caption below the figure: `Illustrative flow — messages are classified, routed to specialist agents, and checked before changes are made.`

#### Reduced-motion and accessibility behavior

- The animated SVG is `aria-hidden="true"` because its movement and repeated text should not be announced.
- The `<figure>` receives an accessible description that explains the complete flow in one sentence.
- Do not send each phase through `aria-live`; that would repeatedly interrupt screen-reader users.
- Under `prefers-reduced-motion: reduce`, skip the timeline and immediately display the completed state with all three results and the safety check visible.
- Keep `Replay flow` keyboard reachable, with a visible focus ring and an accessible name.
- Do not rely on color alone. Active agents also gain a label/check or stronger line weight.

#### Animation acceptance criteria

- A first-time visitor can correctly describe that email is classified and routed to label, Task, and Calendar specialists.
- The animation runs only when visible and does not loop endlessly.
- No more than two pop-ups are present simultaneously.
- The final state remains readable indefinitely.
- The frame still feels like the surrounding white-paper site.
- No layout shift occurs when the animation starts.
- Reduced-motion users receive the same information without movement.
- The added animation does not drop the production Lighthouse Performance score below `95`.

### 4. What it does

Replace the four-card grid with four stacked editorial rows. Each row has a short explanation followed by either an image, screenshot, or quiet diagram.

| Label | Title | Copy | Action label |
| --- | --- | --- | --- |
| `01 / TRIAGE` | Triage mail into clean labels | Understands sender and intent, then applies a predictable label taxonomy. | `See the label rules` |
| `02 / ACT` | Turn action mail into Tasks and events | Creates traceable Tasks and Calendar events with source links and undo notes. | `See what gets created` |
| `03 / RECAP` | Review the week without reopening every thread | Produces a read-only summary of meetings, unread mail, and triage activity. | `Preview a recap` |
| `04 / AUTOPILOT` | Keep the inbox organized overnight | Runs deterministic, idempotent sender-to-label rules locally or in GitHub Actions. | `See the nightly workflow` |

Row anatomy:

- A thin divider.
- Small uppercase/monospace label on the left.
- Year-style metadata on the right can instead show `READ-ONLY`, `UNDOABLE`, or `IDEMPOTENT`.
- Title and description above the media, following Paul Faivret’s text-to-image pacing.
- Do not place each row inside a card.
- Use a compact text link or small outline button. Avoid large pill CTAs.

### 5. Image rhythm

Use visuals as pauses between dense explanations, similar to the pacing on Paul Faivret’s page and the smaller image moment on Jay Suthar’s page.

Recommended sequence:

- Hero: real product/terminal image.
- After feature 2: one editorial stock image.
- After feature 4: one real workflow or recap screenshot.

Stock-image direction:

- Quiet, documentary, naturally lit, slightly warm.
- Subjects: an organized desk, a handwritten task list beside a laptop, an overhead mail/paper composition, or a calm end-of-day workspace.
- Avoid smiling-office-team stock, fake futuristic AI imagery, Gmail logos pasted into a scene, gradients, floating glass cards, and 3D blobs.
- Download approved images into the repository instead of hotlinking them.
- Confirm licensing and add credit metadata in the repository when required.
- Crop to consistent `3:2` or `16:9` frames; use `object-fit: cover`.

### 6. Docs

Docs live on the same page under `#docs`. This section should feel like a concise manual, not a second marketing page.

Use this structure:

```text
Docs
Set up in three steps.

01  Install
02  Authenticate
03  Ask your agent

[copyable command blocks]

Safety model
Reads and labels. Never sends, trashes, or deletes.

Links
Agent runbook  /llms.txt
Source code    github.com/Mulla759/GWSforDummies
GWS CLI        github.com/googleworkspace/cli
```

Implementation notes:

- Commands use the same reusable `CopyRow` component as the hero.
- Keep explanations visible; do not hide all documentation in accordions.
- Long optional details may use native `<details>` elements.
- Deep links should work with hashes such as `#docs-install` and `#docs-safety`.
- If a full docs route already exists later, the one-page section remains the quick start and may link outward using `Open the full runbook ↗`.

### 7. Contact me

End with a wide, warm-gray contact section that is visually distinct but still part of the paper system.

Use Abdullahi’s Gravatar profile image:

```text
https://0.gravatar.com/avatar/d61f0bf8a6e712531b4ba4899fb8934fd93865b4f1d7fa4aa0a4b7601c0d4344?size=512&d=initials
```

Suggested content:

```text
[profile image]

Built by Abdullahi Abdi
Student · Computer scientist

Have a setup issue, an improvement, or a workflow worth adding?
I’d like to hear about it.

[Copy my email]   [GitHub ↗]   [LinkedIn ↗]
```

Use verified profile links:

- GitHub: `https://github.com/Mulla759`
- LinkedIn: `https://linkedin.com/in/abdull-abdi5`
- X: `https://x.com/AAbdallahDev`

Contact behavior:

- Read the email from one site-level content/config value. Do not duplicate it across components.
- `Copy my email` writes the plain address to the clipboard.
- Feedback states: `Copy my email` → `Copied ✓` → reset after 1.6 seconds.
- Provide a `mailto:` fallback immediately beside or beneath the copy action.
- Avatar is `88–104px` on desktop and `72–80px` on mobile.
- Use meaningful alt text: `Portrait of Abdullahi Abdi`.
- Do not recreate the bordered Gravatar profile card.

### 8. Footer

Keep it one line and factual:

```text
Not an official Google product. Built on the open-source gws CLI.   GitHub ↗
```

No oversized footer, newsletter form, or extra sitemap.

## Visual system

### Color tokens

```css
:root {
  --paper: #fbfbf8;
  --paper-subtle: #f4f4ef;
  --ink: #171715;
  --ink-muted: #74746e;
  --line: #e3e3dc;
  --accent: #2457d6;
  --accent-hover: #173fa8;
  --focus: #2457d6;
}
```

Rules:

- Use `--paper` for nearly the entire page.
- Use `--paper-subtle` only for command rows, docs examples, and the final contact field.
- Use blue only for actionable text, selected navigation, focus, and small state accents.
- Remove all gradients, colored glows, translucent glass, and oversized colored panels.
- Avoid pure gray-on-gray text that drops below WCAG AA contrast.

### Typography

- Primary stack: `ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`.
- Monospace stack: `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`.
- Do not load more than one external font family. Prefer no external font request.
- Body: `16px`, line-height `1.55–1.65`.
- Hero: `clamp(2.3rem, 5vw, 4.75rem)`, line-height `0.98–1.06`, weight `450–550`.
- Section title: `clamp(1.5rem, 2.4vw, 2.25rem)`.
- Labels/meta: `12–13px`, letter-spacing `0.04em`; avoid excessive uppercase.
- Keep most paragraphs under `68ch`.

### Spacing

Use an 8px base system:

- Small gap: `8–12px`
- Component gap: `20–24px`
- Section gap: `96–144px` desktop, `64–88px` mobile
- Hero top/bottom breathing room: about `12–18vh`
- Divider-to-heading gap: `32–40px`

The site should feel spacious because of proportion, not because every element is huge.

### Borders and shadows

- Dividers: `1px solid var(--line)`.
- Radius: `0` for text blocks, `8px` for copy rows, `10–12px` for media.
- Buttons: small radius (`6–8px`), never fully pill-shaped.
- Shadows: none by default. If an image needs separation, use only `0 8px 30px rgb(0 0 0 / 0.05)`.

## Interaction and motion

- Standard transition: `140–180ms ease-out`.
- Links: color shift or underline reveal.
- Buttons: 1px translate or subtle background change; no scale bounce.
- Copy controls: immediate label swap with a small check mark.
- Images may fade/translate up by no more than `8px` once when entering the viewport.
- Generic reveal transitions should finish in `320–380ms`; do not reuse the workflow animation’s longer timing elsewhere.
- The agentic trickle figure may run for about `8.4s` because it explains a sequence, but it runs once and then stays resolved.
- No parallax, cursor-following effects, auto-playing carousel, particle canvas, or animation library.
- Respect `prefers-reduced-motion: reduce` and make the page fully usable with motion disabled.
- Anchor navigation should use smooth scrolling only when reduced motion is not requested.

## Component plan

Keep the component tree small:

```text
Page
├── SideRail / MobileHeader
├── Hero
├── CopyRow
├── AgenticFlowFigure
├── FeatureList
│   └── FeatureSection × 4
├── DocsQuickstart
│   └── CopyRow × n
├── ContactSection
│   └── CopyEmailButton
└── Footer
```

Suggested data separation:

- `site.ts`: contact email, Gravatar URL, social links, project links.
- `features.ts`: feature labels, titles, descriptions, proof labels, image metadata.
- Components render the data; do not bury copy in repeated JSX.

## Performance requirements

- Keep the landing page static whenever the framework permits.
- Use client-side JavaScript only for active-section tracking, clipboard feedback, and the small deterministic controller inside `AgenticFlowFigure`.
- Do not add Framer Motion or another animation dependency for simple fades.
- Store and optimize stock images locally as AVIF/WebP.
- Always specify image width and height to prevent layout shift.
- Load only the first meaningful hero/product image eagerly; lazy-load every image below the fold.
- Responsive source widths should roughly cover `480`, `768`, `1200`, and `1600px`.
- Target each large image at roughly `120–220KB`; the avatar should be much smaller.
- Preconnect only to domains used above the fold. Prefer no third-party requests beyond unavoidable analytics.
- Avoid heavy icon packages for three social icons; use text links or a tiny local icon set.
- Remove unused CSS, duplicate client components, and old theme assets after the redesign is verified.

Performance acceptance targets on a production mobile build:

- Lighthouse Performance: `95+`
- Accessibility: `100`
- Best Practices: `100`
- SEO: `100`
- LCP: `< 2.5s`
- CLS: `< 0.05`
- No hydration warnings or console errors

## Responsive behavior

### `≥ 1024px`

- Sticky left rail plus content column.
- Feature media may extend slightly beyond the paragraph measure.
- Contact content may use a two-column layout: identity left, invitation/actions right.

### `640–1023px`

- Narrow left rail or switch to the mobile header when space becomes tight.
- Main content max width around `720px`.
- Keep media full width.

### `< 640px`

- Sticky top bar.
- Single-column sections.
- Minimum `20px` horizontal padding.
- Copy rows wrap: command first, full-width copy button below if necessary.
- Touch targets at least `44 × 44px`.
- Never use horizontal page scrolling.

## Accessibility and trust

- Use semantic landmarks: `<header>`, `<nav>`, `<main>`, `<section>`, and `<footer>`.
- Maintain one `<h1>` and a logical heading order.
- Add a visible skip link.
- Every interaction must work with keyboard only.
- Use `aria-current="location"` for the active navigation item.
- Announce copied states without moving focus.
- External links receive a clear `↗` cue and safe `rel` attributes when opening a new tab.
- Preserve the safety statement prominently: the tool reads and labels, but never sends, trashes, or deletes.
- Add descriptive alt text to product images; decorative stock images should use empty alt text.

## Implementation order

### Pass 1 — Strip the old visual language

1. Preserve existing content, routes, links, and working copy behavior.
2. Remove the dark theme, gradients, glows, oversized pills, and repeated card wrappers.
3. Delete old visual assets only after confirming they are no longer referenced.
4. Establish the paper color, typography, spacing, and line tokens.

### Pass 2 — Rebuild the document structure

1. Add the desktop side rail and mobile top bar.
2. Create the one-page anchor structure.
3. Recompose the hero and setup command.
4. Convert the feature grid into stacked editorial sections.
5. Add the concise docs section.
6. Add the contact section using the Gravatar image and verified profile links.

### Pass 3 — Add proof and interaction

1. Capture or create the primary product screenshot.
2. Add no more than two licensed editorial stock images.
3. Replace the static workflow placeholder with `AgenticFlowFigure` using the storyboard above.
4. Implement the shared copy interaction for setup commands and email.
5. Add active-section tracking and restrained reveal motion.

### Pass 4 — Quality pass

1. Test at `375px`, `768px`, `1024px`, and `1440px` widths.
2. Test copy actions, anchors, focus order, reduced motion, and no-JavaScript reading.
3. Run a production build and Lighthouse.
4. Compress any image that causes the performance budget to fail.
5. Check every link and confirm the safety language remains accurate.

## Definition of done

The redesign is complete when:

- The page is visibly a minimal white-paper experience, not a dark SaaS template.
- Desktop has a persistent side rail; mobile has a compact top bar.
- `GWS for Dummies`, `Docs`, and `Contact me` are always easy to reach.
- Overview, features, docs, and contact are all present on one page and deep-linkable.
- Feature sections follow a text → proof/media rhythm rather than a card grid.
- The workflow figure visibly shows messages trickling into an orchestrator, routing to specialist agents, and ending in an audited safety state.
- The workflow runs once on entry, offers replay, stays readable when complete, and has an equivalent reduced-motion state.
- Setup and email copy controls provide clear `Copied ✓` feedback.
- The contact area uses Abdullahi’s Gravatar portrait and verified profile links.
- Stock imagery is sparse, relevant, licensed, local, responsive, and lazy-loaded.
- The page has no gradients, glow effects, glass cards, huge pills, or unnecessary animation.
- Keyboard navigation, focus styling, reduced motion, and mobile layout are verified.
- The production page meets the stated performance targets or documents a concrete blocker.

## Final direction to the implementation agent

Do not redesign this as a bigger marketing site. Make it smaller, clearer, and more deliberate.

Preserve the usefulness of the current copy, then organize it like a short manual: a confident statement, one obvious setup action, proof of what happens, concise documentation, and a human contact at the end. Let typography, spacing, thin rules, and relevant imagery carry the page. If an element does not explain, orient, prove, or enable an action, remove it.
