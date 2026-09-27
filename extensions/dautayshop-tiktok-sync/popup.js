document.addEventListener('DOMContentLoaded', () => {
  const countEl = document.getElementById('productCount');
  const btnSync = document.getElementById('btnSync');
  const btnReloadTab = document.getElementById('btnReloadTab');
  const btnCopyJson = document.getElementById('btnCopyJson');
  const cleanFirstCheck = document.getElementById('cleanFirst');
  const debugBox = document.getElementById('debugBox');

  function updateCount() {
    chrome.storage.local.get(['tiktok_products_count', 'tiktok_products_map'], (res) => {
      const count = res.tiktok_products_count || 0;
      countEl.textContent = `${count} sản phẩm`;
      if (count > 0) {
        btnSync.textContent = `⚡ Đồng bộ ${count} SP về DauTayShop`;
        if (res.tiktok_products_map) {
          try {
            const map = new Map(JSON.parse(res.tiktok_products_map));
            const first = Array.from(map.values())[0];
            if (first) {
              debugBox.style.display = 'block';
              debugBox.textContent = `Trường SP: ` + Object.keys(first).join(', ');
            }
          } catch (e) {}
        }
      } else {
        btnSync.textContent = `⚡ Đồng bộ về DauTayShop`;
      }
    });
  }
  updateCount();

  btnReloadTab.addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      if (tabs[0]) {
        chrome.tabs.reload(tabs[0].id);
        window.close();
      }
    });
  });

  btnCopyJson.addEventListener('click', () => {
    chrome.storage.local.get(['tiktok_products_map'], (res) => {
      if (!res.tiktok_products_map) {
        alert('Chưa có sản phẩm nào!');
        return;
      }
      try {
        const map = new Map(JSON.parse(res.tiktok_products_map));
        const first = Array.from(map.values())[0];
        if (first) {
          navigator.clipboard.writeText(JSON.stringify(first, null, 2)).then(() => {
            alert('Đã copy JSON của 1 sản phẩm vào bộ nhớ tạm! Bạn chỉ việc Ctrl+V dán vào khung chat.');
          });
        }
      } catch (e) {
        alert(e.message);
      }
    });
  });

  btnSync.addEventListener('click', async () => {
    btnSync.disabled = true;
    btnSync.textContent = '⏳ Đang đồng bộ...';

    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      const activeTab = tabs[0];
      if (activeTab && activeTab.url.includes('seller-vn.tiktok.com')) {
        chrome.tabs.sendMessage(activeTab.id, { 
          action: 'SYNC_NOW',
          clean_first: cleanFirstCheck.checked 
        }, (resp) => {
          btnSync.disabled = false;
          updateCount();
          if (chrome.runtime.lastError) {
            alert('Vui lòng bấm Tải lại trang TikTok (F5) rồi thử lại!');
          } else if (resp && resp.success) {
            alert(`🎉 Hoàn thành! Đã đồng bộ ${resp.synced_count} sản phẩm sang DauTayShop.`);
          }
        });
        return;
      }

      // Fallback
      chrome.storage.local.get(['tiktok_products_map'], async (res) => {
        if (!res.tiktok_products_map) {
          alert('Chưa có sản phẩm nào!');
          btnSync.disabled = false;
          return;
        }

        const map = new Map(JSON.parse(res.tiktok_products_map));
        const prods = Array.from(map.values());
        try {
          const resp = await fetch('https://dautayshop.nextapp.vn/api/admin/tiktok/sync-from-extension', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-sync-secret': 'dautayshop_sync_secret_2026'
            },
            body: JSON.stringify({
              clean_first: cleanFirstCheck.checked,
              products: prods
            })
          });
          const json = await resp.json();
          alert(`🎉 Hoàn thành! Đã đồng bộ ${json.synced_count} sản phẩm sang DauTayShop.`);
        } catch (err) {
          alert(`Lỗi: ${err.message}`);
        } finally {
          btnSync.disabled = false;
          updateCount();
        }
      });
    });
  });
});
