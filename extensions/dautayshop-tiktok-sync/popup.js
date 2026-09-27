document.addEventListener('DOMContentLoaded', () => {
  const countEl = document.getElementById('productCount');
  const btnSync = document.getElementById('btnSync');
  const btnClear = document.getElementById('btnClear');
  const cleanFirstCheck = document.getElementById('cleanFirst');
  const logBox = document.getElementById('logBox');

  function updateCount() {
    chrome.storage.local.get(['tiktok_products_count'], (res) => {
      const count = res.tiktok_products_count || 0;
      countEl.textContent = `${count} sản phẩm`;
    });
  }
  updateCount();

  function log(msg) {
    logBox.style.display = 'block';
    logBox.innerHTML += `<div>${msg}</div>`;
    logBox.scrollTop = logBox.scrollHeight;
  }

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
          btnSync.textContent = '⚡ Đồng bộ về DauTayShop';
          if (chrome.runtime.lastError) {
            log(`Lỗi giao tiếp: Thử bấm trực tiếp nút 🍓 DauTayShop ở góc màn hình TikTok.`);
          } else if (resp && resp.success) {
            log(`✅ Hoàn thành: ${resp.synced_count} sản phẩm.`);
          }
        });
        return;
      }

      // Fallback: send directly from storage
      chrome.storage.local.get(['tiktok_products_map'], async (res) => {
        if (!res.tiktok_products_map) {
          alert('Không tìm thấy sản phẩm nào! Vui lòng mở trang Quản lý sản phẩm trên TikTok Shop.');
          btnSync.disabled = false;
          btnSync.textContent = '⚡ Đồng bộ về DauTayShop';
          return;
        }

        const map = new Map(JSON.parse(res.tiktok_products_map));
        const prods = Array.from(map.values());
        if (prods.length === 0) {
          alert('Danh sách sản phẩm trống.');
          btnSync.disabled = false;
          btnSync.textContent = '⚡ Đồng bộ về DauTayShop';
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
          btnSync.textContent = '⚡ Đồng bộ về DauTayShop';
        }
      });
    });
  });

  btnClear.addEventListener('click', () => {
    chrome.storage.local.remove(['tiktok_products_map', 'tiktok_products_count'], () => {
      updateCount();
      log('Đã xóa dữ liệu tạm đã quét.');
    });
  });
});
