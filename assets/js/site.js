/* Progressive enhancement only — every page is complete without this file. */
(function () {
  'use strict';

  /* Wide reference tables (errors.md) must scroll inside their own box rather
     than pushing the page sideways. Kramdown emits a bare <table>, so the
     wrapper has to be added here. */
  document.querySelectorAll('.prose table').forEach(function (table) {
    if (table.parentElement.classList.contains('scrollx')) return;
    var box = document.createElement('div');
    box.className = 'scrollx';
    table.parentNode.insertBefore(box, table);
    box.appendChild(table);
  });

  /* Deep links into a long document. Kramdown already generates the ids. */
  document.querySelectorAll('.prose h2[id], .prose h3[id]').forEach(function (h) {
    var a = document.createElement('a');
    a.className = 'anchor';
    a.href = '#' + h.id;
    a.textContent = '#';
    a.setAttribute('aria-label', 'Link to “' + h.textContent.trim() + '”');
    h.appendChild(a);
  });

  /* The spine is a <details> so it collapses on a phone. Above 56rem there is
     room for the whole list, so hold it open — and keep it open across a
     resize, which the CSS alone cannot do in every browser. */
  var spine = document.getElementById('spine');
  if (spine) {
    var wide = window.matchMedia('(min-width: 56rem)');
    var sync = function () { if (wide.matches) spine.open = true; };
    sync();
    wide.addEventListener('change', sync);
  }
})();
