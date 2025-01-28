const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const pool = require('../db');
const authenticateToken = require('../middleware/authenticateToken');
const authorizeRole = require('../middleware/authorizeRole');

// Update work on a tooth (Doctor)
router.put('/patients/:id/teeth/:toothNumber', authenticateToken, authorizeRole('Doctor'), [
  body('status').optional(),
  body('notes').optional()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { id, toothNumber } = req.params;
  const { status, notes } = req.body;

  try {
    await pool.query(
      'INSERT INTO teeth_work (patient_id, tooth_number, status, notes) VALUES ($1, $2, $3, $4) ' +
      'ON CONFLICT (patient_id, tooth_number) DO UPDATE SET status = $3, notes = $4',
      [id, toothNumber, status, notes]
    );
    res.status(200).json({ message: `Tooth ${toothNumber} updated successfully.` });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Other teeth work routes here (get teeth work for a patient)

module.exports = router;
