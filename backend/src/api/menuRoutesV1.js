const express = require('express');
const mongoMenuService = require('../services/mongoMenuService');
const logger = require('../utils/logger');

const router = express.Router();

/**
 * GET /api/v1/menu
 * Get all menu items
 */
router.get('/', async (req, res) => {
  try {
    logger.info('📋 Menu: Fetching all menu items');
    const items = await mongoMenuService.getAllItems();
    logger.info(`✅ Menu: Retrieved ${items.length} items`);
    res.json({
      success: true,
      data: items,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to fetch items - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/menu/categories
 * Get all categories
 * NOTE: This route MUST come before /:id to prevent 'categories' being treated as an ID
 */
router.get('/categories', async (req, res) => {
  try {
    logger.info('📋 Menu: Fetching all categories');
    const categories = await mongoMenuService.getCategories();
    logger.info(`✅ Menu: Retrieved ${categories.length} categories: ${categories.join(', ')}`);
    res.json({
      success: true,
      data: categories,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to fetch categories - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/menu/category/:category
 * Get items by category
 * NOTE: This route MUST come before /:id to prevent 'category' being treated as an ID
 */
router.get('/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    logger.info(`📋 Menu: Fetching items for category: ${category}`);
    const items = await mongoMenuService.getItemsByCategory(category);
    logger.info(`✅ Menu: Retrieved ${items.length} items in category "${category}"`);
    res.json({
      success: true,
      data: items,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to fetch items by category - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/menu/:id
 * Get menu item by ID
 * NOTE: This parameterized route comes AFTER specific routes to prevent conflicts
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    logger.info(`📋 Menu: Fetching item with ID: ${id}`);
    const item = await mongoMenuService.getMenuItemById(id);
    if (!item) {
      logger.warn(`⚠️ Menu: Item not found - ID: ${id}`);
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    logger.info(`✅ Menu: Retrieved item "${item.name}" (ID: ${id})`);
    res.json({
      success: true,
      data: item,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to fetch item - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/v1/menu
 * Add new menu item
 */
router.post('/', async (req, res) => {
  try {
    const { name, category, price, description, icon } = req.body;

    logger.info(`🆕 Menu: Creating new item - Name: ${name}, Category: ${category}, Price: ${price}`);

    if (!name || !category || !price) {
      logger.warn(`⚠️ Menu: Missing required fields - Name: ${name}, Category: ${category}, Price: ${price}`);
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, category, price',
      });
    }

    const newItem = await mongoMenuService.addMenuItem(
      name,
      category,
      price,
      description || '',
      icon || '🍽️'
    );

    logger.info(`✅ Menu: Item created successfully - ID: ${newItem.id}, Name: ${newItem.name}`);

    res.status(201).json({
      success: true,
      data: newItem,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to create item - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * PUT /api/v1/menu/:id
 * Update menu item
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    logger.info(`✏️ Menu: Updating item - ID: ${id}, Updates: ${JSON.stringify(req.body)}`);

    const updatedItem = await mongoMenuService.updateMenuItem(id, req.body);
    if (!updatedItem) {
      logger.warn(`⚠️ Menu: Item not found for update - ID: ${id}`);
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    logger.info(`✅ Menu: Item updated successfully - ID: ${id}, Name: ${updatedItem.name}`);
    res.json({
      success: true,
      data: updatedItem,
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to update item - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/v1/menu/:id
 * Delete menu item
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    logger.info(`🗑️ Menu: Deleting item - ID: ${id}`);

    const deleted = await mongoMenuService.deleteMenuItem(id);
    if (!deleted) {
      logger.warn(`⚠️ Menu: Item not found for deletion - ID: ${id}`);
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    logger.info(`✅ Menu: Item deleted successfully - ID: ${id}`);
    res.json({
      success: true,
      message: 'Menu item deleted successfully',
    });
  } catch (error) {
    logger.error(`❌ Menu: Failed to delete item - ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
