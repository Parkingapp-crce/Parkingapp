window.addEventListener('error', function(e) {
  var errorDiv = document.createElement('div');
  errorDiv.style.color = 'red';
  errorDiv.style.padding = '20px';
  errorDiv.style.fontSize = '16px';
  errorDiv.style.fontFamily = 'monospace';
  errorDiv.style.zIndex = '999999';
  errorDiv.style.position = 'absolute';
  errorDiv.style.background = 'white';
  errorDiv.style.top = '0';
  errorDiv.style.left = '0';
  errorDiv.innerHTML = '<h3>Crash Error:</h3>' + e.message + '<br>' + e.filename + ':' + e.lineno;
  document.body.appendChild(errorDiv);
});
window.addEventListener('unhandledrejection', function(e) {
  var errorDiv = document.createElement('div');
  errorDiv.style.color = 'red';
  errorDiv.style.padding = '20px';
  errorDiv.style.fontSize = '16px';
  errorDiv.style.fontFamily = 'monospace';
  errorDiv.style.zIndex = '999999';
  errorDiv.style.position = 'absolute';
  errorDiv.style.background = 'white';
  errorDiv.style.top = '100px';
  errorDiv.style.left = '0';
  errorDiv.innerHTML = '<h3>Promise Error:</h3>' + (e.reason && e.reason.message ? e.reason.message : String(e.reason));
  document.body.appendChild(errorDiv);
});
