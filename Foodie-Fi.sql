# How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT(customer_id)) AS total_customers
FROM subscriptions;

# What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTH(start_date) AS month_date, MONTHNAME(start_date) AS month_name, COUNT(*) AS customer_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY month_date, month_name
ORDER BY month_date;

# What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, COUNT(plan_name) AS num_of_events
FROM subscriptions
NATURAL JOIN plans
WHERE YEAR(start_date)>=2021
GROUP BY plan_name
ORDER BY num_of_events;

# What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
	COUNT(DISTINCT(customer_id)) AS churn_customers, 
	ROUND(
		COUNT(DISTINCT(customer_id)) / (
			SELECT COUNT(DISTINCT(customer_id)) AS total_customers
			FROM subscriptions
		) * 100, 1
	) AS churn_percentage
FROM subscriptions
WHERE plan_id = 4;

# How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id) AS duplicates
	FROM subscriptions
)
SELECT COUNT(*) AS churn_customers, (
	ROUND(
		COUNT(*) / (
			SELECT COUNT(DISTINCT(customer_id))
			FROM subscriptions
		) * 100, 0)
	) AS churn_percentage
FROM cte
WHERE duplicates = 2 AND plan_id = 4;

# What is the number and percentage of customer plans after their initial free trial?
WITH cte AS (
	SELECT customer_id, plan_id, plan_name, ROW_NUMBER() OVER (PARTITION BY customer_id) AS duplicates
	FROM subscriptions
	NATURAL JOIN plans
)
SELECT plan_id, plan_name, COUNT(*) AS customer_counts, (
	ROUND(COUNT(*) / (
		SELECT COUNT(DISTINCT(customer_id))
        FROM subscriptions
    ) * 100, 1)
) AS conversion_percentage
FROM cte
WHERE duplicates = 2
GROUP BY plan_id, plan_name
ORDER BY plan_id;

# What is the customer count and percentage breakdown of all 5 plan_name values by 2020-12-31?
WITH cte AS (
	SELECT *, LEAD(start_date) OVER (PARTITION BY customer_id) AS next_date
	FROM subscriptions
	WHERE start_date <= '2020-12-31'
)
SELECT plan_id, 
COUNT(DISTINCT(customer_id)) AS customer_count, 
COUNT(DISTINCT(customer_id))/(
	SELECT COUNT(DISTINCT(customer_id))
    FROM cte
) AS customer_percentage
FROM cte
WHERE next_date IS NULL
GROUP BY plan_id;

# How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(customer_id) AS total_customers
FROM subscriptions
WHERE plan_id = 3 AND YEAR(start_date) = 2020;

# How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH cte AS (
	SELECT *, LAG(start_date) OVER (PARTITION BY customer_id) AS previous_date
	FROM subscriptions
	WHERE plan_id = 0 OR plan_id = 3
)
SELECT ROUND(SUM(DATEDIFF(start_date, previous_date)) / (
	SELECT COUNT(DISTINCT(customer_id))
    FROM subscriptions
	WHERE plan_id = 3
),0) AS avg_days
FROM cte
WHERE previous_date IS NOT NULL;

# Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT bin, COUNT(customer_id) AS customer_count
FROM (
	WITH cte AS (
		SELECT *, LAG(start_date) OVER (PARTITION BY customer_id) AS previous_date
		FROM subscriptions
		WHERE plan_id = 0 OR plan_id = 3
	)
	SELECT *, CONCAT(FLOOR(DATEDIFF(start_date, previous_date)/30)*30, '-', (FLOOR(DATEDIFF(start_date, previous_date)/30)+1)*30) AS bin
	FROM cte
	WHERE previous_date IS NOT NULL
) AS temp
GROUP BY bin
ORDER BY CAST(SUBSTRING_INDEX(bin, '-', 1) AS UNSIGNED);  # UNSIGNED 表示无符号整数，即整数类型的取值范围从0开始，不包含负数

# How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

# How would you calculate the rate of growth for Foodie-Fi? What's the new join customer number of each month? 
