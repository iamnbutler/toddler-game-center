import * as matching from './matching';
import * as redLightGreenLight from './redLightGreenLight';
import * as balloonPop from './balloonPop';

export interface GameEntry {
  id: string;
  title: string;
  emoji: string;
  color: string;
  mount: (container: HTMLElement) => void;
  unmount: () => void;
}

export const games: GameEntry[] = [
  {
    id: 'matching',
    title: 'Matching',
    emoji: '🐻',
    color: '#ffd6a5',
    mount: matching.mount,
    unmount: matching.unmount,
  },
  {
    id: 'red-light-green-light',
    title: 'Red Light, Green Light',
    emoji: '🚦',
    color: '#a0e7a0',
    mount: redLightGreenLight.mount,
    unmount: redLightGreenLight.unmount,
  },
  {
    id: 'balloon-pop',
    title: 'Balloon Pop',
    emoji: '🎈',
    color: '#bde4ff',
    mount: balloonPop.mount,
    unmount: balloonPop.unmount,
  },
];
