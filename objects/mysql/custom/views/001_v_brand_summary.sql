CREATE OR REPLACE VIEW v_brand_summary AS

SELECT
    Brand_ID,
    Brand_Name,
    Parent_Company,
    Brand_Origin_Country,
    Brand_Tier,
    Brand_Status
FROM brands
WHERE Brand_Status IS NOT NULL;