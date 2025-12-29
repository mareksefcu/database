-- Database schema for cloud application homework
-- Course: Architektura cloudových aplikací

-- Create database
CREATE DATABASE cloud_app_db;

-- Use database
USE cloud_app_db;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_roles_name ON roles(name);
CREATE INDEX idx_permissions_name ON permissions(name);

-- Roles table
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- User roles junction table
CREATE TABLE user_roles (
    user_id INT,
    role_id INT,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- Permissions table
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Role permissions junction table
CREATE TABLE role_permissions (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- Sample data
INSERT INTO roles (name, description) VALUES ('admin', 'Administrator role'), ('user', 'Regular user role');
INSERT INTO permissions (name, description) VALUES ('read', 'Read access'), ('write', 'Write access'), ('delete', 'Delete access');

-- Sample users
INSERT INTO users (username, email, password_hash) VALUES 
('admin_user', 'admin@example.com', '$2b$10$example.hash.for.admin'),
('regular_user', 'user@example.com', '$2b$10$example.hash.for.user'),
('john_doe', 'john@example.com', '$2b$10$example.hash.for.john');

-- Assign roles to users
INSERT INTO user_roles (user_id, role_id) VALUES 
(1, 1), -- admin_user is admin
(2, 2), -- regular_user is user
(3, 2); -- john_doe is user

-- Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id) VALUES 
(1, 1), (1, 2), (1, 3), -- admin has all permissions
(2, 1), (2, 2); -- user has read and write, no delete

-- View for user permissions
CREATE VIEW user_permissions AS
SELECT u.username, r.name AS role, p.name AS permission
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id;

-- Stored procedure to check if user has permission
DELIMITER //
CREATE PROCEDURE check_user_permission(IN user_username VARCHAR(50), IN perm_name VARCHAR(100))
BEGIN
    SELECT COUNT(*) > 0 AS has_permission
    FROM user_permissions
    WHERE username = user_username AND permission = perm_name;
END //
DELIMITER ;