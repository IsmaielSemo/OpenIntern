-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS openintern 
  DEFAULT CHARACTER SET utf8 
  COLLATE utf8_general_ci;

-- Select the database
USE openintern;

-- Create the users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  dob DATE NOT NULL,
  university VARCHAR(100) NOT NULL,
  graduation_year INT(4) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY unique_email (email),
  UNIQUE KEY unique_username (username)
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8 
  COLLATE=utf8_general_ci;

CREATE TABLE user_filters (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  location VARCHAR(255),
  salary_range DECIMAL(10,2),
  experience_level VARCHAR(50),
  duration INT,
  is_paid BOOLEAN,
  field VARCHAR(100),
  is_remote BOOLEAN,
  has_job_offer BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
