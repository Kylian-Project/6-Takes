<?php
require 'config.php';

$type = $_POST['type'] ?? '';
$message = $_POST['message'] ?? '';
$filename = null;

// Enregistrement du fichier s’il y en a un
if (isset($_FILES['screenshot']) && $_FILES['screenshot']['error'] === UPLOAD_ERR_OK) {
    $uploadDir = 'uploads/';
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $filename = uniqid() . '_' . basename($_FILES['screenshot']['name']);
    $targetPath = $uploadDir . $filename;

    if (!move_uploaded_file($_FILES['screenshot']['tmp_name'], $targetPath)) {
        echo json_encode(['success' => false, 'error' => 'Upload failed']);
        exit;
    }
}

try {
    $stmt = $pdo->prepare("INSERT INTO feedback (type, message, screenshot) VALUES (?, ?, ?)");
    $stmt->execute([$type, $message, $filename]);

    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
