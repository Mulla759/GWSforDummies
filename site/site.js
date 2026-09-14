/* site.js — progressive enhancement for the GWS for Dummies landing page.
   Loaded with `defer`. Everything is guarded; with JS disabled the page stays
   fully readable. Behaviors: copy controls, active section nav, reveal +
   scroll progress. No dependencies, no animation libraries. */
(function () {
  'use strict';

  var doc = document;
  var hasIO = 'IntersectionObserver' in window;
  var reduceMotion = false;
  try {
    reduceMotion = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  } catch (e) { reduceMotion = false; }

  var raf = window.requestAnimationFrame
    ? window.requestAnimationFrame.bind(window)
    : function (cb) { return setTimeout(cb, 16); };

  function toArray(list) {
    return Array.prototype.slice.call(list || []);
  }

  /* ------------------------------------------------------------------ *
   * 1. Copy controls                                                    *
   * ------------------------------------------------------------------ */

  var RESET_MS = 1600;

  function legacyCopy(text) {
    var ta = doc.createElement('textarea');
    ta.value = text;
    ta.setAttribute('readonly', '');
    ta.style.position = 'fixed';
    ta.style.top = '-1000px';
    ta.style.left = '-1000px';
    ta.style.opacity = '0';
    var prev = doc.activeElement;
    doc.body.appendChild(ta);
    var ok = false;
    try {
      ta.select();
      if (typeof ta.setSelectionRange === 'function') {
        ta.setSelectionRange(0, ta.value.length);
      }
      ok = doc.execCommand('copy');
    } catch (e) {
      ok = false;
    }
    if (ta.parentNode) { ta.parentNode.removeChild(ta); }
    if (prev && typeof prev.focus === 'function') {
      try { prev.focus({ preventScroll: true }); }
      catch (e) { try { prev.focus(); } catch (e2) {} }
    }
    return !!ok;
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).then(
        function () { return true; },
        function () { return legacyCopy(text); }
      );
    }
    return Promise.resolve(legacyCopy(text));
  }

  function initCopy() {
    var buttons = toArray(doc.querySelectorAll('button.copy[data-copy-from]'));
    if (!buttons.length) { return; }

    var live = doc.getElementById('copy-live');
    var originals = new Map();
    var timers = new Map();

    function announce(message) {
      if (live) { live.textContent = message; }
    }

    function scheduleReset(button, ms) {
      if (timers.has(button)) { clearTimeout(timers.get(button)); }
      timers.set(button, setTimeout(function () {
        timers.delete(button);
        var original = originals.get(button);
        if (original) {
          button.textContent = original.text;
          if (original.label === null) { button.removeAttribute('aria-label'); }
          else { button.setAttribute('aria-label', original.label); }
        }
        button.classList.remove('is-copied');
        announce('');
      }, ms || RESET_MS));
    }

    function onCopy(button) {
      var selector = button.getAttribute('data-copy-from');
      if (!selector) { return; }

      var source = null;
      try { source = doc.querySelector(selector); }
      catch (e) { source = null; }
      if (!source) { return; }

      var text;
      if (button.getAttribute('data-copy-type') === 'email') {
        var href = source.getAttribute ? source.getAttribute('href') : null;
        var raw = (href && /^mailto:/i.test(href)) ? href : (source.textContent || '');
        text = raw.replace(/^mailto:/i, '').trim();
      } else {
        text = (source.textContent || '').trim();
      }

      if (!originals.has(button)) {
        originals.set(button, {
          text: button.textContent,
          label: button.hasAttribute('aria-label') ? button.getAttribute('aria-label') : null
        });
      }

      var doneMsg = button.getAttribute('data-copy-announce') || 'Copied to clipboard';
      var failMsg = 'Copy failed \u2014 select and copy manually';
      var resetMs = parseInt(button.getAttribute('data-copy-reset'), 10) || RESET_MS;

      copyText(text).then(function (ok) {
        if (ok) {
          button.textContent = 'Copied \u2713';
          button.classList.add('is-copied');
          announce(doneMsg);
          scheduleReset(button, resetMs);
        } else {
          announce(failMsg);
          scheduleReset(button, resetMs);
        }
      }, function () {
        announce(failMsg);
        scheduleReset(button, resetMs);
      });
    }

    buttons.forEach(function (button) {
      button.addEventListener('click', function () { onCopy(button); });
    });
  }

  /* ------------------------------------------------------------------ *
   * 2. Active section navigation                                        *
   * ------------------------------------------------------------------ */

  function initNav() {
    if (!hasIO) { return; }

    var sections = toArray(doc.querySelectorAll('[data-section]'));
    if (!sections.length) { return; }

    var links = Object.create(null);
    toArray(doc.querySelectorAll('[data-nav]')).forEach(function (link) {
      var value = link.getAttribute('data-nav');
      (links[value] || (links[value] = [])).push(link);
    });

    var current = null;

    function setActive(value) {
      if (value === current) { return; }
      current = value;
      Object.keys(links).forEach(function (key) {
        var on = key === value;
        links[key].forEach(function (link) {
          if (on) {
            link.setAttribute('aria-current', 'location');
            link.classList.add('is-active');
          } else {
            link.removeAttribute('aria-current');
            link.classList.remove('is-active');
          }
        });
      });
    }

    function pick() {
      var height = window.innerHeight || doc.documentElement.clientHeight || 0;
      var bandTop = height * 0.45;
      var bandBottom = height * 0.50;
      var best = null;
      var bestTop = -Infinity;
      sections.forEach(function (section) {
        var rect = section.getBoundingClientRect();
        var overlaps = rect.top < bandBottom && rect.bottom > bandTop;
        if (overlaps && rect.top > bestTop) {
          bestTop = rect.top;
          best = section;
        }
      });
      if (best) { setActive(best.getAttribute('data-section')); }
    }

    var observer = new IntersectionObserver(function () { pick(); }, {
      root: null,
      rootMargin: '-45% 0px -50% 0px',
      threshold: [0]
    });

    sections.forEach(function (section) { observer.observe(section); });

    pick();
    window.addEventListener('resize', function () { pick(); }, { passive: true });
  }

  /* ------------------------------------------------------------------ *
   * 3. Reveal + scroll progress                                         *
   * ------------------------------------------------------------------ */

  function initReveal() {
    var elements = toArray(doc.querySelectorAll('[data-reveal]'));
    if (!elements.length) { return; }

    if (reduceMotion || !hasIO) {
      elements.forEach(function (el) { el.classList.add('is-visible'); });
      return;
    }

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12 });

    elements.forEach(function (el) { observer.observe(el); });
  }

  function initProgress() {
    var marker = doc.querySelector('[data-progress]');
    if (!marker) { return; }

    var track = marker.closest ? marker.closest('.progress') : null;
    if (!track) { return; }

    if (reduceMotion) {
      marker.style.transform = 'translateX(0px)';
      return;
    }

    var trackWidth = 0;
    var ticking = false;

    function measure() {
      trackWidth = track.clientWidth || 0;
    }

    function apply() {
      ticking = false;
      var root = doc.documentElement;
      var scrollTop = window.pageYOffset || root.scrollTop || 0;
      var max = root.scrollHeight - (window.innerHeight || root.clientHeight || 0);
      var progress = max > 0 ? scrollTop / max : 0;
      if (progress < 0) { progress = 0; }
      if (progress > 1) { progress = 1; }
      var span = trackWidth - (marker.offsetWidth || 0);
      if (span < 0) { span = 0; }
      marker.style.transform = 'translateX(' + (progress * span) + 'px)';
    }

    function onScroll() {
      if (ticking) { return; }
      ticking = true;
      raf(apply);
    }

    measure();
    apply();
    window.addEventListener('scroll', onScroll, { passive: true });

    var resizeTimer = null;
    window.addEventListener('resize', function () {
      if (resizeTimer) { clearTimeout(resizeTimer); }
      resizeTimer = setTimeout(function () { measure(); apply(); }, 150);
    }, { passive: true });
  }

  function init() {
    initCopy();
    initNav();
    initReveal();
    initProgress();
  }

  if (doc.readyState === 'loading') {
    doc.addEventListener('DOMContentLoaded', init, { once: true });
  } else {
    init();
  }
})();
