const express = require('express');
const menuService = require('../services/menuService');

const router = express.Router();

/**
 * GET /api/menu
 * Get all menu items
 */
router.get('/', (req, res) => {
  try {
    const items = menuService.getAllItems();
    res.json({
      success: true,
      data: items.map(item => item.toJSON()),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/menu/categories
 * Get all categories
 */
router.get('/categories', (req, res) => {
  try {
    const categories = menuService.getCategories();
    res.json({
      success: true,
      data: categories,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/menu/category/:category
 * Get items by category
 */
router.get('/category/:category', (req, res) => {
  try {
    const items = menuService.getItemsByCategory(req.params.category);
    res.json({
      success: true,
      data: items.map(item => item.toJSON()),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/menu/:id
 * Get menu item by ID
 */
router.get('/:id', (req, res) => {
  try {
    const item = menuService.getMenuItemById(req.params.id);
    if (!item) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    res.json({
      success: true,
      data: item.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/menu
 * Add new menu item
 */
router.post('/', (req, res) => {
  try {
    const { name, category, price, description, icon } = req.body;

    if (!name || !category || !price) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, category, price',
      });
    }

    const newItem = menuService.addMenuItem(name, category, price, description || '', icon || '🍽️');
    res.status(201).json({
      success: true,
      data: newItem.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * PUT /api/menu/:id
 * Update menu item
 */
router.put('/:id', (req, res) => {
  try {
    const updatedItem = menuService.updateMenuItem(req.params.id, req.body);
    if (!updatedItem) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    res.json({
      success: true,
      data: updatedItem.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/menu/:id
 * Delete menu item
 */
router.delete('/:id', (req, res) => {
  try {
    const deleted = menuService.deleteMenuItem(req.params.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: 'Menu item not found',
      });
    }
    res.json({
      success: true,
      message: 'Menu item deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
