-- 1. En excluant les commandes annulées, quelles sont les commandes récentes de moins de 3 mois que les clients ont reçues avec au moins 3 jours de retard ?
WITH recent_orders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM 
        orders o
    WHERE 
        o.order_status != 'canceled' -- Exclure les commandes annulées
        AND o.order_purchase_timestamp BETWEEN '2018-07-17 00:00:00' AND '2018-10-17 17:30:18' -- Commandes des 3 derniers mois avant le 17 octobre 2018
),
delivery_delays AS (
    SELECT 
        r.order_id,
        (julianday(r.order_delivered_customer_date) - julianday(r.order_estimated_delivery_date)) AS delivery_delay_days
    FROM 
        recent_orders r
    WHERE 
        (julianday(r.order_delivered_customer_date) - julianday(r.order_estimated_delivery_date)) >= 3 -- Retard de 3 jours ou plus
)
SELECT 
    r.order_id,
    r.customer_id,
    r.order_purchase_timestamp,
    r.order_status,
    r.order_delivered_customer_date,
    r.order_estimated_delivery_date,
    d.delivery_delay_days
FROM 
    recent_orders r
JOIN 
    delivery_delays d ON r.order_id = d.order_id
ORDER BY 
    r.order_purchase_timestamp DESC; -- Tri par date d'achat, de la plus récente à la plus ancienne

    
-- 2. Qui sont les vendeurs ayant généré un chiffre d'affaires de plus de 100000 Real sur des commandes livrées via Olist ?
WITH seller_revenue AS (
    SELECT 
        oi.seller_id, 
        SUM(oi.price) AS total_revenue -- Total du chiffre d'affaires généré par chaque vendeur
    FROM 
        order_items oi
    JOIN 
        orders o ON oi.order_id = o.order_id
    WHERE 
        o.order_status = 'delivered' -- Filtrer uniquement les commandes livrées
    GROUP BY 
        oi.seller_id
)
SELECT 
    seller_id,
    total_revenue
FROM 
    seller_revenue
WHERE 
    total_revenue > 100000 -- Filtrer les vendeurs dont le chiffre d'affaires est supérieur à 100 000 Real
ORDER BY 
    total_revenue DESC; -- Trier par chiffre d'affaires décroissant

    

-- 3. Qui sont les nouveaux vendeurs (moins de 3 mois d'ancienneté) qui sont déjà très engagés avec la plateforme (ayant déjà vendu plus de 30 produits) ?
WITH new_sellers AS (
    SELECT 
        oi.seller_id,
        MIN(o.order_purchase_timestamp) AS first_order_date -- Première commande du vendeur
    FROM 
        order_items oi
    JOIN 
        orders o ON oi.order_id = o.order_id
    WHERE 
        o.order_status = 'delivered' -- Filtrer les commandes livrées
    GROUP BY 
        oi.seller_id
    HAVING 
        first_order_date BETWEEN '2018-07-17' AND '2018-10-17' -- Vendeurs dont la première commande est entre le 17 juillet et le 17 octobre 2018
),
seller_activity AS (
    SELECT 
        oi.seller_id,
        COUNT(oi.order_item_id) AS total_products_sold -- Nombre total de produits vendus par chaque vendeur
    FROM 
        order_items oi
    JOIN 
        orders o ON oi.order_id = o.order_id
    WHERE 
        o.order_status = 'delivered' -- Filtrer les commandes livrées
    GROUP BY 
        oi.seller_id
)
SELECT 
    sa.seller_id,
    sa.total_products_sold
FROM 
    seller_activity sa
JOIN 
    new_sellers ns ON sa.seller_id = ns.seller_id
WHERE 
    sa.total_products_sold > 30 -- Filtrer les vendeurs ayant vendu plus de 30 produits
ORDER BY 
    sa.total_products_sold DESC; -- Trier par nombre de produits vendus décroissant

   

-- 4. Quels sont les 5 codes postaux, enregistrant plus de 30 reviews, avec le pire review score moyen sur les 12 derniers mois ? 
WITH review_data AS (
    SELECT 
        c.customer_zip_code_prefix, 
        ov.review_score, 
        ov.review_id, 
        ov.review_answer_timestamp
    FROM 
        order_reviews ov
    JOIN 
        orders o ON ov.order_id = o.order_id -- Jointure avec la table orders pour obtenir customer_id
    JOIN 
        customers c ON o.customer_id = c.customer_id -- Jointure avec la table customers pour obtenir customer_zip_code_prefix
    WHERE 
        ov.review_answer_timestamp BETWEEN '2017-10-17' AND '2018-10-17' -- Période des 12 derniers mois
),
review_summary AS (
    SELECT 
        customer_zip_code_prefix, 
        AVG(review_score) AS avg_review_score, -- Calcul de la moyenne des scores de revue
        COUNT(review_id) AS total_reviews -- Nombre total de revues
    FROM 
        review_data
    GROUP BY 
        customer_zip_code_prefix
    HAVING 
        total_reviews > 30 -- Plus de 30 revues
)
SELECT 
    customer_zip_code_prefix, 
    avg_review_score, 
    total_reviews
FROM 
    review_summary
ORDER BY 
    avg_review_score ASC -- Trier par score moyen (du pire au meilleur)
LIMIT 5; -- Limiter à 5 codes postaux avec le pire score moyen

  