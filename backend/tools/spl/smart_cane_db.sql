-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : lun. 13 avr. 2026 à 11:14
-- Version du serveur : 5.7.24
-- Version de PHP : 8.3.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `smart_cane_db`
--

-- --------------------------------------------------------

--
-- Structure de la table `abonnement`
--

CREATE TABLE `abonnement` (
  `sim_de_la_canne` varchar(50) NOT NULL,
  `cin_utilisateur` varchar(20) NOT NULL,
  `type_d_abonnement` varchar(50) DEFAULT NULL,
  `date_de_debut` date NOT NULL,
  `date_de_fin` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure de la table `admin`
--

CREATE TABLE `admin` (
  `cin` varchar(20) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `mot_de_passe` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure de la table `canne`
--

CREATE TABLE `canne` (
  `sim_de_la_canne` varchar(50) NOT NULL,
  `version` varchar(50) DEFAULT NULL,
  `statut` enum('disponible','louee','vendue') DEFAULT 'disponible',
  `type` enum('location','abonnement') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure de la table `location`
--

CREATE TABLE `location` (
  `sim_de_la_canne` varchar(50) NOT NULL,
  `cin_utilisateur` varchar(20) NOT NULL,
  `date_de_location` date NOT NULL,
  `date_de_retour` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure de la table `staff`
--

CREATE TABLE `staff` (
  `cin` varchar(20) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `mot_de_passe` varchar(255) NOT NULL,
  `numero_de_telephone` varchar(20) DEFAULT NULL,
  `adresse` varchar(255) DEFAULT NULL,
  `role` enum('admin','staff') DEFAULT 'staff',
  `poste_periode_travail` enum('matin','soir') DEFAULT NULL,
  `cree_le` datetime DEFAULT CURRENT_TIMESTAMP,
  `mis_a_jour_le` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `admin_cin` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure de la table `utilisateur`
--

CREATE TABLE `utilisateur` (
  `cin` varchar(20) NOT NULL,
  `nom` varchar(100) NOT NULL,
  `age` int(11) DEFAULT NULL,
  `adresse` varchar(255) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `numero_de_telephone` varchar(20) DEFAULT NULL,
  `contact_familial` varchar(100) DEFAULT NULL,
  `etat_de_sante` text,
  `sim_de_la_canne` varchar(50) DEFAULT NULL,
  `cree_le` datetime DEFAULT CURRENT_TIMESTAMP,
  `mis_a_jour_le` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `abonnement`
--
ALTER TABLE `abonnement`
  ADD PRIMARY KEY (`sim_de_la_canne`,`cin_utilisateur`,`date_de_debut`),
  ADD KEY `cin_utilisateur` (`cin_utilisateur`),
  ADD KEY `idx_abonnement_date` (`date_de_debut`);

--
-- Index pour la table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`cin`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Index pour la table `canne`
--
ALTER TABLE `canne`
  ADD PRIMARY KEY (`sim_de_la_canne`),
  ADD KEY `idx_canne_statut` (`statut`),
  ADD KEY `idx_canne_type` (`type`);

--
-- Index pour la table `location`
--
ALTER TABLE `location`
  ADD PRIMARY KEY (`sim_de_la_canne`,`cin_utilisateur`,`date_de_location`),
  ADD KEY `cin_utilisateur` (`cin_utilisateur`),
  ADD KEY `idx_location_date` (`date_de_location`);

--
-- Index pour la table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`cin`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `admin_cin` (`admin_cin`);

--
-- Index pour la table `utilisateur`
--
ALTER TABLE `utilisateur`
  ADD PRIMARY KEY (`cin`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `abonnement`
--
ALTER TABLE `abonnement`
  ADD CONSTRAINT `abonnement_ibfk_1` FOREIGN KEY (`sim_de_la_canne`) REFERENCES `canne` (`sim_de_la_canne`),
  ADD CONSTRAINT `abonnement_ibfk_2` FOREIGN KEY (`cin_utilisateur`) REFERENCES `utilisateur` (`cin`);

--
-- Contraintes pour la table `location`
--
ALTER TABLE `location`
  ADD CONSTRAINT `location_ibfk_1` FOREIGN KEY (`sim_de_la_canne`) REFERENCES `canne` (`sim_de_la_canne`),
  ADD CONSTRAINT `location_ibfk_2` FOREIGN KEY (`cin_utilisateur`) REFERENCES `utilisateur` (`cin`);

--
-- Contraintes pour la table `staff`
--
ALTER TABLE `staff`
  ADD CONSTRAINT `staff_ibfk_1` FOREIGN KEY (`admin_cin`) REFERENCES `admin` (`cin`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
