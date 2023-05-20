CREATE DATABASE Travel_Agency;
USE Travel_Agency;

-- DROP DATABASE IF EXISTS Travel_Agency;

CREATE TABLE Country (
	id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(56) NOT NULL,
    # ISO 3166-1 alpha-2 kod države za komunikaciju s ostalim uslugama izvan trvrtke
    iso_alpha_2 CHAR(2) NOT NULL UNIQUE
);

-- Čitavi objekt adrese koji se može referencirati
CREATE TABLE Address (
	id INT AUTO_INCREMENT PRIMARY KEY,
    country INT NOT NULL REFERENCES Country (id),
    locality VARCHAR (48) NOT NULL, # City, town, village, settlement
    street_1 VARCHAR(128) NOT NULL,
    street_2 VARCHAR(128) NOT NULL DEFAULT "",
    postal_code VARCHAR(16) NOT NULL
);

CREATE TABLE Hotel (
	id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT NOT NULL REFERENCES Address (id),
    title VARCHAR(64) NOT NULL
);

CREATE TABLE Customer (
	id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT NOT NULL REFERENCES Address (id),
    forename VARCHAR(48) NOT NULL,
    surname VARCHAR(48) NOT NULL,
    email VARCHAR(64) NOT NULL
);

CREATE TABLE Guide (
	id INT AUTO_INCREMENT PRIMARY KEY,
    forename VARCHAR(48),
    surname VARCHAR(48),
    email VARCHAR(64),
    phone VARCHAR(15),
    language VARCHAR(32)
);

CREATE TABLE Activity (
	id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT NOT NULL REFERENCES Address (id),
    title VARCHAR(64),
    description TEXT,
    start_time DATETIME,
    end_time DATETIME
);

CREATE TABLE Destination (
	id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT NOT NULL REFERENCES Address (id),
    title VARCHAR(64) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE Package (
	id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
	start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price_per_tourist NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Package_Destination (
	package_id INT NOT NULL REFERENCES Package (id) ON DELETE CASCADE,
    destination_id INT NOT NULL REFERENCES Destination (id) ON DELETE CASCADE
);

CREATE TABLE Package_Hotel (
	package_id INT NOT NULL REFERENCES Package (id) ON DELETE CASCADE,
    hotel_id INT NOT NULL REFERENCES Hotel (id) ON DELETE CASCADE
);

-- Alan Burić
CREATE TABLE Booking (
	id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customer (id) ON DELETE CASCADE,
    package_id INT NOT NULL REFERENCES Package (id) ON DELETE CASCADE,
    title VARCHAR(64),
    date DATETIME,
    total_cost NUMERIC(10, 2)
);

-- date DATE DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

CREATE TABLE Insurance (
	id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    description VARCHAR(256) DEFAULT "",
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Booking_Insurance (
	id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking (id) ON DELETE CASCADE,
    insurance_id INT NOT NULL REFERENCES Insurance (id) ON DELETE CASCADE
);

CREATE TABLE Special_Request (
	id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking (id) ON DELETE CASCADE,
    description VARCHAR(500)
);

CREATE TABLE Itinerary_Entry (
	id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL REFERENCES Package (id) ON DELETE CASCADE,
    day_number INT UNSIGNED NOT NULL,
    description TEXT NOT NULL,
    CHECK (day_number BETWEEN 0 AND 365)
);

CREATE TABLE Payment (
	id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking (id)  ON DELETE CASCADE,
    method ENUM('cash', 'check', 'credit', 'debit', 'redirect', 'transfer', 'voucher', 'wallet', 'other') NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    date DATETIME NOT NULL
);

CREATE TABLE Transport (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(64) NOT NULL, # Opisni naziv prijevoznog sredstva koji obično sadržava i vrstu prijevoznog sredstva
    description VARCHAR(256) DEFAULT "",
    capacity INT NOT NULL,
    departure DATETIME NOT NULL,
    arrival DATETIME NOT NULL,
    CHECK (departure <= arrival)
);

CREATE TABLE Review (
	id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customer (id) ON DELETE CASCADE,
    rating INT NOT NULL,
    comment TEXT,
    hotel_id INT DEFAULT NULL REFERENCES Hotel (id) ON DELETE CASCADE,
    transport_id INT DEFAULT NULL REFERENCES Transport (id) ON DELETE CASCADE,
    activity_id INT DEFAULT NULL REFERENCES Activity (id) ON DELETE CASCADE,
    guide_id INT DEFAULT NULL REFERENCES Guide (id) ON DELETE CASCADE,
    package_id INT DEFAULT NULL REFERENCES Package (id) ON DELETE CASCADE,
    CHECK (rating IN (1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5))
);

CREATE TABLE Employee (
	id INT AUTO_INCREMENT PRIMARY KEY,
    forename VARCHAR(48) NOT NULL,
    surname VARCHAR(48) NOT NULL,
    email VARCHAR(64) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    position VARCHAR(48)
);

CREATE TABLE Employee_Role_Type (
	id INT AUTO_INCREMENT PRIMARY KEY,
    role_description VARCHAR(256),
    role_name VARCHAR(48) NOT NULL
);

CREATE TABLE Employee_Role (
	employee_id INT NOT NULL REFERENCES Employee (id) ON DELETE CASCADE,
    role_type_id INT NOT NULL REFERENCES Employee_Role_Type (id) ON DELETE CASCADE
);