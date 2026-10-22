// Removes the plain-HTML splash once Flutter paints its first frame.
(function () {
  'use strict';
  window.addEventListener('flutter-first-frame', function () {
    var splash = document.getElementById('splash');
    if (!splash) return;
    splash.style.opacity = '0';
    setTimeout(function () { splash.remove(); }, 300);
  });
})();
