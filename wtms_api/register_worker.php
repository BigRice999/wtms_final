<?php
include("db_connect.php");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $password = sha1($_POST['password']); 
    $phone = $_POST['phone'];
    $address = $_POST['address'];

    if (!$name || !$email || !$password || !$phone || !$address) {
        echo json_encode(["status" => "error", "message" => "Missing required fields."]);
        exit();
    }

    $sql = "INSERT INTO tbl_users (name, email, password, phone, address)
            VALUES ('$name', '$email', '$password', '$phone', '$address')";

    if (mysqli_query($conn, $sql)) {
        echo json_encode(["status" => "success", "message" => "Worker registered successfully!"]);
    } else {
        echo json_encode(["status" => "error", "message" => "ERROR! Something goes wrong"]);
    }
}

    $imagePath = "";
    if (isset($_FILES['image'])) {
        $image = $_FILES['image']['name'];
        $tempPath = $_FILES['image']['tmp_name'];
        $uploadPath = 'uploads/' . $image;
        move_uploaded_file($tempPath, $uploadPath);
        $imagePath = $uploadPath;
    }

    $sql = "INSERT INTO tbl_users (name, email, password, phone, address, image)
        VALUES ('$name', '$email', '$password', '$phone', '$address', '$imagePath')";

?>
