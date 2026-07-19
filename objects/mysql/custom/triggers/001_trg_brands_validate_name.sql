CREATE TRIGGER trg_brands_validate_name
BEFORE INSERT ON brands
FOR EACH ROW
SET NEW.Brand_Name = TRIM(NEW.Brand_Name);