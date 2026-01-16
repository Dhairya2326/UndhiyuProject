const mongoose = require('mongoose');

// MenuItem Schema
const menuItemSchema = new mongoose.Schema(
  {
    id: {
      type: String,
      required: true,
      unique: true,
      default: function () {
        return `item_${Date.now()}`;
      },
    },
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
      maxlength: [100, 'Name cannot be more than 100 characters'],
    },
    category: {
      type: String,
      required: [true, 'Please provide a category'],
      enum: ['Main Dish', 'Beverages', 'Desserts', 'Snacks', 'Other'],
    },
    price: {
      type: Number,
      required: [true, 'Please provide a price'],
      min: [0, 'Price cannot be negative'],
      max: [99999, 'Price is too high'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot be more than 500 characters'],
      default: '',
    },
    icon: {
      type: String,
      default: '🍽️',
    },
    available: {
      type: Boolean,
      default: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// BillItem Schema
const billItemSchema = new mongoose.Schema({
  itemName: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    default: '🍽️',
  },
  quantityInGrams: {
    type: Number,
    required: [true, 'Quantity is required'],
    min: [1, 'Quantity must be at least 1 gram'],
  },
  pricePerGram: {
    type: Number,
    required: true,
    min: 0,
  },
  totalPrice: {
    type: Number,
    required: true,
    min: 0,
  },
});

// BillRecord Schema
const billRecordSchema = new mongoose.Schema(
  {
    id: {
      type: String,
      required: true,
      unique: true,
      default: function () {
        return `bill_${Date.now()}`;
      },
    },
    timestamp: {
      type: Date,
      default: Date.now,
      required: true,
    },
    items: [billItemSchema],
    subtotal: {
      type: Number,
      required: [true, 'Subtotal is required'],
      min: 0,
    },
    discount: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalAmount: {
      type: Number,
      required: [true, 'Total amount is required'],
      min: 0,
    },
    paymentMethod: {
      type: String,
      required: [true, 'Payment method is required'],
      enum: ['cash', 'upi', 'card', 'check', 'other'],
      default: 'cash',
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [500, 'Notes cannot be more than 500 characters'],
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'cancelled'],
      default: 'completed',
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Create Models
const MenuItem = mongoose.model('MenuItem', menuItemSchema);
const BillRecord = mongoose.model('BillRecord', billRecordSchema);
const BillItem = mongoose.model('BillItem', billItemSchema);

module.exports = { MenuItem, BillRecord, BillItem };
