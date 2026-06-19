-- Database schema for Kasir Kopi Jo

CREATE DATABASE IF NOT EXISTS `kasir_kopijo`;
USE `kasir_kopijo`;

-- 1. Categories
CREATE TABLE IF NOT EXISTS `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Products
CREATE TABLE IF NOT EXISTS `products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `image` TEXT DEFAULT NULL,
    `type` VARCHAR(50) NOT NULL, -- 'kopi', 'bubuk kopi', 'makanan'
    `base_price` DECIMAL(10, 2) NOT NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Product Variants (especially for weight-based coffee beans / powders)
CREATE TABLE IF NOT EXISTS `product_variants` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_id` INT NOT NULL,
    `name` VARCHAR(255) NOT NULL, -- e.g., 'Regular', 'Large', '250g', '500g', '1kg'
    `price` DECIMAL(10, 2) NOT NULL,
    `stock` DECIMAL(10, 3) DEFAULT 0.000, -- decimal for weight in kg or count
    `unit` VARCHAR(20) DEFAULT 'pcs', -- 'gr', 'pcs', 'kg'
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Modifiers (e.g. Temperature options, Extra shots, etc.)
CREATE TABLE IF NOT EXISTS `modifiers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `modifier_group` VARCHAR(100) NOT NULL, -- e.g., 'Suhu', 'Ekstra'
    `name` VARCHAR(255) NOT NULL, -- e.g., 'Dingin', 'Panas', 'Oatmilk', 'Espresso Shot'
    `price_adjustment` DECIMAL(10, 2) DEFAULT 0.00,
    FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Transactions
CREATE TABLE IF NOT EXISTS `transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `transaction_code` VARCHAR(100) UNIQUE NOT NULL,
    `subtotal` DECIMAL(10, 2) NOT NULL,
    `discount` DECIMAL(10, 2) DEFAULT 0.00,
    `tax` DECIMAL(10, 2) DEFAULT 0.00,
    `total` DECIMAL(10, 2) NOT NULL,
    `payment_method` VARCHAR(50) NOT NULL, -- 'cash', 'qris', 'transfer'
    `amount_paid` DECIMAL(10, 2) NOT NULL,
    `change_amount` DECIMAL(10, 2) DEFAULT 0.00,
    `status` VARCHAR(50) DEFAULT 'paid', -- 'paid', 'canceled'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Transaction Items
CREATE TABLE IF NOT EXISTS `transaction_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `variant_id` INT DEFAULT NULL,
    `quantity` DECIMAL(10, 3) NOT NULL, -- supporting decimal quantity
    `unit_price` DECIMAL(10, 2) NOT NULL,
    `subtotal` DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`),
    FOREIGN KEY (`variant_id`) REFERENCES `product_variants`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Transaction Item Modifiers
CREATE TABLE IF NOT EXISTS `transaction_item_modifiers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_item_id` INT NOT NULL,
    `modifier_id` INT NOT NULL,
    `price_adjustment` DECIMAL(10, 2) DEFAULT 0.00,
    FOREIGN KEY (`transaction_item_id`) REFERENCES `transaction_items`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`modifier_id`) REFERENCES `modifiers`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Seed sample data
-- Insert Categories
INSERT INTO `categories` (`id`, `name`) VALUES
(1, 'Kopi'),
(2, 'Bubuk Kopi'),
(3, 'Makanan');

-- Insert Products
INSERT INTO `products` (`id`, `category_id`, `name`, `description`, `image`, `type`, `base_price`, `is_active`) VALUES
-- Kopi
(1, 1, 'Kopi Susu Gula Aren', 'Es Kopi Susu dengan Espresso Blend pilihan, Susu Segar, dan Gula Aren murni.', 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=300&auto=format&fit=crop', 'kopi', 15000.00, 1),
(2, 1, 'Americano', 'Espresso double shot dengan air mineral berkualitas tinggi, disajikan panas atau dingin.', 'https://images.unsplash.com/photo-1551046713-bc47f9987f0f?q=80&w=300&auto=format&fit=crop', 'kopi', 12000.00, 1),
(3, 1, 'Caramel Macchiato', 'Espresso, vanilla syrup, steamed milk, caramel sauce drizzle.', 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?q=80&w=300&auto=format&fit=crop', 'kopi', 22000.00, 1),

-- Bubuk Kopi
(4, 2, 'Arabica Gayo Clean Wash', 'Biji/Bubuk Kopi Arabika Gayo, proses wash, body medium, tingkat asam sedang. Cocok untuk manual brew.', 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=300&auto=format&fit=crop', 'bubuk kopi', 45000.00, 1),
(5, 2, 'Robusta Temanggung Espresso Blend', 'Biji/Bubuk Kopi Robusta Temanggung, body tebal, rasa cokelat kuat dan pahit mantap. Cocok untuk mesin espresso.', 'https://images.unsplash.com/photo-1606791402619-fc30ee02abe2?q=80&w=300&auto=format&fit=crop', 'bubuk kopi', 35000.00, 1),

-- Makanan
(6, 3, 'Croissant Plain', 'Butter croissant khas Perancis yang renyah dan gurih.', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=300&auto=format&fit=crop', 'makanan', 18000.00, 1),
(7, 3, 'Roti Bakar Cokelat Keju', 'Roti bakar tebal diisi cokelat premium dan taburan keju cheddar parut.', 'https://images.unsplash.com/photo-1584776296974-aa1efb5fa4f1?q=80&w=300&auto=format&fit=crop', 'makanan', 15000.00, 1);

-- Insert Product Variants
-- Each product has variants. Even if there's no major variant, we have a base/default variant that handles stock and price.
INSERT INTO `product_variants` (`id`, `product_id`, `name`, `price`, `stock`, `unit`) VALUES
-- Kopi Susu Gula Aren
(1, 1, 'Regular', 15000.00, 99.000, 'pcs'),
(2, 1, 'Large', 18000.00, 99.000, 'pcs'),
-- Americano
(3, 2, 'Regular', 12000.00, 99.000, 'pcs'),
(4, 2, 'Large', 15000.00, 99.000, 'pcs'),
-- Caramel Macchiato
(5, 3, 'Regular', 22000.00, 99.000, 'pcs'),
(6, 3, 'Large', 26000.00, 99.000, 'pcs'),

-- Arabica Gayo (Bubuk Kopi) - based on weight
(7, 4, '250 gram', 45000.00, 15.000, 'gr'),
(8, 4, '500 gram', 85000.00, 10.000, 'gr'),
(9, 4, '1 kg', 160000.00, 5.000, 'gr'),

-- Robusta Temanggung (Bubuk Kopi)
(10, 5, '250 gram', 35000.00, 20.000, 'gr'),
(11, 5, '500 gram', 65000.00, 12.000, 'gr'),
(12, 5, '1 kg', 120000.00, 6.000, 'gr'),

-- Croissant Plain
(13, 6, 'Default', 18000.00, 25.000, 'pcs'),
-- Roti Bakar Cokelat Keju
(14, 7, 'Default', 15000.00, 30.000, 'pcs');

-- Insert Modifiers
INSERT INTO `modifiers` (`id`, `category_id`, `modifier_group`, `name`, `price_adjustment`) VALUES
-- For Kopi Category (id: 1)
(1, 1, 'Suhu', 'Dingin', 0.00),
(2, 1, 'Suhu', 'Panas', 0.00),
(3, 1, 'Susu', 'Oatmilk', 6000.00),
(4, 1, 'Susu', 'Almond Milk', 8000.00),
(5, 1, 'Ekstra', 'Espresso Shot', 4000.00),
(6, 1, 'Ekstra', 'Caramel Syrup', 3000.00),
(7, 1, 'Ekstra', 'Hazelnut Syrup', 3000.00),

-- For Bubuk Kopi Category (id: 2)
(8, 2, 'Gilingan', 'Biji Kopi (Whole Beans)', 0.00),
(9, 2, 'Gilingan', 'Giling Kasar (Coarse)', 0.00),
(10, 2, 'Gilingan', 'Giling Sedang (Medium)', 0.00),
(11, 2, 'Gilingan', 'Giling Halus (Fine)', 0.00);
