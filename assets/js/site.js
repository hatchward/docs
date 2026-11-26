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

  var main = document.getElementById('main');

  /* "On this page", from the page's h2s. Built before the anchors and tags
     below are added to those headings, so their text stays clean. Three or
     more sections, or it is not worth a column. */
  var toc = document.getElementById('toc');
  var sections = main ? [].slice.call(main.querySelectorAll('h2[id]')) : [];
  if (toc && sections.length >= 3) {
    var list = toc.querySelector('.toc__list');
    var links = sections.map(function (h) {
      var li = document.createElement('li');
      var a = document.createElement('a');
      a.href = '#' + h.id;
      a.textContent = h.textContent.trim();
      li.appendChild(a);
      list.appendChild(li);
      return a;
    });
    toc.hidden = false;

    /* Mark the section being read: the last heading above the top fifth of
       the viewport. */
    var mark = function () {
      var line = window.innerHeight / 5, current = 0;
      sections.forEach(function (h, i) { if (h.getBoundingClientRect().top <= line) current = i; });
      links.forEach(function (a, i) {
        if (i === current) a.setAttribute('aria-current', 'location');
        else a.removeAttribute('aria-current');
      });
    };
    var queued = false;
    window.addEventListener('scroll', function () {
      if (queued) return;
      queued = true;
      requestAnimationFrame(function () { queued = false; mark(); });
    }, { passive: true });
    mark();
  }

  /* The page's audience tags are rendered before the content so they exist
     without this script; they belong under the title. */
  var tags = document.getElementById('page-tags');
  var h1 = main && main.querySelector('h1');
  if (tags && h1) h1.insertAdjacentElement('afterend', tags);

  /* Deep links into a long document. Kramdown already generates the ids. */
  document.querySelectorAll('.prose h2[id], .prose h3[id]').forEach(function (h) {
    var a = document.createElement('a');
    a.className = 'anchor';
    a.href = '#' + h.id;
    a.textContent = '#';
    a.setAttribute('aria-label', 'Link to “' + h.textContent.trim() + '”');
    h.appendChild(a);
  });

  /* Sections for Hatchward operators, as listed in _data/nav.yml. */
  if (main && main.dataset.operatorSections) {
    main.dataset.operatorSections.split(' ').forEach(function (id) {
      var h = document.getElementById(id);
      if (!h || h.tagName !== 'H2') return;
      var t = document.createElement('span');
      t.className = 'tag tag--operator';
      t.textContent = main.dataset.operatorLabel;
      h.appendChild(t);
    });
  }

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

  /* Light / Dark / Auto, as a dropdown menu. head.html applies a saved
     choice before paint; this shows the switch, runs the menu and keeps the
     choice. Auto removes it, so the system setting decides again. */
  var theme = document.getElementById('theme');
  if (theme) {
    var root = document.documentElement;
    var toggle = theme.querySelector('.theme__toggle');
    var menu = theme.querySelector('.theme__menu');
    var items = Array.prototype.slice.call(menu.querySelectorAll('[role="menuitemradio"]'));
    var label = theme.querySelector('.theme__label');
    var show = function () {
      var now = root.getAttribute('data-theme') || 'system';
      theme.setAttribute('data-current', now);
      items.forEach(function (b) {
        var on = b.dataset.themeChoice === now;
        b.setAttribute('aria-checked', String(on));
        if (on) label.textContent = b.textContent.trim();
      });
    };
    var open = function (focusIndex) {
      menu.hidden = false;
      toggle.setAttribute('aria-expanded', 'true');
      var i = typeof focusIndex === 'number' ? focusIndex
        : items.findIndex(function (b) { return b.getAttribute('aria-checked') === 'true'; });
      items[(i + items.length) % items.length].focus();
    };
    var close = function (refocus) {
      if (menu.hidden) return;
      menu.hidden = true;
      toggle.setAttribute('aria-expanded', 'false');
      if (refocus) toggle.focus();
    };
    var choose = function (choice) {
      if (choice === 'system') root.removeAttribute('data-theme');
      else root.setAttribute('data-theme', choice);
      try {
        if (choice === 'system') localStorage.removeItem('hatchward-theme');
        else localStorage.setItem('hatchward-theme', choice);
      } catch (err) { /* storage blocked: the choice lasts for this page only */ }
      show();
    };
    toggle.addEventListener('click', function () {
      if (menu.hidden) open(); else close(false);
    });
    toggle.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown') { e.preventDefault(); open(0); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); open(items.length - 1); }
    });
    menu.addEventListener('click', function (e) {
      var b = e.target.closest('[role="menuitemradio"]');
      if (!b) return;
      choose(b.dataset.themeChoice);
      close(true);
    });
    menu.addEventListener('keydown', function (e) {
      var i = items.indexOf(document.activeElement);
      if (e.key === 'ArrowDown') { e.preventDefault(); items[(i + 1) % items.length].focus(); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); items[(i - 1 + items.length) % items.length].focus(); }
      else if (e.key === 'Home') { e.preventDefault(); items[0].focus(); }
      else if (e.key === 'End') { e.preventDefault(); items[items.length - 1].focus(); }
      else if (e.key === 'Escape') { e.preventDefault(); close(true); }
      else if (e.key === 'Tab') close(false);
    });
    document.addEventListener('click', function (e) {
      if (!theme.contains(e.target)) close(false);
    });
    show();
    theme.hidden = false;
  }
})();
