# Undhiyu Backend API

Backend API for the Undhiyu Catering Management System. This API provides endpoints for menu management and billing operations.

## Features

- **Menu Management**: CRUD operations for menu items
- **Billing System**: Create and manage bills with multiple items
- **Sales Analytics**: Track sales, revenue, and popular items
- **Payment Methods**: Support for multiple payment methods (cash, UPI, etc.)

## Installation

```bash
cd backend
npm install
```

## Running the Server

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

The server will run on `http://localhost:5000` by default.

## API Documentation

### Health Check
- **GET** `/health` - Check if server is running

### Menu Endpoints

#### Get all menu items
- **GET** `/api/menu`
- Returns all available menu items

#### Get all categories
- **GET** `/api/menu/categories`
- Returns list of all item categories

#### Get items by category
- **GET** `/api/menu/category/:category`
- Returns items for a specific category

#### Get item by ID
- **GET** `/api/menu/:id`
- Returns a specific menu item

#### Add new menu item
- **POST** `/api/menu`
- Body: `{ name, category, price, description, icon }`

#### Update menu item
- **PUT** `/api/menu/:id`
- Body: `{ name?, category?, price?, description?, icon? }`

#### Delete menu item
- **DELETE** `/api/menu/:id`

### Billing Endpoints

#### Create a new bill
- **POST** `/api/billing/create`
- Body: 
  ```json
  {
    "cartItems": [
      {
        "menuItem": { "id", "name", "price", ... },
        "quantityInGrams": 1000
      }
    ],
    "discount": 0,
    "paymentMethod": "cash",
    "notes": ""
  }
  ```

#### Get all bills
- **GET** `/api/billing/all`
- Returns all bill records

#### Get bill by ID
- **GET** `/api/billing/:id`
- Returns a specific bill

#### Get bills by date range
- **GET** `/api/billing/range/:startDate/:endDate`
- Returns bills within a date range

#### Get bills by payment method
- **GET** `/api/billing/method/:paymentMethod`
- Returns bills paid with specific method

#### Get sales summary
- **GET** `/api/billing/summary/sales`
- Returns sales statistics and breakdown

#### Get most sold items
- **GET** `/api/billing/summary/top-items?limit=10`
- Returns top selling items

#### Update bill
- **PUT** `/api/billing/:id`
- Body: `{ discount?, paymentMethod?, notes?, ... }`

#### Delete bill
- **DELETE** `/api/billing/:id`

## Project Structure

```
backend/
├── src/
│   ├── api/              # API route handlers
│   │   ├── menuRoutes.js
│   │   └── billingRoutes.js
│   ├── models/           # Data models
│   │   ├── menu.js
│   │   └── bill.js
│   ├── services/         # Business logic
│   │   ├── menuService.js
│   │   └── billingService.js
│   ├── middleware/       # Express middleware
│   │   ├── corsMiddleware.js
│   │   └── errorHandler.js
│   ├── config/           # Configuration
│   │   ├── server.js
│   │   └── database.js
│   └── utils/            # Utility functions
│       └── logger.js
├── server.js             # Main server file
├── package.json
└── README.md
```

## Environment Variables

- `PORT` - Server port (default: 5000)
- `NODE_ENV` - Environment (development/production/test)

## Frontend Integration

The frontend Flutter app should connect to this backend at:
- Development: `http://localhost:5000`
- Production: `<your-production-url>`

Example frontend API call:
```dart
Future<void> fetchMenuItems() async {
  final response = await http.get(
    Uri.parse('http://localhost:5000/api/menu'),
  );
  // Handle response...
}
```

## License

MIT
