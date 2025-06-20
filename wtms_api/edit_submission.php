<?php
include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $submission_id = $_POST['submission_id'];
    $updated_text = $_POST['updated_text'];

    $sql = "UPDATE tbl_submissions SET submission_text = ?, submitted_at = NOW() WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $updated_text, $submission_id);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Submission updated successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to update submission']);
    }

    $stmt->close();
    $conn->close();
}
?>