import assert from 'node:assert';
import {LiveActivity, defineFlow} from '../src/index.js';

globalThis.__ios = [];
globalThis.__android = [];

const isIos = process.env.TEST_OS === 'ios';
const label = isIos ? 'iOS' : 'Android';

// 1. start returns a handle bound to the id
const order = await LiveActivity.start({
  id: 'order-1',
  title: 'Order on the way',
  stages: ['Confirmed', 'Preparing', 'Out for delivery', 'Delivered'],
  stage: 1,
  status: 'Arriving ~20 min',
});
assert.equal(order.id, 'order-1', 'handle carries id');
assert.equal(typeof order.update, 'function');
assert.equal(typeof order.end, 'function');

// 2. update in place, then end
await order.update({stage: 2, status: 'Rider nearby'});
await order.end({title: 'Delivered', body: 'Enjoy'});

if (isIos) {
  const [start, update, end] = globalThis.__ios.map(entry => entry[0]);
  assert.deepEqual([start, update, end], ['start', 'update', 'end'], 'iOS bridge got start/update/end');
  const startPayload = globalThis.__ios[0][1];
  assert.deepEqual(startPayload.stages, ['Confirmed', 'Preparing', 'Out for delivery', 'Delivered']);
  assert.equal(startPayload.currentStage, 1);
  assert.equal(globalThis.__ios[1][1].currentStage, 2, 'update advanced the stage');
} else {
  const kinds = globalThis.__android.map(entry => entry[0]);
  assert.ok(kinds.includes('channel'), 'channel created');
  assert.ok(kinds.includes('display'), 'notification displayed');
  const firstDisplay = globalThis.__android.find(entry => entry[0] === 'display')[1];
  assert.equal(firstDisplay.android.progress.current, 2, 'progress = stage+1');
  assert.ok(firstDisplay.android.style.text.includes('✓'), 'timeline has a done marker');
  assert.ok(kinds.includes('cancel'), 'ended = cancelled');
}

// 3. defineFlow with keyed stages resolves index from key
const flow = defineFlow({
  id: 'pay',
  title: 'Payment',
  stages: [
    {key: 'INIT', label: 'Initiated'},
    {key: 'HELD', label: 'Held in escrow'},
    {key: 'RELEASED', label: 'Released'},
  ],
});
assert.equal(flow.stageIndex('HELD'), 1, 'keyed lookup');
assert.equal(flow.stageIndex('NOPE'), 0, 'unknown key falls back to 0');
globalThis.__ios = [];
globalThis.__android = [];
await flow.start({stageKey: 'RELEASED', status: 'Done'});
if (isIos) {
  assert.equal(globalThis.__ios[0][1].currentStage, 2, 'stageKey mapped to index 2');
} else {
  const display = globalThis.__android.find(entry => entry[0] === 'display')[1];
  assert.equal(display.android.progress.current, 3, 'stageKey RELEASED → current 3/3');
}

// 4. theme flows to the right place on each platform
globalThis.__ios = [];
globalThis.__android = [];
await LiveActivity.start({
  id: 'themed',
  title: 'Themed',
  stages: ['A', 'B'],
  theme: {accent: '#FF8800', icon: 'bag.fill', background: '#101010'},
});
if (isIos) {
  const payload = globalThis.__ios[0][1];
  assert.equal(payload.accentColorHex, '#FF8800', 'iOS gets accent');
  assert.equal(payload.iconSystemName, 'bag.fill', 'iOS gets SF Symbol');
  assert.equal(payload.backgroundColorHex, '#101010', 'iOS gets background');
} else {
  const display = globalThis.__android.find(entry => entry[0] === 'display')[1];
  assert.equal(display.android.color, '#FF8800', 'Android accent falls back to theme.accent');
}

console.log(`✓ ${label}: start/update/end + defineFlow + theme all pass`);
