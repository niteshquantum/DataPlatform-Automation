"""Idempotent SQL Server RBAC provisioning with server logins and database users."""
from __future__ import annotations
import sys
from pathlib import Path
import pyodbc
ROOT=Path(__file__).resolve().parents[4]; sys.path.insert(0,str(ROOT))
from scripts.python.common.rbac_config import database_rbac_config,validate_identifier
from scripts.python.common.rbac_logging import get_rbac_logger
from scripts.python.common.rbac_cli import command_arguments
DATABASE='mssql'
def connect(c,database=None,user=None,password=None):
 db=database or c['MSSQL_DB']; return pyodbc.connect(f"DRIVER={{{c['MSSQL_ODBC_DRIVER']}}};SERVER={c['MSSQL_HOST']},{c['MSSQL_PORT']};DATABASE={db};UID={user or c['MSSQL_USER']};PWD={password or c['MSSQL_PASSWORD']};Encrypt=no;TrustServerCertificate=yes;",autocommit=True)
def ident(v): return '['+validate_identifier(v)+']'
def esc(v): return v.replace("'","''")
def configure():
 c,u=database_rbac_config(DATABASE); log=get_rbac_logger(DATABASE)
 if c.get('RBAC_ENABLED','true').lower()=='false': log.info('RBAC disabled by configuration'); return
 db=ident(c['MSSQL_DB']); x=connect(c,'master'); q=x.cursor()
 try:
  for role,z in u.items():
   name=ident(z['username']); pwd=esc(z['password'])
   q.execute(f"IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name=N'{esc(z['username'])}') CREATE LOGIN {name} WITH PASSWORD=N'{pwd}', CHECK_POLICY=ON, CHECK_EXPIRATION=OFF; ELSE ALTER LOGIN {name} WITH PASSWORD=N'{pwd}';")
   if role=='admin': q.execute(f"IF NOT EXISTS (SELECT 1 FROM sys.server_role_members m JOIN sys.server_principals r ON m.role_principal_id=r.principal_id JOIN sys.server_principals p ON m.member_principal_id=p.principal_id WHERE r.name='sysadmin' AND p.name=N'{esc(z['username'])}') ALTER SERVER ROLE [sysadmin] ADD MEMBER {name};")
  log.info('server logins reconciled')
 finally:q.close();x.close()
 x=connect(c);q=x.cursor()
 try:
  for role,z in u.items():
   name=ident(z['username']); n=esc(z['username'])
   q.execute(f"IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'{n}') CREATE USER {name} FOR LOGIN {name};")
   if role=='admin': q.execute(f"IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON m.role_principal_id=r.principal_id JOIN sys.database_principals p ON m.member_principal_id=p.principal_id WHERE r.name='db_owner' AND p.name=N'{n}') ALTER ROLE [db_owner] ADD MEMBER {name};")
   if role=='developer':
    for r in ('db_datareader','db_datawriter','db_ddladmin'): q.execute(f"IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON m.role_principal_id=r.principal_id JOIN sys.database_principals p ON m.member_principal_id=p.principal_id WHERE r.name='{r}' AND p.name=N'{n}') ALTER ROLE [{r}] ADD MEMBER {name};")
    q.execute(f'GRANT EXECUTE TO {name}')
   if role=='qa': q.execute(f'ALTER ROLE [db_datareader] ADD MEMBER {name}; GRANT EXECUTE TO {name}')
   if role=='viewer': q.execute(f'ALTER ROLE [db_datareader] ADD MEMBER {name}')
   log.info('database user reconciled: %s',z['username'])
  log.info('RBAC configuration PASS')
 finally:q.close();x.close()
def validate():
 c,u=database_rbac_config(DATABASE);out=[]; log=get_rbac_logger(DATABASE)
 def check(label,allow,role,stmt,database=None):
  try:
   x=connect(c,database,user=u[role]['username'],password=u[role]['password']);q=x.cursor();q.execute(stmt);q.close();x.close();actual=True
  except Exception as e:actual=False;print(f"{'PASS' if actual==allow else 'FAIL'} {label}: {e.__class__.__name__}")
  else:print(f"{'PASS' if actual==allow else 'FAIL'} {label}")
  out.append(actual==allow)
 check('admin can create database',True,'admin','CREATE DATABASE dp_rbac_validation_tmp','master')
 x=connect(c,'master');x.cursor().execute('DROP DATABASE IF EXISTS dp_rbac_validation_tmp');x.close()
 check('developer can create table',True,'developer','CREATE TABLE dbo.dp_rbac_validation_tmp(id int)')
 check('developer cannot manage users',False,'developer',"CREATE USER dp_denied WITHOUT LOGIN")
 check('qa cannot modify data',False,'qa','INSERT INTO dbo.dp_rbac_validation_tmp VALUES (1)')
 check('viewer cannot modify schema',False,'viewer','ALTER TABLE dbo.dp_rbac_validation_tmp ADD x int')
 x=connect(c);x.cursor().execute('DROP TABLE IF EXISTS dbo.dp_rbac_validation_tmp');x.close()
 log.info('RBAC validation %s','PASS' if all(out) else 'FAIL')
 if not all(out):raise SystemExit(1)
def main():
 a=command_arguments('SQL Server RBAC');configure()
 if a.command=='validate' or not a.skip_validation:validate()
if __name__=='__main__':main()
