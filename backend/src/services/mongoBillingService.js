const mongoose = require('mongoose');
const { BillRecord, BillItem, MenuItem } = require('../models/schemas');
const billingService = require('./billingService');
const logger = require('../utils/logger');

class MongoBillingService {
  /**
   * Create a new bill
   */
  async createBill(cartItems, discount = 0, paymentMethod = 'cash', notes = '') {
    try {
      if (mongoose.connection.readyState !== 1) {
        const bill = billingService.createBill(cartItems, discount, paymentMethod, notes);
        return bill.toJSON ? bill.toJSON() : bill;
      }

      // Validate empty cart
      if (!cartItems || cartItems.length === 0) {
        throw new Error('Cart is empty');
      }

      // 1. Validate Stock first (to prevent partial updates if one fails)
      for (const cartItem of cartItems) {
        const menuItemId = cartItem.menuItem.id;
        const quantityInGrams = cartItem.quantityInGrams;

        const itemDoc = await MenuItem.findOne({ id: menuItemId });
        if (!itemDoc) {
          throw new Error(`Item not found: ${cartItem.menuItem.name}`);
        }

        if (itemDoc.stockQuantity !== undefined && itemDoc.stockQuantity < quantityInGrams) {
          throw new Error(`Insufficient stock for ${itemDoc.name}. Available: ${itemDoc.stockQuantity}g, Requested: ${quantityInGrams}g`);
        }
      }

      // 2. Deduct Stock and Prepare Bill Items
      const billItems = [];
      for (const cartItem of cartItems) {
        const menuItemId = cartItem.menuItem.id;
        const quantityInGrams = cartItem.quantityInGrams;

        // Deduct stock
        await MenuItem.findOneAndUpdate(
          { id: menuItemId },
          { $inc: { stockQuantity: -quantityInGrams } }
        );

        const menuItem = cartItem.menuItem;
        const pricePerGram = menuItem.price;
        const totalPrice = quantityInGrams * pricePerGram;

        billItems.push({
          itemName: menuItem.name,
          icon: menuItem.icon,
          quantityInGrams,
          pricePerGram,
          totalPrice,
        });
      }

      // Calculate subtotal and total
      const subtotal = billItems.reduce((sum, item) => sum + item.totalPrice, 0);
      const totalAmount = subtotal - discount;

      // Create and save bill
      const bill = new BillRecord({
        items: billItems,
        subtotal,
        discount,
        totalAmount,
        paymentMethod,
        notes,
      });

      await bill.save();
      logger.info(`Bill created: ${bill.id}`);
      return bill;
    } catch (error) {
      logger.error('Error creating bill:', error.message);
      const bill = billingService.createBill(cartItems, discount, paymentMethod, notes);
      return bill.toJSON ? bill.toJSON() : bill;
    }
  }

  /**
   * Get all bills
   */
  async getAllBills() {
    try {
      if (mongoose.connection.readyState !== 1) {
        const bills = billingService.getAllBills();
        return bills.map(b => b.toJSON ? b.toJSON() : b);
      }
      const bills = await BillRecord.find().sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills:', error.message);
      const bills = billingService.getAllBills();
      return bills.map(b => b.toJSON ? b.toJSON() : b);
    }
  }

  /**
   * Get bill by ID
   */
  async getBillById(billId) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const bill = billingService.getBillById(billId);
        return bill && bill.toJSON ? bill.toJSON() : bill;
      }
      const bill = await BillRecord.findOne({ id: billId });
      return bill;
    } catch (error) {
      logger.error('Error fetching bill:', error.message);
      const bill = billingService.getBillById(billId);
      return bill && bill.toJSON ? bill.toJSON() : bill;
    }
  }

  /**
   * Get bills by date range
   */
  async getBillsByDateRange(startDate, endDate) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const bills = billingService.getBillsByDateRange(startDate, endDate);
        return bills.map(b => b.toJSON ? b.toJSON() : b);
      }
      const bills = await BillRecord.find({
        timestamp: {
          $gte: new Date(startDate),
          $lte: new Date(endDate),
        },
      }).sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills by date range:', error.message);
      const bills = billingService.getBillsByDateRange(startDate, endDate);
      return bills.map(b => b.toJSON ? b.toJSON() : b);
    }
  }

  /**
   * Get bills by payment method
   */
  async getBillsByPaymentMethod(paymentMethod) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const bills = billingService.getBillsByPaymentMethod(paymentMethod);
        return bills.map(b => b.toJSON ? b.toJSON() : b);
      }
      const bills = await BillRecord.find({ paymentMethod }).sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills by payment method:', error.message);
      const bills = billingService.getBillsByPaymentMethod(paymentMethod);
      return bills.map(b => b.toJSON ? b.toJSON() : b);
    }
  }

  /**
   * Get sales summary
   */
  async getSalesSummary() {
    try {
      if (mongoose.connection.readyState !== 1) {
        return billingService.getSalesSummary();
      }
      const totalBills = await BillRecord.countDocuments();

      const result = await BillRecord.aggregate([
        {
          $group: {
            _id: null,
            totalRevenue: { $sum: '$totalAmount' },
            totalDiscount: { $sum: '$discount' },
          },
        },
      ]);

      const { totalRevenue = 0, totalDiscount = 0 } = result[0] || {};
      const averageOrderValue = totalBills > 0 ? totalRevenue / totalBills : 0;

      // Payment method breakdown
      const paymentBreakdown = await BillRecord.aggregate([
        {
          $group: {
            _id: '$paymentMethod',
            amount: { $sum: '$totalAmount' },
          },
        },
      ]);

      const paymentMethodBreakdown = {};
      paymentBreakdown.forEach(item => {
        paymentMethodBreakdown[item._id] = item.amount;
      });

      return {
        totalBills,
        totalRevenue,
        totalDiscount,
        averageOrderValue,
        paymentMethodBreakdown,
      };
    } catch (error) {
      logger.error('Error fetching sales summary:', error.message);
      return billingService.getSalesSummary();
    }
  }

  /**
   * Get most sold items
   */
  async getMostSoldItems(limit = 10) {
    try {
      if (mongoose.connection.readyState !== 1) {
        return billingService.getMostSoldItems(limit);
      }
      const items = await BillRecord.aggregate([
        { $unwind: '$items' },
        {
          $group: {
            _id: '$items.itemName',
            name: { $first: '$items.itemName' },
            icon: { $first: '$items.icon' },
            quantitySold: { $sum: '$items.quantityInGrams' },
            revenue: { $sum: '$items.totalPrice' },
          },
        },
        { $sort: { quantitySold: -1 } },
        { $limit: limit },
      ]);

      return items;
    } catch (error) {
      logger.error('Error fetching most sold items:', error.message);
      return billingService.getMostSoldItems(limit);
    }
  }

  /**
   * Update bill
   */
  async updateBill(billId, updates) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const updated = billingService.updateBill(billId, updates);
        return updated && updated.toJSON ? updated.toJSON() : updated;
      }
      const bill = await BillRecord.findOneAndUpdate(
        { id: billId },
        { ...updates, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      return bill;
    } catch (error) {
      logger.error('Error updating bill:', error.message);
      const updated = billingService.updateBill(billId, updates);
      return updated && updated.toJSON ? updated.toJSON() : updated;
    }
  }

  /**
   * Delete bill
   */
  async deleteBill(billId) {
    try {
      if (mongoose.connection.readyState !== 1) {
        return billingService.deleteBill(billId);
      }
      const result = await BillRecord.findOneAndDelete({ id: billId });
      return result ? true : false;
    } catch (error) {
      logger.error('Error deleting bill:', error.message);
      return billingService.deleteBill(billId);
    }
  }

  /**
   * Get daily sales summary
   */
  async getDailySalesSummary(date) {
    try {
      if (mongoose.connection.readyState !== 1) {
        const summary = billingService.getSalesSummary();
        return {
          totalBills: summary.totalBills,
          totalRevenue: summary.totalRevenue,
          totalDiscount: summary.totalDiscount,
        };
      }
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);

      const summary = await BillRecord.aggregate([
        {
          $match: {
            timestamp: {
              $gte: startOfDay,
              $lte: endOfDay,
            },
          },
        },
        {
          $group: {
            _id: null,
            totalBills: { $sum: 1 },
            totalRevenue: { $sum: '$totalAmount' },
            totalDiscount: { $sum: '$discount' },
          },
        },
      ]);

      return summary[0] || { totalBills: 0, totalRevenue: 0, totalDiscount: 0 };
    } catch (error) {
      logger.error('Error fetching daily sales summary:', error.message);
      return { totalBills: 0, totalRevenue: 0, totalDiscount: 0 };
    }
  }
}

module.exports = new MongoBillingService();
