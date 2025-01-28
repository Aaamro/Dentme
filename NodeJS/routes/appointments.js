const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const pool = require('../db');
const authenticateToken = require('../middleware/authenticateToken');
const authorizeRole = require('../middleware/authorizeRole');

// Create an appointment (Secretary)
router.post('/register', authenticateToken, authorizeRole('Secretary'), [
  body('patient_id').isInt(),
  body('date').isISO8601(),
  body('description').not().isEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { patient_id, date, description } = req.body;

  try {
    await pool.query(
      'INSERT INTO appointments (patient_id, date, description) VALUES ($1, $2, $3)',
      [patient_id, date, description]
    );
    res.status(201).json({ message: 'Appointment created successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Get all appointments by date (Admin, Secretary)
router.get('/getappointmentsD', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { date } = req.query; // Get date from query parameters if provided

  try {
    let result;
    if (date) {
      result = await pool.query('SELECT * FROM appointments WHERE date = $1 ORDER BY date', [date]);
    } else {
      result = await pool.query('SELECT * FROM appointments ORDER BY date');
    }
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch appointments.' });
  }
});

// Get appointments for a specific patient (Admin, Secretary)
router.get('/getappointmentP/:id', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM appointments WHERE patient_id = $1 ORDER BY date', [id]);
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch appointments.' });
  }
});

// Update an appointment (Secretary)
router.put('/edit/:id', authenticateToken, authorizeRole('Secretary'), [
  body('date').optional().isISO8601(),
  body('description').optional().not().isEmpty()
], async (req, res) => {
  const { id } = req.params;
  const { date, description } = req.body;

  if (!date && !description) {
    return res.status(400).json({ error: 'At least one field must be provided to update.' });
  }

  try {
    const updates = [];
    const values = [];

    if (date) {
      updates.push('date = $1');
      values.push(date);
    }

    if (description) {
      updates.push('description = $2');
      values.push(description);
    }

    values.push(id);

    const updateQuery = `UPDATE appointments SET ${updates.join(', ')} WHERE id = $${values.length}`;
    await pool.query(updateQuery, values);

    res.status(200).json({ message: 'Appointment updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Delete an appointment (Admin only)
router.delete('/delete/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM appointments WHERE id = $1', [id]);
    res.status(200).json({ message: 'Appointment deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
