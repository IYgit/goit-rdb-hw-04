use mydb;

SELECT count(*)
FROM order_details od
LEFT JOIN orders o ON od.order_id = o.id
LEFT JOIN customers c ON o.customer_id = c.id
LEFT JOIN employees e ON o.employee_id = e.employee_id
LEFT JOIN shippers sh ON o.shipper_id = sh.id
LEFT JOIN products p ON od.product_id = p.id
LEFT JOIN categories cat ON p.id = cat.id
LEFT JOIN suppliers s ON p.id = s.id;


LEFT JOIN (Ліве зовнішнє приєднання)
повертає всі рядки з лівої таблиці, вказаної перед JOIN (в нашому випадку order_details).
Якщо у правій таблиці немає відповідного рядка, замість значень із неї будуть NULL.
Таким чином, всі інші таблиці, крім order_details, будуть представлені в тій кількості, 
яка відповідає умові об'єднання. 
Кількість рядків в цьому запиті буде дорівнювати кількості рядків в таблиці order_details.