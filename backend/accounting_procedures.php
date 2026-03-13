<?php
/**
 * Accounting Module – العهد والمصاريف والتحصيلات
 *
 * Transaction types:
 *   collection  – تحصيل من عميل (يزيد عهدة الفني)
 *   expense     – مصروف (ينقص عهدة الفني) – يحتاج اعتماد
 *   advance     – سلفة / مقدم للفني (يزيد عهدة الفني)
 *   settlement  – تسليم مبلغ (ينقص عهدة الفني)
 *   adjustment  – تسوية يدوية (+ أو -)
 */

function _ensureAccountingSchema() {
    global $db;

    $db->exec("CREATE TABLE IF NOT EXISTS acc_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(30) NOT NULL,
        technician_id INT NOT NULL,
        task_id INT DEFAULT NULL,
        amount DECIMAL(12,2) NOT NULL DEFAULT 0,
        description TEXT,
        receipt_url TEXT DEFAULT NULL,
        category VARCHAR(100) DEFAULT NULL,
        status VARCHAR(30) DEFAULT 'pending',
        approved_by INT DEFAULT NULL,
        approved_at DATETIME DEFAULT NULL,
        rejection_note TEXT DEFAULT NULL,
        created_by INT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_tech (technician_id),
        INDEX idx_task (task_id),
        INDEX idx_type (type),
        INDEX idx_status (status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $db->exec("CREATE TABLE IF NOT EXISTS acc_expense_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        icon VARCHAR(50) DEFAULT 'receipt',
        color VARCHAR(30) DEFAULT '#FF9800'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    // Remove duplicates: keep only the row with the smallest id per name
    $db->exec("DELETE c1 FROM acc_expense_categories c1
               INNER JOIN acc_expense_categories c2
               WHERE c1.name = c2.name AND c1.id > c2.id");

    $cnt = (int)$db->query("SELECT COUNT(*) FROM acc_expense_categories")->fetchColumn();
    if ($cnt == 0) {
        $db->exec("INSERT INTO acc_expense_categories (name, icon, color) VALUES
            ('قطع غيار', 'build', '#2196F3'),
            ('موصلات وكابلات', 'cable', '#4CAF50'),
            ('مواصلات', 'directions_car', '#FF9800'),
            ('أدوات', 'handyman', '#9C27B0'),
            ('مستلزمات', 'shopping_bag', '#F44336'),
            ('أخرى', 'more_horiz', '#607D8B')
        ");
    }
}

function _formatAccTransaction($r) {
    return [
        'id' => (int)$r['id'],
        'type' => $r['type'],
        'technicianId' => (int)$r['technician_id'],
        'technicianName' => $r['technician_name'] ?? null,
        'taskId' => $r['task_id'] ? (int)$r['task_id'] : null,
        'taskTitle' => $r['task_title'] ?? null,
        'amount' => (float)$r['amount'],
        'description' => $r['description'] ?? '',
        'receiptUrl' => $r['receipt_url'] ?? null,
        'category' => $r['category'] ?? null,
        'status' => $r['status'] ?? 'pending',
        'approvedBy' => $r['approved_by'] ? (int)$r['approved_by'] : null,
        'approverName' => $r['approver_name'] ?? null,
        'approvedAt' => $r['approved_at'] ?? null,
        'rejectionNote' => $r['rejection_note'] ?? null,
        'createdBy' => $r['created_by'] ? (int)$r['created_by'] : null,
        'creatorName' => $r['creator_name'] ?? null,
        'createdAt' => $r['created_at'] ?? null,
    ];
}

// ─── acc.getTransactions ───────────────────────────────────────
function acc_getTransactions($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $where = [];
    $params = [];

    if (!empty($input['technicianId'])) {
        $where[] = 't.technician_id = ?';
        $params[] = (int)$input['technicianId'];
    }
    if (!empty($input['type'])) {
        $where[] = 't.type = ?';
        $params[] = $input['type'];
    }
    if (!empty($input['status'])) {
        $where[] = 't.status = ?';
        $params[] = $input['status'];
    }
    if (!empty($input['taskId'])) {
        $where[] = 't.task_id = ?';
        $params[] = (int)$input['taskId'];
    }
    if (!empty($input['dateFrom'])) {
        $where[] = 'DATE(t.created_at) >= ?';
        $params[] = $input['dateFrom'];
    }
    if (!empty($input['dateTo'])) {
        $where[] = 'DATE(t.created_at) <= ?';
        $params[] = $input['dateTo'];
    }

    $sql = "SELECT t.*,
                   tech.name AS technician_name,
                   task.title AS task_title,
                   approver.name AS approver_name,
                   creator.name AS creator_name
            FROM acc_transactions t
            LEFT JOIN users tech ON tech.id = t.technician_id
            LEFT JOIN tasks task ON task.id = t.task_id
            LEFT JOIN users approver ON approver.id = t.approved_by
            LEFT JOIN users creator ON creator.id = t.created_by";

    if ($where) $sql .= ' WHERE ' . implode(' AND ', $where);
    $sql .= ' ORDER BY t.created_at DESC';

    if (!empty($input['limit'])) {
        $sql .= ' LIMIT ' . (int)$input['limit'];
    }

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    return array_map('_formatAccTransaction', $stmt->fetchAll());
}

// ─── acc.createTransaction ─────────────────────────────────────
function acc_createTransaction($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $type = $input['type'] ?? 'expense';
    $techId = (int)($input['technicianId'] ?? 0);
    $taskId = !empty($input['taskId']) ? (int)$input['taskId'] : null;
    $amount = (float)($input['amount'] ?? 0);
    $description = $input['description'] ?? '';
    $receiptUrl = $input['receiptUrl'] ?? null;
    $category = $input['category'] ?? null;
    $createdBy = $ctx['userId'] ?? null;

    $status = 'approved';
    if ($type === 'expense') {
        $status = 'pending';
    }

    $stmt = $db->prepare("INSERT INTO acc_transactions
        (type, technician_id, task_id, amount, description, receipt_url, category, status, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$type, $techId, $taskId, $amount, $description, $receiptUrl, $category, $status, $createdBy]);
    $txId = (int)$db->lastInsertId();

    try {
        $typeLabels = ['expense' => 'مصروف', 'custody' => 'عهدة', 'collection' => 'تحصيل', 'settlement' => 'تصفية'];
        $label = $typeLabels[$type] ?? $type;
        if ($type === 'expense') {
            _notifyAdminsAndSupervisors("{$label} جديد يحتاج اعتماد", "{$description} - المبلغ: {$amount} ج.م", 'accounting', $txId, 'accounting');
        }
    } catch (\Exception $e) { /* ignore */ }

    return ['id' => $txId, 'status' => $status];
}

// ─── acc.approveTransaction ────────────────────────────────────
function acc_approveTransaction($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $id = (int)($input['id'] ?? 0);
    $action = $input['action'] ?? 'approve'; // approve | reject
    $note = $input['note'] ?? null;
    $approverId = $ctx['userId'] ?? null;

    if ($action === 'approve') {
        $db->prepare("UPDATE acc_transactions SET status = 'approved', approved_by = ?, approved_at = NOW() WHERE id = ?")
           ->execute([$approverId, $id]);
    } else {
        $db->prepare("UPDATE acc_transactions SET status = 'rejected', approved_by = ?, approved_at = NOW(), rejection_note = ? WHERE id = ?")
           ->execute([$approverId, $note, $id]);
    }

    try {
        $txStmt = $db->prepare("SELECT technician_id, description, amount FROM acc_transactions WHERE id = ?");
        $txStmt->execute([$id]);
        $tx = $txStmt->fetch();
        if ($tx && $tx['technician_id']) {
            $statusLabel = $action === 'approve' ? 'تم اعتماد' : 'تم رفض';
            _notifyUser((int)$tx['technician_id'], "{$statusLabel} مصروفك",
                "{$statusLabel}: {$tx['description']} - {$tx['amount']} ج.م", 'accounting', $id, 'accounting');
        }
    } catch (\Exception $e) { /* ignore */ }

    return ['success' => true];
}

// ─── acc.deleteTransaction ─────────────────────────────────────
function acc_deleteTransaction($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $id = (int)($input['id'] ?? 0);
    $db->prepare("DELETE FROM acc_transactions WHERE id = ?")->execute([$id]);
    return ['success' => true];
}

// ─── acc.getCustodyBalances ────────────────────────────────────
function acc_getCustodyBalances($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $sql = "SELECT
                u.id AS technician_id,
                u.name AS technician_name,
                COALESCE(SUM(CASE WHEN t.type IN ('collection','advance','adjustment') AND t.status = 'approved' AND t.amount > 0 THEN t.amount ELSE 0 END), 0) AS total_in,
                COALESCE(SUM(CASE WHEN t.type IN ('expense','settlement') AND t.status = 'approved' THEN t.amount ELSE 0 END), 0) AS total_out,
                COALESCE(SUM(CASE WHEN t.type = 'adjustment' AND t.status = 'approved' AND t.amount < 0 THEN ABS(t.amount) ELSE 0 END), 0) AS adjustments_out,
                COALESCE(SUM(CASE WHEN t.type = 'expense' AND t.status = 'pending' THEN t.amount ELSE 0 END), 0) AS pending_expenses,
                COUNT(DISTINCT t.id) AS transaction_count
            FROM users u
            LEFT JOIN acc_transactions t ON t.technician_id = u.id
            WHERE u.role IN ('technician','admin')
            GROUP BY u.id, u.name
            ORDER BY u.name";

    $rows = $db->query($sql)->fetchAll();
    $result = [];
    foreach ($rows as $r) {
        $totalIn = (float)$r['total_in'];
        $totalOut = (float)$r['total_out'] + (float)$r['adjustments_out'];
        $balance = $totalIn - $totalOut;

        $result[] = [
            'technicianId' => (int)$r['technician_id'],
            'technicianName' => $r['technician_name'],
            'totalIn' => $totalIn,
            'totalOut' => $totalOut,
            'balance' => $balance,
            'pendingExpenses' => (float)$r['pending_expenses'],
            'transactionCount' => (int)$r['transaction_count'],
        ];
    }
    return $result;
}

// ─── acc.getTechnicianCustody ──────────────────────────────────
function acc_getTechnicianCustody($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $techId = (int)($input['technicianId'] ?? $ctx['userId'] ?? 0);

    $stmt = $db->prepare("SELECT
        COALESCE(SUM(CASE WHEN type IN ('collection','advance','adjustment') AND status = 'approved' AND amount > 0 THEN amount ELSE 0 END), 0) AS total_in,
        COALESCE(SUM(CASE WHEN type IN ('expense','settlement') AND status = 'approved' THEN amount ELSE 0 END), 0) AS total_out,
        COALESCE(SUM(CASE WHEN type = 'adjustment' AND status = 'approved' AND amount < 0 THEN ABS(amount) ELSE 0 END), 0) AS adjustments_out,
        COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'pending' THEN amount ELSE 0 END), 0) AS pending_expenses
        FROM acc_transactions WHERE technician_id = ?");
    $stmt->execute([$techId]);
    $r = $stmt->fetch();

    $totalIn = (float)($r['total_in'] ?? 0);
    $totalOut = (float)($r['total_out'] ?? 0) + (float)($r['adjustments_out'] ?? 0);

    return [
        'technicianId' => $techId,
        'totalIn' => $totalIn,
        'totalOut' => $totalOut,
        'balance' => $totalIn - $totalOut,
        'pendingExpenses' => (float)($r['pending_expenses'] ?? 0),
    ];
}

// ─── acc.getDashboard ──────────────────────────────────────────
function acc_getDashboard($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $dateFrom = $input['dateFrom'] ?? date('Y-m-01');
    $dateTo = $input['dateTo'] ?? date('Y-m-d');

    $stmt = $db->prepare("SELECT
        COALESCE(SUM(CASE WHEN type = 'collection' AND status = 'approved' THEN amount ELSE 0 END), 0) AS total_collections,
        COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'approved' THEN amount ELSE 0 END), 0) AS total_expenses,
        COALESCE(SUM(CASE WHEN type = 'advance' AND status = 'approved' THEN amount ELSE 0 END), 0) AS total_advances,
        COALESCE(SUM(CASE WHEN type = 'settlement' AND status = 'approved' THEN amount ELSE 0 END), 0) AS total_settlements,
        COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'pending' THEN amount ELSE 0 END), 0) AS pending_expenses,
        COUNT(CASE WHEN type = 'expense' AND status = 'pending' THEN 1 END) AS pending_count
        FROM acc_transactions
        WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?");
    $stmt->execute([$dateFrom, $dateTo]);
    $r = $stmt->fetch();

    $totalCustody = $db->query("SELECT
        COALESCE(SUM(CASE WHEN type IN ('collection','advance','adjustment') AND status = 'approved' AND amount > 0 THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type IN ('expense','settlement') AND status = 'approved' THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'adjustment' AND status = 'approved' AND amount < 0 THEN ABS(amount) ELSE 0 END), 0)
        FROM acc_transactions")->fetchColumn();

    return [
        'totalCollections' => (float)$r['total_collections'],
        'totalExpenses' => (float)$r['total_expenses'],
        'totalAdvances' => (float)$r['total_advances'],
        'totalSettlements' => (float)$r['total_settlements'],
        'pendingExpenses' => (float)$r['pending_expenses'],
        'pendingCount' => (int)$r['pending_count'],
        'totalCustody' => (float)$totalCustody,
        'dateFrom' => $dateFrom,
        'dateTo' => $dateTo,
    ];
}

// ─── acc.getExpenseCategories ──────────────────────────────────
function acc_getExpenseCategories($ctx) {
    global $db;
    _ensureAccountingSchema();

    $rows = $db->query("SELECT * FROM acc_expense_categories ORDER BY id")->fetchAll();
    return array_map(function($r) {
        return [
            'id' => (int)$r['id'],
            'name' => $r['name'],
            'icon' => $r['icon'] ?? 'receipt',
            'color' => $r['color'] ?? '#FF9800',
        ];
    }, $rows);
}

// ─── acc.settleCustody ─────────────────────────────────────────
function acc_settleCustody($input, $ctx) {
    global $db;
    _ensureAccountingSchema();

    $techId = (int)($input['technicianId'] ?? 0);
    $amount = (float)($input['amount'] ?? 0);
    $description = $input['description'] ?? 'تصفية عهدة';
    $receiptUrl = $input['receiptUrl'] ?? null;

    $stmt = $db->prepare("INSERT INTO acc_transactions
        (type, technician_id, amount, description, receipt_url, status, approved_by, approved_at, created_by)
        VALUES ('settlement', ?, ?, ?, ?, 'approved', ?, NOW(), ?)");
    $stmt->execute([$techId, $amount, $description, $receiptUrl, $ctx['userId'], $ctx['userId']]);

    return ['id' => (int)$db->lastInsertId()];
}
