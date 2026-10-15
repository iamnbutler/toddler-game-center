// Self-contained Red Light / Green Light game.
// Tap the big button (or press Space) to move. Only counts on GREEN. On RED, taps send you back to the start.

let root: HTMLElement | null = null;
let switchTimer: number | null = null;
let penaltyTimer: number | null = null;
// Window listeners added by the current round; removed on unmount and before re-rendering.
let removeListeners: (() => void) | null = null;

export function mount(container: HTMLElement): void {
  root = container;
  render();
}

export function unmount(): void {
  if (switchTimer !== null) { clearTimeout(switchTimer); switchTimer = null; }
  if (penaltyTimer !== null) { clearTimeout(penaltyTimer); penaltyTimer = null; }
  if (removeListeners) { removeListeners(); removeListeners = null; }
  if (root) { root.innerHTML = ''; root = null; }
}

function render(): void {
  if (!root) return;
  // "Play Again" re-renders: stop the previous round's timers and listeners.
  if (switchTimer !== null) { clearTimeout(switchTimer); switchTimer = null; }
  if (penaltyTimer !== null) { clearTimeout(penaltyTimer); penaltyTimer = null; }
  if (removeListeners) { removeListeners(); removeListeners = null; }
  root.innerHTML = '';

  const light = document.createElement('div');
  light.className = 'rl-light green';
  light.textContent = 'GO!';
  root.appendChild(light);

  const track = document.createElement('div');
  track.className = 'rl-track';
  const runner = document.createElement('div');
  runner.className = 'rl-runner';
  runner.textContent = '🐢';
  const goal = document.createElement('div');
  goal.className = 'rl-goal';
  goal.textContent = '🏁';
  track.appendChild(runner);
  track.appendChild(goal);
  root.appendChild(track);

  const tap = document.createElement('button');
  tap.type = 'button';
  tap.className = 'rl-tap';
  tap.textContent = '👆 TAP TO GO';
  root.appendChild(tap);

  const reset = document.createElement('button');
  reset.type = 'button';
  reset.className = 'big';
  reset.style.marginTop = '16px';
  reset.style.alignSelf = 'center';
  reset.textContent = '🔄 Play Again';
  reset.addEventListener('click', () => {
    render();
    // Keyboard focus would otherwise drop to <body>. Put it on the new tap
    // button so the next Space is a tap, not another restart.
    root?.querySelector<HTMLButtonElement>('.rl-tap')?.focus();
  });
  root.appendChild(reset);

  let isGreen = true;
  let progress = 0; // 0..1
  let won = false;

  function scheduleSwitch(): void {
    const delay = isGreen ? 2500 + Math.random() * 3000 : 1500 + Math.random() * 1500;
    switchTimer = window.setTimeout(() => {
      if (won) return;
      isGreen = !isGreen;
      light.className = `rl-light ${isGreen ? 'green' : 'red'}`;
      light.textContent = isGreen ? 'GO!' : 'STOP!';
      scheduleSwitch();
    }, delay);
  }
  scheduleSwitch();

  function positionRunner(): void {
    const trackWidth = track.clientWidth - 64;
    runner.style.left = `${Math.max(0, progress * trackWidth)}px`;
  }
  requestAnimationFrame(positionRunner);

  // Space is the tap, wherever focus is. Other buttons (Back, Play Again) keep
  // their normal Space behavior, and the tap button already turns Space into a
  // click by itself, so skip those to avoid double taps.
  function onKeyDown(e: KeyboardEvent): void {
    if (e.code !== 'Space' && e.key !== ' ') return;
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    const target = e.target as HTMLElement | null;
    if (target?.closest('button, input, textarea, select, a[href], [contenteditable]')) return;
    e.preventDefault(); // don't scroll the page
    if (e.repeat) return; // holding Space is not a stream of taps
    onTap();
  }

  window.addEventListener('resize', positionRunner);
  window.addEventListener('keydown', onKeyDown);
  removeListeners = () => {
    window.removeEventListener('resize', positionRunner);
    window.removeEventListener('keydown', onKeyDown);
  };

  tap.addEventListener('click', onTap);

  function onTap(): void {
    if (won) return;
    if (isGreen) {
      progress = Math.min(1, progress + 0.08);
      positionRunner();
      if (progress >= 1) {
        won = true;
        light.className = 'rl-light green';
        light.textContent = 'YOU WIN! 🎉';
        runner.textContent = '🐇';
        tap.disabled = true;
        tap.textContent = '🏆 Finished!';
        if (switchTimer !== null) { clearTimeout(switchTimer); switchTimer = null; }
      }
    } else {
      // Red light: go back to the start!
      progress = 0;
      positionRunner();
      const original = '👆 TAP TO GO';
      tap.textContent = '⛔ Back to start!';
      if (penaltyTimer !== null) clearTimeout(penaltyTimer);
      penaltyTimer = window.setTimeout(() => {
        tap.textContent = original;
        penaltyTimer = null;
      }, 900);
    }
  }
}
