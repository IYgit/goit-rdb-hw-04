USE LibraryManagement;

-- Вставка тестових даних у таблицю authors
INSERT INTO authors (author_name) VALUES 
('J.K. Rowling'),
('George Orwell');

-- Вставка тестових даних у таблицю genres
INSERT INTO genres (genre_name) VALUES 
('Fantasy'),
('Dystopian');

-- Вставка тестових даних у таблицю books
INSERT INTO books (title, publication_year, author_id, genre_id) VALUES 
('Harry Potter and the Philosopher\'s Stone', 1997, 1, 1),
('1984', 1949, 2, 2);

-- Вставка тестових даних у таблицю users
INSERT INTO users (user_name, email) VALUES 
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com');

-- Вставка тестових даних у таблицю book_loans
INSERT INTO book_loans (book_id, user_id, loan_date, return_date) VALUES 
(1, 1, '2025-01-01', '2025-01-15'),
(2, 2, '2025-02-01', '2025-02-15');
