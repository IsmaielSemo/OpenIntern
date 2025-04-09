const express = require('express');
const mysql = require('mysql');
const session = require('express-session');
const bcrypt = require('bcrypt');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

// Generate a secure session secret
const crypto = require('crypto');
const sessionSecret = process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex');

const app = express();

// Improved CORS configuration - allow credentials
app.use(cors({
  origin: true,  // Allow requests from any origin in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie'],
  exposedHeaders: ['set-cookie']
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Session configuration with secure secret
app.use(session({
  secret: sessionSecret,
  resave: true,
  saveUninitialized: true,
  cookie: {
    secure: false, // Set to true in production with HTTPS
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    sameSite: 'lax'
  }
}));

// MySQL Connection with better error handling
const connection = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'Ganna97812000',
  database: process.env.DB_NAME || 'openintern'
});

connection.connect(error => {
  if (error) {
    console.error('Database connection failed:', error);
    throw error; // This will stop the server if DB connection fails
  }
  console.log('Successfully connected to the database.');
});

// Debug middleware to log session information
app.use((req, res, next) => {
  console.log('Session ID:', req.sessionID);
  console.log('Session Data:', req.session);
  console.log('Cookies:', req.headers.cookie);
  next();
});

// Test endpoint to verify server is running
app.get('/', (req, res) => {
  res.status(200).send({
    message: 'Server is running correctly!',
    sessionID: req.sessionID,
    isLoggedIn: req.session.loggedin || false
  });
});

// 1. Sign-up endpoint with improved error handling
app.post('/sign-up', async (req, res) => {
  try {
    console.log('Received sign-up request:', req.body);
    const { username, email, password, dob, university, graduationYear } = req.body;

    // Validate required fields
    if (!username || !email || !password) {
      return res.status(400).send({
        message: 'Username, email, and password are required!'
      });
    }

    // Check if user already exists
    connection.query(
      'SELECT * FROM users WHERE email = ? OR username = ?',
      [email, username],
      async (error, results) => {
        if (error) {
          console.error('Database query error:', error);
          return res.status(500).send({
            message: 'Database error during user check.',
            error: error.message
          });
        }

        if (results.length > 0) {
          return res.status(409).send({
            message: 'This email or username is already in use!'
          });
        }

        try {
          // Hash password
          const hashedPassword = await bcrypt.hash(password, 10);

          // Insert new user
          connection.query(
            'INSERT INTO users (username, email, password, dob, university, graduation_year) VALUES (?, ?, ?, ?, ?, ?)',
            [username, email, hashedPassword, dob, university, graduationYear],
            (error, results) => {
              if (error) {
                console.error('User insertion error:', error);
                return res.status(500).send({
                  message: 'Error creating user account.',
                  error: error.message
                });
              }

              // Create session
              req.session.loggedin = true;
              req.session.username = username;
              req.session.userId = results.insertId;

              // Save session before responding
              req.session.save(err => {
                if (err) {
                  console.error('Session save error:', err);
                }

                console.log('Session created:', req.sessionID);

                return res.status(201).send({
                  message: 'User registered successfully!',
                  userId: results.insertId,
                  username: username,
                  sessionID: req.sessionID
                });
              });
            }
          );
        } catch (hashError) {
          console.error('Password hashing error:', hashError);
          return res.status(500).send({
            message: 'Error processing password.',
            error: hashError.message
          });
        }
      }
    );
  } catch (error) {
    console.error('Sign-up error:', error);
    return res.status(500).send({
      message: 'Server error occurred during registration.',
      error: error.message
    });
  }
});

// 2. Login endpoint with improved error handling
app.post('/login', (req, res) => {
  try {
    console.log('Received login request:', req.body);
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).send({
        message: 'Email and password are required!'
      });
    }

    connection.query(
      'SELECT * FROM users WHERE email = ?',
      [email],
      async (error, results) => {
        if (error) {
          console.error('Database query error:', error);
          return res.status(500).send({
            message: 'Database error during login.',
            error: error.message
          });
        }

        if (results.length === 0) {
          return res.status(401).send({
            message: 'Invalid email or password!'
          });
        }

        try {
          // Compare passwords
          const match = await bcrypt.compare(password, results[0].password);

          if (!match) {
            return res.status(401).send({
              message: 'Invalid email or password!'
            });
          }

          // Set session
          req.session.loggedin = true;
          req.session.username = results[0].username;
          req.session.userId = results[0].id;

          // Save session before responding
          req.session.save(err => {
            if (err) {
              console.error('Session save error:', err);
            }

            console.log('Login successful, session created:', req.sessionID);

            return res.status(200).send({
              message: 'Login successful!',
              userId: results[0].id,
              username: results[0].username,
              sessionID: req.sessionID
            });
          });
        } catch (compareError) {
          console.error('Password comparison error:', compareError);
          return res.status(500).send({
            message: 'Error verifying password.',
            error: compareError.message
          });
        }
      }
    );
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).send({
      message: 'Server error occurred during login.',
      error: error.message
    });
  }
});

// 3. Set username endpoint
app.post('/set-username', (req, res) => {
  console.log('Set username request, session:', req.session);

  if (!req.session.loggedin) {
    return res.status(401).send({
      message: 'Please login to access this feature!'
    });
  }

  const { username } = req.body;

  if (!username) {
    return res.status(400).send({
      message: 'Username is required!'
    });
  }

  connection.query(
    'UPDATE users SET username = ? WHERE id = ?',
    [username, req.session.userId],
    (error, results) => {
      if (error) {
        console.error('Username update error:', error);
        if (error.code === 'ER_DUP_ENTRY') {
          return res.status(409).send({
            message: 'Username already taken!'
          });
        }
        return res.status(500).send({
          message: 'Error updating username.',
          error: error.message
        });
      }

      req.session.username = username;

      // Save session before responding
      req.session.save(err => {
        if (err) {
          console.error('Session save error:', err);
        }

        return res.status(200).send({
          message: 'Username updated successfully!',
          username: username
        });
      });
    }
  );
});

// 4. Logout endpoint
app.get('/logout', (req, res) => {
  console.log('Logout request, session:', req.session);

  req.session.destroy((err) => {
    if (err) {
      console.error('Logout error:', err);
      return res.status(500).send({
        message: 'Error during logout',
        error: err.message
      });
    }
    res.clearCookie('connect.sid');
    return res.status(200).send({
      message: 'Logged out successfully!'
    });
  });
});

// 5. Get user profile endpoint
app.get('/profile', (req, res) => {
  console.log('Profile fetch request, session:', req.session);

  // Check if user is logged in
  if (!req.session.loggedin || !req.session.userId) {
    return res.status(401).send({
      message: 'You must be logged in to access this resource'
    });
  }

  // Query the database for user info
  connection.query(
    'SELECT id, username, email, university, graduation_year, dob FROM users WHERE id = ?',
    [req.session.userId],
    (error, results) => {
      if (error) {
        console.error('Profile fetch error:', error);
        return res.status(500).send({
          message: 'Error fetching profile data',
          error: error.message
        });
      }

      if (results.length === 0) {
        return res.status(404).send({
          message: 'User not found'
        });
      }

      // Return user data (excluding password)
      return res.status(200).send(results[0]);
    }
  );
});

// 6. Update user profile endpoint
// 6. Update user profile endpoint with email/password authentication
app.put('/profile', async (req, res) => {
  console.log('Update profile request received');

  const { email, password, username, university, graduationYear, newPassword } = req.body;

  // Validate email and password are provided
  if (!email || !password) {
    return res.status(400).send({
      message: 'Email and password are required for authentication'
    });
  }

  try {
    // First authenticate the user with email and password
    connection.query(
      'SELECT * FROM users WHERE email = ?',
      [email],
      async (error, results) => {
        if (error) {
          console.error('Database query error:', error);
          return res.status(500).send({
            message: 'Database error during authentication',
            error: error.message
          });
        }

        if (results.length === 0) {
          return res.status(401).send({
            message: 'Invalid email or password'
          });
        }

        const user = results[0];

        try {
          // Compare passwords
          const match = await bcrypt.compare(password, user.password);

          if (!match) {
            return res.status(401).send({
              message: 'Invalid email or password'
            });
          }

          // Authentication successful, now update profile

          // Prepare update fields
          const updateFields = {};
          const queryParams = [];

          if (username) {
            updateFields.username = '?';
            queryParams.push(username);
          }

          if (university) {
            updateFields.university = '?';
            queryParams.push(university);
          }

          if (graduationYear) {
            updateFields.graduation_year = '?';
            queryParams.push(graduationYear);
          }

          // Handle new password if provided
          if (newPassword) {
            const hashedPassword = await bcrypt.hash(newPassword, 10);
            updateFields.password = '?';
            queryParams.push(hashedPassword);
          }

          // If no fields to update
          if (Object.keys(updateFields).length === 0) {
            return res.status(400).send({
              message: 'No data provided for update'
            });
          }

          // Build SET part of query
          const setClause = Object.entries(updateFields)
            .map(([field, placeholder]) => `${field} = ${placeholder}`)
            .join(', ');

          // Add user ID as the last parameter
          queryParams.push(user.id);

          const query = `UPDATE users SET ${setClause} WHERE id = ?`;

          connection.query(query, queryParams, (error, results) => {
            if (error) {
              console.error('Profile update error:', error);
              if (error.code === 'ER_DUP_ENTRY') {
                return res.status(409).send({
                  message: 'Username already taken'
                });
              }
              return res.status(500).send({
                message: 'Error updating profile',
                error: error.message
              });
            }

            return res.status(200).send({
              message: 'Profile updated successfully'
            });
          });
        } catch (compareError) {
          console.error('Password comparison error:', compareError);
          return res.status(500).send({
            message: 'Error verifying password',
            error: compareError.message
          });
        }
      }
    );
  } catch (error) {
    console.error('Profile update error:', error);
    return res.status(500).send({
      message: 'Server error occurred during profile update',
      error: error.message
    });
  }
});
// Set port and start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});