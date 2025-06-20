<?php
header('Content-Type: application/json');
include("db_connect.php");

$input = json_decode(file_get_contents("php://input"), true);

$workerId = $input['worker_id'] ?? '';
$email = $input['email'] ?? '';
$phone = $input['phone'] ?? '';
$address = $input['address'] ?? '';
$birthDate = $input['birth_date'] ?? '';
$gender = $input['gender'] ?? '';

if (!$workerId || !$email) {
    echo json_encode(["status" => "error", "message" => "Missing required fields"]);
    exit();
}

// only allow updating for email, phone number, address, birth date and gender
$sql = "UPDATE tbl_users 
        SET email = ?, phone = ?, address = ?, birth_date = ?, gender = ?
        WHERE id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sssssi", $email, $phone, $address, $birthDate, $gender, $workerId);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => "Update failed"]);
}

$stmt->close();
$conn->close();
?>
