from xml_generators.xml_generator_base import XMLGeneratorBase


def generate_event_xml(database):

    generator = XMLGeneratorBase(
        database,
        "events"
    )

    sql_files = sorted(
        generator.sql_folder.glob("*.sql")
    )

    for change_id, sql_file in enumerate(sql_files, start=1):

        xml = generator.template.format(

            id=f"event-{change_id}",

            sql_path=f"../../../../objects/generated/events/{sql_file.name}"

        )

        xml_file = (
            generator.xml_folder
            / f"{sql_file.stem}.xml"
        )

        with open(
            xml_file,
            "w",
            encoding="utf-8"
        ) as file:

            file.write(xml)

        print(f"Generated : {xml_file.name}")