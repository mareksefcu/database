-- Database schema for cloud infrastructure simulation application
-- Course: Architektura cloudových aplikací

-- Create database
CREATE DATABASE cloud_infrastructure_db;

-- Use database
USE cloud_infrastructure_db;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Projects table (representing cloud projects/tenants)
CREATE TABLE projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    owner_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- User projects junction table
CREATE TABLE user_projects (
    user_id INT,
    project_id INT,
    role ENUM('owner', 'admin', 'member') DEFAULT 'member',
    PRIMARY KEY (user_id, project_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Virtual Machines table
CREATE TABLE virtual_machines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    instance_type VARCHAR(50) NOT NULL, -- e.g., t2.micro, m5.large
    status ENUM('running', 'stopped', 'terminated') DEFAULT 'stopped',
    region VARCHAR(50) NOT NULL,
    availability_zone VARCHAR(50),
    public_ip VARCHAR(15),
    private_ip VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE KEY unique_vm_name_project (name, project_id)
);

-- Storage volumes table
CREATE TABLE storage_volumes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    size_gb INT NOT NULL,
    volume_type ENUM('gp2', 'io1', 'st1', 'sc1') DEFAULT 'gp2',
    status ENUM('available', 'in-use', 'deleted') DEFAULT 'available',
    region VARCHAR(50) NOT NULL,
    availability_zone VARCHAR(50),
    attached_to_vm_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (attached_to_vm_id) REFERENCES virtual_machines(id) ON DELETE SET NULL,
    UNIQUE KEY unique_volume_name_project (name, project_id)
);

-- Networks table
CREATE TABLE networks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    cidr_block VARCHAR(18) NOT NULL, -- e.g., 10.0.0.0/16
    region VARCHAR(50) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE KEY unique_network_name_project (name, project_id)
);

-- Subnets table
CREATE TABLE subnets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    network_id INT NOT NULL,
    cidr_block VARCHAR(18) NOT NULL, -- e.g., 10.0.1.0/24
    availability_zone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE,
    UNIQUE KEY unique_subnet_name_network (name, network_id)
);

-- Security Groups table
CREATE TABLE security_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE KEY unique_sg_name_project (name, project_id)
);

-- Security Group Rules table
CREATE TABLE security_group_rules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    security_group_id INT NOT NULL,
    type ENUM('ingress', 'egress') NOT NULL,
    protocol VARCHAR(10) NOT NULL, -- tcp, udp, icmp, -1 (all)
    from_port INT,
    to_port INT,
    cidr_block VARCHAR(18),
    source_security_group_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (security_group_id) REFERENCES security_groups(id) ON DELETE CASCADE,
    FOREIGN KEY (source_security_group_id) REFERENCES security_groups(id) ON DELETE CASCADE
);

-- Load Balancers table
CREATE TABLE load_balancers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    type ENUM('application', 'network') DEFAULT 'application',
    scheme ENUM('internet-facing', 'internal') DEFAULT 'internet-facing',
    region VARCHAR(50) NOT NULL,
    dns_name VARCHAR(255),
    status ENUM('active', 'provisioning', 'failed') DEFAULT 'provisioning',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    UNIQUE KEY unique_lb_name_project (name, project_id)
);

-- Load Balancer Listeners table
CREATE TABLE load_balancer_listeners (
    id INT AUTO_INCREMENT PRIMARY KEY,
    load_balancer_id INT NOT NULL,
    protocol VARCHAR(10) NOT NULL, -- HTTP, HTTPS, TCP, UDP
    port INT NOT NULL,
    target_group_id INT,
    ssl_certificate_arn VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (load_balancer_id) REFERENCES load_balancers(id) ON DELETE CASCADE
);

-- Target Groups table
CREATE TABLE target_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    project_id INT NOT NULL,
    protocol VARCHAR(10) NOT NULL,
    port INT NOT NULL,
    vpc_id INT, -- references networks table
    health_check_path VARCHAR(255) DEFAULT '/',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (vpc_id) REFERENCES networks(id) ON DELETE SET NULL,
    UNIQUE KEY unique_tg_name_project (name, project_id)
);

-- VM Target Group junction table
CREATE TABLE vm_target_groups (
    vm_id INT,
    target_group_id INT,
    PRIMARY KEY (vm_id, target_group_id),
    FOREIGN KEY (vm_id) REFERENCES virtual_machines(id) ON DELETE CASCADE,
    FOREIGN KEY (target_group_id) REFERENCES target_groups(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_vms_project ON virtual_machines(project_id);
CREATE INDEX idx_vms_status ON virtual_machines(status);
CREATE INDEX idx_volumes_project ON storage_volumes(project_id);
CREATE INDEX idx_volumes_attached ON storage_volumes(attached_to_vm_id);
CREATE INDEX idx_networks_project ON networks(project_id);
CREATE INDEX idx_subnets_network ON subnets(network_id);
CREATE INDEX idx_sg_project ON security_groups(project_id);
CREATE INDEX idx_sg_rules_sg ON security_group_rules(security_group_id);
CREATE INDEX idx_lb_project ON load_balancers(project_id);
CREATE INDEX idx_lb_listeners_lb ON load_balancer_listeners(load_balancer_id);
CREATE INDEX idx_tg_project ON target_groups(project_id);

-- Sample data
INSERT INTO users (username, email, password_hash) VALUES
('admin', 'admin@cloud.com', '$2b$10$example.hash.for.admin'),
('user1', 'user1@cloud.com', '$2b$10$example.hash.for.user1'),
('user2', 'user2@cloud.com', '$2b$10$example.hash.for.user2');

INSERT INTO projects (name, description, owner_id) VALUES
('project-alpha', 'Development project', 1),
('project-beta', 'Production project', 2);

INSERT INTO user_projects (user_id, project_id, role) VALUES
(1, 1, 'owner'), (1, 2, 'admin'),
(2, 1, 'member'), (2, 2, 'owner'),
(3, 1, 'member');

INSERT INTO networks (name, project_id, cidr_block, region, is_default) VALUES
('vpc-alpha', 1, '10.0.0.0/16', 'us-east-1', TRUE),
('vpc-beta', 2, '10.1.0.0/16', 'us-west-2', TRUE);

INSERT INTO subnets (name, network_id, cidr_block, availability_zone) VALUES
('subnet-alpha-1a', 1, '10.0.1.0/24', 'us-east-1a'),
('subnet-alpha-1b', 1, '10.0.2.0/24', 'us-east-1b'),
('subnet-beta-2a', 2, '10.1.1.0/24', 'us-west-2a');

INSERT INTO virtual_machines (name, project_id, instance_type, status, region, availability_zone, private_ip) VALUES
('web-server-1', 1, 't2.micro', 'running', 'us-east-1', 'us-east-1a', '10.0.1.10'),
('db-server-1', 1, 't2.small', 'running', 'us-east-1', 'us-east-1b', '10.0.2.20'),
('app-server-1', 2, 'm5.large', 'stopped', 'us-west-2', 'us-west-2a', '10.1.1.30');

INSERT INTO storage_volumes (name, project_id, size_gb, volume_type, status, region, availability_zone, attached_to_vm_id) VALUES
('vol-web-1', 1, 20, 'gp2', 'in-use', 'us-east-1', 'us-east-1a', 1),
('vol-db-1', 1, 100, 'io1', 'in-use', 'us-east-1', 'us-east-1b', 2),
('vol-app-1', 2, 50, 'gp2', 'available', 'us-west-2', 'us-west-2a', NULL);

INSERT INTO security_groups (name, project_id, description) VALUES
('web-sg', 1, 'Security group for web servers'),
('db-sg', 1, 'Security group for database servers'),
('app-sg', 2, 'Security group for application servers');

INSERT INTO security_group_rules (security_group_id, type, protocol, from_port, to_port, cidr_block) VALUES
(1, 'ingress', 'tcp', 80, 80, '0.0.0.0/0'),
(1, 'ingress', 'tcp', 443, 443, '0.0.0.0/0'),
(2, 'ingress', 'tcp', 3306, 3306, '10.0.0.0/16'),
(3, 'ingress', 'tcp', 8080, 8080, '0.0.0.0/0');

INSERT INTO target_groups (name, project_id, protocol, port, vpc_id) VALUES
('web-targets', 1, 'HTTP', 80, 1),
('app-targets', 2, 'HTTP', 8080, 2);

INSERT INTO load_balancers (name, project_id, type, scheme, region, dns_name, status) VALUES
('web-lb', 1, 'application', 'internet-facing', 'us-east-1', 'web-lb-123456789.us-east-1.elb.amazonaws.com', 'active'),
('app-lb', 2, 'application', 'internal', 'us-west-2', 'app-lb-987654321.us-west-2.elb.amazonaws.com', 'active');

INSERT INTO load_balancer_listeners (load_balancer_id, protocol, port, target_group_id) VALUES
(1, 'HTTP', 80, 1),
(2, 'HTTP', 8080, 2);

INSERT INTO vm_target_groups (vm_id, target_group_id) VALUES
(1, 1), (3, 2);

-- Views for common queries
CREATE VIEW project_resources AS
SELECT p.name AS project_name, p.description,
       COUNT(DISTINCT vm.id) AS vm_count,
       COUNT(DISTINCT sv.id) AS volume_count,
       COUNT(DISTINCT n.id) AS network_count,
       COUNT(DISTINCT lb.id) AS lb_count
FROM projects p
LEFT JOIN virtual_machines vm ON p.id = vm.project_id
LEFT JOIN storage_volumes sv ON p.id = sv.project_id
LEFT JOIN networks n ON p.id = n.project_id
LEFT JOIN load_balancers lb ON p.id = lb.project_id
GROUP BY p.id, p.name, p.description;

CREATE VIEW vm_details AS
SELECT vm.name AS vm_name, vm.instance_type, vm.status, vm.region, vm.availability_zone,
       vm.public_ip, vm.private_ip, p.name AS project_name,
       GROUP_CONCAT(sv.name) AS attached_volumes
FROM virtual_machines vm
JOIN projects p ON vm.project_id = p.id
LEFT JOIN storage_volumes sv ON vm.id = sv.attached_to_vm_id
GROUP BY vm.id, vm.name, vm.instance_type, vm.status, vm.region, vm.availability_zone,
         vm.public_ip, vm.private_ip, p.name;

-- Stored procedure to get project usage summary
DELIMITER //
CREATE PROCEDURE get_project_usage(IN project_name_param VARCHAR(100))
BEGIN
    SELECT pr.project_name, pr.vm_count, pr.volume_count, pr.network_count, pr.lb_count,
           SUM(vm.instance_type LIKE 't2.%') AS t2_instances,
           SUM(vm.instance_type LIKE 'm5.%') AS m5_instances,
           SUM(sv.size_gb) AS total_storage_gb
    FROM project_resources pr
    LEFT JOIN virtual_machines vm ON pr.project_name = (SELECT name FROM projects WHERE id = vm.project_id)
    LEFT JOIN storage_volumes sv ON pr.project_name = (SELECT name FROM projects WHERE id = sv.project_id)
    WHERE pr.project_name = project_name_param
    GROUP BY pr.project_name, pr.vm_count, pr.volume_count, pr.network_count, pr.lb_count;
END //
DELIMITER ;