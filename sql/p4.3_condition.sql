use mydb;

SELECT 
    od.id AS order_detail_id,
    o.id AS order_id,
    o.date AS order_date,
    c.id AS customer_id,
    c.name AS customer_name,
    e.employee_id,
    e.first_name,
    e.last_name,
    sh.id AS shipper_id,
    sh.name AS shipper_name,
    p.id AS product_id,
    p.name AS product_name,
    cat.id AS category_id,
    cat.name AS category_name,
    s.id AS supplier_id,
    s.name AS supplier_name,
    od.quantity
FROM order_details od
LEFT JOIN orders o ON od.order_id = o.id
LEFT JOIN customers c ON o.customer_id = c.id
LEFT JOIN employees e ON o.employee_id = e.employee_id
LEFT JOIN shippers sh ON o.shipper_id = sh.id
LEFT JOIN products p ON od.product_id = p.id
LEFT JOIN categories cat ON p.id = cat.id
LEFT JOIN suppliers s ON p.id = s.id
WHERE e.employee_id > 3 AND e.employee_id <= 10;