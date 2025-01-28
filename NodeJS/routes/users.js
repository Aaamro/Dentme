const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const authenticateToken = require('../middleware/authenticateToken');
const authorizeRole = require('../middleware/authorizeRole');

// Create a user (Admin only)
router.post('/register', authenticateToken, authorizeRole('Admin'), [
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('role').not().isEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password, role } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.query('INSERT INTO users (email, password, role) VALUES ($1, $2, $3)', [
      email,
      hashedPassword,
      role,
    ]);
    res.status(201).json({ message: 'User created successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  try {
    console.log('Received login request:', { email, password }); // Debug log

    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    console.log('User query result:', userResult.rows); // Debug log

    if (userResult.rowCount === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const user = userResult.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);
    console.log('Password validation result:', validPassword); // Debug log

    if (!validPassword) {
      return res.status(403).json({ error: 'Invalid email or password.' });
    }

    // Issue JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.status(200).json({ token, role: user.role });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error.' });
  }
});



// Get all users (Admin only)
router.get('/allusers', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  try {
    const result = await pool.query('SELECT id, email, role FROM users ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users.' });
  }
});

// Update a user (Admin only)
router.put('/edit/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;
  const { email, role } = req.body;

  if (!email && !role) {
    return res.status(400).json({ error: 'Email or role must be provided.' });
  }

  try {
    const updates = [];
    const values = [];

    if (email) {
      updates.push('email = $1');
      values.push(email);
    }

    if (role) {
      updates.push('role = $2');
      values.push(role);
    }

    values.push(id);

    const updateQuery = `UPDATE users SET ${updates.join(', ')} WHERE id = $${values.length}`;
    await pool.query(updateQuery, values);

    res.status(200).json({ message: 'User updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// Delete a user (Admin only)
router.delete('/delete/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
    res.status(200).json({ message: 'User deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
