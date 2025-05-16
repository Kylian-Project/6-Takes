-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Mar 09, 2025 at 12:36 PM
-- Server version: 8.0.41-0ubuntu0.24.04.1
-- PHP Version: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `6_takes`
--

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--
/*
CREATE TABLE `audit_log` (
  `id` int NOT NULL,
  `action_type` varchar(50) DEFAULT NULL,
  `affected_table` varchar(50) DEFAULT NULL,
  `action_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `performed_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
*/
-- --------------------------------------------------------

--
-- Table structure for table `cards`
--

CREATE TABLE `cards` (
  `card_number` int NOT NULL,
  `heads` int NOT NULL,
  `file_path` varchar(255) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Table structure for table `games`
--

CREATE TABLE `games` (
  `id` int NOT NULL,
  `id_lobby` int DEFAULT NULL,
  `id_winner` int DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'in_progress',
  `started_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` timestamp NULL DEFAULT NULL,
  `final_global_score` json DEFAULT NULL,
  `current_round` int DEFAULT '1',
  `current_status` json NOT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `game_players`
--

CREATE TABLE `game_players` (
  `id_game` int NOT NULL,
  `id_player` int NOT NULL,
  `score` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `icons`
--

CREATE TABLE `icons` (
  `id` int NOT NULL,
  `alt` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `leaderboard`
-- (See below for the actual view)
--
CREATE TABLE `leaderboard` (
`username` varchar(255)
,`score` int
,`total_played` int
,`total_won` int
);

-- --------------------------------------------------------

--
-- Table structure for table `lobbies`
--

CREATE TABLE `lobbies` (
  `id` int NOT NULL,
  `id_creator` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `state` enum('PUBLIC','PRIVATE') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `lobbies`
--

INSERT INTO `lobbies` (`id`, `id_creator`, `name`, `state`) VALUES
(1, 6, 'Lobby Alpha', 'PUBLIC'),
(2, 35, 'Lobby Beta', 'PRIVATE'),
(3, 9, 'Lobby Gamma', 'PUBLIC'),
(4, 38, 'Lobby Delta', 'PRIVATE'),
(5, 12, 'Lobby Omega', 'PUBLIC'),
(6, 44, 'Lobby Zeta', 'PRIVATE'),
(7, 34, 'Lobby Sigma', 'PUBLIC'),
(8, 40, 'Lobby Epsilon', 'PRIVATE'),
(9, 45, 'Lobby Kappa', 'PUBLIC'),
(10, 4, 'Lobby Lambda', 'PRIVATE');

-- --------------------------------------------------------

--
-- Table structure for table `lobby_parameters`
--

CREATE TABLE `lobby_parameters` (
  `id_lobby` int NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `nb_players` int NOT NULL DEFAULT '10',
  `nb_bots` int NOT NULL DEFAULT '0',
  `nb_cards` int NOT NULL DEFAULT '10',
  `max_points` int DEFAULT '66',
  `max_rounds` int DEFAULT NULL,
  `timer` int DEFAULT '30',
  `sound` int DEFAULT NULL,
  `card_theme` int DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `password_reset`
--

CREATE TABLE `password_reset` (
  `id` int NOT NULL,
  `id_player` int NOT NULL,
  `reset_token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `used` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `password_reset`
--

INSERT INTO `password_reset` (`id`, `id_player`, `reset_token`, `created_at`, `expires_at`, `used`) VALUES
(7, 7, '', '2025-03-09 11:27:41', '2025-03-30 17:53:53', 0),
(15, 15, '', '2025-03-09 11:27:41', '2025-04-29 06:11:29', 0);

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `id` int NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `first_login` tinyint(1) DEFAULT '1',
  `icon` int DEFAULT NULL,
  `score` int NOT NULL DEFAULT '0',
  `total_played` int NOT NULL DEFAULT '0',
  `total_won` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` int NOT NULL,
  `id_player` int NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expire_at` timestamp NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sounds`
--

CREATE TABLE `sounds` (
  `id` int NOT NULL,
  `alt` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Structure for view `leaderboard`
--
DROP TABLE IF EXISTS `leaderboard`;

CREATE VIEW `leaderboard`  AS SELECT `p`.`username` AS `username`, `p`.`score` AS `score`, `p`.`total_played` AS `total_played`, `p`.`total_won` AS `total_won` FROM `players` AS `p` ORDER BY `p`.`score` DESC ;

--
-- Indexes for dumped tables
--


--
-- Indexes for table `audit_log`
--
/*
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`);
*/
--
-- Indexes for table `cards`
--
ALTER TABLE `cards`
  ADD PRIMARY KEY (`card_number`),
  ADD UNIQUE KEY `card_number` (`card_number`);

--
-- Indexes for table `games`
--
ALTER TABLE `games`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `id_lobby` (`id_lobby`);

--
-- Indexes for table `game_players`
--
ALTER TABLE `game_players`
  ADD PRIMARY KEY (`id_game`,`id_player`),
  ADD KEY `id_player` (`id_player`);

--
-- Indexes for table `icons`
--
ALTER TABLE `icons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `file_path` (`file_path`);

--
-- Indexes for table `lobbies`
--
ALTER TABLE `lobbies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `id_creator` (`id_creator`);

--
-- Indexes for table `lobby_parameters`
--
ALTER TABLE `lobby_parameters`
  ADD PRIMARY KEY (`id_lobby`),
  ADD UNIQUE KEY `id_lobby` (`id_lobby`),
  ADD KEY `sound` (`sound`),
  ADD KEY `card_theme` (`card_theme`);

--
-- Indexes for table `password_reset`
--
ALTER TABLE `password_reset`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `id_player` (`id_player`),
  ADD KEY `reset_token` (`reset_token`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `players_index_0` (`username`),
  ADD KEY `players_index_1` (`email`),
  ADD KEY `icon` (`icon`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `sessions_index_0` (`id_player`);

--
-- Indexes for table `sounds`
--
ALTER TABLE `sounds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `file_path` (`file_path`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `card_themes`
--
ALTER TABLE `card_themes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `games`
--
ALTER TABLE `games`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `icons`
--
ALTER TABLE `icons`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lobbies`
--
ALTER TABLE `lobbies`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `lobby_parameters`
--
ALTER TABLE `lobby_parameters`
  MODIFY `id_lobby` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_reset`
--
ALTER TABLE `password_reset`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `sessions`
--
ALTER TABLE `sessions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sounds`
--
ALTER TABLE `sounds`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `games`
--
ALTER TABLE `games`
  ADD CONSTRAINT `games_ibfk_1` FOREIGN KEY (`id_lobby`) REFERENCES `lobbies` (`id`),
  add CONSTRAINT check_status CHECK (status IN ("in_progress", "pending", "finished"));

--
-- Constraints for table `game_players`
--
ALTER TABLE `game_players`
  ADD CONSTRAINT `game_players_ibfk_1` FOREIGN KEY (`id_game`) REFERENCES `games` (`id`),
  ADD CONSTRAINT `game_players_ibfk_2` FOREIGN KEY (`id_player`) REFERENCES `players` (`id`),
  ADD CONSTRAINT `game_players_ibfk_3` FOREIGN KEY (`id_game`) REFERENCES `games` (`id`),
  ADD CONSTRAINT `game_players_ibfk_4` FOREIGN KEY (`id_player`) REFERENCES `players` (`id`);

--
-- Constraints for table `lobbies`
--
ALTER TABLE `lobbies`
  ADD CONSTRAINT `lobbies_ibfk_1` FOREIGN KEY (`id_creator`) REFERENCES `players` (`id`);

--
-- Constraints for table `lobby_parameters`
--
ALTER TABLE `lobby_parameters`
  ADD CONSTRAINT `lobby_parameters_ibfk_1` FOREIGN KEY (`sound`) REFERENCES `sounds` (`id`),
  ADD CONSTRAINT `lobby_parameters_ibfk_2` FOREIGN KEY (`card_theme`) REFERENCES `card_themes` (`id`),
  ADD CONSTRAINT `lobby_parameters_ibfk_3` FOREIGN KEY (`id_lobby`) REFERENCES `lobbies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `password_reset`
--
ALTER TABLE `password_reset`
  ADD CONSTRAINT `password_reset_ibfk_1` FOREIGN KEY (`id_player`) REFERENCES `players` (`id`);

--
-- Constraints for table `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `players_ibfk_1` FOREIGN KEY (`icon`) REFERENCES `icons` (`id`);

--
-- Constraints for table `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`id_player`) REFERENCES `players` (`id`);

DELIMITER $$
--
-- Events
--
CREATE EVENT `delete_used_rows` ON SCHEDULE EVERY 10 MINUTE STARTS '2025-03-09 14:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM password_reset WHERE used = 1 
     OR expires_at < CURRENT_TIMESTAMP;
END$$


CREATE EVENT `delete_used_token` ON SCHEDULE EVERY 10 MINUTE  STARTS '2025-04-06 14:50:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
	DELETE FROM sessions WHERE expire_at < CURRENT_TIMESTAMP ;
	END$$

DELIMITER ;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


-- --------------------------------------------------------

--
-- Table structure for table `card_themes`
--
/*
CREATE TABLE `card_themes` (
  `id` int NOT NULL,
  `alt` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `card_themes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `file_path` (`file_path`);

*/
-- --------------------------------------------------------

--
