// Self-contained matching game.
// Toddler-friendly: 6 pairs, generous card size, gentle feedback.

const FACES = ['🐶', '🐱', '🐰', '🐼', '🦊', '🐸'];

let root: HTMLElement | null = null;
let lockTimer: number | null = null;

interface Card { face: string; el: HTMLElement; matched: boolean; flipped: boolean; }

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
  render();
}

export function unmount(): void {
  if (lockTimer !== null) { clearTimeout(lockTimer); lockTimer = null; }
  if (root) { root.innerHTML = ''; root = null; }
}

function render(): void {
  if (!root) return;
  root.innerHTML = '';

  const status = document.createElement('div');
  status.className = 'match-status';
  status.textContent = 'Find the pairs! 🎈';
  root.appendChild(status);

  const grid = document.createElement('div');
  grid.className = 'match-grid';
  root.appendChild(grid);

  const deck = shuffle([...FACES, ...FACES]);
  const cards: Card[] = [];
  let firstPick: Card | null = null;
  let matchedCount = 0;
  let locked = false;

  for (const face of deck) {
    const el = document.createElement('div');
    el.className = 'match-card';
    el.textContent = '';
    const card: Card = { face, el, matched: false, flipped: false };
    cards.push(card);
    el.addEventListener('click', () => onPick(card));
    grid.appendChild(el);
  }

  const reset = document.createElement('button');
  reset.className = 'big';
  reset.style.marginTop = '20px';
  reset.style.alignSelf = 'center';
  reset.textContent = '🔄 New Game';
  reset.addEventListener('click', render);
  root.appendChild(reset);

  function flip(card: Card, show: boolean): void {
    card.flipped = show;
    card.el.textContent = show ? card.face : '';
    card.el.classList.toggle('flipped', show);
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
      status.textContent = `Great job! ⭐ (${matchedCount}/${FACES.length})`;
      if (matchedCount === FACES.length) {
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
