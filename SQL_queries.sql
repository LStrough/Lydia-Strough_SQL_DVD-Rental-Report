-- A. Business Question: Total rentals for each store organized by film category

-- B. CREATE detailed_report table

DROP TABLE IF EXISTS detailed_report;
CREATE TABLE detailed_report (
	rental_id INT,
	film_category_name varchar(45), 
	store_id INT,
	rental_date DATE
);

-- To view empty detailed_report table
-- SELECT * FROM detailed_report;

-- CREATE summary_report table

DROP TABLE IF EXISTS summary_report; 
CREATE TABLE summary_report (
	store_id INT, 
	film_category_name varchar(45), 
	num_rentals INT
);

-- To view empty summary_report table 
-- SELECT * FROM summary_report; 

-- C. Extract raw data from dvdrental database into detailed_report table

INSERT INTO detailed_report (
	rental_id,
	film_category_name,
	store_id,
	rental_date
)
SELECT 
	r.rental_id,
	cat.name,
	i.store_id,
	r.rental_date
FROM rental AS r
INNER JOIN inventory AS i ON i.inventory_id = r.inventory_id
INNER JOIN film AS f ON f.film_id = i.film_id 
INNER JOIN film_category AS fc ON fc.film_id = f.film_id
INNER JOIN category AS cat ON cat.category_id = fc.category_id;

-- To view contents of detailed_report table
-- SELECT * FROM detailed_report;

-- To verify accuracy of data, compare the aggregated data (detailed_report table) to the raw data (rental, inventory, film_category, and category table(s))

-- To view raw data
-- SELECT rental_id, rental_date, inventory_id FROM rental;
-- SELECT inventory_id, film_id, store_id FROM inventory;
-- SELECT film_id, category_id FROM film_category;
-- SELECT category_id, name FROM category;

-- To view aggregated data
-- SELECT * FROM detailed_report; 

-- D. CREATE FUNCTION

CREATE OR REPLACE FUNCTION rentals_by_category() 
	RETURNS TRIGGER 
AS 
$$
BEGIN 
	DELETE FROM summary_report;
	INSERT INTO summary_report (
	SELECT
		store_id,
		film_category_name,
		count(rental_id)
	FROM detailed_report
	GROUP BY store_id, film_category_name
	ORDER BY store_id, COUNT(rental_id) desc
	);
RETURN NEW;	
END; 
$$ 
LANGUAGE PLPGSQL;

-- E. CREATE TRIGGER on detailed_report table
-- To refresh summary_report table

CREATE TRIGGER summary_refresh
AFTER INSERT ON detailed_report
FOR EACH STATEMENT
EXECUTE PROCEDURE rentals_by_category();

-- F. Create Stored Procedure to refresh detailed_report table
-- Note: The summary_refresh trigger initiates the refresh_reports() store procedure
-- Automated with an external tool (e.g., pgAgent) this procedure should be conducted once a month at the end of the month

CREATE OR REPLACE PROCEDURE refresh_reports()
LANGUAGE PLPGSQL
AS 
$$
BEGIN
	DELETE FROM detailed_report;
	INSERT INTO detailed_report (
		rental_id,
		film_category_name,
		store_id,
		rental_date
	)
	SELECT 
		r.rental_id,
		cat.name,
		i.store_id,
		r.rental_date
	FROM rental AS r
	INNER JOIN inventory AS i ON i.inventory_id = r.inventory_id
	INNER JOIN film AS f ON f.film_id = i.film_id 
	INNER JOIN film_category AS fc ON fc.film_id = f.film_id
	INNER JOIN category AS cat ON cat.category_id = fc.category_id;
END; 
$$;

-- To Call Stored Procedure
-- CALL refresh_reports();

-- To view results
-- SELECT * FROM detailed_report;
-- SELECT * FROM summary_report;
