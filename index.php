<?php
// Налаштування підключення
$conn = new mysqli('localhost', 'root', '', 'pharmacy_ais_kr');
if ($conn->connect_error) die("Помилка підключення: " . $conn->connect_error);
$conn->set_charset("utf8mb4");
?>
<!DOCTYPE html>
<html lang="uk">
<head>
    <meta charset="UTF-8">
    <title>АІС Аптеки - Dashboard</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="sidebar">
        <h2>💊 Pharmacy AIS</h2>
        <nav>
            <a href="index.php" class="active">🏠 Головна панель</a>
            <a href="all_tables.php">📊 Огляд таблиць</a>
        </nav>
        <div class="db-info">База: pharmacy_ais_kr</div>
    </div>

    <div class="main-content">
        <header>
            <h1>Адміністративна панель Аптеки</h1>
            <p>Система автоматизації рецептурного відділу та складу</p>
        </header>

        <div class="stats-grid">
            <div class="card finance">
                <h3>💰 Загальна виручка</h3>
                <?php
                // Відображення результату роботи процедури RecalculateOrderTotal
                $res = $conn->query("SELECT SUM(total_price) FROM `order` WHERE status IN ('ready', 'issued', 'completed') OR status = ''");
                $total = $res->fetch_row()[0] ?? 0;
                echo "<span>" . number_format($total, 2) . " грн</span>";
                ?>
                <p>Базується на закритих чеках</p>
            </div>

            <div class="card inventory">
                <h3>⚠️ Дефіцит компонентів</h3>
                <?php
                // Логіка тригера trg_Stock_CriticalLevel
                $res = $conn->query("SELECT COUNT(*) FROM stock WHERE quantity <= critical_level");
                $count = $res->fetch_row()[0];
                echo "<span class='" . ($count > 0 ? "warning-text" : "") . "'>$count поз.</span>";
                ?>
                <p>Потребують термінової закупівлі</p>
            </div>
        </div>

        <section class="recent-activity">
            <h3>📜 Журнал аудиту статусів (Trigger Log)</h3>
            <table>
                <thead>
                    <tr>
                        <th>ID Замовлення</th>
                        <th>Новий статус</th>
                        <th>Дата та час зміни</th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    // Виведення даних, згенерованих тригером trg_Order_StatusHistory
                    $res = $conn->query("SELECT order_id, status, changed_at FROM orderstatushistory ORDER BY changed_at DESC LIMIT 5");
                    while($row = $res->fetch_assoc()) {
                        echo "<tr>
                                <td>#{$row['order_id']}</td>
                                <td><span class='status-badge'>{$row['status']}</span></td>
                                <td>{$row['changed_at']}</td>
                              </tr>";
                    }
                    ?>
                </tbody>
            </table>
        </section>
    </div>
</body>
</html>