-- начинающиеся на букву “В” (с учётом регистра)
SELECT code_book, title_book
FROM books
WHERE title_book ~ '^В';

-- буква в хотя бы два раза
SELECT code_book, title_book
FROM books
WHERE title_book ~* '(.*в.*){2,}';


-- пробелы на нижние подчеркивания
SELECT
    title_book,
    regexp_replace(title_book, '\s+', '_', 'g') AS title_underscored
FROM books;

--в названии встречаются слова длиной более 6 символов
SELECT code_book, title_book
FROM books
WHERE title_book ~ '\y\w{7,}\y';


SELECT title_book,
       CASE
         WHEN title_book ~* 'война|преступление|мастер' THEN 'Классика'
         ELSE 'Другое'
       END AS category
FROM books
ORDER BY category;