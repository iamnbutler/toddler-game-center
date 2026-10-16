# Toddler Game Center

A tiny hub of learning games for toddlers, built with TypeScript + Vite.

Included games:
- 🐻 **Matching** — flip cards and find pairs.
- 🚦 **Red Light, Green Light** — tap to move on green, freeze on red.
- 🎈 **Balloon Pop** — tap floating balloons (or press Space) to pop them.

## Run it

```bash
npm install
npm run dev
```

Then open the URL Vite prints (usually http://localhost:5173).

To build a static bundle:

```bash
npm run build
npm run preview
```

## Adding a new game

Each game is self-contained and exposes a simple lifecycle:

```ts
export function mount(container: HTMLElement): void { /* build UI, wire events */ }
export function unmount(): void { /* clean up timers/listeners */ }
```

Steps:

1. Create `src/games/<yourGame>/index.ts` exporting `mount` and `unmount`.
2. Add an entry to `src/games/registry.ts`:

```ts
import * as yourGame from './yourGame';

export const games: GameEntry[] = [
  // ...existing games
  {
    id: 'your-game',
    title: 'Your Game',
    emoji: '🎈',
    color: '#ffcc66',
    mount: yourGame.mount,
    unmount: yourGame.unmount,
  },
];
```

That's it — the hub will render a new tile automatically.

## Project layout

```
index.html
src/
  main.ts                 # hub: renders tiles, mounts/unmounts games
  styles.css              # big buttons, high-contrast toddler-friendly styling
  games/
    registry.ts           # single source of truth for available games
    matching/index.ts     # self-contained matching game
    redLightGreenLight/index.ts  # self-contained red/green light game
    balloonPop/index.ts   # self-contained balloon popping game
```
