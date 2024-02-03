--1 
CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
SELECT
    c.name AS category,
    EXTRACT(QUARTER FROM p.payment_date) AS quarter,
    COALESCE(SUM(p.amount), 0::numeric) AS total_sales_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE
   EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
   AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY c.name, EXTRACT(QUARTER FROM p.payment_date)
HAVING COUNT(DISTINCT p.payment_id) > 0;

--2
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(current_qtr NUMERIC)
RETURNS TABLE(category_result TEXT, quarter_result NUMERIC, total_sales_revenue_result NUMERIC)
LANGUAGE 'plpgsql'
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM sales_revenue_by_category_qtr
  WHERE quarter = current_qtr;
END;
$$;

SELECT * FROM get_sales_revenue_by_category_qtr(EXTRACT(QUARTER FROM CURRENT_DATE));

--3
CREATE OR REPLACE PROCEDURE new_movie(movie_title VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    s_language_id INT;
    new_film_id INT;
BEGIN
    SELECT language_id INTO s_language_id
    FROM language
    WHERE name = 'Klingon';

    IF s_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "Klingon" does not exist in the language table.';
    END IF;

    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id
    FROM film;
  
    INSERT INTO film (film_id, title, rental_rate, rental_duration, replacement_cost, release_year, language_id)
    VALUES (new_film_id, movie_title, 4.99, 3, 19.99, EXTRACT(YEAR FROM CURRENT_DATE), s_language_id);
END;
$$;

CALL new_movie('Shrek prison edition');