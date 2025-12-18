-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Дек 18 2025 г., 18:38
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `pharmacy_ais_kr`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `RecalculateOrderTotal` (IN `p_order_id` INT)   BEGIN
   DECLARE v_total DECIMAL(10,2);
 
   SELECT SUM(pi.quantity * m.base_price)
   INTO v_total
   FROM `order` o
   JOIN prescription pr     ON o.prescription_id = pr.prescription_id
   JOIN prescriptionitem pi ON pr.prescription_id = pi.prescription_id
   JOIN medicine m          ON m.medicine_id = pi.medicine_id
   WHERE o.order_id = p_order_id;
 
   UPDATE `order`
   SET total_price = IFNULL(v_total, 0.00)
   WHERE order_id = p_order_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ReserveComponentsForOrder` (IN `p_order_id` INT)   BEGIN
   UPDATE stock s
   JOIN medicinecomposition mc ON s.component_id = mc.component_id
   JOIN prescriptionitem pi    ON mc.medicine_id = pi.medicine_id
   JOIN prescription pr        ON pi.prescription_id = pr.prescription_id
   JOIN `order` o              ON o.prescription_id = pr.prescription_id
   SET s.quantity = s.quantity - (mc.quantity * pi.quantity)
   WHERE o.order_id = p_order_id 
     AND s.quantity >= (mc.quantity * pi.quantity); -- Захист від від'ємних значень
END$$

--
-- Функции
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalculateMedicineCost` (`p_medicine_id` INT) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
   DECLARE v_total DECIMAL(10,2);
 
   SELECT SUM(mc.quantity * c.price_per_unit)
   INTO v_total
   FROM medicinecomposition mc
   JOIN component c ON mc.component_id = c.component_id
   WHERE mc.medicine_id = p_medicine_id;
 
   RETURN IFNULL(v_total, 0.00);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `component`
--

CREATE TABLE `component` (
  `component_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `price_per_unit` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `component`
--

INSERT INTO `component` (`component_id`, `name`, `unit`, `price_per_unit`) VALUES
(1, 'Парацетамол', 'мг', 0.05),
(2, 'Ібупрофен', 'мг', 0.07),
(3, 'Вода очищена', 'мл', 0.01),
(4, 'Спирт етиловий', 'мл', 0.03),
(5, 'Ментол', 'мг', 0.10);

-- --------------------------------------------------------

--
-- Структура таблицы `doctor`
--

CREATE TABLE `doctor` (
  `doctor_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `specialty` varchar(100) DEFAULT NULL,
  `license_number` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `doctor`
--

INSERT INTO `doctor` (`doctor_id`, `full_name`, `specialty`, `license_number`) VALUES
(1, 'Іваненко Олег Петрович', 'Терапевт', 'LIC-001'),
(2, 'Ковальчук Марія Сергіївна', 'Педіатр', 'LIC-002'),
(3, 'Шевченко Андрій Миколайович', 'Хірург', 'LIC-003');

-- --------------------------------------------------------

--
-- Структура таблицы `medicine`
--

CREATE TABLE `medicine` (
  `medicine_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` enum('готовий','виготовлюваний') NOT NULL,
  `form` varchar(50) NOT NULL,
  `application_type` varchar(50) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `base_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `medicine`
--

INSERT INTO `medicine` (`medicine_id`, `name`, `type`, `form`, `application_type`, `category`, `base_price`) VALUES
(1, 'Парацетамол таблетки', 'готовий', 'таблетки', 'внутрішнє', 'жарознижувальні', 35.00),
(2, 'Ібупрофен сироп', 'готовий', 'сироп', 'внутрішнє', 'протизапальні', 60.00),
(3, 'Мікстура від кашлю', 'виготовлюваний', 'мікстура', 'внутрішнє', 'протикашльові', 80.00),
(4, 'Мазь ментолова', 'виготовлюваний', 'мазь', 'зовнішнє', 'знеболювальні', 50.00);

-- --------------------------------------------------------

--
-- Структура таблицы `medicinecomposition`
--

CREATE TABLE `medicinecomposition` (
  `medicine_id` int(11) NOT NULL,
  `component_id` int(11) NOT NULL,
  `quantity` decimal(10,3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `medicinecomposition`
--

INSERT INTO `medicinecomposition` (`medicine_id`, `component_id`, `quantity`) VALUES
(3, 1, 500.000),
(3, 3, 200.000),
(3, 4, 50.000),
(4, 4, 30.000),
(4, 5, 100.000);

-- --------------------------------------------------------

--
-- Структура таблицы `order`
--

CREATE TABLE `order` (
  `order_id` int(11) NOT NULL,
  `prescription_id` int(11) NOT NULL,
  `order_date` datetime NOT NULL,
  `estimated_ready_time` datetime DEFAULT NULL,
  `ready_date` datetime DEFAULT NULL,
  `pickup_date` datetime DEFAULT NULL,
  `status` enum('waiting_components','in_production','ready','issued','cancelled') NOT NULL DEFAULT 'waiting_components',
  `total_price` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `order`
--

INSERT INTO `order` (`order_id`, `prescription_id`, `order_date`, `estimated_ready_time`, `ready_date`, `pickup_date`, `status`, `total_price`) VALUES
(1, 1, '2025-12-01 10:00:00', '2025-12-11 15:32:23', '2025-12-01 12:10:00', NULL, '', 70.00),
(2, 2, '2025-12-02 11:00:00', '2025-12-02 14:00:00', NULL, NULL, 'waiting_components', 80.00),
(3, 3, '2025-12-03 09:30:00', '2025-12-03 11:30:00', '2025-12-03 11:40:00', '2025-12-03 12:00:00', 'issued', 50.00),
(4, 4, '2025-12-04 15:00:00', '2025-12-04 16:30:00', NULL, NULL, 'in_production', 60.00);

--
-- Триггеры `order`
--
DELIMITER $$
CREATE TRIGGER `trg_Order_StartProduction` AFTER UPDATE ON `order` FOR EACH ROW BEGIN
   IF NEW.status = 'in_production' AND OLD.status <> 'in_production' THEN
       CALL ReserveComponentsForOrder(NEW.order_id);
   END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_Order_StatusHistory` AFTER UPDATE ON `order` FOR EACH ROW BEGIN
   IF NEW.status <> OLD.status THEN
        INSERT INTO OrderStatusHistory (order_id, status, changed_at, comment)
        VALUES (NEW.order_id, NEW.status, NOW(), NULL);
   END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `orderstatushistory`
--

CREATE TABLE `orderstatushistory` (
  `status_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `changed_at` datetime NOT NULL,
  `comment` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `orderstatushistory`
--

INSERT INTO `orderstatushistory` (`status_id`, `order_id`, `status`, `changed_at`, `comment`) VALUES
(1, 1, '', '2025-12-18 13:30:10', NULL);

-- --------------------------------------------------------

--
-- Структура таблицы `patient`
--

CREATE TABLE `patient` (
  `patient_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `birth_date` date DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `patient`
--

INSERT INTO `patient` (`patient_id`, `full_name`, `birth_date`, `phone`, `address`) VALUES
(1, 'Петренко Ірина Василівна', '1990-05-12', '0971112233', 'м. Київ'),
(2, 'Мельник Олександр Ігорович', '1985-11-20', '0502223344', 'м. Львів'),
(3, 'Савчук Наталія Петрівна', '2001-03-08', '0933334455', 'м. Вінниця'),
(4, 'Кравченко Денис Сергійович', '1978-07-01', '0664445566', 'м. Харків');

-- --------------------------------------------------------

--
-- Структура таблицы `prescription`
--

CREATE TABLE `prescription` (
  `prescription_id` int(11) NOT NULL,
  `doctor_id` int(11) DEFAULT NULL,
  `patient_id` int(11) DEFAULT NULL,
  `diagnosis` text DEFAULT NULL,
  `usage_instructions` text DEFAULT NULL,
  `created_at` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `prescription`
--

INSERT INTO `prescription` (`prescription_id`, `doctor_id`, `patient_id`, `diagnosis`, `usage_instructions`, `created_at`) VALUES
(1, 1, 1, 'ГРВІ', 'Приймати 2 рази на день', '2025-12-01'),
(2, 2, 2, 'Кашель', 'По 1 ложці 3 рази на день', '2025-12-02'),
(3, 1, 3, 'Біль у мʼязах', 'Наносити 2 рази на день', '2025-12-03'),
(4, 3, 4, 'Запалення', 'Згідно рекомендацій лікаря', '2025-12-04');

-- --------------------------------------------------------

--
-- Структура таблицы `prescriptionitem`
--

CREATE TABLE `prescriptionitem` (
  `prescription_id` int(11) NOT NULL,
  `medicine_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `prescriptionitem`
--

INSERT INTO `prescriptionitem` (`prescription_id`, `medicine_id`, `quantity`) VALUES
(1, 1, 2),
(2, 3, 1),
(3, 4, 1),
(4, 2, 1);

-- --------------------------------------------------------

--
-- Структура таблицы `stock`
--

CREATE TABLE `stock` (
  `component_id` int(11) NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `critical_level` decimal(10,3) NOT NULL,
  `expiration_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `stock`
--

INSERT INTO `stock` (`component_id`, `quantity`, `critical_level`, `expiration_date`) VALUES
(1, 5000.000, 1000.000, '2026-12-31'),
(2, 3000.000, 800.000, '2026-10-01'),
(3, 2000.000, 500.000, '2026-05-20'),
(4, 510.000, 700.000, '2025-11-01'),
(5, 50.000, 200.000, '2025-09-15');

--
-- Триггеры `stock`
--
DELIMITER $$
CREATE TRIGGER `trg_Stock_CriticalLevel` AFTER UPDATE ON `stock` FOR EACH ROW BEGIN
   IF NEW.quantity <= NEW.critical_level THEN
       SIGNAL SQLSTATE '01000'
           SET MESSAGE_TEXT = 'Увага: кількість компонента досягла критичного рівня';
   END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `technology`
--

CREATE TABLE `technology` (
  `technology_id` int(11) NOT NULL,
  `medicine_id` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `prep_time_minutes` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `technology`
--

INSERT INTO `technology` (`technology_id`, `medicine_id`, `description`, `prep_time_minutes`) VALUES
(1, 3, 'Змішування компонентів з подальшим відстоюванням і фільтрацією', 60),
(2, 4, 'Змішування компонентів до однорідної маси', 45);

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `component`
--
ALTER TABLE `component`
  ADD PRIMARY KEY (`component_id`),
  ADD UNIQUE KEY `uq_component_name` (`name`);

--
-- Индексы таблицы `doctor`
--
ALTER TABLE `doctor`
  ADD PRIMARY KEY (`doctor_id`),
  ADD UNIQUE KEY `license_number` (`license_number`);

--
-- Индексы таблицы `medicine`
--
ALTER TABLE `medicine`
  ADD PRIMARY KEY (`medicine_id`),
  ADD UNIQUE KEY `uq_medicine_name` (`name`);

--
-- Индексы таблицы `medicinecomposition`
--
ALTER TABLE `medicinecomposition`
  ADD PRIMARY KEY (`medicine_id`,`component_id`),
  ADD KEY `fk_mc_component` (`component_id`);

--
-- Индексы таблицы `order`
--
ALTER TABLE `order`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `uq_order_prescription` (`prescription_id`),
  ADD KEY `idx_order_status` (`status`),
  ADD KEY `idx_order_ready_time` (`estimated_ready_time`);

--
-- Индексы таблицы `orderstatushistory`
--
ALTER TABLE `orderstatushistory`
  ADD PRIMARY KEY (`status_id`),
  ADD KEY `idx_osh_order` (`order_id`),
  ADD KEY `idx_osh_changed_at` (`changed_at`);

--
-- Индексы таблицы `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`patient_id`);

--
-- Индексы таблицы `prescription`
--
ALTER TABLE `prescription`
  ADD PRIMARY KEY (`prescription_id`),
  ADD KEY `fk_presc_doctor` (`doctor_id`),
  ADD KEY `fk_presc_patient` (`patient_id`);

--
-- Индексы таблицы `prescriptionitem`
--
ALTER TABLE `prescriptionitem`
  ADD PRIMARY KEY (`prescription_id`,`medicine_id`),
  ADD KEY `fk_pi_medicine` (`medicine_id`);

--
-- Индексы таблицы `stock`
--
ALTER TABLE `stock`
  ADD PRIMARY KEY (`component_id`);

--
-- Индексы таблицы `technology`
--
ALTER TABLE `technology`
  ADD PRIMARY KEY (`technology_id`),
  ADD UNIQUE KEY `uq_technology_medicine` (`medicine_id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `component`
--
ALTER TABLE `component`
  MODIFY `component_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `doctor`
--
ALTER TABLE `doctor`
  MODIFY `doctor_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `medicine`
--
ALTER TABLE `medicine`
  MODIFY `medicine_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `order`
--
ALTER TABLE `order`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `orderstatushistory`
--
ALTER TABLE `orderstatushistory`
  MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT для таблицы `patient`
--
ALTER TABLE `patient`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `prescription`
--
ALTER TABLE `prescription`
  MODIFY `prescription_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `technology`
--
ALTER TABLE `technology`
  MODIFY `technology_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `medicinecomposition`
--
ALTER TABLE `medicinecomposition`
  ADD CONSTRAINT `fk_mc_component` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_mc_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicine` (`medicine_id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `order`
--
ALTER TABLE `order`
  ADD CONSTRAINT `fk_order_prescription` FOREIGN KEY (`prescription_id`) REFERENCES `prescription` (`prescription_id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `orderstatushistory`
--
ALTER TABLE `orderstatushistory`
  ADD CONSTRAINT `fk_osh_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `prescription`
--
ALTER TABLE `prescription`
  ADD CONSTRAINT `fk_presc_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctor` (`doctor_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_presc_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `prescriptionitem`
--
ALTER TABLE `prescriptionitem`
  ADD CONSTRAINT `fk_pi_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicine` (`medicine_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pi_prescription` FOREIGN KEY (`prescription_id`) REFERENCES `prescription` (`prescription_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `stock`
--
ALTER TABLE `stock`
  ADD CONSTRAINT `fk_stock_component` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `technology`
--
ALTER TABLE `technology`
  ADD CONSTRAINT `fk_tech_medicine` FOREIGN KEY (`medicine_id`) REFERENCES `medicine` (`medicine_id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
