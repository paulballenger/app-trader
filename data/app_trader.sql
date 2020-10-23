--for app_store_apps - works except for $
SELECT name
     , CAST(price AS money)
     , CASE WHEN price >= 1 THEN price * 10000
            ELSE 10000
        END AS purchase_price
FROM app_store_apps;

--play_store_apps change price to money and calculate purchase price
SELECT name
     , REPLACE(price,'$','')::money AS price
     , CASE WHEN REPLACE(price,'$','')::decimal > 0.99 THEN (REPLACE(price,'$','')::decimal) * 10000
            ELSE 10000
       END AS purchase_price
FROM play_store_apps
ORDER BY price DESC;

/*
SELECT name, REPLACE(price,'$','') AS cr
FROM play_store_apps;

WITH cash_price AS (SELECT name, (REPLACE(price,'$','')::money) AS cp
				   FROM play_store_apps)
SELECT name
     , REPLACE(price,'$','') AS money
     , CASE WHEN cp > '1' THEN cp * $10000.
            ELSE $10000
       END AS total_price
FROM play_store_apps INNER JOIN cash_price USING(name);

*/

/* From datacamp - may be useful
-- Bins created in Step 2
WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
     -- Subset stackoverflow to just tag dropbox (Step 1)
     dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 
-- Select columns for result
-- What column are you counting to summarize?
SELECT lower, upper, count(question_count) 

   FROM bins  -- Created above
       -- Join to dropbox (created above), 
       -- keeping all rows from the bins table in the join
       LEFT JOIN dropbox
       -- Compare question_count to lower and upper
         ON question_count >= lower 
        AND question_count < upper
 -- Group by lower and upper to count values in each bin
 GROUP BY lower, upper
 -- Order by lower to put bins in order
 ORDER BY lower;
 */
--convert rating to life expectancy for app_store_apps 
SELECT name, rating,
	CASE WHEN rating = 0 THEN 1
	WHEN rating = 0.5 THEN 2
	WHEN rating = 1.0 THEN 3
	WHEN rating = 1.5 THEN 4
	WHEN rating = 2.0 THEN 5
	WHEN rating = 2.5 THEN 6
	WHEN rating = 3.0 THEN 7
	WHEN rating = 3.5 THEN 8
	WHEN rating = 4.0 THEN 9
	WHEN rating = 4.5 THEN 10
	WHEN rating = 5.0 THEN 11
	END AS life_exp
FROM app_store_apps
WHERE rating IS NOT NULL;

--convert rating to life expectancy for play_store_apps (filters out null values )
WITH rounded_rating AS (SELECT rating, round(round(rating/5,1)*5,1) AS r_rating from play_store_apps)  
SELECT name, rating,
	CASE WHEN r_rating = 0 THEN 1
	WHEN r_rating = 0.5 THEN 2
	WHEN r_rating = 1.0 THEN 3
	WHEN r_rating = 1.5 THEN 4
	WHEN r_rating = 2.0 THEN 5
	WHEN r_rating = 2.5 THEN 6
	WHEN r_rating = 3.0 THEN 7
	WHEN r_rating = 3.5 THEN 8
	WHEN r_rating = 4.0 THEN 9
	WHEN r_rating = 4.5 THEN 10
	WHEN r_rating = 5.0 THEN 11
	END AS life_exp
FROM play_store_apps LEFT JOIN rounded_rating USING(rating) 
WHERE rating IS NOT NULL;

-- asa.life_profit = asa_life_rev - asa_life_cost
			(((asa.rating * 2) + 1) * 30000) -
			(CASE WHEN asa.price >= 1 THEN (asa.price * 10000) + ((asa.rating * 2) + 1) * 12000
			ELSE 10000 + ((asa.rating * 2) + 1) * 12000 END) AS asa_profit
-- psa.life_profit = psa_life_rev - psa_life_cost
			(((psa.rating * 2) + 1) * 30000) - 
			(CASE WHEN REPLACE(psa.price,'$','')::decimal > 0.99 
			THEN ((REPLACE(psa.price,'$','')::decimal) * 10000) + ((psa.rating * 2) + 1) * 12000
            ELSE 10000 + ((psa.rating * 2) + 1) * 12000 END) AS psa_life_profit

--final script
SELECT asa.name,
			--asa
			asa.primary_genre,
			asa.rating AS app_store_rating,
			ROUND(AVG(asa.review_count::numeric)) AS app_store_avg_review,
			ROUND((asa.rating * 2) + 1) AS asa_life_exp,
			CASE WHEN asa.price >= 1 THEN asa.price * 10000
            ELSE 10000 END AS asa_purchase_price,
			-- asa_life_cost = asa_purchase_price * asa_life_exp
			CASE WHEN asa.price >= 1 THEN (asa.price * 10000) + ((asa.rating * 2) + 1) * 12000
			ELSE 10000 + ((asa.rating * 2) + 1) * 12000 END AS asa_life_cost,
			-- asa_life_rev = asa_life_exp * 30000
			((asa.rating * 2) + 1) * 30000 AS asa_life_rev,
			--psa 
			psa.category,
			psa.rating AS play_store_rating,
			ROUND(AVG(psa.review_count)) AS play_store_avg_review,
			ROUND((psa.rating * 2) + 1) AS psa_life_exp,
			CASE WHEN REPLACE(psa.price,'$','')::decimal > 0.99 
			THEN (REPLACE(psa.price,'$','')::decimal) * 10000
            ELSE 10000 END AS psa_purchase_price,
			-- psa_life_cost = psa_purchase_price * psa_life_exp
			CASE WHEN REPLACE(psa.price,'$','')::decimal > 0.99 
			THEN ((REPLACE(psa.price,'$','')::decimal) * 10000) + ((psa.rating * 2) + 1) * 12000
            ELSE 10000 + ((psa.rating * 2) + 1) * 12000 END AS psa_life_cost,
			-- psa_life_rev = psa_life_exp * 30000
			((psa.rating * 2) + 1) * 30000 AS psa_life_rev,
			-- life_profit = asa_life_rev + psa_life_rev - asa_life_cost - psa_life_cost
			(((asa.rating * 2) + 1) * 30000) + 
			(((psa.rating * 2) + 1) * 30000) -
			(CASE WHEN asa.price >= 1 THEN (asa.price * 10000) + ((asa.rating * 2) + 1) * 12000
			ELSE 10000 + ((asa.rating * 2) + 1) * 12000 END) - 
			(CASE WHEN REPLACE(psa.price,'$','')::decimal > 0.99 
			THEN ((REPLACE(psa.price,'$','')::decimal) * 10000) + ((psa.rating * 2) + 1) * 12000
            ELSE 10000 + ((psa.rating * 2) + 1) * 12000 END) AS life_profit
		FROM play_store_apps AS psa
			INNER JOIN
			app_store_apps AS asa
			ON psa.name = asa.name
		WHERE LOWER(asa.primary_genre) LIKE 'game%'
		AND LOWER(psa.category) LIKE 'game%'
		AND asa.rating > (SELECT AVG(asa.rating) FROM play_store_apps AS psa
			INNER JOIN
			app_store_apps AS asa
			ON psa.name = asa.name)
		AND psa.rating > (SELECT AVG(psa.rating) FROM play_store_apps AS psa
			INNER JOIN
			app_store_apps AS asa
			ON psa.name = asa.name)
		GROUP BY asa.name, app_store_rating, play_store_rating,
		asa.price, psa.price, asa.primary_genre, psa.category
		ORDER BY life_profit DESC;



			
