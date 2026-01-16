const { MenuItem, menuItems } = require('../models/menu');

class MenuService {
  /**
   * Get all menu items
   */
  getAllItems() {
    return menuItems;
  }

  /**
   * Get items by category
   */
  getItemsByCategory(category) {
    return menuItems.filter(item => item.category === category);
  }

  /**
   * Get all categories
   */
  getCategories() {
    const categories = new Set();
    menuItems.forEach(item => categories.add(item.category));
    return Array.from(categories);
  }

  /**
   * Get menu item by ID
   */
  getMenuItemById(id) {
    return menuItems.find(item => item.id === id) || null;
  }

  /**
   * Add new menu item
   */
  addMenuItem(name, category, price, description, icon) {
    const newId = `item_${Date.now()}`;
    const newItem = new MenuItem(newId, name, category, price, description, icon);
    menuItems.push(newItem);
    return newItem;
  }

  /**
   * Update menu item
   */
  updateMenuItem(id, updates) {
    const itemIndex = menuItems.findIndex(item => item.id === id);
    if (itemIndex === -1) return null;

    const item = menuItems[itemIndex];
    const updatedItem = new MenuItem(
      id,
      updates.name || item.name,
      updates.category || item.category,
      updates.price || item.price,
      updates.description || item.description,
      updates.icon || item.icon
    );
    menuItems[itemIndex] = updatedItem;
    return updatedItem;
  }

  /**
   * Delete menu item
   */
  deleteMenuItem(id) {
    const index = menuItems.findIndex(item => item.id === id);
    if (index === -1) return false;
    menuItems.splice(index, 1);
    return true;
  }
}

module.exports = new MenuService();
