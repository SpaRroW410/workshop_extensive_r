(function(){
  // Load fitty library then initialize
  function loadScript(src, cb) {
    var s = document.createElement('script');
    s.src = src;
    s.onload = cb;
    document.head.appendChild(s);
  }

  function initFitty(){
    if (typeof fitty !== 'undefined'){
      try{
        fitty('.r-fit-text', { minSize: 24, maxSize: 60, multiLine: true });
      }catch(e){console.warn('fitty init failed', e)}
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function(){
      loadScript('https://cdn.jsdelivr.net/npm/fitty@2/dist/fitty.min.js', initFitty);
    });
  } else {
    loadScript('https://cdn.jsdelivr.net/npm/fitty@2/dist/fitty.min.js', initFitty);
  }
})();
