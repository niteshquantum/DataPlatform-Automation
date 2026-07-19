CREATE EVENT ev_daily_brand_maintenance
ON SCHEDULE EVERY 1 DAY
DO
    SELECT COUNT(*)
    FROM brands;