// Undhiyu Catering POS System - Web Application Client Logic
const API_BASE = '/api/v1';

// App State
let menuItems = [];
let categories = [];
let cart = []; // { menuItem, quantityInGrams }
let activeCategory = 'All';
let billRecords = [];

// DOM Loaded Initialization
document.addEventListener('DOMContentLoaded', () => {
  initApp();
});

async function initApp() {
  await checkHealth();
  await loadMenuItems();
  await loadCategories();
  renderCategoryChips();
  renderMenuGrid();
  renderCart();
}

// Health Check
async function checkHealth() {
  try {
    const res = await fetch('/health');
    const data = await res.json();
    const badge = document.getElementById('backend-status-badge');
    if (data.success) {
      badge.className = 'status-badge connected';
      badge.innerHTML = '<span class="pulse-dot"></span> Backend Active';
    }
  } catch (err) {
    const badge = document.getElementById('backend-status-badge');
    badge.className = 'status-badge disconnected';
    badge.innerHTML = '⚠️ Offline / Memory Mode';
  }
}

// Navigation Tabs Switcher
function switchTab(tabId) {
  document.querySelectorAll('.nav-tab').forEach(btn => btn.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));

  const btn = document.getElementById(`tab-${tabId}-btn`);
  const content = document.getElementById(`tab-${tabId}`);

  if (btn) btn.classList.add('active');
  if (content) content.classList.add('active');

  if (tabId === 'bills') {
    loadBillHistory();
  } else if (tabId === 'analytics') {
    loadAnalytics();
  } else if (tabId === 'admin') {
    loadAdminMenu();
  }
}

// ==================== MENU & POS LOGIC ====================

async function loadMenuItems() {
  try {
    const res = await fetch(`${API_BASE}/menu`);
    const data = await res.json();
    if (data.success) {
      menuItems = data.data;
    }
  } catch (err) {
    showToast('Failed to load menu items', 'error');
  }
}

async function loadCategories() {
  try {
    const res = await fetch(`${API_BASE}/menu/categories`);
    const data = await res.json();
    if (data.success) {
      categories = ['All', ...data.data];
    } else {
      extractCategoriesFromItems();
    }
  } catch (err) {
    extractCategoriesFromItems();
  }
}

function extractCategoriesFromItems() {
  const set = new Set(['All']);
  menuItems.forEach(i => set.add(i.category));
  categories = Array.from(set);
}

function renderCategoryChips() {
  const container = document.getElementById('category-chips');
  container.innerHTML = categories.map(cat => `
    <button class="chip ${cat === activeCategory ? 'active' : ''}" onclick="selectCategory('${cat}')">
      ${cat}
    </button>
  `).join('');
}

function selectCategory(cat) {
  activeCategory = cat;
  renderCategoryChips();
  filterMenuItems();
}

function filterMenuItems() {
  const query = document.getElementById('menu-search').value.toLowerCase().trim();
  const filtered = menuItems.filter(item => {
    const matchesCat = activeCategory === 'All' || item.category === activeCategory;
    const matchesQuery = item.name.toLowerCase().includes(query) || 
                         (item.description && item.description.toLowerCase().includes(query));
    return matchesCat && matchesQuery;
  });
  renderMenuGrid(filtered);
}

function renderMenuGrid(itemsToRender = null) {
  const items = itemsToRender || menuItems;
  const grid = document.getElementById('menu-grid');

  if (items.length === 0) {
    grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--text-muted);">
      No menu items found. Add items from the <strong>Menu Admin</strong> tab.
    </div>`;
    return;
  }

  grid.innerHTML = items.map(item => {
    const pricePerKg = (item.price * 1000).toFixed(0);
    return `
      <div class="menu-card" onclick="addToCart('${item.id}', 500)">
        <div class="menu-card-top">
          <div class="menu-card-icon">${item.icon || '🍲'}</div>
          <div class="menu-card-info">
            <h3>${item.name}</h3>
            <span class="menu-card-category">${item.category}</span>
          </div>
        </div>
        <p class="menu-card-desc">${item.description || 'Delicious catering item prepared fresh.'}</p>
        <div class="menu-card-footer">
          <div class="price-tag">
            <span class="price-rate">₹${pricePerKg} / kg</span>
            <span class="price-unit">₹${item.price.toFixed(2)} per gram</span>
          </div>
          <button class="btn-add-item" onclick="event.stopPropagation(); addToCart('${item.id}', 500)">
            + Add
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// ==================== CART MANAGEMENT ====================

function addToCart(itemId, defaultGrams = 500) {
  const item = menuItems.find(i => i.id === itemId);
  if (!item) return;

  const existing = cart.find(c => c.menuItem.id === itemId);
  if (existing) {
    existing.quantityInGrams += defaultGrams;
  } else {
    cart.push({ menuItem: item, quantityInGrams: defaultGrams });
  }

  renderCart();
  showToast(`Added ${item.name} (+${defaultGrams}g) to cart!`);
}

function removeFromCart(itemId) {
  cart = cart.filter(c => c.menuItem.id !== itemId);
  renderCart();
}

function updateCartQuantity(itemId, grams) {
  const entry = cart.find(c => c.menuItem.id === itemId);
  if (entry) {
    entry.quantityInGrams = Math.max(10, parseInt(grams) || 0);
    renderCart();
  }
}

function setCartPreset(itemId, grams) {
  const entry = cart.find(c => c.menuItem.id === itemId);
  if (entry) {
    entry.quantityInGrams = grams;
    renderCart();
  }
}

function clearCart() {
  cart = [];
  document.getElementById('cart-discount').value = 0;
  document.getElementById('cart-notes').value = '';
  renderCart();
}

function calculateCartTotals() {
  let subtotal = 0;
  cart.forEach(entry => {
    subtotal += entry.quantityInGrams * entry.menuItem.price;
  });

  const discountVal = parseFloat(document.getElementById('cart-discount').value) || 0;
  const grandTotal = Math.max(0, subtotal - discountVal);

  return { subtotal, discount: discountVal, grandTotal };
}

function updateCartTotal() {
  const { subtotal, discount, grandTotal } = calculateCartTotals();
  document.getElementById('cart-subtotal').innerText = `₹${subtotal.toFixed(2)}`;
  document.getElementById('cart-grand-total').innerText = `₹${grandTotal.toFixed(2)}`;
}

function renderCart() {
  const container = document.getElementById('cart-items-container');

  if (cart.length === 0) {
    container.innerHTML = `
      <div class="empty-cart-state">
        <span class="empty-icon">🛍️</span>
        <p>Your cart is empty</p>
        <span class="empty-sub">Click items on the left to add to cart</span>
      </div>
    `;
    updateCartTotal();
    return;
  }

  container.innerHTML = cart.map(entry => {
    const item = entry.menuItem;
    const itemTotal = (entry.quantityInGrams * item.price).toFixed(2);
    const q = entry.quantityInGrams;

    return `
      <div class="cart-item-row">
        <div class="cart-item-main">
          <span class="cart-item-title">${item.icon || '🍲'} ${item.name}</span>
          <span class="cart-item-price">₹${itemTotal}</span>
        </div>
        <div class="cart-item-controls">
          <div class="presets">
            <button class="qty-preset-btn ${q === 250 ? 'active' : ''}" onclick="setCartPreset('${item.id}', 250)">250g</button>
            <button class="qty-preset-btn ${q === 500 ? 'active' : ''}" onclick="setCartPreset('${item.id}', 500)">500g</button>
            <button class="qty-preset-btn ${q === 1000 ? 'active' : ''}" onclick="setCartPreset('${item.id}', 1000)">1kg</button>
          </div>
          <div class="qty-input-group">
            <input type="number" value="${q}" step="50" min="10" onchange="updateCartQuantity('${item.id}', this.value)">
            <span>g</span>
            <button class="btn-remove-item" onclick="removeFromCart('${item.id}')">❌</button>
          </div>
        </div>
      </div>
    `;
  }).join('');

  updateCartTotal();
}

function onPaymentMethodChange() {
  // Can trigger additional payment specific UI if needed
}

// ==================== CHECKOUT & BILL CREATION ====================

async function checkoutBill() {
  if (cart.length === 0) {
    showToast('Cannot checkout empty cart!', 'error');
    return;
  }

  const { subtotal, discount, grandTotal } = calculateCartTotals();
  const paymentMethod = document.querySelector('input[name="paymentMethod"]:checked').value;
  const notes = document.getElementById('cart-notes').value;

  const payload = {
    cartItems: cart.map(item => ({
      menuItem: {
        id: item.menuItem.id,
        name: item.menuItem.name,
        category: item.menuItem.category,
        price: item.menuItem.price,
        icon: item.menuItem.icon || '🍲'
      },
      quantityInGrams: item.quantityInGrams
    })),
    discount,
    paymentMethod,
    notes
  };

  try {
    const res = await fetch(`${API_BASE}/billing/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const result = await res.json();
    if (result.success) {
      showToast('Order completed successfully!', 'success');
      showReceiptModal(result.data);
      clearCart();
    } else {
      showToast(result.error || 'Failed to create bill', 'error');
    }
  } catch (err) {
    showToast('Error connecting to backend server', 'error');
  }
}

// Receipt Modal Handler
function showReceiptModal(billRecord) {
  document.getElementById('rec-id').innerText = `#${billRecord.id || billRecord._id || '01'}`;
  document.getElementById('rec-date').innerText = new Date(billRecord.timestamp || Date.now()).toLocaleString();
  document.getElementById('rec-payment').innerText = (billRecord.paymentMethod || 'CASH').toUpperCase();
  document.getElementById('rec-subtotal').innerText = `₹${(billRecord.subtotal || 0).toFixed(2)}`;
  document.getElementById('rec-discount').innerText = `-₹${(billRecord.discount || 0).toFixed(2)}`;
  document.getElementById('rec-total').innerText = `₹${(billRecord.totalAmount || 0).toFixed(2)}`;

  const tbody = document.getElementById('rec-items-tbody');
  tbody.innerHTML = (billRecord.items || []).map(item => {
    const qtyStr = item.quantityInGrams >= 1000 
      ? `${(item.quantityInGrams / 1000).toFixed(2)}kg` 
      : `${item.quantityInGrams}g`;
    const rateStr = `₹${(item.pricePerGram * 1000).toFixed(0)}/kg`;
    return `
      <tr>
        <td>${item.itemName}</td>
        <td>${qtyStr}</td>
        <td>${rateStr}</td>
        <td>₹${item.totalPrice.toFixed(2)}</td>
      </tr>
    `;
  }).join('');

  document.getElementById('receipt-modal').classList.add('active');
}

function closeReceiptModal() {
  document.getElementById('receipt-modal').classList.remove('active');
}

function printReceipt() {
  window.print();
}

// ==================== BILL HISTORY LOGIC ====================

async function loadBillHistory() {
  try {
    const res = await fetch(`${API_BASE}/billing/all`);
    const data = await res.json();
    if (data.success) {
      billRecords = data.data;
      renderBillsTable(billRecords);
    }
  } catch (err) {
    showToast('Failed to load bill records', 'error');
  }
}

function filterBills() {
  const query = document.getElementById('bill-search').value.toLowerCase().trim();
  const filtered = billRecords.filter(bill => {
    const matchId = String(bill.id).toLowerCase().includes(query);
    const matchMethod = String(bill.paymentMethod).toLowerCase().includes(query);
    const matchItem = bill.items && bill.items.some(i => i.itemName.toLowerCase().includes(query));
    return matchId || matchMethod || matchItem;
  });
  renderBillsTable(filtered);
}

function renderBillsTable(bills) {
  const tbody = document.getElementById('bills-tbody');
  if (!bills || bills.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align: center; color: var(--text-muted); padding: 30px;">No bill records found</td></tr>`;
    return;
  }

  tbody.innerHTML = bills.map(bill => {
    const itemsSummary = (bill.items || []).map(i => `${i.itemName} (${i.quantityInGrams}g)`).join(', ');
    const dateStr = new Date(bill.timestamp).toLocaleString();
    return `
      <tr>
        <td><strong>#${bill.id}</strong></td>
        <td>${dateStr}</td>
        <td style="max-width: 280px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${itemsSummary}</td>
        <td>₹${bill.subtotal.toFixed(2)}</td>
        <td>₹${bill.discount.toFixed(2)}</td>
        <td><strong style="color: var(--accent-primary);">₹${bill.totalAmount.toFixed(2)}</strong></td>
        <td><span class="chip" style="font-size:0.75rem;">${bill.paymentMethod.toUpperCase()}</span></td>
        <td>
          <button class="btn-secondary" style="padding: 4px 8px; font-size:0.8rem;" onclick='viewBillDetail(${JSON.stringify(bill).replace(/'/g, "&apos;")})'>📜 Receipt</button>
        </td>
      </tr>
    `;
  }).join('');
}

function viewBillDetail(bill) {
  showReceiptModal(bill);
}

// ==================== SALES ANALYTICS LOGIC ====================

async function loadAnalytics() {
  try {
    const resSummary = await fetch(`${API_BASE}/billing/summary/sales`);
    const summaryData = await resSummary.json();

    if (summaryData.success) {
      const data = summaryData.data;
      document.getElementById('stat-total-revenue').innerText = `₹${(data.totalRevenue || 0).toFixed(2)}`;
      document.getElementById('stat-total-bills').innerText = data.totalBills || 0;
      document.getElementById('stat-avg-order').innerText = `₹${(data.averageOrderValue || 0).toFixed(2)}`;
      document.getElementById('stat-total-discount').innerText = `₹${(data.totalDiscount || 0).toFixed(2)}`;

      renderPaymentBreakdown(data.paymentMethodBreakdown || {});
    }

    const resTop = await fetch(`${API_BASE}/billing/summary/top-items?limit=5`);
    const topData = await resTop.json();

    if (topData.success) {
      renderTopItems(topData.data || []);
    }

  } catch (err) {
    showToast('Failed to load analytics data', 'error');
  }
}

function renderTopItems(items) {
  const container = document.getElementById('top-items-list');
  if (items.length === 0) {
    container.innerHTML = '<p style="color: var(--text-muted);">No sales data available yet</p>';
    return;
  }

  container.innerHTML = items.map((item, idx) => `
    <div class="top-item-row">
      <div style="display:flex; align-items:center; gap: 10px;">
        <span style="font-weight:700; color:var(--accent-primary);">#${idx + 1}</span>
        <span>${item.icon || '🍲'} ${item.name}</span>
      </div>
      <div>
        <strong style="color: #fff;">${(item.quantitySold / 1000).toFixed(1)} kg</strong>
        <span style="color: var(--text-muted); font-size: 0.8rem; margin-left: 8px;">(₹${item.revenue.toFixed(0)})</span>
      </div>
    </div>
  `).join('');
}

function renderPaymentBreakdown(breakdown) {
  const container = document.getElementById('payment-breakdown-list');
  const keys = Object.keys(breakdown);

  if (keys.length === 0) {
    container.innerHTML = '<p style="color: var(--text-muted);">No transaction data available yet</p>';
    return;
  }

  container.innerHTML = keys.map(key => `
    <div class="payment-item-row">
      <span style="text-transform: capitalize; font-weight: 600;">💳 ${key}</span>
      <strong style="color: var(--success);">₹${breakdown[key].toFixed(2)}</strong>
    </div>
  `).join('');
}

// ==================== ADMIN MENU LOGIC ====================

function loadAdminMenu() {
  const tbody = document.getElementById('admin-menu-tbody');
  if (menuItems.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:var(--text-muted);">No menu items found</td></tr>`;
    return;
  }

  tbody.innerHTML = menuItems.map(item => {
    const pricePerKg = (item.price * 1000).toFixed(0);
    return `
      <tr>
        <td><strong>${item.icon || '🍲'} ${item.name}</strong></td>
        <td><span class="chip" style="font-size:0.75rem;">${item.category}</span></td>
        <td>₹${item.price.toFixed(2)} / g</td>
        <td>₹${pricePerKg} / kg</td>
        <td>${item.stockQuantity !== undefined ? item.stockQuantity + 'g' : 'Unlimited'}</td>
        <td>
          <button class="btn-danger-sm" onclick="deleteMenuItem('${item.id}')">Delete</button>
        </td>
      </tr>
    `;
  }).join('');
}

async function handleCreateMenuItem(e) {
  e.preventDefault();
  const name = document.getElementById('item-name').value;
  const category = document.getElementById('item-category').value;
  const price = parseFloat(document.getElementById('item-price').value);
  const icon = document.getElementById('item-icon').value || '🍲';
  const description = document.getElementById('item-description').value;

  try {
    const res = await fetch(`${API_BASE}/menu`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, category, price, icon, description })
    });
    const result = await res.json();
    if (result.success) {
      showToast(`Created menu item: ${name}`, 'success');
      document.getElementById('add-item-form').reset();
      await loadMenuItems();
      await loadCategories();
      renderCategoryChips();
      renderMenuGrid();
      loadAdminMenu();
    } else {
      showToast(result.error || 'Failed to create menu item', 'error');
    }
  } catch (err) {
    showToast('Failed to connect to backend', 'error');
  }
}

async function deleteMenuItem(id) {
  if (!confirm('Are you sure you want to delete this menu item?')) return;

  try {
    const res = await fetch(`${API_BASE}/menu/${id}`, { method: 'DELETE' });
    const result = await res.json();
    if (result.success) {
      showToast('Menu item deleted successfully');
      await loadMenuItems();
      renderMenuGrid();
      loadAdminMenu();
    } else {
      showToast(result.error || 'Failed to delete item', 'error');
    }
  } catch (err) {
    showToast('Failed to connect to backend', 'error');
  }
}

// ==================== TOAST NOTIFICATIONS ====================

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${type === 'success' ? '✅' : type === 'error' ? '❌' : 'ℹ️'}</span> ${message}`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'fadeOut 0.3s forwards';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}
