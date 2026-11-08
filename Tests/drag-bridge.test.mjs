import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { Window } from 'happy-dom';
import { createDragDropManager } from 'dnd-core';
import { HTML5Backend } from 'react-dnd-html5-backend';

const root = new URL('../', import.meta.url);
const script = await fs.readFile(new URL('DimGameBar/DragBridge.js', root), 'utf8');
function createWindow() {
  const window = new Window({
    url: 'https://app.destinyitemmanager.com/',
    settings: { enableJavaScriptEvaluation: true, disableJavaScriptFileLoading: true, disableCSSFileLoading: true },
  });
  // The DOM emulator omits DragEventInit.dataTransfer and has no layout engine.
  window.DragEvent = class extends window.MouseEvent {
    constructor(type, init = {}) { super(type, init); this.dataTransfer = init.dataTransfer || null; }
  };
  window.HTMLElement.prototype.getBoundingClientRect = function () {
    const left = this.id === 'accepted' || this.parentElement?.id === 'accepted' ? 200 :
      this.id === 'rejected' ? 400 : 20;
    return {left, top: 20, width: 100, height: 100, right: left + 100, bottom: 120};
  };
  window.document.elementsFromPoint = (x, y) => y < 0 || y > 120 ? [] : [
    window.document.getElementById('drag-overlay'),
    window.document.getElementById(x >= 400 ? 'rejected' : x >= 200 ? 'accepted' : 'source'),
  ].filter(Boolean);
  window.document.elementFromPoint = (x, y) => window.document.elementsFromPoint(x, y)[0] || null;
  window.addEventListener('error', event => { throw event.error || new Error(event.message); });
  return window;
}

const window = createWindow();
try {
  const html = (await fs.readFile(new URL('Tests/drag-bridge.html', root), 'utf8'))
    .replace('<script src="../DimGameBar/DragBridge.js"></script>', '<script>' + script + '</script>');
  window.document.write(html);
  await window.happyDOM.waitUntilComplete();
  const result = window.document.getElementById('results')?.textContent;
  console.log(result);
  assert.equal(window.document.body.dataset.result, 'pass', 'DOM drag contract failed');
  assert.match(result, /10 tests passed/);
} finally {
  await window.happyDOM.close();
}

// Exercise the actual HTML5 backend version used by DIM, without any Bungie account or API calls.
const dndWindow = createWindow();
try {
  Object.assign(globalThis, {
    window: dndWindow,
    document: dndWindow.document,
    Image: dndWindow.Image,
    HTMLElement: dndWindow.HTMLElement,
    Node: dndWindow.Node,
    requestAnimationFrame: dndWindow.requestAnimationFrame.bind(dndWindow),
    cancelAnimationFrame: dndWindow.cancelAnimationFrame.bind(dndWindow),
  });
  dndWindow.document.body.innerHTML = '<div id="source">Item</div>' +
    '<div id="accepted" class="sub-bucket">Vault</div><div id="rejected">Outside bucket</div>';
  dndWindow.eval(script);
  const manager = createDragDropManager(HTML5Backend, dndWindow);
  const registry = manager.getRegistry();
  let received = null;
  let canDrop = true;
  const sourceId = registry.addSource('ITEM', {
    canDrag: () => true,
    beginDrag: () => ({id: 'local-test-item'}),
    isDragging: monitor => monitor.getSourceId() === sourceId,
    endDrag: () => {},
  });
  const targetId = registry.addTarget('ITEM', {
    canDrop: () => canDrop,
    hover: () => {},
    drop: monitor => { received = monitor.getItem(); return {location: 'vault'}; },
  });
  const backend = manager.getBackend();
  const source = dndWindow.document.getElementById('source');
  const target = dndWindow.document.getElementById('accepted');
  const disconnectSource = backend.connectDragSource(sourceId, source);
  const disconnectTarget = backend.connectDropTarget(targetId, target);
  const mouse = (type, node, x, buttons) => node.dispatchEvent(new dndWindow.PointerEvent(type, {
    bubbles: true, cancelable: true, pointerId: 1, pointerType: 'mouse', isPrimary: true,
    button: 0, buttons, clientX: x, clientY: 70,
  }));
  mouse('pointerdown', source, 70, 1);
  mouse('pointermove', target, 250, 1);
  await new Promise(resolve => setTimeout(resolve, 20));
  const nativeEnd = new dndWindow.DragEvent('dragend', {bubbles: true});
  // Model an OS-originated termination in the DOM emulator, without ending the shim drag.
  Object.defineProperty(nativeEnd, 'isTrusted', {value: true});
  source.dispatchEvent(nativeEnd);
  assert.equal(manager.getMonitor().isDragging(), true, 'Native dragend terminated the synthetic drag');
  // DIM adds an invisible full-screen hit-test overlay after dragstart.
  const overlay = dndWindow.document.createElement('div');
  overlay.id = 'drag-overlay';
  overlay.className = '_dragPerfFix_test';
  dndWindow.document.body.appendChild(overlay);
  mouse('pointermove', target, 250, 1);
  mouse('pointerup', target, 250, 0);
  assert.deepEqual(received, {id: 'local-test-item'});
  assert.equal(manager.getMonitor().isDragging(), false);
  received = null;
  mouse('pointerdown', source, 70, 1);
  mouse('pointermove', target, 250, 1);
  await new Promise(resolve => setTimeout(resolve, 20));
  mouse('pointerup', overlay, 450, 0);
  assert.equal(received, null, 'Overlay fallback dropped outside a DIM bucket');
  assert.equal(manager.getMonitor().isDragging(), false);
  overlay.remove();
  // A cursor-effect failure must not suppress DIM's own drop-time validation.
  dndWindow.addEventListener('dragover', event => { event.dataTransfer.dropEffect = 'none'; });
  for (const permitted of [true, false]) {
    canDrop = permitted;
    received = null;
    mouse('pointerdown', source, 70, 1);
    mouse('pointermove', target, 250, 1);
    await new Promise(resolve => setTimeout(resolve, 20));
    mouse('pointerup', target, 250, 0);
    assert.deepEqual(received, permitted ? {id: 'local-test-item'} : null,
      'DIM bucket must apply backend canDrop even when cursor effect is none');
    assert.equal(manager.getMonitor().isDragging(), false);
  }
  disconnectSource(); disconnectTarget();
  registry.removeSource(sourceId); registry.removeTarget(targetId);
  console.log('PASS React DnD HTML5Backend 16.0.1 integration');
} finally {
  await dndWindow.happyDOM.close();
  for (const name of ['window', 'document', 'Image', 'HTMLElement', 'Node', 'requestAnimationFrame', 'cancelAnimationFrame'])
    delete globalThis[name];
}
