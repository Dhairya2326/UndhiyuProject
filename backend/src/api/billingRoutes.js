const express = require('express');
const billingService = require('../services/billingService');

const router = express.Router();

/**
 * POST /api/billing/create
 * Create a new bill
 */
router.post('/create', (req, res) => {
  try {
    const { cartItems, discount = 0, paymentMethod = 'cash', notes = '' } = req.body;

    if (!cartItems || !Array.isArray(cartItems) || cartItems.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Cart items are required and must be a non-empty array',
      });
    }

    const bill = billingService.createBill(cartItems, discount, paymentMethod, notes);
    res.status(201).json({
      success: true,
      data: bill.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/billing/all
 * Get all bills
 */
router.get('/all', (req, res) => {
  try {
    const bills = billingService.getAllBills();
    res.json({
      success: true,
      data: bills.map(bill => bill.toJSON()),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/billing/:id
 * Get bill by ID
 */
router.get('/:id', (req, res) => {
  try {
    const bill = billingService.getBillById(req.params.id);
    if (!bill) {
      return res.status(404).json({
        success: false,
        error: 'Bill not found',
      });
    }
    res.json({
      success: true,
      data: bill.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/billing/range/:startDate/:endDate
 * Get bills by date range
 */
router.get('/range/:startDate/:endDate', (req, res) => {
  try {
    const bills = billingService.getBillsByDateRange(req.params.startDate, req.params.endDate);
    res.json({
      success: true,
      data: bills.map(bill => bill.toJSON()),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/billing/method/:paymentMethod
 * Get bills by payment method
 */
router.get('/method/:paymentMethod', (req, res) => {
  try {
    const bills = billingService.getBillsByPaymentMethod(req.params.paymentMethod);
    res.json({
      success: true,
      data: bills.map(bill => bill.toJSON()),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/billing/summary/sales
 * Get sales summary
 */
router.get('/summary/sales', (req, res) => {
  try {
    const summary = billingService.getSalesSummary();
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
 * GET /api/billing/summary/top-items
 * Get most sold items
 */
router.get('/summary/top-items', (req, res) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit) : 10;
    const topItems = billingService.getMostSoldItems(limit);
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
 * PUT /api/billing/:id
 * Update bill
 */
router.put('/:id', (req, res) => {
  try {
    const updatedBill = billingService.updateBill(req.params.id, req.body);
    if (!updatedBill) {
      return res.status(404).json({
        success: false,
        error: 'Bill not found',
      });
    }
    res.json({
      success: true,
      data: updatedBill.toJSON(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * DELETE /api/billing/:id
 * Delete bill
 */
router.delete('/:id', (req, res) => {
  try {
    const deleted = billingService.deleteBill(req.params.id);
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
