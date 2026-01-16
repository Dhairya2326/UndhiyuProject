// Menu Item Model
class MenuItem {
  constructor(id, name, category, price, description, icon) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.price = price; // Price per gram
    this.description = description;
    this.icon = icon;
  }

  toJSON() {
    return {
      id: this.id,
      name: this.name,
      category: this.category,
      price: this.price,
      description: this.description,
      icon: this.icon,
    };
  }

  static fromJSON(data) {
    return new MenuItem(
      data.id,
      data.name,
      data.category,
      data.price,
      data.description,
      data.icon
    );
  }
}

// In-memory menu data (can be replaced with database)
const menuItems = [
  new MenuItem('m1', 'Undhiyu', 'Main Dish', 150.0, 'Traditional Gujarati undhiyu', '🥘'),
  new MenuItem('m2', 'Fafda Jalebi', 'Main Dish', 80.0, 'Crispy fafda with sweet jalebi', '🍟'),
  new MenuItem('m3', 'Dhokla', 'Main Dish', 60.0, 'Steamed spongy dhokla', '🍰'),
  new MenuItem('m4', 'Khandvi', 'Main Dish', 70.0, 'Rolled gram flour snack', '🥒'),
  new MenuItem('b1', 'Masala Chai', 'Beverages', 20.0, 'Hot spiced tea', '☕'),
  new MenuItem('b2', 'Lassi', 'Beverages', 40.0, 'Yogurt-based drink', '🥛'),
  new MenuItem('b3', 'Fresh Juice', 'Beverages', 50.0, 'Seasonal fresh juice', '🧃'),
  new MenuItem('b4', 'Soft Drink', 'Beverages', 30.0, 'Cold beverage', '🥤'),
  new MenuItem('d1', 'Kheer', 'Desserts', 90.0, 'Rice pudding with nuts', '🍚'),
  new MenuItem('d2', 'Gulab Jamun', 'Desserts', 85.0, 'Sweet dumplings in syrup', '🍮'),
  new MenuItem('d3', 'Ras Malai', 'Desserts', 100.0, 'Sweet creamy dessert', '🍛'),
  new MenuItem('s1', 'Samosa', 'Snacks', 25.0, 'Crispy triangular pastry', '🥟'),
  new MenuItem('s2', 'Pakora', 'Snacks', 35.0, 'Fried vegetable fritters', '🍗'),
  new MenuItem('s3', 'Moumos', 'Snacks', 45.0, 'Steamed dumplings', '🥟'),
];

module.exports = { MenuItem, menuItems };
