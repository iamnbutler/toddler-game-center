// Self-contained matching game.
// Toddler-friendly: pick a board size, generous card size, gentle feedback.

const FACES = ['🐶', '🐱', '🐰', '🐼', '🦊', '🐸'];

interface BoardSize { label: string; cols: number; rows: number; }

const SIZES: BoardSize[] = [
  { label: '🐣 Easy', cols: 2, rows: 2 },
  { label: '🐥 Medium', cols: 3, rows: 2 },
  { label: '🦁 Hard', cols: 4, rows: 3 },
];

let root: HTMLElement | null = null;
let lockTimer: number | null = null;

interface Card { face: string; el: HTMLButtonElement; matched: boolean; flipped: boolean; }

function shuffle<T>(arr: T[]): T[] {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function mount(container: HTMLElement): void {
  root = container;
  renderPicker();
}

export function unmount(): void {
  if (lockTimer !== null) { clearTimeout(lockTimer); lockTimer = null; }
  if (root) { root.innerHTML = ''; root = null; }
}

function renderPicker(): void {
  if (!root) return;
  if (lockTimer !== null) { clearTimeout(lockTimer); lockTimer = null; }
  root.innerHTML = '';

  const status = document.createElement('div');
  status.className = 'match-status';
  status.textContent = 'How many cards? 🃏';
  root.appendChild(status);

  const picker = document.createElement('div');
  picker.className = 'match-sizes';
  for (const size of SIZES) {
    const btn = document.createElement('button');
    btn.className = 'big';
    btn.textContent = `${size.label} (${size.cols}×${size.rows})`;
    btn.addEventListener('click', () => render(size));
    picker.appendChild(btn);
  }
  root.appendChild(picker);
}

function render(size: BoardSize): void {
  if (!root) return;
  if (lockTimer !== null) { clearTimeout(lockTimer); lockTimer = null; }
  root.innerHTML = '';

  const faces = FACES.slice(0, (size.cols * size.rows) / 2);

  const status = document.createElement('div');
  status.className = 'match-status';
  status.textContent = 'Find the pairs! 🎈';
  root.appendChild(status);

  const grid = document.createElement('div');
  grid.className = 'match-grid';
  grid.style.gridTemplateColumns = `repeat(${size.cols}, 1fr)`;
  // Cap width per column so small boards keep big cards without stretching.
  grid.style.maxWidth = `${size.cols * 140}px`;
  root.appendChild(grid);

  const deck = shuffle([...faces, ...faces]);
  const cards: Card[] = [];
  let firstPick: Card | null = null;
  let matchedCount = 0;
  let locked = false;

  for (const face of deck) {
    // Real buttons, so cards are reachable with Tab and flip with Enter/Space.
    const el = document.createElement('button');
    el.type = 'button';
    el.className = 'match-card';
    el.textContent = '';
    el.setAttribute('aria-label', 'Hidden card');
    const card: Card = { face, el, matched: false, flipped: false };
    cards.push(card);
    el.addEventListener('click', () => onPick(card));
    grid.appendChild(el);
  }

  const controls = document.createElement('div');
  controls.className = 'match-sizes';
  controls.style.marginTop = '20px';
  const reset = document.createElement('button');
  reset.className = 'big';
  reset.textContent = '🔄 New Game';
  reset.addEventListener('click', () => render(size));
  const change = document.createElement('button');
  change.className = 'big';
  change.textContent = '🃏 Change Size';
  change.addEventListener('click', renderPicker);
  controls.append(reset, change);
  root.appendChild(controls);

  function flip(card: Card, show: boolean): void {
    card.flipped = show;
    card.el.textContent = show ? card.face : '';
    card.el.classList.toggle('flipped', show);
    card.el.setAttribute('aria-label', show ? card.face : 'Hidden card');
  }

  function onPick(card: Card): void {
    if (locked || card.matched || card.flipped) return;
    flip(card, true);

    if (!firstPick) { firstPick = card; return; }

    if (firstPick.face === card.face) {
      firstPick.matched = true;
      card.matched = true;
      firstPick.el.classList.add('matched');
      card.el.classList.add('matched');
      firstPick = null;
      matchedCount++;
      status.textContent = `Great job! ⭐ (${matchedCount}/${faces.length})`;
      if (matchedCount === faces.length) {
        status.textContent = 'You did it! 🎉🎉🎉';
      }
    } else {
      locked = true;
      const a = firstPick, b = card;
      firstPick = null;
      lockTimer = window.setTimeout(() => {
        flip(a, false); flip(b, false);
        locked = false;
        lockTimer = null;
      }, 900);
    }
  }
}
