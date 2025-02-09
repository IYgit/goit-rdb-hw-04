USE mydb;

SELECT 
    cat.name AS category_name,
    COUNT(*) AS num_rows,  -- Кількість рядків у кожній групі
    AVG(od.quantity) AS avg_quantity  -- Середня кількість товару
FROM order_details od
INNER JOIN orders o ON od.order_id = o.id
INNER JOIN customers c ON o.customer_id = c.id
INNER JOIN employees e ON o.employee_id = e.employee_id
INNER JOIN shippers sh ON o.shipper_id = sh.id
INNER JOIN products p ON od.product_id = p.id
INNER JOIN categories cat ON p.category_id = cat.id  -- Зв'язок з категорією
INNER JOIN suppliers s ON p.supplier_id = s.id
WHERE e.employee_id > 3 AND e.employee_id <= 10
GROUP BY cat.name;
