<?php
$conn = new mysqli('localhost', 'root', '', 'pharmacy_ais_kr');
$conn->set_charset("utf8mb4");

echo "<html><head><link rel='stylesheet' href='style.css'><style>
    body { display: block; padding: 20px; background: #f0f2f5; }
    .table-section { background: white; padding: 20px; margin-bottom: 30px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    h2 { color: #27ae60; border-bottom: 2px solid #eee; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th { background: #f8f9fa; color: #333; }
</style></head><body>";

echo "<h1>📊 Повний реєстр даних АІС</h1><p><a href='index.php'>← Повернутися на головну</a></p>";

$tables = $conn->query("SHOW TABLES");
while ($table_row = $tables->fetch_array()) {
    $tableName = $table_row[0];
    echo "<div class='table-section'><h2>Таблиця: $tableName</h2>";
    
    $data = $conn->query("SELECT * FROM `$tableName` LIMIT 10");
    if ($data && $data->num_rows > 0) {
        echo "<table><thead><tr>";
        while ($field = $data->fetch_field()) echo "<th>{$field->name}</th>";
        echo "</tr></thead><tbody>";
        while ($row = $data->fetch_assoc()) {
            echo "<tr>";
            foreach ($row as $val) echo "<td>" . htmlspecialchars($val ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</tbody></table>";
    } else {
        echo "<p>Немає записів</p>";
    }
    echo "</div>";
}
echo "</body></html>";