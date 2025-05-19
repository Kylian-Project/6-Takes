<?php
$host = 'mysql-6takes.alwaysdata.net';
$dbname = '6takes_db';
$username = '6takes';
$password = '6Takes2025**';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Erreur de connexion : " . $e->getMessage());
}
