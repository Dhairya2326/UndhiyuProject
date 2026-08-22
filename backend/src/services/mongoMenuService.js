const mongoose = require('mongoose');
const { MenuItem } = require('../models/schemas');
const menuService = require('./menuService');
const logger = require('../utils/logger');

class MongoMenuService {
  /**
   * Get all menu items
   */
  async getAllItems() {
    try {
      if (mongoose.connection.readyState !== 1) {
        const items = menuService.getAllItems();
        return items.map(item => item.toJSON ? item.toJSON() : item);
      }
      const items = await MenuItem.find({ available: true });
      return items;
    } catch (error) {
      logger.error('Error fetching menu items:', error.message);
      const items = menuService.getAllItems();
      return items.map(item => item.toJSON ? item.toJSON() : item);
    }
  }

  /**
   * Get items by category
   */
  async getItemsByCategory(category) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const items = menuService.getItemsByCategory(category);
        return items.map(item => item.toJSON ? item.toJSON() : item);
      }
      const items = await MenuItem.find({ category, available: true });
      return items;
    } catch (error) {
      logger.error('Error fetching items by category:', error.message);
      const items = menuService.getItemsByCategory(category);
      return items.map(item => item.toJSON ? item.toJSON() : item);
    }
  }

  /**
   * Get all categories
   */
  async getCategories() {
    try {
      if (mongoose.connection.readyState !== 1) {
        return menuService.getCategories();
      }
      const categories = await MenuItem.distinct('category', { available: true });
      return categories;
    } catch (error) {
      logger.error('Error fetching categories:', error.message);
      return menuService.getCategories();
    }
  }

  /**
   * Get menu item by ID
   */
  async getMenuItemById(id) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const item = menuService.getMenuItemById(id);
        return item && item.toJSON ? item.toJSON() : item;
      }
      const item = await MenuItem.findOne({ id, available: true });
      return item;
    } catch (error) {
      logger.error('Error fetching menu item:', error.message);
      const item = menuService.getMenuItemById(id);
      return item && item.toJSON ? item.toJSON() : item;
    }
  }

  /**
   * Add new menu item
   */
  async addMenuItem(name, category, price, description, icon, imageUrl = '') {
    try {
      if (mongoose.connection.readyState !== 1) {
        const item = menuService.addMenuItem(name, category, price, description, icon);
        if (imageUrl) item.imageUrl = imageUrl;
        return item.toJSON ? item.toJSON() : item;
      }
      const newItem = new MenuItem({
        name,
        category,
        price,
        description,
        icon,
        imageUrl,
      });
      await newItem.save();
      return newItem;
    } catch (error) {
      logger.error('Error adding menu item:', error.message);
      const item = menuService.addMenuItem(name, category, price, description, icon);
      if (imageUrl) item.imageUrl = imageUrl;
      return item.toJSON ? item.toJSON() : item;
    }
  }

  /**
   * Update menu item
   */
  async updateMenuItem(id, updates) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const item = menuService.updateMenuItem(id, updates);
        return item && item.toJSON ? item.toJSON() : item;
      }
      const item = await MenuItem.findOneAndUpdate(
        { id },
        { ...updates, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      return item;
    } catch (error) {
      logger.error('Error updating menu item:', error.message);
      const item = menuService.updateMenuItem(id, updates);
      return item && item.toJSON ? item.toJSON() : item;
    }
  }

  /**
   * Delete menu item (hard delete)
   */
  async deleteMenuItem(id) {
    try {
      if (mongoose.connection.readyState !== 1) {
        return menuService.deleteMenuItem(id);
      }
      const result = await MenuItem.findOneAndDelete({ id });
      return result ? true : false;
    } catch (error) {
      logger.error('Error deleting menu item:', error.message);
      return menuService.deleteMenuItem(id);
    }
  }

  /**
   * Get menu item by MongoDB _id
   */
  async getMenuItemByMongoId(mongoId) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const item = menuService.getMenuItemById(mongoId);
        return item && item.toJSON ? item.toJSON() : item;
      }
      const item = await MenuItem.findById(mongoId);
      return item;
    } catch (error) {
      logger.error('Error fetching menu item by mongo id:', error.message);
      const item = menuService.getMenuItemById(mongoId);
      return item && item.toJSON ? item.toJSON() : item;
    }
  }
}

module.exports = new MongoMenuService();
