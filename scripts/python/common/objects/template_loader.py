import importlib


def load_template(database, object_type):

    module_name = (
        f"templates.{database}.{object_type}_template"
    )

    module = importlib.import_module(module_name)

    variable_name = f"{object_type.upper()}_TEMPLATE"

    return getattr(module, variable_name)


def load_liquibase_template(database, object_type):

    module_name = (
        f"templates.{database}.liquibase_{object_type}_template"
    )

    module = importlib.import_module(module_name)

    variable_name = (
        f"LIQUIBASE_{object_type.upper()}_TEMPLATE"
    )

    return getattr(module, variable_name)