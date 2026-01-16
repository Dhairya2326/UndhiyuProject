require('dotenv').config();
const mongoose = require('mongoose');
const { MenuItem } = require('./src/models/schemas');
const logger = require('./src/utils/logger');

// Menu items to seed
const menuItems = [
    {
        id: 'm1',
        name: 'Undhiyu',
        category: 'Main Dish',
        price: 0.4, // Price per gram (150 per kg / 1000)
        description: 'Traditional Gujarati undhiyu',
        icon: '🥘',
    },
    {
        id: 'm2',
        name: 'Fafda Jalebi',
        category: 'Main Dish',
        price: 0.08, // Price per gram (80 per kg / 1000)
        description: 'Crispy fafda with sweet jalebi',
        icon: '🍟',
    },
    {
        id: 'm3',
        name: 'Dhokla',
        category: 'Main Dish',
        price: 0.06, // Price per gram (60 per kg / 1000)
        description: 'Steamed spongy dhokla',
        icon: '🍰',
    },
    {
        id: 'm4',
        name: 'Khandvi',
        category: 'Main Dish',
        price: 0.07, // Price per gram (70 per kg / 1000)
        description: 'Rolled gram flour snack',
        icon: '🥒',
    },
    {
        id: 'm5',
        name: 'Jalebi',
        category: 'Desserts',
        price: 0.1, // Price per gram (100 per kg / 1000)
        description: 'Sweet crispy jalebi',
        icon: '🍥',
    },
    {
        id: 'b1',
        name: 'Masala Chai',
        category: 'Beverages',
        price: 0.02, // Price per gram (20 per kg / 1000)
        description: 'Hot spiced tea',
        icon: '☕',
    },
    {
        id: 'b2',
        name: 'Lassi',
        category: 'Beverages',
        price: 0.04, // Price per gram (40 per kg / 1000)
        description: 'Yogurt-based drink',
        icon: '🥛',
    },
    {
        id: 'b3',
        name: 'Fresh Juice',
        category: 'Beverages',
        price: 0.05, // Price per gram (50 per kg / 1000)
        description: 'Seasonal fresh juice',
        icon: '🧃',
    },
    {
        id: 'b4',
        name: 'Soft Drink',
        category: 'Beverages',
        price: 0.03, // Price per gram (30 per kg / 1000)
        description: 'Cold beverage',
        icon: '🥤',
    },
    {
        id: 'd1',
        name: 'Kheer',
        category: 'Desserts',
        price: 0.09, // Price per gram (90 per kg / 1000)
        description: 'Rice pudding with nuts',
        icon: '🍚',
    },
    {
        id: 'd2',
        name: 'Gulab Jamun',
        category: 'Desserts',
        price: 0.085, // Price per gram (85 per kg / 1000)
        description: 'Sweet dumplings in syrup',
        icon: '🍮',
    },
    {
        id: 'd3',
        name: 'Ras Malai',
        category: 'Desserts',
        price: 0.1, // Price per gram (100 per kg / 1000)
        description: 'Sweet creamy dessert',
        icon: '🍛',
    },
    {
        id: 's1',
        name: 'Samosa',
        category: 'Snacks',
        price: 0.025, // Price per gram (25 per kg / 1000)
        description: 'Crispy triangular pastry',
        icon: '🥟',
    },
    {
        id: 's2',
        name: 'Pakora',
        category: 'Snacks',
        price: 0.035, // Price per gram (35 per kg / 1000)
        description: 'Fried vegetable fritters',
        icon: '🍗',
    },
    {
        id: 's3',
        name: 'Momos',
        category: 'Snacks',
        price: 0.045, // Price per gram (45 per kg / 1000)
        description: 'Steamed dumplings',
        icon: '🥟',
    },
];

async function seedDatabase() {
    try {
        // Connect to MongoDB
        const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/undhiyu';
        await mongoose.connect(mongoURI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });
        logger.info('Connected to MongoDB');

        // Insert menu items
        for (const item of menuItems) {
            try {
                // Check if item already exists
                const existingItem = await MenuItem.findOne({ id: item.id });
                if (existingItem) {
                    logger.info(`Item already exists: ${item.name} (${item.id})`);

                    // Preserve existing dynamic data if not provided in seed
                    if (item.stockQuantity === undefined) {
                        item.stockQuantity = existingItem.stockQuantity;
                    }
                    if (item.lowStockThreshold === undefined) {
                        item.lowStockThreshold = existingItem.lowStockThreshold;
                    }
                    if (item.imageUrl === undefined) {
                        item.imageUrl = existingItem.imageUrl;
                    }

                    // Update the existing item
                    await MenuItem.updateOne({ id: item.id }, item);
                    logger.info(`Updated: ${item.name} (Preserved Stock: ${existingItem.stockQuantity})`);
                } else {
                    // Create new item
                    // Ensure defaults for new item if not in seed (though schema handles most)
                    if (item.stockQuantity === undefined) item.stockQuantity = 50000;
                    if (item.lowStockThreshold === undefined) item.lowStockThreshold = 5000;

                    await MenuItem.create(item);
                    logger.info(`Created: ${item.name}`);
                }
            } catch (error) {
                logger.error(`Error processing ${item.name}: ${error.message}`);
            }
        }

        logger.info('\n✅ Database seeding completed successfully!');

        // Display summary
        const count = await MenuItem.countDocuments();
        logger.info(`Total menu items in database: ${count}`);

        // Disconnect
        await mongoose.disconnect();
        logger.info('Disconnected from MongoDB');
        process.exit(0);
    } catch (error) {
        logger.error('Error seeding database:', error.message);
        process.exit(1);
    }
}

seedDatabase();
