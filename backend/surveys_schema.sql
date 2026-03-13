-- Smart Survey tables for EasyTech backend
-- Run this SQL on your MySQL database before using surveys.create

CREATE TABLE IF NOT EXISTS surveys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  project_name VARCHAR(255) NOT NULL,
  client_id INT NULL,
  client_email VARCHAR(255) NULL,
  floors JSON NULL,
  rooms JSON NULL,
  lighting_lines INT DEFAULT 0,
  switch_groups JSON NULL,
  ac_units INT DEFAULT 0,
  tv_units INT DEFAULT 0,
  curtains INT DEFAULT 0,
  curtain_meters DECIMAL(10, 2) DEFAULT 0,
  sensors JSON NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by INT NULL,
  INDEX idx_client_id (client_id),
  INDEX idx_created_at (created_at),
  INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
