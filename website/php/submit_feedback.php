<?php
require 'config.php';

$type = $_POST['type'] ?? '';
$message = $_POST['message'] ?? '';
$screenshotData = null;

// Validation des données
if (empty($type) || empty($message)) {
    echo json_encode(['success' => false, 'error' => 'Type and message are required']);
    exit;
}

if (strlen($message) > 500) {
    echo json_encode(['success' => false, 'error' => 'Message is too long']);
    exit;
}

if (!in_array($type, ['bug', 'suggestion'])) {
    echo json_encode(['success' => false, 'error' => 'Invalid type']);
    exit;
}

// Clear les données pour éviter les injections SQL*
$message = strip_tags($message);
$type = htmlspecialchars($type, ENT_QUOTES, 'UTF-8');

// Enregistrement du fichier s’il y en a un
if (isset($_FILES['screenshot']) && $_FILES['screenshot']['error'] === UPLOAD_ERR_OK) {
    if ($_FILES['screenshot']['size'] <= 2 * 1024 * 1024) { // 2 Mo max
        $tmpName = $_FILES['screenshot']['tmp_name'];
        $mimeType = mime_content_type($tmpName);

        if (in_array($mimeType, ['image/jpeg', 'image/png'])) {
            // Compression de l'image
            if ($mimeType === 'image/jpeg') {
                // Charger l'image
                $image = imagecreatefromjpeg($tmpName);

                // Redimensionner l'image si nécessaire
                $width = imagesx($image);
                $height = imagesy($image);
                $max_width = 1024; // Limite de largeur
                $max_height = 1024; // Limite de hauteur

                if ($width > $max_width || $height > $max_height) {
                    $ratio = min($max_width / $width, $max_height / $height);
                    $new_width = round($width * $ratio);
                    $new_height = round($height * $ratio);

                    $resized_image = imagecreatetruecolor($new_width, $new_height);
                    imagecopyresampled($resized_image, $image, 0, 0, 0, 0, $new_width, $new_height, $width, $height);
                    imagedestroy($image); // Libère l'ancienne image
                    $image = $resized_image; // L'image redimensionnée
                }

                // Compression de l'image JPEG
                ob_start();
                imagejpeg($image, null, 75); // Compression à 75%
                $screenshotData = ob_get_clean();
                imagedestroy($image);
            } elseif ($mimeType === 'image/png') {
                // Charger l'image
                $image = imagecreatefrompng($tmpName);

                // Redimensionner l'image si nécessaire
                $width = imagesx($image);
                $height = imagesy($image);
                $max_width = 1024;
                $max_height = 1024;

                if ($width > $max_width || $height > $max_height) {
                    $ratio = min($max_width / $width, $max_height / $height);
                    $new_width = round($width * $ratio);
                    $new_height = round($height * $ratio);

                    $resized_image = imagecreatetruecolor($new_width, $new_height);
                    imagecopyresampled($resized_image, $image, 0, 0, 0, 0, $new_width, $new_height, $width, $height);
                    imagedestroy($image); // Libère l'ancienne image
                    $image = $resized_image; // L'image redimensionnée
                }

                // Compression PNG avec niveau 6 (niveau de compression modéré)
                ob_start();
                imagepng($image, null, 6); // Compression de PNG
                $screenshotData = ob_get_clean();
                imagedestroy($image);
            }
        } else {
            echo json_encode(['success' => false, 'error' => 'Unsupported image type']);
            exit;
        }
    } else {
        echo json_encode(['success' => false, 'error' => 'File size exceeds 2MB']);
        exit;
    }
}

try {
    // Insertion des données dans la base
    $stmt = $pdo->prepare("INSERT INTO feedback (type, message, screenshot) VALUES (?, ?, ?)");
    $stmt->bindParam(1, $type);
    $stmt->bindParam(2, $message);
    $stmt->bindParam(3, $screenshotData, PDO::PARAM_LOB);
    $stmt->execute();

    echo json_encode(['success' => true]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
