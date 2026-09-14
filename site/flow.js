/* flow.js — deterministic state controller for the AgenticFlowFigure.
   Sets [data-phase] (transient) and is-* milestone classes (persistent) on the
   [data-flow] figure; flow.css renders every visual change. One ordered phase
   table, no libraries, cleaned-up timers, reduced-motion safe. */
(function () {
  'use strict';

  var fig = document.querySelector('[data-flow]');
  if (!fig) { return; }

  /* One ordered array of [phase, durationMs]; total ≈ 8.4s. */
  var PHASES = [
    ['wake', 700],
    ['ingest', 1300],
    ['classify', 1200],
    ['route-label', 867],
    ['route-task', 867],
    ['route-calendar', 866],
    ['produce', 1300],
    ['audit', 1300]
  ];

  var reduceMotion = false;
  try {
    reduceMotion = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  } catch (e) { reduceMotion = false; }

  var idx = 0;
  var running = false;
  var started = false;
  var timer = null;
  var remaining = 0;
  var endedAt = 0;

  function clearTimer() {
    if (timer) { clearTimeout(timer); timer = null; }
  }

  function stripMilestones() {
    for (var i = 0; i < PHASES.length; i++) { fig.classList.remove('is-' + PHASES[i][0]); }
    fig.classList.remove('is-complete');
  }

  function complete() {
    running = false;
    clearTimer();
    fig.classList.remove('is-paused');
    fig.setAttribute('data-phase', 'complete');
  }

  function advance() {
    if (!running) { return; }
    if (idx >= PHASES.length) { complete(); return; }
    var phase = PHASES[idx++];
    fig.setAttribute('data-phase', phase[0]);
    fig.classList.add('is-' + phase[0]);
    endedAt = Date.now() + phase[1];
    timer = setTimeout(advance, phase[1]);
  }

  function play() {
    if (running || started) { return; }
    started = true;
    running = true;
    advance();
  }

  function restart() {
    clearTimer();
    stripMilestones();
    /* flush styles so the re-added is-wake restarts the wake animation */
    void fig.offsetWidth;
    fig.classList.remove('is-paused');
    fig.setAttribute('data-phase', 'idle');
    idx = 0;
    remaining = 0;
    running = false;
    started = true;
    running = true;
    advance();
  }

  function pause() {
    if (!running) { return; }
    clearTimer();
    remaining = Math.max(0, endedAt - Date.now());
    running = false;
    fig.classList.add('is-paused');
  }

  function resume() {
    if (running || !started) { return; }
    if (fig.getAttribute('data-phase') === 'complete') { return; }
    fig.classList.remove('is-paused');
    running = true;
    if (remaining > 0) {
      endedAt = Date.now() + remaining;
      timer = setTimeout(advance, remaining);
      remaining = 0;
    } else {
      advance();
    }
  }

  function showComplete() {
    var names = ['wake', 'ingest', 'classify', 'route-label', 'route-task', 'route-calendar', 'produce', 'audit'];
    for (var i = 0; i < names.length; i++) { fig.classList.add('is-' + names[i]); }
    fig.classList.remove('is-paused');
    fig.setAttribute('data-phase', 'complete');
    started = true;
  }

  if (reduceMotion) {
    showComplete();
  } else {
    fig.classList.add('is-armed');

    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].isIntersecting) {
            if (!started) { play(); } else { resume(); }
          } else {
            pause();
          }
        }
      }, { threshold: 0.35 });
      io.observe(fig);
    } else {
      play();
    }

    document.addEventListener('visibilitychange', function () {
      if (document.hidden) { pause(); } else { resume(); }
    });
  }

  var replay = fig.querySelector('[data-flow-replay]');
  if (replay) {
    replay.addEventListener('click', function () {
      if (reduceMotion) { showComplete(); return; }
      restart();
    });
  }
})();
