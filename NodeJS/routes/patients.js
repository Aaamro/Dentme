const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const pool = require('../db');
const authenticateToken = require('../middleware/authenticateToken');
const authorizeRole = require('../middleware/authorizeRole');

// Create a new patient (Admin, Secretary)
router.post('/register', authenticateToken, authorizeRole('Secretary'), [
  body('name').not().isEmpty(),
  body('contact').optional(),
  body('medical_history').optional()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { name, contact, medical_history } = req.body;

  try {
    await pool.query(
      'INSERT INTO patients (name, contact, medical_history) VALUES ($1, $2, $3)',
      [name, contact, medical_history]
    );
    res.status(201).json({ message: 'Patient added successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Get all patients (Admin, Secretary)
router.get('/allpatients', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM patients ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch patients.' });
  }
});

// Get a specific patient (Admin, Secretary)
router.get('/getpatient/:id', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM patients WHERE id = $1', [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Patient not found.' });
    }
    res.status(200).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Update a patient's details (Admin, Secretary)
router.put('/edit/:id', authenticateToken, authorizeRole('Secretary'), [
  body('name').optional(),
  body('contact').optional(),
  body('medical_history').optional()
], async (req, res) => {
  const { id } = req.params;
  const { name, contact, medical_history } = req.body;

  if (!name && !contact && !medical_history) {
    return res.status(400).json({ error: 'At least one field must be provided to update.' });
  }

  try {
    const updates = [];
    const values = [];

    if (name) {
      updates.push('name = $1');
      values.push(name);
    }

    if (contact) {
      updates.push('contact = $2');
      values.push(contact);
    }

    if (medical_history) {
      updates.push('medical_history = $3');
      values.push(medical_history);
    }

    values.push(id);

    const updateQuery = `UPDATE patients SET ${updates.join(', ')} WHERE id = $${values.length}`;
    await pool.query(updateQuery, values);

    res.status(200).json({ message: 'Patient updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Delete a patient (Admin only)
router.delete('/delete/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM patients WHERE id = $1', [id]);
    res.status(200).json({ message: 'Patient deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
