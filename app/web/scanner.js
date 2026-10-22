// Camera QR scanner living outside Flutter's canvas (ADR-0006).
// A fixed <video playsinline muted> is placed over the rectangle Flutter
// reserves for the viewfinder; decoding uses BarcodeDetector where available
// (Android Chrome) and the self-hosted zxing-wasm reader elsewhere (iOS).
(function () {
  'use strict';

  let wrap = null;
  let video = null;
  let stream = null;
  let timer = null;
  let detector = null;
  let canvas = null;
  let zxingReady = null;
  let last = { text: '', at: 0 };

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = src;
      s.async = true;
      s.onload = resolve;
      s.onerror = () => reject(new Error('script load failed'));
      document.head.appendChild(s);
    });
  }

  function ensureZxing() {
    if (!zxingReady) {
      zxingReady = loadScript('zxing/reader.js').then(() => {
        window.ZXingWASM.prepareZXingModule({
          overrides: {
            locateFile: (path, prefix) => (path.endsWith('.wasm') ? 'zxing/' + path : prefix + path),
          },
          fireImmediately: true,
        });
      });
    }
    return zxingReady;
  }

  function place(x, y, w, h) {
    if (!wrap) return;
    Object.assign(wrap.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: h + 'px' });
  }

  async function decode() {
    if (!video || video.readyState < 2) return null;
    const vw = video.videoWidth;
    const vh = video.videoHeight;
    const side = Math.min(vw, vh, 720);
    const sx = (vw - side) / 2;
    const sy = (vh - side) / 2;
    if (detector) {
      const codes = await detector.detect(video);
      return codes.length ? codes[0].rawValue : null;
    }
    canvas = canvas || document.createElement('canvas');
    canvas.width = side;
    canvas.height = side;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(video, sx, sy, side, side, 0, 0, side, side);
    const results = await window.ZXingWASM.readBarcodes(ctx.getImageData(0, 0, side, side), {
      formats: ['QRCode'],
      tryHarder: false,
      maxNumberOfSymbols: 1,
    });
    const hit = results.find((r) => r.isValid);
    return hit ? hit.text : null;
  }

  async function start(x, y, w, h, onResult, onError) {
    stop();
    try {
      if ('BarcodeDetector' in window) {
        const formats = await window.BarcodeDetector.getSupportedFormats();
        if (formats.includes('qr_code')) detector = new window.BarcodeDetector({ formats: ['qr_code'] });
      }
      if (!detector) await ensureZxing();

      wrap = document.createElement('div');
      wrap.setAttribute('aria-hidden', 'true');
      Object.assign(wrap.style, {
        position: 'fixed',
        zIndex: '10',
        overflow: 'hidden',
        borderRadius: '21px',
        pointerEvents: 'none',
        background: '#0E0D10',
      });
      video = document.createElement('video');
      video.setAttribute('playsinline', '');
      video.setAttribute('muted', '');
      video.muted = true;
      video.autoplay = true;
      Object.assign(video.style, { width: '100%', height: '100%', objectFit: 'cover' });
      wrap.appendChild(video);
      document.body.appendChild(wrap);
      place(x, y, w, h);

      stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 1280 }, height: { ideal: 720 } },
      });
      video.srcObject = stream;
      await video.play();

      timer = setInterval(async () => {
        try {
          const text = await decode();
          if (!text) return;
          const now = Date.now();
          if (text === last.text && now - last.at < 2000) return;
          last = { text, at: now };
          onResult(text);
        } catch (_) {
          /* a single bad frame is not an error */
        }
      }, 180);
    } catch (e) {
      const name = e && e.name ? e.name : 'Error';
      stop();
      onError(name === 'NotAllowedError' || name === 'SecurityError' ? 'denied' : name === 'NotFoundError' ? 'no-camera' : 'failed');
    }
  }

  function stop() {
    if (timer) clearInterval(timer);
    timer = null;
    if (stream) stream.getTracks().forEach((t) => t.stop());
    stream = null;
    if (wrap) wrap.remove();
    wrap = null;
    video = null;
    detector = null;
  }

  function prefetch() {
    if (!('BarcodeDetector' in window)) ensureZxing().catch(() => {});
  }

  window.bagScanner = { start, stop, place, prefetch };
})();
