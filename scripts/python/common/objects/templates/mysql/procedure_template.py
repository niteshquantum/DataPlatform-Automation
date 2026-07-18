PROCEDURE_TEMPLATE = """
DELIMITER $$

CREATE PROCEDURE {procedure_name}()

BEGIN

SELECT *

FROM {table_name}

LIMIT {limit};

END$$

DELIMITER ;
""".strip()