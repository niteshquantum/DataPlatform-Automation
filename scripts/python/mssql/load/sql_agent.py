import sys
from scripts.python.mssql.setup.db_connection import get_connection


def rows(query):
    conn = get_connection('msdb'); cursor = conn.cursor(); cursor.execute(query)
    result = cursor.fetchall(); cursor.close(); conn.close(); return result


def inventory():
    for row in rows("""SELECT j.name, SUSER_SNAME(j.owner_sid), c.name, j.enabled, ISNULL(s.name, ''), ISNULL(j.description, '') FROM dbo.sysjobs j LEFT JOIN dbo.syscategories c ON c.category_id=j.category_id LEFT JOIN dbo.sysjobschedules js ON js.job_id=j.job_id LEFT JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id ORDER BY j.name"""):
        print(f"Job Name: {row[0]} | Owner: {row[1]} | Category: {row[2]} | Enabled: {bool(row[3])} | Schedule: {row[4]} | Description: {row[5]}")


def validation():
    for row in rows("""SELECT j.name, j.enabled, MAX(CASE WHEN h.instance_id IS NOT NULL THEN CONVERT(varchar(19), msdb.dbo.agent_datetime(h.run_date,h.run_time),120) END), MIN(CASE WHEN s.enabled=1 THEN s.name END) FROM dbo.sysjobs j LEFT JOIN dbo.sysjobhistory h ON h.job_id=j.job_id AND h.step_id=0 LEFT JOIN dbo.sysjobschedules js ON js.job_id=j.job_id LEFT JOIN dbo.sysschedules s ON s.schedule_id=js.schedule_id GROUP BY j.name,j.enabled ORDER BY j.name"""):
        print(f"Exists: True | Job Name: {row[0]} | Enabled: {bool(row[1])} | Last Run: {row[2] or ''} | Next Run: {row[3] or ''}")


def history():
    for row in rows("""SELECT j.name, msdb.dbo.agent_datetime(h.run_date,h.run_time), h.run_duration, h.run_status, h.message FROM dbo.sysjobhistory h JOIN dbo.sysjobs j ON j.job_id=h.job_id WHERE h.step_id=0 ORDER BY h.instance_id DESC"""):
        print(f"Job Name: {row[0]} | Run Date: {row[1]} | Duration: {row[2]} | Status: {row[3]} | Message: {row[4]}")


def assessment():
    for row in rows("""SELECT COUNT(*), SUM(CASE WHEN enabled=1 THEN 1 ELSE 0 END), SUM(CASE WHEN enabled=0 THEN 1 ELSE 0 END) FROM dbo.sysjobs"""):
        print(f"Total Jobs: {row[0]} | Enabled Jobs: {row[1] or 0} | Disabled Jobs: {row[2] or 0}")


if __name__ == '__main__':
    {'inventory': inventory, 'validation': validation, 'history': history, 'assessment': assessment}[sys.argv[1]]()
