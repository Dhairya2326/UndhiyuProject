const { MenuItem } = require('../models/schemas');
const logger = require('../utils/logger');

class MongoMenuService {
  /**
   * Get all menu items
   */
  async getAllItems() {
    try {
      const items = await MenuItem.find({ available: true });
      return items;
    } catch (error) {
      logger.error('Error fetching menu items:', error.message);
      throw new Error('Failed to fetch menu items');
    }
  }

  /**
   * Get items by category
   */
  async getItemsByCategory(category) {
    try {
      const items = await MenuItem.find({ category, available: true });
      return items;
    } catch (error) {
      logger.error('Error fetching items by category:', error.message);
      throw new Error('Failed to fetch items by category');
    }
  }

  /**
   * Get all categories
   */
  async getCategories() {
    try {
      const categories = await MenuItem.distinct('category', { available: true });
      return categories;
    } catch (error) {
      logger.error('Error fetching categories:', error.message);
      throw new Error('Failed to fetch categories');
    }
  }

  /**
   * Get menu item by ID
   */
  async getMenuItemById(id) {
    try {
      const item = await MenuItem.findOne({ id, available: true });
      return item;
    } catch (error) {
      logger.error('Error fetching menu item:', error.message);
      throw new Error('Failed to fetch menu item');
    }
  }

  /**
   * Add new menu item
   */
  async addMenuItem(name, category, price, description, icon) {
    try {
      const newItem = new MenuItem({
        name,
        category,
        price,
        description,
        icon,
      });
      await newItem.save();
      return newItem;
    } catch (error) {
      logger.error('Error adding menu item:', error.message);
      throw new Error('Failed to add menu item: ' + error.message);
    }
  }

  /**
   * Update menu item
   */
  async updateMenuItem(id, updates) {
    try {
      const item = await MenuItem.findOneAndUpdate(
        { id },
        { ...updates, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      return item;
    } catch (error) {
      logger.error('Error updating menu item:', error.message);
      throw new Error('Failed to update menu item: ' + error.message);
    }
  }

  /**
   * Delete menu item (hard delete)
   */
  async deleteMenuItem(id) {
    try {
      // Hard delete to immediately remove from database
      const result = await MenuItem.findOneAndDelete({ id });
      return result ? true : false;
    } catch (error) {
      logger.error('Error deleting menu item:', error.message);
      throw new Error('Failed to delete menu item');
    }
  }

  /**
   * Get menu item by MongoDB _id
   */
  async getMenuItemByMongoId(mongoId) {
    try {
      const item = await MenuItem.findById(mongoId);
      return item;
    } catch (error) {
      logger.error('Error fetching menu item by mongo id:', error.message);
      throw new Error('Failed to fetch menu item');
    }
  }
}

module.exports = new MongoMenuService();
