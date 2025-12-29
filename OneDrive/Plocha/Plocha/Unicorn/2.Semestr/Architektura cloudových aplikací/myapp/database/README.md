# Database Homework for Architektura cloudových aplikací

This folder contains the database schema for the cloud application homework.

## Schema Overview

The database `cloud_app_db` includes tables for user management with roles and permissions.

### Tables

- **users**: Stores user information including username, email, and password hash.
- **roles**: Defines roles like admin and user.
- **user_roles**: Junction table linking users to roles.
- **permissions**: Defines permissions like read, write, delete.
- **role_permissions**: Junction table linking roles to permissions.

### Additional Features

- **Indexes**: Added on username, email, role name, and permission name for optimized queries.
- **Sample Data**: Includes sample users, role assignments, and permission assignments.
- **View**: `user_permissions` - A view to easily query user permissions.
- **Stored Procedure**: `check_user_permission` - Procedure to check if a user has a specific permission.

### Usage

To set up the database, run the `schema.sql` script in your MySQL or compatible database server.

This schema supports a basic RBAC (Role-Based Access Control) system suitable for cloud applications.