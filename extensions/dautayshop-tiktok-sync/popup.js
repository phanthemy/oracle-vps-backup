document.addEventListener('DOMContentLoaded', () => {
  const countEl = document.getElementById('productCount');
  const btnSync = document.getElementById('btnSync');
  const btnClear = document.getElementById('btnClear');
  const btnReloadTab = document.getElementById('btnReloadTab');
  const cleanFirstCheck = document.getElementById('cleanFirst');
  const logBox = document.getElementById('logBox');

  function updateCount() {
    chrome.storage.local.get(['tiktok_products_count'], (res) => {
      const count = res.tiktok_products_count || 0;
      countEl.textContent = `${count} sản phẩm`;
      if (count > 0) {
        btnSync.textContent = `⚡ Đồng bộ ${count} SP về DauTayShop`;
      } else {
        btnSync.textContent = `⚡ Đồng bộ về DauTayShop`;
      }
    });
  }
  updateCount();

  function log(msg) {
    logBox.style.display = 'block';
    logBox.innerHTML += `<div>${msg}</div>`;
    logBox.scrollTop = logBox.scrollHeight;
  }

  btnReloadTab.addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      if (tabs[0]) {
        chrome.tabs.reload(tabs[0].id);
        window.close();
      }
    });
  });

  btnSync.addEventListener('click', async () => {
    btnSync.disabled = true;
    btnSync.textContent = '⏳ Đang đồng bộ...';
    log('Đang chuẩn bị danh sách sản phẩm...');

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
            log(`Chưa bắt được dữ liệu. Vui lòng bấm nút 'Tải lại trang TikTok (F5)'!`);
          } else if (resp && resp.success) {
            log(`✅ Hoàn thành: ${resp.synced_count} sản phẩm.`);
          }
        });
        return;
      }

      // Fallback: send directly from storage
      chrome.storage.local.get(['tiktok_products_map'], async (res) => {
        if (!res.tiktok_products_map) {
          alert('Chưa có sản phẩm nào được quét. Vui lòng bấm nút "Tải lại trang TikTok (F5)"!');
          btnSync.disabled = false;
          updateCount();
          return;
        }

        const map = new Map(JSON.parse(res.tiktok_products_map));
        const prods = Array.from(map.values());
        if (prods.length === 0) {
          alert('Danh sách sản phẩm trống. Vui lòng F5 lại trang TikTok!');
          btnSync.disabled = false;
          updateCount();
          return;
        }

        try {
          const BATCH_SIZE = 25;
          let total = 0;

          for (let i = 0; i < prods.length; i += BATCH_SIZE) {
            const chunk = prods.slice(i, i + BATCH_SIZE);
            const isFirst = (i === 0);

            log(`Đang gửi đợt ${i + 1}-${Math.min(i + BATCH_SIZE, prods.length)}/${prods.length} sản phẩm...`);

            const resp = await fetch('https://dautayshop.nextapp.vn/api/admin/tiktok/sync-from-extension', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'x-sync-secret': 'dautayshop_sync_secret_2026'
              },
              body: JSON.stringify({
                clean_first: isFirst ? cleanFirstCheck.checked : false,
                products: chunk
              })
            });

            if (!resp.ok) {
              const text = await resp.text();
              throw new Error(`HTTP ${resp.status}: ${text.slice(0, 100)}`);
            }

            const json = await resp.json();
            total += (json.synced_count || chunk.length);
          }

          log(`✅ Thành công! Đã đồng bộ ${total} sản phẩm.`);
          alert(`🎉 Thành công! Đã đồng bộ ${total} sản phẩm.`);
        } catch (err) {
          log(`❌ Lỗi kết nối: ${err.message}`);
          alert(`Lỗi: ${err.message}`);
        } finally {
          btnSync.disabled = false;
          updateCount();
        }
      });
    });
  });

  if (btnClear) {
    btnClear.addEventListener('click', () => {
      chrome.storage.local.remove(['tiktok_products_map', 'tiktok_products_count'], () => {
        updateCount();
        log('Đã xóa dữ liệu tạm.');
      });
    });
  }
});
