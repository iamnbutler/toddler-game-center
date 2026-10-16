// Self-contained Balloon Pop game.
// Balloons float up from the bottom. Tap one (or press Space) to pop it.
// No way to lose: balloons that drift off the top just float away.

const COLORS = ['#ff5a5f', '#ffb400', '#3ec300', '#00a6ed', '#a259ff', '#ff7ac6', '#ff8c42'];
const MAX_BALLOONS = 7;
const SPAWN_EVERY_MS = 1100;
const BALLOON_WIDTH = 96; // px; keep in sync with .bp-balloon in styles.css
const BALLOON_HEIGHT = 168; // px, including the string

let root: HTMLElement | null = null;
let frame: number | null = null;
let audio: AudioContext | null = null;
// Window listeners and pending timers for the current round; cleared on unmount and re-render.
let removeListeners: (() => void) | null = null;
const burstTimers = new Set<number>();

interface Balloon {
  el: HTMLButtonElement;
  x: number; // 0..1, fraction of the sky's usable width
  y: number; // px from the top of the sky to the balloon's top edge
  speed: number; // px per second, upward
  sway: number; // phase for the side-to-side wobble
  left: number; // px, last rendered horizontal position
}

export function mount(container: HTMLElement): void {
  root = container;
  render();
}

export function unmount(): void {
  stopRound();
  if (audio) { void audio.close().catch(() => {}); audio = null; }
  if (root) { root.innerHTML = ''; root = null; }
}

function stopRound(): void {
  if (frame !== null) { cancelAnimationFrame(frame); frame = null; }
  if (removeListeners) { removeListeners(); removeListeners = null; }
  for (const t of burstTimers) clearTimeout(t);
  burstTimers.clear();
}

function render(): void {
  if (!root) return;
  stopRound();
  root.innerHTML = '';

  const status = document.createElement('div');
  status.className = 'bp-status';
  status.setAttribute('aria-live', 'polite');
  status.textContent = 'Pop the balloons! 🎈';
  root.appendChild(status);

  const sky = document.createElement('div');
  sky.className = 'bp-sky';
  root.appendChild(sky);

  const reset = document.createElement('button');
  reset.type = 'button';
  reset.className = 'big';
  reset.style.marginTop = '16px';
  reset.style.alignSelf = 'center';
  reset.textContent = '🔄 Start Over';
  reset.addEventListener('click', render);
  root.appendChild(reset);

  const balloons: Balloon[] = [];
  let popped = 0;
  let sinceSpawn = SPAWN_EVERY_MS; // spawn one right away
  let last = performance.now();

  function spawn(): void {
    const el = document.createElement('button');
    el.type = 'button';
    el.className = 'bp-balloon';
    // Moving targets make poor Tab stops; Space pops balloons instead (see onKeyDown).
    el.tabIndex = -1;
    el.setAttribute('aria-label', 'Balloon');
    el.style.setProperty('--balloon', COLORS[Math.floor(Math.random() * COLORS.length)]);
    const balloon: Balloon = {
      el,
      x: Math.random(),
      y: sky.clientHeight,
      speed: 55 + Math.random() * 45,
      sway: Math.random() * Math.PI * 2,
      left: 0,
    };
    // pointerdown, not click: a balloon can drift out from under a slow tap
    // between press and release, which would cancel a click.
    el.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      pop(balloon);
    });
    // Assistive tech (e.g. VoiceOver) activates buttons with a click and no pointer events.
    // pop() ignores balloons that are already gone, so a tap's trailing click is harmless.
    el.addEventListener('click', () => pop(balloon));
    balloons.push(balloon);
    sky.appendChild(el);
    place(balloon);
  }

  function place(b: Balloon): void {
    const usable = Math.max(0, sky.clientWidth - BALLOON_WIDTH);
    b.left = b.x * usable + Math.sin(b.sway) * 10;
    b.el.style.transform = `translate(${b.left}px, ${b.y}px)`;
  }

  function pop(b: Balloon): void {
    const i = balloons.indexOf(b);
    if (i === -1) return;
    balloons.splice(i, 1);
    b.el.remove();

    const burst = document.createElement('div');
    burst.className = 'bp-burst';
    burst.textContent = '💥';
    // Positioned with left/top so the CSS pop animation can own `transform`.
    burst.style.left = `${b.left}px`;
    burst.style.top = `${b.y}px`;
    sky.appendChild(burst);
    const t = window.setTimeout(() => { burst.remove(); burstTimers.delete(t); }, 500);
    burstTimers.add(t);

    playPop();
    popped++;
    status.textContent = popped % 10 === 0
      ? `Wow! ${popped} balloons! 🎉`
      : `Pop! ⭐ ${popped}`;
  }

  function tick(now: number): void {
    // Clamp so a backgrounded tab doesn't make everything jump on return.
    const dt = Math.min(now - last, 100);
    last = now;

    sinceSpawn += dt;
    if (sinceSpawn >= SPAWN_EVERY_MS && balloons.length < MAX_BALLOONS) {
      sinceSpawn = 0;
      spawn();
    }

    for (let i = balloons.length - 1; i >= 0; i--) {
      const b = balloons[i];
      b.y -= (b.speed * dt) / 1000;
      b.sway += dt / 600;
      if (b.y < -BALLOON_HEIGHT) {
        // Floated away. No penalty.
        b.el.remove();
        balloons.splice(i, 1);
      } else {
        place(b);
      }
    }
    frame = requestAnimationFrame(tick);
  }
  frame = requestAnimationFrame(tick);

  // Space pops the highest balloon that's on screen, wherever focus is.
  // Buttons (Back, Start Over) keep their own Space behavior.
  function onKeyDown(e: KeyboardEvent): void {
    if (e.code !== 'Space' && e.key !== ' ') return;
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    const target = e.target as HTMLElement | null;
    if (target?.closest('button, input, textarea, select, a[href], [contenteditable]')) return;
    e.preventDefault(); // don't scroll the page
    if (e.repeat) return;
    const visible = balloons.filter((b) => b.y < sky.clientHeight - BALLOON_HEIGHT / 2);
    if (visible.length === 0) return;
    pop(visible.reduce((top, b) => (b.y < top.y ? b : top)));
  }
  window.addEventListener('keydown', onKeyDown);
  removeListeners = () => window.removeEventListener('keydown', onKeyDown);
}

// A short, soft "pop": a burst of filtered noise. Silently skipped if audio is unavailable.
function playPop(): void {
  try {
    audio ??= new AudioContext();
    const ctx = audio;
    if (ctx.state === 'suspended') void ctx.resume();
    const length = Math.floor(ctx.sampleRate * 0.08);
    const buffer = ctx.createBuffer(1, length, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < length; i++) {
      data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, 3);
    }
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = 900 + Math.random() * 600;
    const gain = ctx.createGain();
    gain.gain.value = 0.6;
    src.connect(filter).connect(gain).connect(ctx.destination);
    src.start();
  } catch {
    // No sound is fine.
  }
}
