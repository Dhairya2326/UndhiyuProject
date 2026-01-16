# Undhiyu Catering Management System

A full-stack catering management application built with Flutter (frontend) and Node.js (backend) with MongoDB database.

## Features

- 📋 **Menu Management**: Add, view, and delete menu items with per-gram pricing
- 💰 **Billing System**: Create bills with multiple items and different payment methods
- 📊 **Bill History**: View all past bills with detailed breakdowns
- 🔧 **Admin Panel**: Manage menu items dynamically
- 🌐 **API Integration**: Full REST API with MongoDB persistence

## Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **HTTP** - API communication

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM for MongoDB

## Project Structure

```
undhiyuapp/
├── lib/                    # Flutter frontend
│   ├── src/
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API services
│   │   └── widgets/       # Reusable widgets
│   └── main.dart
├── backend/               # Node.js backend
│   ├── src/
│   │   ├── api/          # API routes
│   │   ├── models/       # Data models
│   │   ├── services/     # Business logic
│   │   └── config/       # Configuration
│   └── server.js
└── README.md
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.10.7 or higher)
- Node.js (v14 or higher)
- MongoDB Atlas account or local MongoDB

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```env
MONGODB_URI=your_mongodb_connection_string
NODE_ENV=development
PORT=5000
```

4. Start the server:
```bash
npm start
```

Backend will run on `http://localhost:5000`

### Frontend Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run -d chrome  # For web
flutter run -d windows # For Windows desktop
```

## API Endpoints

### Menu
- `GET /api/v1/menu` - Get all menu items
- `GET /api/v1/menu/categories` - Get all categories
- `POST /api/v1/menu` - Add new menu item
- `PUT /api/v1/menu/:id` - Update menu item
- `DELETE /api/v1/menu/:id` - Delete menu item

### Billing
- `POST /api/v1/billing/create` - Create new bill
- `GET /api/v1/billing/all` - Get all bills
- `GET /api/v1/billing/:id` - Get bill by ID

## Features in Detail

### Menu Management
- Add items with name, category, price per gram, description, and icon
- View all items organized by category
- Delete items from the admin panel
- Prices are stored per gram for precise calculations

### Billing
- Select multiple items with quantities in grams
- Automatic price calculation
- Support for cash and UPI payments
- Optional discount and notes
- Bill history with detailed item breakdowns

### Admin Panel
- Add new menu items
- View all existing items
- Delete items with confirmation
- Real-time updates from database

## Database Schema

### MenuItem
```javascript
{
  id: String,
  name: String,
  category: String,
  price: Number,  // Price per gram
  description: String,
  icon: String,
  available: Boolean
}
```

### BillRecord
```javascript
{
  id: String,
  timestamp: Date,
  items: [BillItem],
  subtotal: Number,
  discount: Number,
  totalAmount: Number,
  paymentMethod: String,
  notes: String
}
```

## Development

### Running in Development Mode

Backend:
```bash
cd backend
npm run dev
```

Frontend:
```bash
flutter run -d chrome
```

### Building for Production

Backend:
```bash
cd backend
npm start
```

Frontend:
```bash
flutter build web
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Author

Dhairya - Shivam Caterers

## Acknowledgments

- Flutter team for the amazing framework
- MongoDB for the database
- Express.js for the backend framework
