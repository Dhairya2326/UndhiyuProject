// Bill Record Model
class BillRecord {
  constructor(id, timestamp, items, subtotal, discount, totalAmount, paymentMethod, notes = '') {
    this.id = id;
    this.timestamp = timestamp;
    this.items = items; // Array of BillItem
    this.subtotal = subtotal;
    this.discount = discount;
    this.totalAmount = totalAmount;
    this.paymentMethod = paymentMethod; // 'cash', 'upi', etc.
    this.notes = notes;
  }

  toJSON() {
    return {
      id: this.id,
      timestamp: this.timestamp.toISOString(),
      items: this.items.map(item => item.toJSON()),
      subtotal: this.subtotal,
      discount: this.discount,
      totalAmount: this.totalAmount,
      paymentMethod: this.paymentMethod,
      notes: this.notes,
    };
  }

  static fromJSON(data) {
    return new BillRecord(
      data.id,
      new Date(data.timestamp),
      data.items.map(item => BillItem.fromJSON(item)),
      data.subtotal,
      data.discount,
      data.totalAmount,
      data.paymentMethod,
      data.notes
    );
  }
}

// Bill Item Model
class BillItem {
  constructor(itemName, icon, quantityInGrams, pricePerGram, totalPrice) {
    this.itemName = itemName;
    this.icon = icon;
    this.quantityInGrams = quantityInGrams;
    this.pricePerGram = pricePerGram;
    this.totalPrice = totalPrice;
  }

  get quantityInKg() {
    return this.quantityInGrams / 1000;
  }

  toJSON() {
    return {
      itemName: this.itemName,
      icon: this.icon,
      quantityInGrams: this.quantityInGrams,
      pricePerGram: this.pricePerGram,
      totalPrice: this.totalPrice,
    };
  }

  static fromJSON(data) {
    return new BillItem(
      data.itemName,
      data.icon,
      data.quantityInGrams,
      data.pricePerGram,
      data.totalPrice
    );
  }
}

// In-memory bill history (can be replaced with database)
const billHistory = [];

module.exports = { BillRecord, BillItem, billHistory };
