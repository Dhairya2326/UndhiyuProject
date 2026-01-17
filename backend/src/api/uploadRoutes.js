const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');

const router = express.Router();

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
    logger.info('📁 Created uploads directory');
}

// Configure multer storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Generate unique filename: timestamp-originalname
        const uniqueName = `${Date.now()}-${file.originalname.replace(/\s+/g, '_')}`;
        cb(null, uniqueName);
    },
});

// File filter - only allow images
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed.'), false);
    }
};

// Configure multer
const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max
    },
});

/**
 * POST /api/v1/upload
 * Upload a single image file
 */
router.post('/', upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            logger.warn('⚠️ Upload: No file provided');
            return res.status(400).json({
                success: false,
                error: 'No image file provided',
            });
        }

        // Generate the URL for the uploaded file
        const imageUrl = `/uploads/${req.file.filename}`;

        logger.info(`✅ Upload: File uploaded successfully - ${req.file.filename}`);

        res.status(201).json({
            success: true,
            data: {
                filename: req.file.filename,
                imageUrl,
                size: req.file.size,
                mimetype: req.file.mimetype,
            },
        });
    } catch (error) {
        logger.error(`❌ Upload: Failed - ${error.message}`);
        res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});

/**
 * DELETE /api/v1/upload/:filename
 * Delete an uploaded image
 */
router.delete('/:filename', (req, res) => {
    try {
        const { filename } = req.params;
        const filePath = path.join(uploadDir, filename);

        if (!fs.existsSync(filePath)) {
            logger.warn(`⚠️ Upload: File not found - ${filename}`);
            return res.status(404).json({
                success: false,
                error: 'File not found',
            });
        }

        fs.unlinkSync(filePath);
        logger.info(`✅ Upload: File deleted - ${filename}`);

        res.json({
            success: true,
            message: 'File deleted successfully',
        });
    } catch (error) {
        logger.error(`❌ Upload: Delete failed - ${error.message}`);
        res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});

// Error handling middleware for multer errors
router.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
        if (error.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                error: 'File too large. Maximum size is 5MB.',
            });
        }
        return res.status(400).json({
            success: false,
            error: error.message,
        });
    }
    if (error) {
        return res.status(400).json({
            success: false,
            error: error.message,
        });
    }
    next();
});

module.exports = router;
