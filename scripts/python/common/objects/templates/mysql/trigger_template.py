TRIGGER_TEMPLATE = """
DELIMITER $$

CREATE TRIGGER {trigger_name}

BEFORE INSERT

ON {table_name}

FOR EACH ROW

BEGIN

SET NEW.created_at = NOW();

END$$

DELIMITER ;
""".strip()