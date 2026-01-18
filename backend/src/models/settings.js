const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
    type: {
        type: String,
        required: true,
        unique: true, // e.g., 'payment_config'
    },
    data: {
        type: mongoose.Schema.Types.Mixed,
        required: true,
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('Settings', settingsSchema);
