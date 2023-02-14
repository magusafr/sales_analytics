SELECT *
FROM iowa_drink_sales
LIMIT 100;

-- checking unique values
SELECT COUNT(DISTINCT(store_name)) AS total_customer, -- plot with their sales
	   COUNT(DISTINCT(zip_code)) AS zip_code, -- plot with their sales
       COUNT(DISTINCT(city)) AS total_city, -- plot with their sales
	   COUNT(DISTINCT(county)) AS total_county, -- plot with their sales
	   COUNT(DISTINCT(state)) AS total_state, -- plot with their sales
	   COUNT(DISTINCT(item_description)) AS total_item, -- plot with their sales
	   COUNT(DISTINCT(category_name)) AS total_category, -- plot with their sales
	   COUNT(DISTINCT(vendor_name)) AS total_vendor -- plot with their sales
FROM iowa_drink_sales;

-- Analysis
-- Grouping sales by product categories
SELECT category_name, SUM(sale_dollars) AS revenue
FROM iowa_drink_sales
GROUP BY category_name
ORDER BY revenue DESC;

-- by year
SELECT EXTRACT(YEAR FROM date) AS yr,
	   SUM(sale_dollars) AS revenue
FROM iowa_drink_sales
GROUP BY yr
ORDER BY revenue;
ORDER BY revenue DESC;

-- What was the best month for sales ? How much was earned that month?
SELECT EXTRACT(MONTH FROM date) AS mt, 
	   SUM(sale_dollars) AS revenue, 
	   COUNT(*) AS frequency, 
	   SUM(sale_dollars)/COUNT(*) AS sales_per_order 
FROM iowa_drink_sales
GROUP BY mt
ORDER BY revenue DESC;

-- March seems to be the months that has the highest sales, what product did they sell in March?
SELECT EXTRACT(MONTH FROM date) AS mt, 
	   category_name,
	   SUM(sale_dollars) AS revenue,
	   COUNT(*)
FROM iowa_drink_sales
WHERE EXTRACT(MONTH FROM date) = '3' AND EXTRACT(YEAR FROM date) = '2022'
GROUP BY mt, category_name
ORDER BY revenue DESC;

-- WHos is our best customer (this could be best answered with RFM)
SELECT
	  store_name,
	  SUM(sale_dollars) MonetaryValue,
	  AVG(sale_dollars) AvgMonetaryValue,
	  COUNT(*) frequency,
	  MAX(date) last_order_date,
	  (SELECT MAX(date) FROM iowa_drink_sales) max_order_date,
	  (SELECT MAX(date) FROM iowa_drink_sales) - MAX(date) recency
FROM iowa_drink_sales
GROUP BY store_name
ORDER BY AvgMonetaryValue DESC;

-- create CTE to make readable codes
WITH rfm_table AS (
					SELECT
						  store_name,
						  SUM(sale_dollars) MonetaryValue,
						  AVG(sale_dollars) AvgMonetaryValue,
						  COUNT(*) frequency,
						  MAX(date) last_order_date,
						  (SELECT MAX(date) FROM iowa_drink_sales) max_order_date,
						  (SELECT MAX(date) FROM iowa_drink_sales) - MAX(date) recency
					FROM iowa_drink_sales
					GROUP BY store_name
					ORDER BY AvgMonetaryValue DESC
                  ),
rfm_cel AS (
			SELECT *,
				   ntile(4) over (order by last_order_date) as rfm_recency,
				   ntile(4) over (order by frequency) as rfm_frequency,
				   ntile(4) over (order by AvgMonetaryValue) as rfm_monetary
			FROM rfm_table
	        ),
rfm_cel2 AS(
			SELECT store_name,
				   rfm_recency,
				   rfm_frequency,
				   rfm_monetary,
				   rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
				   CONCAT(CAST(rfm_recency AS varchar), CAST(rfm_frequency AS varchar), CAST(rfm_monetary as varchar)) rfm_cell_string
			FROM rfm_cel
			ORDER BY rfm_cell --min 3 and max 12
			),
tes AS(

select store_name , rfm_recency, rfm_frequency, rfm_monetary, rfm_cell_string,
	case 
		when CAST(rfm_cell_string AS integer) in (111, 113, 124, 112 , 121, 122, 123, 132, 211, 212, 114, 141, 213, 214) then 'lost_customers'  --lost customers
		when CAST(rfm_cell_string AS integer)  in (131, 133, 134, 142, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when CAST(rfm_cell_string AS integer)  in (311, 411, 331, 412, 413, 414, 421, 423, 424) then 'new customers'
		when CAST(rfm_cell_string AS integer)  in (222, 223, 233, 322, 221, 224, 231, 232, 234, 241, 242, 243) then 'potential churners'
		when CAST(rfm_cell_string AS integer)  in (323, 333, 321, 422, 332, 432, 312, 313, 314, 324, 341, 342) then 'active' --(Customers who buy often & recently, but at low price points)
		when CAST(rfm_cell_string AS integer)  in (433, 434, 443, 444, 431, 441, 442) then 'loyal'
	end rfm_segment
FROM rfm_cel2
)

SELECT *
FROM tes;
