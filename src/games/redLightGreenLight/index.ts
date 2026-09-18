// Self-contained Red Light / Green Light game.
// Tap the big button to move. Only counts on GREEN. On RED, taps freeze you briefly.

let root: HTMLElement | null = null;
let switchTimer: number | null = null;
let freezeTimer: number | null = null;

export function mount(container: HTMLElement): void {
  root = container;
  render();
}

export function unmount(): void {
  if (switchTimer !== null) { clearTimeout(switchTimer); switchTimer = null; }
  if (freezeTimer !== null) { clearTimeout(freezeTimer); freezeTimer = null; }
  if (root) { root.innerHTML = ''; root = null; }
}

function render(): void {
  if (!root) return;
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
  tap.className = 'rl-tap';
  tap.textContent = '👆 TAP TO GO';
  root.appendChild(tap);

  const reset = document.createElement('button');
  reset.className = 'big';
  reset.style.marginTop = '16px';
  reset.style.alignSelf = 'center';
  reset.textContent = '🔄 Play Again';
  reset.addEventListener('click', render);
  root.appendChild(reset);

  let isGreen = true;
  let frozen = false;
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
  window.addEventListener('resize', positionRunner);

  tap.addEventListener('click', () => {
    if (won || frozen) return;
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
      // Red light: brief freeze + wiggle feedback, no progress lost (toddler-kind).
      frozen = true;
      const original = tap.textContent;
      tap.textContent = '❄️ Freeze!';
      if (freezeTimer !== null) clearTimeout(freezeTimer);
      freezeTimer = window.setTimeout(() => {
        frozen = false;
        tap.textContent = original;
        freezeTimer = null;
      }, 700);
    }
  });
}
