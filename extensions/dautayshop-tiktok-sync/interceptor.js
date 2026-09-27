// Injected into the page context to intercept internal TikTok Shop fetch/XHR product calls
(function() {
  const origFetch = window.fetch;
  window.fetch = async function(...args) {
    const resp = await origFetch.apply(this, args);
    try {
      const url = typeof args[0] === 'string' ? args[0] : args[0]?.url;
      if (url && (url.includes('product') || url.includes('item') || url.includes('goods') || url.includes('sku'))) {
        const clone = resp.clone();
        clone.json().then(data => {
          window.postMessage({ type: 'TIKTOK_SHOP_PRODUCTS_INTERCEPTED', url, data }, '*');
        }).catch(() => {});
      }
    } catch (e) {}
    return resp;
  };

  const origXHROpen = XMLHttpRequest.prototype.open;
  const origXHRSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    this._url = url;
    return origXHROpen.call(this, method, url, ...rest);
  };
  XMLHttpRequest.prototype.send = function(...args) {
    this.addEventListener('load', function() {
      try {
        if (this._url && (this._url.includes('product') || this._url.includes('item') || this._url.includes('goods') || this._url.includes('sku'))) {
          const data = JSON.parse(this.responseText);
          window.postMessage({ type: 'TIKTOK_SHOP_PRODUCTS_INTERCEPTED', url: this._url, data }, '*');
        }
      } catch (e) {}
    });
    return origXHRSend.apply(this, args);
  };
})();
