const { BillRecord, BillItem, billHistory } = require('../models/bill');
const menuService = require('./menuService');

class BillingService {
  /**
   * Calculate bill total
   */
  calculateBillTotal(items, discount = 0) {
    const subtotal = items.reduce((sum, item) => sum + item.totalPrice, 0);
    const totalAmount = subtotal - discount;
    return { subtotal, totalAmount };
  }

  /**
   * Create a new bill
   */
  createBill(cartItems, discount = 0, paymentMethod = 'cash', notes = '') {
    const billItems = cartItems.map(cartItem => {
      const menuItem = cartItem.menuItem;
      const quantityInGrams = cartItem.quantityInGrams;
      const pricePerGram = menuItem.price;
      const totalPrice = quantityInGrams * pricePerGram;

      return new BillItem(
        menuItem.name,
        menuItem.icon,
        quantityInGrams,
        pricePerGram,
        totalPrice
      );
    });

    const { subtotal, totalAmount } = this.calculateBillTotal(billItems, discount);

    const billId = `bill_${Date.now()}`;
    const bill = new BillRecord(
      billId,
      new Date(),
      billItems,
      subtotal,
      discount,
      totalAmount,
      paymentMethod,
      notes
    );

    billHistory.push(bill);
    return bill;
  }

  /**
   * Get all bills
   */
  getAllBills() {
    return billHistory;
  }

  /**
   * Get bill by ID
   */
  getBillById(billId) {
    return billHistory.find(bill => bill.id === billId) || null;
  }

  /**
   * Get bills by date range
   */
  getBillsByDateRange(startDate, endDate) {
    return billHistory.filter(bill => {
      return bill.timestamp >= new Date(startDate) && bill.timestamp <= new Date(endDate);
    });
  }

  /**
   * Get bills by payment method
   */
  getBillsByPaymentMethod(paymentMethod) {
    return billHistory.filter(bill => bill.paymentMethod === paymentMethod);
  }

  /**
   * Get sales summary
   */
  getSalesSummary() {
    const totalBills = billHistory.length;
    const totalRevenue = billHistory.reduce((sum, bill) => sum + bill.totalAmount, 0);
    const totalDiscount = billHistory.reduce((sum, bill) => sum + bill.discount, 0);
    const averageOrderValue = totalBills > 0 ? totalRevenue / totalBills : 0;

    const paymentMethodBreakdown = {};
    billHistory.forEach(bill => {
      if (!paymentMethodBreakdown[bill.paymentMethod]) {
        paymentMethodBreakdown[bill.paymentMethod] = 0;
      }
      paymentMethodBreakdown[bill.paymentMethod] += bill.totalAmount;
    });

    return {
      totalBills,
      totalRevenue,
      totalDiscount,
      averageOrderValue,
      paymentMethodBreakdown,
    };
  }

  /**
   * Get most sold items
   */
  getMostSoldItems(limit = 10) {
    const itemSales = {};

    billHistory.forEach(bill => {
      bill.items.forEach(item => {
        if (!itemSales[item.itemName]) {
          itemSales[item.itemName] = {
            name: item.itemName,
            icon: item.icon,
            quantitySold: 0,
            revenue: 0,
          };
        }
        itemSales[item.itemName].quantitySold += item.quantityInGrams;
        itemSales[item.itemName].revenue += item.totalPrice;
      });
    });

    return Object.values(itemSales)
      .sort((a, b) => b.quantitySold - a.quantitySold)
      .slice(0, limit);
  }

  /**
   * Update bill
   */
  updateBill(billId, updates) {
    const billIndex = billHistory.findIndex(bill => bill.id === billId);
    if (billIndex === -1) return null;

    const bill = billHistory[billIndex];
    const updatedBill = new BillRecord(
      billId,
      updates.timestamp || bill.timestamp,
      updates.items || bill.items,
      updates.subtotal || bill.subtotal,
      updates.discount || bill.discount,
      updates.totalAmount || bill.totalAmount,
      updates.paymentMethod || bill.paymentMethod,
      updates.notes || bill.notes
    );

    billHistory[billIndex] = updatedBill;
    return updatedBill;
  }

  /**
   * Delete bill
   */
  deleteBill(billId) {
    const index = billHistory.findIndex(bill => bill.id === billId);
    if (index === -1) return false;
    billHistory.splice(index, 1);
    return true;
  }
}

module.exports = new BillingService();
