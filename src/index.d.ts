export type Stage = string | {key?: string; label: string};

export type AndroidImportanceName = 'min' | 'low' | 'default' | 'high';

export interface AndroidOptions {
  /** Notification channel id. Auto-created. Default: `'live_activity'`. */
  channelId?: string;
  /** Channel name shown in system settings. Default: `'Live updates'`. */
  channelName?: string;
  /** Channel importance. Keep `'default'` so updates don't heads-up each time. */
  importance?: AndroidImportanceName;
  /** Accent color (e.g. `'#062FA1'`). */
  color?: string;
  /** Small icon resource name (drawable). Falls back to the app default. */
  smallIcon?: string;
  /** Persistent + non-dismissable while active. Default: `true`. */
  ongoing?: boolean;
}

export interface StartOptions {
  /** Stable id — reuse it to update/end this activity. Default: `'live'`. */
  id?: string;
  /** Headline shown on the activity. */
  title?: string;
  /** Ordered stages: strings, or `{ key, label }` for keyed lookups. */
  stages?: Stage[];
  /** Zero-based index of the current stage. Default: `0`. */
  stage?: number;
  /** Sub-line under the title (ETA, next step, …). */
  status?: string;
  /** Live countdown target — `Date` or epoch ms. */
  deadline?: Date | number;
  /** Android-only presentation overrides. */
  android?: AndroidOptions;
}

export interface UpdatePatch {
  stage?: number;
  status?: string;
  deadline?: Date | number;
  /** Only needed on Android after a cold restart, to re-render from scratch. */
  title?: string;
  stages?: Stage[];
  android?: AndroidOptions;
}

export interface EndOptions {
  /** Leave a final static notification (Android) / end copy (iOS). */
  title?: string;
  body?: string;
}

export interface ActivityHandle {
  id: string;
  update(patch?: UpdatePatch): Promise<unknown>;
  end(final?: EndOptions): Promise<void>;
}

export interface GlobalConfig {
  channelId?: string;
  channelName?: string;
  importance?: AndroidImportanceName;
  color?: string;
  smallIcon?: string;
  ongoing?: boolean;
}

export interface FlowTemplate {
  id?: string;
  title?: string;
  stages: Stage[];
  android?: AndroidOptions;
}

export interface Flow {
  stages: {key: string; label: string}[];
  stageIndex(key: string): number;
  start(options?: Partial<StartOptions> & {stageKey?: string}): Promise<ActivityHandle>;
  update(id?: string, patch?: UpdatePatch & {stageKey?: string}): Promise<unknown>;
  end(id?: string, final?: EndOptions): Promise<void>;
}

export function configure(options: GlobalConfig): void;
export function start(options?: StartOptions): Promise<ActivityHandle>;
export function update(id: string, patch?: UpdatePatch): Promise<unknown>;
export function end(id: string, final?: EndOptions): Promise<void>;
export function isSupported(): Promise<boolean>;
export function defineFlow(template: FlowTemplate): Flow;

export const LiveActivity: {
  configure: typeof configure;
  start: typeof start;
  update: typeof update;
  end: typeof end;
  isSupported: typeof isSupported;
  defineFlow: typeof defineFlow;
};

export default LiveActivity;
