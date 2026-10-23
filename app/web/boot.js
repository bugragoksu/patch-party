// Plain-HTML splash: rotates game tips while Flutter loads, then removes
// itself once Flutter paints its first frame.
(function () {
  'use strict';
  var tips = [
    "QR'ını okutan kişi de onaylayınca bağlantı kurulur.",
    'Her bağlantı ikinize de +10 puan kazandırır.',
    'Ortak ilgi alanınız yoksa +5 bonus var.',
    'Bağlantı kurulunca ikinize ortak bir soru gelir.',
    'Liderlik tablosu projeksiyonda.',
  ];
  var tip = document.getElementById('splash-tip');
  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var i = 0;
  var timer = tip && setInterval(function () {
    i = (i + 1) % tips.length;
    if (reduced) { show(); return; }
    tip.style.opacity = '0';
    setTimeout(show, 200);
  }, 2600);
  function show() {
    tip.innerHTML = '<b>İpucu:</b> ';
    tip.appendChild(document.createTextNode(tips[i]));
    tip.style.opacity = '1';
  }

  window.addEventListener('flutter-first-frame', function () {
    clearInterval(timer);
    var splash = document.getElementById('splash');
    if (!splash) return;
    splash.style.opacity = '0';
    setTimeout(function () { splash.remove(); }, 300);
  });
})();
