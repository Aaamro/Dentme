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

function validatePassword(password) {
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$/;
  // Minimum 8 characters, at least one letter, one number
  return passwordRegex.test(password);
}


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


app.get('/', (req, res) => {
  res.send('Server is running!');
});

//Create user
app.post('/register', authenticateToken, async (req, res) => {
  const { email, password, role } = req.body;
  const authrole = req.headers['current-role']

  if (authrole !== 'Admin') {
    return res.status(403).json({ error: 'Access denied. Only Admins can view users.' });
  }

  if (!email || !password || !role) {
    return res.status(400).json({ error: 'Email, password, and role are required' });
  }

  if (!['Admin', 'Secretary', 'Doctor'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rowCount > 0) {
      return res.status(409).json({ error: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.query('INSERT INTO users (email, password, role) VALUES ($1, $2, $3)', [
      email,
      hashedPassword,
      role,
    ]);

    res.status(201).json({ message: `User registered as ${role} successfully` });
  } catch (err) {
    console.error('Error during registration:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//login with token auth
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rowCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(403).json({ error: 'Invalid email or password' });
    }

    // Issue JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      'your_secret_key', // Replace with an environment variable
      { expiresIn: '1h' }
    );

    res.status(200).json({ token, role: user.role });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//Get all users
app.get('/users', authenticateToken, async (req, res) => {
  const authrole = req.headers['current-role']

  if (authrole !== 'Admin') {
    return res.status(403).json({ error: 'Access denied. Only Admins can view users.' });
  }

  try {
    const result = await pool.query('SELECT id, email, role FROM users ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//Update User(email or role)
app.put('/users/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const { email, role } = req.body;
  const authrole = req.headers['current-role']

  if (authrole !== 'Admin') {
    return res.status(403).json({ error: 'Access denied. Only Admins can view users.' });
  }

  try {
    if (!email && !role) {
      return res.status(400).json({ error: 'Email or role must be provided.' });
    }

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

    res.status(200).json({ message: 'User updated successfully' });
  } catch (err) {
    console.error('Error updating user:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//Delete user
app.delete('/users/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  const authrole = req.headers['current-role']
  if (authrole !== 'Admin') {
    return res.status(403).json({ error: 'Access denied. Only Admins can view users.' });
  }

  try {
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (err) {
    console.error('Error deleting user:', err);
    res.status(500).json({ error: 'Server error' });
  }
});


// Get all patients
app.get('/patients', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM patients');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch patients' });
  }
});

// Add a patient
app.post('/patients', authenticateToken, async (req, res) => {
  const { name, contact, medical_history } = req.body;

  try {
    await pool.query(
      'INSERT INTO patients (name, contact, medical_history) VALUES ($1, $2, $3)',
      [name, contact, medical_history]
    );
    res.status(201).json({ message: 'Patient added successfully' });
  } catch (err) {
    res.status(400).json({ error: 'Invalid data' });
  }
});

// Get all appointments
app.get('/appointments', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM appointments');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch appointments' });
  }
});

// Add an appointment
app.post('/appointments', authenticateToken, async (req, res) => {
  const { patient_id, doctor_name, appointment_date } = req.body;

  try {
    await pool.query(
      'INSERT INTO appointments (patient_id, doctor_name, appointment_date) VALUES ($1, $2, $3)',
      [patient_id, doctor_name, appointment_date]
    );
    res.status(201).json({ message: 'Appointment scheduled successfully' });
  } catch (err) {
    res.status(400).json({ error: 'Invalid data' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
