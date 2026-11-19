// Progress sync for signed-in learners (LAUNCH_PLAN.md §6). Added to every page by stage.mjs,
// so it exists only on the Cloudflare site; GitHub Pages never loads it.
//
// The pages keep using localStorage exactly as before. This script watches the keys that hold
// progress, sends changes to /api/progress, and writes back what the server merged.
//   - Only when signed in (the 'ws-account' flag, set by /account and the landing page):
//     signed-out visitors never call the server, so free pages cost no Function requests.
//   - One request per page load (sync + last visit), then one per burst of changes.
//   - If the server had newer progress, the page reloads once so it shows it.
(function () {
  if (window.WSSync) return;
  var ls;
  try { ls = window.localStorage; ls.getItem('x'); } catch (e) { return; }

  var FLAG = 'ws-account';
  var META = 'ws-sync-ts';
  var SYNCED = [/^rq:v1$/, /^quiz-score:[A-Za-z0-9_\-\/.]{1,120}$/, /^ws-path-done$/, /^ws-plan:[a-z0-9-]{1,40}$/];
  var proto = Object.getPrototypeOf(ls);
  var rawSet = proto.setItem, rawRemove = proto.removeItem, rawGet = proto.getItem;
  var get = function (k) { return rawGet.call(ls, k); };
  var put = function (k, v) { rawSet.call(ls, k, v); };
  var drop = function (k) { rawRemove.call(ls, k); };
  function isSynced(k) { return SYNCED.some(function (re) { return re.test(k); }); }
  function syncedKeys() { var out = []; for (var i = 0; i < ls.length; i++) { var k = ls.key(i); if (isSynced(k)) out.push(k); } return out; }
  function meta() { try { return JSON.parse(get(META)) || {}; } catch (e) { return {}; } }
  function setMeta(m) { put(META, JSON.stringify(m)); }
  function account() { return get(FLAG); }

  // Same JSON whatever the key order, to tell whether the server's copy differs from ours.
  function stable(v) {
    if (Array.isArray(v)) return '[' + v.map(stable).join(',') + ']';
    if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map(function (k) { return JSON.stringify(k) + ':' + stable(v[k]); }).join(',') + '}';
    return JSON.stringify(v);
  }

  var pendingSet = {}, pendingDel = {}, timer = null;

  // Watch the pages' own writes.
  proto.setItem = function (k, v) {
    rawSet.call(this, k, v);
    if (this === ls && isSynced(k)) {
      var m = meta(); m[k] = Date.now(); setMeta(m);
      // A delete still waiting is kept: the server deletes first, then stores this (a reset).
      pendingSet[k] = 1; schedule();
    }
  };
  proto.removeItem = function (k) {
    rawRemove.call(this, k);
    if (this === ls && isSynced(k)) {
      var m = meta(); delete m[k]; setMeta(m);
      pendingDel[k] = 1; delete pendingSet[k]; schedule();
    }
  };

  function body(keys, dels) {
    var m = meta(), set = {};
    keys.forEach(function (k) {
      var raw = get(k);
      if (raw === null) return;
      try { set[k] = { value: JSON.parse(raw), ts: m[k] || 0 }; } catch (e) { /* not JSON: leave it */ }
    });
    return { set: set, delete: dels };
  }

  function apply(items, first, gone) {
    var m = meta(), changed = false;
    // Reset on another device after this copy was last changed: drop it here too.
    (gone || []).forEach(function (k) {
      if (isSynced(k) && !pendingSet[k] && get(k) !== null) { drop(k); delete m[k]; changed = true; }
    });
    Object.keys(items || {}).forEach(function (k) {
      if (!isSynced(k) || pendingSet[k] || pendingDel[k]) return;
      var mine = get(k), theirs = items[k];
      var same = false;
      try { same = mine !== null && stable(JSON.parse(mine)) === stable(theirs.value); } catch (e) { same = false; }
      if (!same) { put(k, JSON.stringify(theirs.value)); changed = true; }
      m[k] = theirs.ts;
    });
    setMeta(m);
    if (changed && first) {
      var once = 'ws-sync-reloaded:' + location.pathname;
      try {
        if (!sessionStorage.getItem(once)) { sessionStorage.setItem(once, '1'); location.reload(); }
      } catch (e) { /* no sessionStorage: show the newer progress on the next visit */ }
    }
  }

  function send(payload, first) {
    if (!account()) return Promise.resolve();
    return fetch('/api/progress', {
      method: 'POST', credentials: 'same-origin', keepalive: true,
      headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload),
    }).then(function (r) {
      if (r.status === 401) { drop(FLAG); return; } // session over: stop syncing, keep the data here
      if (!r.ok) return;
      return r.json().then(function (d) { apply(d.items, first, d.gone); });
    }).catch(function () { /* offline: the next page load sends it again */ });
  }

  function flush() {
    clearTimeout(timer); timer = null;
    var keys = Object.keys(pendingSet), dels = Object.keys(pendingDel);
    if (!keys.length && !dels.length) return Promise.resolve();
    pendingSet = {}; pendingDel = {};
    return send(body(keys, dels), false);
  }
  function schedule() { if (!account()) return; clearTimeout(timer); timer = setTimeout(flush, 1500); }

  // Leaving the page: send what is still waiting (the game reloads right after a reset or import).
  function flushNow() {
    if (!account()) return;
    var keys = Object.keys(pendingSet), dels = Object.keys(pendingDel);
    if (!keys.length && !dels.length) return;
    pendingSet = {}; pendingDel = {};
    var b = JSON.stringify(body(keys, dels));
    if (!(navigator.sendBeacon && navigator.sendBeacon('/api/progress', new Blob([b], { type: 'application/json' })))) {
      fetch('/api/progress', { method: 'POST', credentials: 'same-origin', keepalive: true, headers: { 'content-type': 'application/json' }, body: b });
    }
  }
  window.addEventListener('pagehide', flushNow);
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden') flushNow(); });

  function start() {
    if (!account()) return;
    var p = body(syncedKeys(), []);
    p.visit = { path: location.pathname, title: document.title };
    send(p, true);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();

  window.WSSync = {
    /** Call when /api/me shows a signed-in user. Progress left here by another account is cleared first. */
    signedIn: function (userId) {
      var prev = account() || get(FLAG + '-last');
      if (prev && prev !== userId) { syncedKeys().forEach(drop); drop(META); }
      var fresh = account() !== userId;
      put(FLAG, userId); put(FLAG + '-last', userId);
      if (fresh) start();
    },
    /** Send anything waiting, then forget this browser's copy (it is in the account). For shared computers. */
    signOut: function () {
      return flush().then(function () {
        syncedKeys().forEach(drop); drop(META); drop(FLAG); drop(FLAG + '-last');
      });
    },
    /** The session ended without a sign-out: stop syncing, keep the data. */
    sessionEnded: function () { drop(FLAG); },
    flush: flush,
  };
})();
