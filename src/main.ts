import { games, type GameEntry } from './games/registry';

const app = document.getElementById('app')!;
let activeGame: GameEntry | null = null;

function renderHub(): void {
  const previousGame = activeGame;
  cleanupActive();
  app.innerHTML = '';

  const header = document.createElement('header');
  header.className = 'hub-header';
  const h1 = document.createElement('h1');
  h1.textContent = '🎉 Toddler Game Center';
  header.appendChild(h1);
  app.appendChild(header);

  const grid = document.createElement('div');
  grid.className = 'tile-grid';
  let tileToFocus: HTMLButtonElement | null = null;
  for (const game of games) {
    const tile = document.createElement('button');
    tile.type = 'button';
    tile.className = 'tile';
    tile.style.background = game.color;
    tile.innerHTML = `<div class="emoji">${game.emoji}</div><div>${game.title}</div>`;
    tile.addEventListener('click', () => openGame(game));
    grid.appendChild(tile);
    // Coming back from a game: return keyboard focus to that game's tile
    // instead of dropping it on <body>.
    if (game === previousGame) tileToFocus = tile;
  }
  app.appendChild(grid);
  tileToFocus?.focus();
}

function openGame(game: GameEntry): void {
  cleanupActive();
  app.innerHTML = '';

  const header = document.createElement('header');
  header.className = 'hub-header';
  const back = document.createElement('button');
  back.type = 'button';
  back.className = 'big';
  back.textContent = '← Back';
  back.addEventListener('click', renderHub);
  const h1 = document.createElement('h1');
  h1.textContent = `${game.emoji} ${game.title}`;
  header.appendChild(back);
  header.appendChild(h1);
  header.appendChild(document.createElement('div'));
  app.appendChild(header);

  const stage = document.createElement('div');
  stage.className = 'game-stage';
  app.appendChild(stage);

  activeGame = game;
  game.mount(stage);
}

function cleanupActive(): void {
  if (activeGame) {
    try { activeGame.unmount(); } catch (e) { console.error(e); }
    activeGame = null;
  }
}

renderHub();
