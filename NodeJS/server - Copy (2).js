const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware
app.use(bodyParser.json());
app.use(cors());

// PostgreSQL connection
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'medical_appointments',
  password: '799771',
  port: 5432,
});

// Authentication Middleware
const authenticateToken = (req, res, next) => {
  const token = req.header('Authorization')?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access Denied' });

  jwt.verify(token, 'your_secret_key', (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid Token' });
    req.user = user;
    next();
  });
};

// Role-based Access Middleware
const authorizeRole = (requiredRole) => {
  return (req, res, next) => {
    const role = req.headers['current-role'];
    if (role !== requiredRole) {
      return res.status(403).json({ error: `Access denied. Only ${requiredRole}s can perform this action.` });
    }
    next();
  };
};

// ---------- USER MANAGEMENT ----------
// Create a user (Admin only)
app.post('/users', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { email, password, role } = req.body;

  if (!email || !password || !role) {
    return res.status(400).json({ error: 'Email, password, and role are required.' });
  }

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
// Login Endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (userResult.rowCount === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const user = userResult.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(403).json({ error: 'Invalid email or password.' });
    }

    // Issue JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      'your_secret_key', // Replace with an environment variable in production
      { expiresIn: '1h' }
    );

    res.status(200).json({ token, role: user.role });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// Get all users (Admin only)
app.get('/users', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  try {
    const result = await pool.query('SELECT id, email, role FROM users ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users.' });
  }
});

// Update a user (Admin only)
app.put('/users/:id',authenticateToken, authorizeRole('Admin'), async (req, res) => {
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
app.delete('/users/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
    res.status(200).json({ message: 'User deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ---------- PATIENT MANAGEMENT ----------
// Create a new patient (Admin, Secretary)
app.post('/patients', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { name, contact, medical_history } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Name is required.' });
  }

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
app.get('/patients', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM patients ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch patients.' });
  }
});

// Get a specific patient (Admin, Secretary)
app.get('/patients/:id', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
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
app.put('/patients/:id', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
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
app.delete('/patients/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM patients WHERE id = $1', [id]);
    res.status(200).json({ message: 'Patient deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ---------- APPOINTMENT MANAGEMENT ----------
// Create an appointment (Secretary)
app.post('/appointments', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { patient_id, date, description } = req.body;

  if (!patient_id || !date || !description) {
    return res.status(400).json({ error: 'Patient ID, date, and description are required.' });
  }

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

// Get all appointments (Admin, Secretary)
app.get('/appointments', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM appointments ORDER BY date');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch appointments.' });
  }
});

// Get appointments for a specific patient (Admin, Secretary)
app.get('/patients/:id/appointments', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM appointments WHERE patient_id = $1 ORDER BY date', [id]);
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch appointments.' });
  }
});

// Update an appointment (Secretary)
app.put('/appointments/:id', authenticateToken, authorizeRole('Secretary'), async (req, res) => {
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
app.delete('/appointments/:id', authenticateToken, authorizeRole('Admin'), async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM appointments WHERE id = $1', [id]);
    res.status(200).json({ message: 'Appointment deleted successfully.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ---------- TEETH WORK MANAGEMENT ----------
// Update work on a tooth (Doctor)
app.put('/patients/:id/teeth/:toothNumber', authenticateToken, authorizeRole('Doctor'), async (req, res) => {
  const { id, toothNumber } = req.params;
  const { status, notes } = req.body;

  if (!status && !notes) {
    return res.status(400).json({ error: 'At least one field must be provided to update.' });
  }

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

// Get teeth work for a patient (Admin, Doctor)
app.get('/patients/:id/teeth', authenticateToken, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query('SELECT * FROM teeth_work WHERE patient_id = $1 ORDER BY tooth_number', [id]);
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch teeth work.' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
