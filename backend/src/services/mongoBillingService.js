const { BillRecord, BillItem, MenuItem } = require('../models/schemas');
const logger = require('../utils/logger');

class MongoBillingService {
  /**
   * Create a new bill
   */
  async createBill(cartItems, discount = 0, paymentMethod = 'cash', notes = '') {
    try {
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

        if (itemDoc.stockQuantity < quantityInGrams) {
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
      throw new Error(error.message);
    }
  }

  /**
   * Get all bills
   */
  async getAllBills() {
    try {
      const bills = await BillRecord.find().sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills:', error.message);
      throw new Error('Failed to fetch bills');
    }
  }

  /**
   * Get bill by ID
   */
  async getBillById(billId) {
    try {
      const bill = await BillRecord.findOne({ id: billId });
      return bill;
    } catch (error) {
      logger.error('Error fetching bill:', error.message);
      throw new Error('Failed to fetch bill');
    }
  }

  /**
   * Get bills by date range
   */
  async getBillsByDateRange(startDate, endDate) {
    try {
      const bills = await BillRecord.find({
        timestamp: {
          $gte: new Date(startDate),
          $lte: new Date(endDate),
        },
      }).sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills by date range:', error.message);
      throw new Error('Failed to fetch bills');
    }
  }

  /**
   * Get bills by payment method
   */
  async getBillsByPaymentMethod(paymentMethod) {
    try {
      const bills = await BillRecord.find({ paymentMethod }).sort({ timestamp: -1 });
      return bills;
    } catch (error) {
      logger.error('Error fetching bills by payment method:', error.message);
      throw new Error('Failed to fetch bills');
    }
  }

  /**
   * Get sales summary
   */
  async getSalesSummary() {
    try {
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
      throw new Error('Failed to fetch sales summary');
    }
  }

  /**
   * Get most sold items
   */
  async getMostSoldItems(limit = 10) {
    try {
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
      throw new Error('Failed to fetch most sold items');
    }
  }

  /**
   * Update bill
   */
  async updateBill(billId, updates) {
    try {
      const bill = await BillRecord.findOneAndUpdate(
        { id: billId },
        { ...updates, updatedAt: new Date() },
        { new: true, runValidators: true }
      );
      return bill;
    } catch (error) {
      logger.error('Error updating bill:', error.message);
      throw new Error('Failed to update bill: ' + error.message);
    }
  }

  /**
   * Delete bill
   */
  async deleteBill(billId) {
    try {
      const result = await BillRecord.findOneAndDelete({ id: billId });
      return result ? true : false;
    } catch (error) {
      logger.error('Error deleting bill:', error.message);
      throw new Error('Failed to delete bill');
    }
  }

  /**
   * Get daily sales summary
   */
  async getDailySalesSummary(date) {
    try {
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
      throw new Error('Failed to fetch daily sales summary');
    }
  }
}

module.exports = new MongoBillingService();
