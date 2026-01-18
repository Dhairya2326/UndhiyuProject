const express = require('express');
const router = express.Router();
const Settings = require('../models/settings');
const logger = require('../utils/logger');

// GET /api/v1/settings/:type
router.get('/:type', async (req, res) => {
    try {
        const { type } = req.params;
        const settings = await Settings.findOne({ type });

        if (!settings) {
            return res.status(404).json({ success: false, message: 'Settings not found' });
        }

        res.json({ success: true, data: settings.data });
    } catch (error) {
        logger.error(`Error fetching settings (${req.params.type}): ${error.message}`);
        res.status(500).json({ success: false, error: error.message });
    }
});

// POST /api/v1/settings/:type
router.post('/:type', async (req, res) => {
    try {
        const { type } = req.params;
        const { data } = req.body;

        const settings = await Settings.findOneAndUpdate(
            { type },
            { type, data, updatedAt: Date.now() },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        logger.info(`Settings updated: ${type}`);
        res.json({ success: true, data: settings.data });
    } catch (error) {
        logger.error(`Error updating settings (${req.params.type}): ${error.message}`);
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;
