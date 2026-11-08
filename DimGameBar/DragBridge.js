// Injected only into the top-level DIM origin by MainPage.xaml.cs.
(() => {
  // shortcut: mouse-only, in-page HTML5 DnD; remove when UWP WebView2 supports it reliably.
  let active = null;
  let suppressClickUntil = 0;

  function emit(type, target, pointer) {
    const event = new DragEvent(type, {
      bubbles: true,
      cancelable: true,
      clientX: pointer.clientX,
      clientY: pointer.clientY,
      screenX: pointer.screenX,
      screenY: pointer.screenY,
      button: 0,
      buttons: pointer.buttons,
      ctrlKey: pointer.ctrlKey,
      shiftKey: pointer.shiftKey,
      altKey: pointer.altKey,
      metaKey: pointer.metaKey,
      dataTransfer: active.data,
    });
    target.dispatchEvent(event);
    return event;
  }

  function finish(pointer, drop) {
    if (!active) return;
    const state = active;
    try {
      if (state.dragging) {
        // DIM's backend rechecks canDrop on drop; its cursor effect is not an API result.
        const completed = drop && state.target &&
          (state.accepted || state.target.closest('.sub-bucket'));
        if (completed) emit('drop', state.target, pointer);
        if (!completed) state.data.dropEffect = 'none';
        emit('dragend', state.source, pointer);
        suppressClickUntil = performance.now() + 250;
      }
    } finally {
      state.preview?.remove();
      active = null;
    }
  }

  function hover(pointer) {
    let target = document.elementFromPoint(pointer.clientX, pointer.clientY);
    active.overlayHit = !!target?.closest('[class*="dragPerfFix"]');
    // DIM's full-screen drag overlay can cover its own inventory drop targets.
    if (active.overlayHit) {
      target = document.elementsFromPoint(pointer.clientX, pointer.clientY)
        .find(node => !active.preview?.contains(node) && node.closest('.sub-bucket'))
        ?.closest('.sub-bucket') || target;
    }
    const allowed = active.data.effectAllowed.toLowerCase();
    active.data.dropEffect = allowed === 'none' ? 'none' :
      allowed === 'copy' || allowed === 'copylink' ? 'copy' :
      allowed === 'link' ? 'link' : 'move';
    if (target !== active.target) {
      if (active.target) emit('dragleave', active.target, pointer);
      active.target = target;
      if (target) emit('dragenter', target, pointer);
    }
    active.accepted = !!target && emit('dragover', target, pointer).defaultPrevented &&
      active.data.dropEffect !== 'none';
    if (active.preview) {
      active.preview.style.left = `${pointer.clientX + 12}px`;
      active.preview.style.top = `${pointer.clientY + 12}px`;
    }
  }

  window.addEventListener('pointerdown', event => {
    if (active || event.button !== 0 || event.pointerType !== 'mouse' || event.isPrimary === false ||
        !(event.target instanceof Element) ||
        event.target.closest('input, textarea, select, [contenteditable="true"]')) return;
    const source = event.target.closest('[draggable="true"]');
    if (!source) return;
    active = { source, pointerId: event.pointerId, start: event, last: event, dragging: false };
  }, true);

  window.addEventListener('pointermove', event => {
    if (!active || event.pointerId !== active.pointerId) return;
    active.last = event;
    if (!active.source.isConnected || (event.buttons & 1) === 0) {
      finish(event, false);
      return;
    }
    if (!active.dragging) {
      if (Math.hypot(event.clientX - active.start.clientX, event.clientY - active.start.clientY) < 6) return;
      active.data = new DataTransfer();
      active.data.effectAllowed = 'all';
      // The preview is drawn in-page, so React DnD must not call UWP's native drag-image path.
      active.data.setDragImage = () => {};
      active.dragging = true;
      if (emit('dragstart', active.source, active.start).defaultPrevented) {
        // A cancelled dragstart never produces dragend.
        active.dragging = false;
        suppressClickUntil = performance.now() + 250;
        finish(event, false);
        return;
      }
      const bounds = active.source.getBoundingClientRect();
      const preview = active.source.cloneNode(true);
      preview.removeAttribute('id');
      preview.querySelectorAll('[id]').forEach(node => node.removeAttribute('id'));
      preview.setAttribute('aria-hidden', 'true');
      preview.inert = true;
      preview.style.cssText += `;position:fixed;pointer-events:none!important;z-index:2147483647;` +
        `margin:0;width:${bounds.width}px;height:${bounds.height}px;opacity:.75;transform:none;`;
      document.body.appendChild(preview);
      active.preview = preview;
    }
    event.preventDefault();
    emit('drag', active.source, event);
    hover(event);
  }, { capture: true, passive: false });

  // Native dragend can terminate React DnD while our synthetic drag is still active.
  for (const type of ['dragstart', 'drag', 'dragenter', 'dragover', 'dragleave', 'drop', 'dragend']) {
    window.addEventListener(type, event => {
      if (event.isTrusted && active) {
        event.preventDefault();
        event.stopImmediatePropagation();
      }
    }, true);
  }

  window.addEventListener('pointerup', event => {
    if (!active || event.pointerId !== active.pointerId) return;
    if (active.dragging) hover(event);
    finish(event, true);
  }, true);

  window.addEventListener('pointercancel', event => {
    if (active && event.pointerId === active.pointerId) finish(event, false);
  }, true);
  window.addEventListener('pointerout', event => {
    if (active && event.pointerId === active.pointerId && event.relatedTarget === null)
      finish(event, false);
  }, true);
  window.addEventListener('blur', () => { if (active) finish(active.last, false, 'blur'); });
  window.addEventListener('pagehide', () => { if (active) finish(active.last, false); });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && active) finish(active.last, false);
  });
  window.addEventListener('keydown', event => {
    if (event.key === 'Escape' && active) {
      event.preventDefault();
      finish(active.last, false, 'escape');
    }
  }, true);
  window.addEventListener('click', event => {
    if (performance.now() < suppressClickUntil) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);
})();
