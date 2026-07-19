CREATE PROCEDURE sp_get_active_brands()
SELECT
    Brand_ID,
    Brand_Name,
    Parent_Company,
    Brand_Origin_Country,
    Brand_Tier
FROM brands
WHERE Brand_Status = 'Active';