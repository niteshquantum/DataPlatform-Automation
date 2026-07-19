CREATE FUNCTION fn_active_brand_count()
RETURNS INT
DETERMINISTIC
READS SQL DATA
RETURN (
    SELECT COUNT(*)
    FROM brands
    WHERE Brand_Status = 'Active'
);