USE hamrah
SELECT 
    hamrah.products.product_id,
    SUM(hamrah.order_details.quantity) AS TotalSales,
    SUM(hamrah.order_details.quantity * hamrah.products.price) AS TotalRevenue,
    AVG(hamrah.reviews.rating) AS AverageRating
FROM 
    hamrah.orders
JOIN 
    hamrah.order_details ON hamrah.orders.order_id = hamrah.order_details.order_id
JOIN 
    hamrah.products ON hamrah.order_details.product_id = hamrah.products.product_id
JOIN 
    hamrah.reviews ON hamrah.products.product_id = hamrah.reviews.product_id
WHERE 
    hamrah.orders.order_status = 'complete'
GROUP BY 
    hamrah.products.product_id;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE hamrah

WITH MostPopularCat AS (
    SELECT 
        hamrah.categories.category_id AS CategoryID,
        AVG(hamrah.reviews.rating) AS AverageRating
    FROM 
        hamrah.categories
    JOIN 
        hamrah.products ON hamrah.categories.category_id = hamrah.products.category_id
    JOIN 
        hamrah.reviews ON hamrah.products.product_id = hamrah.reviews.product_id
    GROUP BY 
        hamrah.categories.category_id
    ORDER BY 
        AverageRating DESC
    LIMIT 1
)

, Category_count AS (
    SELECT 
        hamrah.users.user_id,
        SUM(CASE 
                WHEN hamrah.categories.category_id = (SELECT CategoryID FROM MostPopularCat) 
                THEN hamrah.orders.total_amount 
                ELSE 0 
            END) AS TotalAmount
    FROM 
        hamrah.users 
    JOIN 
        hamrah.orders ON hamrah.users.user_id = hamrah.orders.user_id 
    JOIN 
        hamrah.order_details ON hamrah.order_details.order_id = hamrah.orders.order_id 
    JOIN 
        hamrah.products ON hamrah.products.product_id = hamrah.order_details.product_id 
    JOIN 
        hamrah.categories ON hamrah.categories.category_id = hamrah.products.category_id 
    GROUP BY 
        hamrah.users.user_id
)

SELECT 
    hamrah.users.user_id,
    SUM(hamrah.orders.total_amount) AS TotalSPENT,
    COALESCE(Category_count.TotalAmount, 0) AS TotalAmount,  
    (SELECT CategoryID FROM MostPopularCat) AS MostPopularCategory
FROM 
    hamrah.users
LEFT JOIN 
    Category_count ON Category_count.user_id = hamrah.users.user_id
JOIN 
    hamrah.orders ON hamrah.orders.user_id = hamrah.users.user_id
WHERE hamrah.orders.order_status = "complete"
GROUP BY 
    hamrah.users.user_id;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE hamrah

WITH MostPopularCategory AS (
    SELECT 
        categories.category_id,
        AVG(reviews.rating) AS average_rating
    FROM 
        hamrah.categories
    JOIN 
        hamrah.products ON hamrah.categories.category_id = hamrah.products.category_id
    JOIN 
        hamrah.reviews ON hamrah.products.product_id = hamrah.reviews.product_id
    GROUP BY 
        categories.category_id
    ORDER BY 
        average_rating DESC
    LIMIT 1
),

MostPurchasedProduct AS (
    SELECT 
        order_details.product_id, 
        COUNT(order_details.product_id) AS total_sold
    FROM 
        hamrah.order_details
    GROUP BY 
        order_details.product_id
    ORDER BY 
        total_sold DESC
    LIMIT 1
),

IsLoyalCustomer AS (
    SELECT 
        orders.user_id,
        COUNT(orders.order_id) AS total_orders_30days
    FROM 
        hamrah.orders
    WHERE 
        orders.created_at BETWEEN (
            SELECT MAX(inner_orders.created_at) - INTERVAL 30 DAY
            FROM hamrah.orders AS inner_orders
            WHERE inner_orders.user_id = orders.user_id
        )
        AND (
            SELECT MAX(inner_orders.created_at)
            FROM hamrah.orders AS inner_orders
            WHERE inner_orders.user_id = orders.user_id
        )
    GROUP BY 
        orders.user_id),

AverageOrderValue AS (
    SELECT 
        orders.user_id,
        AVG(orders.total_amount) AS average_order_value,
        RANK() OVER (ORDER BY AVG(orders.total_amount) DESC) AS rank_value
    FROM 
        hamrah.orders
    GROUP BY 
        orders.user_id
),

LastOrderDate AS (
    SELECT 
        orders.user_id, 
        MAX(orders.created_at) AS last_order_date
    FROM 
        hamrah.orders
    GROUP BY 
        orders.user_id
)

SELECT 
    orders.user_id,
    COUNT(orders.order_id) AS total_orders,
    SUM(orders.total_amount) AS total_spent,
    COALESCE(AverageOrderValue.average_order_value, 0) AS average_order_value,
    COALESCE(AverageOrderValue.rank_value, 0) AS rank_value,
    COALESCE(LastOrderDate.last_order_date, 'N/A') AS last_order_date,
    (SELECT category_id FROM MostPopularCategory LIMIT 1) AS most_popular_category,
    (SELECT product_id FROM MostPurchasedProduct LIMIT 1) AS most_purchased_product,
    (SELECT total_sold FROM MostPurchasedProduct LIMIT 1) AS total_sold,
    CASE 
        WHEN COALESCE(IsLoyalCustomer.total_orders_30days, 0) > 2 THEN 'Yes' 
        ELSE 'No' 
    END AS is_loyal_customer
FROM 
    hamrah.orders
LEFT JOIN 
    AverageOrderValue ON hamrah.orders.user_id = AverageOrderValue.user_id
LEFT JOIN 
    LastOrderDate ON hamrah.orders.user_id = LastOrderDate.user_id
LEFT JOIN 
    IsLoyalCustomer ON hamrah.orders.user_id = IsLoyalCustomer.user_id
WHERE 
    hamrah.orders.order_status = 'complete'
GROUP BY 
    orders.user_id;








    






