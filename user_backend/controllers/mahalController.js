const Mahal = require('../models/Mahal');

const toBase64Image = (value) => {
    if (!value) return null;

    if (typeof value === 'string') {
        return value;
    }

    if (Buffer.isBuffer(value)) {
        return value.toString('base64');
    }

    if (value instanceof Uint8Array) {
        return Buffer.from(value).toString('base64');
    }

    if (value?.buffer) {
        const bufferLike = value.buffer;
        if (Buffer.isBuffer(bufferLike)) {
            return bufferLike.toString('base64');
        }

        if (bufferLike instanceof Uint8Array || ArrayBuffer.isView(bufferLike)) {
            return Buffer.from(bufferLike).toString('base64');
        }

        if (bufferLike instanceof ArrayBuffer) {
            return Buffer.from(new Uint8Array(bufferLike)).toString('base64');
        }
    }

    if (value && typeof value === 'object' && value.constructor && value.constructor.name === 'Binary') {
        return Buffer.from(value.buffer).toString('base64');
    }

    try {
        return Buffer.from(value).toString('base64');
    } catch (err) {
        return null;
    }
};

exports.getAllMahals = async (req, res, next) => {
    try {
        const mahals = await Mahal.find();

        const processed = mahals.map(mahalDoc => {
            const mahal = mahalDoc.toObject();
            let imageBase64List = [];
            
            const imageKeys = ['mahal_image', 'mahal_images_2', 'mahal_images_3', 'mahal_images_4', 'mahal_images_5', 'mahal_images_6'];
            
            for (const key of imageKeys) {
                const base64Value = toBase64Image(mahal[key]);
                if (base64Value) {
                    imageBase64List.push(base64Value);
                }
            }

            return {
                ...mahal,
                mahal_id: mahal._id,
                mahal_images: imageBase64List.length > 0 ? imageBase64List.join(',') : null
            };
        });

        return res.status(200).json({
            success: true,
            count: processed.length,
            data: processed
        });
    } catch (err) {
        next(err);
    }
};

exports.getMahalById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const mahalDoc = await Mahal.findById(id);

        if (!mahalDoc) {
            return res.status(404).json({ success: false, message: 'Mahal not found' });
        }

        const mahal = mahalDoc.toObject();
        let imageBase64List = [];
        
        const imageKeys = ['mahal_image', 'mahal_images_2', 'mahal_images_3', 'mahal_images_4', 'mahal_images_5', 'mahal_images_6'];
        
        for (const key of imageKeys) {
            const base64Value = toBase64Image(mahal[key]);
            if (base64Value) {
                imageBase64List.push(base64Value);
            }
        }
        
        mahal.mahal_images = imageBase64List.length > 0 ? imageBase64List.join(',') : null;
        mahal.mahal_id = mahal._id;

        return res.status(200).json({
            success: true,
            data: mahal
        });
    } catch (err) {
        next(err);
    }
};

exports.getDefaultTimings = async (req, res, next) => {
    try {
        const mahal_id = req.params.mahal_id || req.params.id;
        const mahal = await Mahal.findById(mahal_id);

        if (!mahal) {
            return res.status(404).json({ success: false, message: 'Mahal not found' });
        }

        const timings = {};
        if (mahal.default_timings) {
            mahal.default_timings.forEach(row => {
                timings[row.booking_type] = {
                    start_time: row.start_time,
                    end_time: row.end_time
                };
            });
        }

        return res.status(200).json({
            success: true,
            mahal_id,
            timings
        });
    } catch (err) {
        next(err);
    }
};

exports.getTimingByBookingType = async (req, res, next) => {
    try {
        const mahal_id = req.params.mahal_id || req.params.id;
        const { booking_type } = req.query;

        if (!booking_type) {
            return res.status(400).json({ success: false, message: 'booking_type is required' });
        }

        const mahal = await Mahal.findById(mahal_id);
        if (!mahal) {
            return res.status(404).json({ success: false, message: 'Mahal not found' });
        }

        const timing = (mahal.default_timings || []).find(t => t.booking_type === booking_type);

        if (!timing) {
            return res.status(404).json({ 
                success: false, 
                message: `Default timings for '${booking_type}' have not been configured by the owner.` 
            });
        }

        return res.status(200).json({
            success: true,
            mahal_id,
            booking_type: timing.booking_type,
            start_time: timing.start_time,
            end_time: timing.end_time
        });
    } catch (err) {
        next(err);
    }
};
