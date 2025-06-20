<?php
include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $worker_id = $_POST['worker_id'];

    // Join tbl_submissions with tbl_works to get the task title
    $sql = "SELECT s.id, s.submission_text, s.submitted_at, w.title 
            FROM tbl_submissions s
            INNER JOIN tbl_works w ON s.work_id = w.id
            WHERE s.worker_id = ?
            ORDER BY s.submitted_at DESC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $worker_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $submissions = array();
    while ($row = $result->fetch_assoc()) {
        $submissions[] = $row;
    }

    echo json_encode(['status' => 'success', 'data' => $submissions]);

    $stmt->close();
    $conn->close();
}
?>