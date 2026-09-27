// Content script for TikTok Shop Seller Center
(function() {
  console.log('🍓 DauTayShop TikTok Sync Content Script loaded');

  // Inject interceptor into the main DOM
  const script = document.createElement('script');
  script.src = chrome.runtime.getURL('interceptor.js');
  (document.head || document.documentElement).appendChild(script);
  script.onload = () => script.remove();

  let capturedProducts = new Map();

  // Load previously saved products from storage
  chrome.storage.local.get(['tiktok_products_map'], (res) => {
    if (res.tiktok_products_map) {
      try {
        capturedProducts = new Map(JSON.parse(res.tiktok_products_map));
        updateFloatingButton();
      } catch (e) {}
    }
  });

  // Listen to intercepted messages
  window.addEventListener('message', (event) => {
    if (event.source !== window || !event.data || event.data.type !== 'TIKTOK_SHOP_PRODUCTS_INTERCEPTED') return;

    const { url, data } = event.data;
    extractProductsFromData(data);
  });

  function extractProductsFromData(data) {
    if (!data) return;

    let items = [];

    // Search common response shapes in TikTok Seller Center
    if (Array.isArray(data)) {
      items = data;
    } else if (Array.isArray(data.products)) {
      items = data.products;
    } else if (Array.isArray(data.product_list)) {
      items = data.product_list;
    } else if (Array.isArray(data.items)) {
      items = data.items;
    } else if (Array.isArray(data.list)) {
      items = data.list;
    } else if (data.data) {
      if (Array.isArray(data.data.products)) items = data.data.products;
      else if (Array.isArray(data.data.product_list)) items = data.data.product_list;
      else if (Array.isArray(data.data.list)) items = data.data.list;
      else if (Array.isArray(data.data.items)) items = data.data.items;
      else if (Array.isArray(data.data)) items = data.data;
      else if (data.data.id && (data.data.title || data.data.product_name)) items = [data.data];
    } else if (data.id && (data.title || data.product_name)) {
      items = [data];
    }

    let added = 0;
    for (const item of items) {
      const pid = item.id || item.product_id || item.item_id;
      const title = item.title || item.product_name || item.name;
      if (pid && title) {
        capturedProducts.set(String(pid), item);
        added++;
      }
    }

    if (added > 0) {
      const serialized = JSON.stringify(Array.from(capturedProducts.entries()));
      chrome.storage.local.set({ 
        tiktok_products_map: serialized,
        tiktok_products_count: capturedProducts.size
      });
      updateFloatingButton();
    }
  }

  // Create cute floating sync button on bottom-right of TikTok Seller Center
  let floatBtn = null;
  function updateFloatingButton() {
    const count = capturedProducts.size;
    if (!floatBtn) {
      floatBtn = document.createElement('div');
      floatBtn.id = 'dautay-sync-float-btn';
      floatBtn.style.cssText = `
        position: fixed;
        bottom: 25px;
        right: 25px;
        z-index: 999999;
        background: linear-gradient(135deg, #ff4d6d, #d90429);
        color: white;
        padding: 12px 20px;
        border-radius: 50px;
        box-shadow: 0 4px 15px rgba(217, 4, 41, 0.4);
        cursor: pointer;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        font-weight: bold;
        font-size: 14px;
        display: flex;
        align-items: center;
        gap: 8px;
        transition: transform 0.2s, box-shadow 0.2s;
      `;
      floatBtn.onmouseenter = () => floatBtn.style.transform = 'scale(1.05)';
      floatBtn.onmouseleave = () => floatBtn.style.transform = 'scale(1)';
      floatBtn.onclick = () => {
        triggerSyncToDauTay(false);
      };
      document.body.appendChild(floatBtn);
    }
    floatBtn.innerHTML = `🍓 DauTayShop (${count} SP)`;
    floatBtn.title = `Đã bắt được ${count} sản phẩm từ TikTok Shop. Bấm để đồng bộ ngay!`;
  }

  // Listen to messages from popup
  chrome.runtime.onMessage.addListener((req, sender, sendResponse) => {
    if (req.action === 'GET_CAPTURED_PRODUCTS') {
      sendResponse({ products: Array.from(capturedProducts.values()) });
    } else if (req.action === 'SYNC_NOW') {
      triggerSyncToDauTay(req.clean_first).then(res => sendResponse(res)).catch(err => sendResponse({ success: false, error: err.message }));
      return true; // async
    } else if (req.action === 'CLEAR_CAPTURED') {
      capturedProducts.clear();
      chrome.storage.local.remove(['tiktok_products_map', 'tiktok_products_count']);
      updateFloatingButton();
      sendResponse({ success: true });
    }
  });

  async function triggerSyncToDauTay(cleanFirst = false) {
    if (capturedProducts.size === 0) {
      alert('Chưa có sản phẩm nào được quét. Vui lòng bấm vào danh sách Sản phẩm trên TikTok Shop hoặc tải lại trang!');
      return { success: false, error: 'Chưa có sản phẩm' };
    }

    const prods = Array.from(capturedProducts.values());
    if (floatBtn) floatBtn.innerHTML = `⏳ Đang gửi ${prods.length} SP...`;

    try {
      // Chunk into batches of 25 to ensure rock-solid transfers
      const BATCH_SIZE = 25;
      let totalSynced = 0;

      for (let i = 0; i < prods.length; i += BATCH_SIZE) {
        const chunk = prods.slice(i, i + BATCH_SIZE);
        const isFirstChunk = (i === 0);

        if (floatBtn) floatBtn.innerHTML = `⏳ Đang gửi SP ${i + 1}-${Math.min(i + BATCH_SIZE, prods.length)}/${prods.length}...`;

        const resp = await fetch('https://dautayshop.nextapp.vn/api/admin/tiktok/sync-from-extension', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-sync-secret': 'dautayshop_sync_secret_2026'
          },
          body: JSON.stringify({
            clean_first: isFirstChunk ? cleanFirst : false,
            products: chunk
          })
        });

        if (!resp.ok) {
          const text = await resp.text();
          throw new Error(`HTTP ${resp.status}: ${text.slice(0, 100)}`);
        }

        const json = await resp.json();
        totalSynced += (json.synced_count || chunk.length);
      }

      if (floatBtn) floatBtn.innerHTML = `✅ Đã đồng bộ ${totalSynced} SP!`;
      setTimeout(updateFloatingButton, 4000);
      alert(`🎉 Thành công! Đã đồng bộ ${totalSynced} sản phẩm và đầy đủ biến thể sang DauTayShop!`);
      return { success: true, synced_count: totalSynced };
    } catch (err) {
      if (floatBtn) floatBtn.innerHTML = `❌ Lỗi đồng bộ`;
      setTimeout(updateFloatingButton, 4000);
      alert(`Lỗi đồng bộ: ${err.message}`);
      throw err;
    }
  }

  // Initial scan if on page
  setTimeout(updateFloatingButton, 1000);
})();
