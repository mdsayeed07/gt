<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Address Book Application</title>
</head>
<body>

<h3 style="color : red">This is - ip</h3>
<h2>Add New Contact</h2>
<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="post">
    <label for="name">Name:</label>
    <input type="text" id="name" name="name" required><br><br>
    <label for="email">Email:</label>
    <input type="email" id="email" name="email"><br><br>
    <label for="phone">Phone:</label>
    <input type="text" id="phone" name="phone"><br><br>
    <input type="submit" name="submit" value="Save Contact">
</form>

<hr>

<h2>Contacts</h2>

<?php
// Database configuration
$servername = "Database End Point";
$username = "Username";
$password = "Password";
$database = "Database Name";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Insert new contact into database
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['submit'])) {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $phone = $_POST['phone'];

    $sql = "INSERT INTO contacts (name, email, phone) VALUES ('$name', '$email', '$phone')";
    if ($conn->query($sql) === TRUE) {
        echo "New contact added successfully";
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }
}

// Fetch contacts from database
$sql = "SELECT * FROM contacts";
$result = $conn->query($sql);

// Display contacts
if ($result->num_rows > 0) {
    echo "<ul>";
    while($row = $result->fetch_assoc()) {
        echo "<li>" . $row["name"];
        if (!empty($row["email"])) {
            echo " - Email: " . $row["email"];
        }
        if (!empty($row["phone"])) {
            echo " - Phone: " . $row["phone"];
        }
        echo "</li>";
    }
    echo "</ul>";
} else {
    echo "No contacts found";
}

// Close connection
$conn->close();
?>

</body>
</html>