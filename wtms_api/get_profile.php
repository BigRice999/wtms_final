<?php
header('Content-Type: application/json');
include 'db_connect.php';

$input = json_decode(file_get_contents("php://input"), true);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $worker_id = isset($input['worker_id']) ? intval($input['worker_id']) : 0;

    if (empty($worker_id)) {
        echo json_encode(['status' => 'error', 'message' => 'Missing worker_id']);
        exit;
    }

    $sql = "SELECT name, email, phone, address, birth_date, gender, image FROM tbl_users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Prepare failed']);
        exit;
    }

    $stmt->bind_param("i", $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result && $result->num_rows > 0) {
        $profile = $result->fetch_assoc();
        echo json_encode(['status' => 'success', 'data' => $profile]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
    }

    $stmt->close();
    $conn->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request']);
}
