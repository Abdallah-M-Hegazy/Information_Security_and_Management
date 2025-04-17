CREATE DATABASE IF NOT EXISTS task2;
USE task2;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,         
    username VARCHAR(80) NOT NULL UNIQUE, 
    password VARCHAR(200) NOT NULL     
);

CREATE TABLE IF NOT EXISTS product (
    pid INT AUTO_INCREMENT PRIMARY KEY, 
    pname VARCHAR(80) NOT NULL,        
    description TEXT,                  
    price DECIMAL(10, 2) NOT NULL,     
    stock INT NOT NULL,               
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);