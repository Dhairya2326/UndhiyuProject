const express = require('express');
const mongoBillingService = require('../services/mongoBillingService');

const router = express.Router();

/**
 * POST /api/v1/billing/create
 * Create a new bill
 */
router.post('/create', async (req, res) => {
  try {
    const { cartItems, discount = 0, paymentMethod = 'cash', notes = '' } = req.body;

    if (!cartItems || !Array.isArray(cartItems) || cartItems.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Cart items are required and must be a non-empty array',
      });
    }

    const bill = await mongoBillingService.createBill(cartItems, discount, paymentMethod, notes);
    res.status(201).json({
      success: true,
      data: bill,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/all
 * Get all bills
 */
router.get('/all', async (req, res) => {
  try {
    const bills = await mongoBillingService.getAllBills();
    res.json({
      success: true,
      data: bills,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/range/:startDate/:endDate
 * Get bills by date range
 */
router.get('/range/:startDate/:endDate', async (req, res) => {
  try {
    const bills = await mongoBillingService.getBillsByDateRange(
      req.params.startDate,
      req.params.endDate
    );
    res.json({
      success: true,
      data: bills,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/method/:paymentMethod
 * Get bills by payment method
 */
router.get('/method/:paymentMethod', async (req, res) => {
  try {
    const bills = await mongoBillingService.getBillsByPaymentMethod(req.params.paymentMethod);
    res.json({
      success: true,
      data: bills,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/summary/sales
 * Get sales summary
 */
router.get('/summary/sales', async (req, res) => {
  try {
    const summary = await mongoBillingService.getSalesSummary();
    res.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/summary/top-items
 * Get most sold items
 */
router.get('/summary/top-items', async (req, res) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit) : 10;
    const topItems = await mongoBillingService.getMostSoldItems(limit);
    res.json({
      success: true,
      data: topItems,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/summary/daily/:date
 * Get daily sales summary
 */
router.get('/summary/daily/:date', async (req, res) => {
  try {
    const summary = await mongoBillingService.getDailySalesSummary(req.params.date);
    res.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/v1/billing/:id
 * Get bill by ID
 */
router.get('/:id', async (req, res) => {
  try {
    const bill = await mongoBillingService.getBillById(req.params.id);
    if (!bill) {
      return res.status(404).json({
        success: false,
        error: 'Bill not found',
      });
    }
    res.json({
      success: true,
      data: bill,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * PUT /api/v1/billing/:id
 * Update bill
 */
router.put('/:id', async (req, res) => {
  try {
    const updatedBill = await mongoBillingService.updateBill(req.params.id, req.body);
    if (!updatedBill) {
      return res.status(404).json({
        success: false,
        error: 'Bill not found',
      });
    }
    res.json({
      success: true,
      data: updatedBill,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/v1/billing/:id
 * Delete bill
 */
router.delete('/:id', async (req, res) => {
  try {
    const deleted = await mongoBillingService.deleteBill(req.params.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: 'Bill not found',
      });
    }
    res.json({
      success: true,
      message: 'Bill deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
