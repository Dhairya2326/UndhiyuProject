const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Settings = require('../models/settings');
const logger = require('../utils/logger');

const inMemorySettings = new Map();

// GET /api/v1/settings/:type
router.get('/:type', async (req, res) => {
    try {
        const { type } = req.params;
        if (mongoose.connection.readyState !== 1) {
            const data = inMemorySettings.get(type);
            if (!data) {
                return res.status(404).json({ success: false, message: 'Settings not found' });
            }
            return res.json({ success: true, data });
        }

        const settings = await Settings.findOne({ type });

        if (!settings) {
            return res.status(404).json({ success: false, message: 'Settings not found' });
        }

        res.json({ success: true, data: settings.data });
    } catch (error) {
        logger.error(`Error fetching settings (${req.params.type}): ${error.message}`);
        const data = inMemorySettings.get(req.params.type);
        if (data) {
            return res.json({ success: true, data });
        }
        res.status(500).json({ success: false, error: error.message });
    }
});

// POST /api/v1/settings/:type
router.post('/:type', async (req, res) => {
    try {
        const { type } = req.params;
        const { data } = req.body;

        inMemorySettings.set(type, data);

        if (mongoose.connection.readyState !== 1) {
            logger.info(`Settings updated (in-memory): ${type}`);
            return res.json({ success: true, data });
        }

        const settings = await Settings.findOneAndUpdate(
            { type },
            { type, data, updatedAt: Date.now() },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        logger.info(`Settings updated: ${type}`);
        res.json({ success: true, data: settings.data });
    } catch (error) {
        logger.error(`Error updating settings (${req.params.type}): ${error.message}`);
        inMemorySettings.set(req.params.type, req.body.data);
        res.json({ success: true, data: req.body.data });
    }
});

module.exports = router;
