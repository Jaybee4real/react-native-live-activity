import notifee, {AndroidImportance, AndroidStyle} from '@notifee/react-native';
import {NativeModules, Platform} from 'react-native';

const {RNLiveActivity} = NativeModules;

const DEFAULTS = {
  channelId: 'live_activity',
  channelName: 'Live updates',
  importance: 'default',
  color: undefined,
  smallIcon: undefined,
  ongoing: true,
};

let config = {...DEFAULTS};

const registry = new Map();

const IMPORTANCE = {
  min: AndroidImportance.MIN,
  low: AndroidImportance.LOW,
  default: AndroidImportance.DEFAULT,
  high: AndroidImportance.HIGH,
};

export function configure(options = {}) {
  config = {...config, ...options};
}

const normalizeStages = stages =>
  (stages ?? []).map(stage =>
    typeof stage === 'string'
      ? {key: stage, label: stage}
      : {key: stage.key ?? stage.label, label: stage.label ?? stage.key},
  );

const toMs = deadline => {
  if (deadline == null) return 0;
  if (deadline instanceof Date) return deadline.getTime();
  return Number(deadline) || 0;
};

const timeline = (stages, stageIndex) =>
  stages
    .map((stage, index) => {
      const marker = index < stageIndex ? '✓' : index === stageIndex ? '●' : '○';
      return `${marker}  ${stage.label}`;
    })
    .join('\n');

async function ensureChannel(android) {
  const channelId = android.channelId ?? config.channelId;
  if (Platform.OS !== 'android') return channelId;
  await notifee.createChannel({
    id: channelId,
    name: android.channelName ?? config.channelName,
    importance: IMPORTANCE[android.importance ?? config.importance] ?? AndroidImportance.DEFAULT,
  });
  return channelId;
}

async function renderAndroid(state) {
  const android = state.android ?? {};
  const channelId = await ensureChannel(android);
  const total = state.stages.length;
  await notifee.displayNotification({
    id: state.id,
    title: state.title,
    body: state.status || state.stages[state.stage]?.label || '',
    android: {
      channelId,
      ongoing: android.ongoing ?? config.ongoing,
      onlyAlertOnce: true,
      pressAction: {id: 'default'},
      color: android.color ?? config.color,
      smallIcon: android.smallIcon ?? config.smallIcon,
      progress: {max: total, current: Math.min(state.stage + 1, total), indeterminate: total === 0},
      style: {type: AndroidStyle.BIGTEXT, text: timeline(state.stages, state.stage)},
      ...(state.deadlineMs
        ? {timestamp: state.deadlineMs, showChronometer: true, chronometerDirection: 'down'}
        : {}),
    },
  });
}

async function pushIos(state, method) {
  const payload =
    method === 'start'
      ? {
          id: state.id,
          title: state.title,
          stages: state.stages.map(stage => stage.label),
          currentStage: state.stage,
          statusLine: state.status ?? '',
          deadlineMs: state.deadlineMs ?? 0,
        }
      : {
          id: state.id,
          currentStage: state.stage,
          statusLine: state.status ?? '',
          deadlineMs: state.deadlineMs ?? 0,
        };
  return RNLiveActivity?.[method]?.(payload);
}

function makeHandle(id) {
  return {
    id,
    update: patch => update(id, patch),
    end: final => end(id, final),
  };
}

/**
 * Start (or replace) a live activity. Returns a handle with `.update()` and
 * `.end()` bound to this activity's id — the simplest way to drive it.
 */
export async function start(options = {}) {
  const state = {
    id: options.id ?? 'live',
    title: options.title ?? '',
    stages: normalizeStages(options.stages),
    stage: options.stage ?? 0,
    status: options.status ?? '',
    deadlineMs: toMs(options.deadline),
    android: options.android ?? {},
  };
  registry.set(state.id, state);
  if (Platform.OS === 'ios') await pushIos(state, 'start');
  else await renderAndroid(state);
  return makeHandle(state.id);
}

/**
 * Advance/refresh an activity in place. Callable with just an id from anywhere
 * (e.g. a push handler) — pass `title`/`stages` too if the process was restarted
 * and the original state is no longer cached (needed on Android to re-render).
 */
export async function update(id, patch = {}) {
  const cached = registry.get(id) ?? {id, title: patch.title ?? '', stages: [], stage: 0, android: {}};
  const state = {
    ...cached,
    title: patch.title ?? cached.title,
    stages: patch.stages ? normalizeStages(patch.stages) : cached.stages,
    stage: patch.stage ?? cached.stage,
    status: patch.status ?? cached.status,
    deadlineMs: patch.deadline != null ? toMs(patch.deadline) : cached.deadlineMs,
    android: {...cached.android, ...(patch.android ?? {})},
  };
  registry.set(id, state);
  if (Platform.OS === 'ios') return pushIos(state, 'update');
  return renderAndroid(state);
}

/** Finish an activity. Optionally leave a final static notification behind. */
export async function end(id, final = {}) {
  const cached = registry.get(id);
  registry.delete(id);
  if (Platform.OS === 'ios') {
    return RNLiveActivity?.end?.({id, finalTitle: final.title ?? '', finalBody: final.body ?? ''});
  }
  await notifee.cancelNotification(id);
  if (final.title) {
    const channelId = cached?.android?.channelId ?? config.channelId;
    await notifee.displayNotification({
      id: `${id}-done`,
      title: final.title,
      body: final.body ?? '',
      android: {channelId, pressAction: {id: 'default'}},
    });
  }
}

/** True when live activities can actually run on this device/build. */
export async function isSupported() {
  if (Platform.OS === 'ios') return !!RNLiveActivity;
  if (Platform.OS === 'android') return true;
  return false;
}

/**
 * Freeze a reusable template (title + ordered stages). Call it later with the
 * live values: `orderFlow.start({ stage: 1, status: '…' })`.
 */
export function defineFlow(template) {
  const stages = normalizeStages(template.stages);
  const stageIndex = key => {
    const found = stages.findIndex(stage => stage.key === key);
    return found < 0 ? 0 : found;
  };
  const merge = options => ({
    ...template,
    ...options,
    stages,
    stage: options?.stageKey != null ? stageIndex(options.stageKey) : options?.stage ?? 0,
  });
  return {
    stages,
    stageIndex,
    start: options => start(merge(options)),
    update: (id, patch) =>
      update(id ?? template.id, {
        ...patch,
        stage: patch?.stageKey != null ? stageIndex(patch.stageKey) : patch?.stage,
      }),
    end: (id, final) => end(id ?? template.id, final),
  };
}

export const LiveActivity = {configure, start, update, end, isSupported, defineFlow};

export default LiveActivity;
