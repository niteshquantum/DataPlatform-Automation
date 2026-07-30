"""Idempotent PostgreSQL role provisioning using native roles and grants."""
from __future__ import annotations
import sys
from pathlib import Path
import psycopg2
from psycopg2 import sql
ROOT = Path(__file__).resolve().parents[4]; sys.path.insert(0, str(ROOT))
from scripts.python.common.rbac_config import database_rbac_config, validate_identifier
from scripts.python.common.rbac_logging import get_rbac_logger
from scripts.python.common.rbac_cli import command_arguments
DATABASE = "postgresql"; ROLE_NAMES = {r: f"dp_{r}" for r in ("admin", "developer", "qa", "viewer")}
def connect(c, database=None, user=None, password=None): return psycopg2.connect(host=c["POSTGRESQL_HOST"], port=int(c["POSTGRESQL_PORT"]), database=database or c["POSTGRESQL_DB"], user=user or c["POSTGRESQL_USER"], password=password or c["POSTGRESQL_PASSWORD"])
def configure():
 c,u=database_rbac_config(DATABASE); log=get_rbac_logger(DATABASE)
 if c.get("RBAC_ENABLED","true").lower()=="false": log.info("RBAC disabled by configuration"); return
 db=validate_identifier(c["POSTGRESQL_DB"],"database name"); conn=connect(c,"postgres"); conn.autocommit=True; cur=conn.cursor()
 try:
  for r,n in ROLE_NAMES.items():
   cur.execute(sql.SQL("DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname={n}) THEN CREATE ROLE {i} NOLOGIN; END IF; END $$").format(n=sql.Literal(n),i=sql.Identifier(n)))
  cur.execute(sql.SQL("ALTER ROLE {} CREATEROLE CREATEDB").format(sql.Identifier(ROLE_NAMES['admin'])))
  for r,x in u.items():
   cur.execute(sql.SQL("DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname={n}) THEN CREATE ROLE {i} LOGIN PASSWORD {p}; ELSE ALTER ROLE {i} LOGIN PASSWORD {p}; END IF; END $$").format(n=sql.Literal(x['username']),i=sql.Identifier(x['username']),p=sql.Literal(x['password'])))
   cur.execute(sql.SQL("GRANT {} TO {}").format(sql.Identifier(ROLE_NAMES[r]),sql.Identifier(x['username'])))
   log.info("user and role reconciled: %s -> %s",x['username'],ROLE_NAMES[r])
  cur.execute(sql.SQL("GRANT ALL PRIVILEGES ON DATABASE {} TO {}").format(sql.Identifier(db),sql.Identifier(ROLE_NAMES['admin'])))
 finally: cur.close(); conn.close()
 conn=connect(c); conn.autocommit=True; cur=conn.cursor()
 try:
  for role in ('developer','qa','viewer'):
   cur.execute(sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(sql.Identifier(db),sql.Identifier(ROLE_NAMES[role])))
   cur.execute(sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(sql.Identifier(ROLE_NAMES[role])))
  cur.execute(sql.SQL("GRANT CREATE ON SCHEMA public TO {}").format(sql.Identifier(ROLE_NAMES['developer'])))
  cur.execute(sql.SQL("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {}").format(sql.Identifier(ROLE_NAMES['developer'])))
  cur.execute(sql.SQL("GRANT SELECT ON ALL TABLES IN SCHEMA public TO {}, {}").format(sql.Identifier(ROLE_NAMES['qa']),sql.Identifier(ROLE_NAMES['viewer'])))
  cur.execute(sql.SQL("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {}").format(sql.Identifier(ROLE_NAMES['developer'])))
  cur.execute(sql.SQL("GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO {}, {}").format(sql.Identifier(ROLE_NAMES['developer']),sql.Identifier(ROLE_NAMES['qa'])))
  for role, privileges in [('developer','SELECT, INSERT, UPDATE, DELETE'),('qa','SELECT'),('viewer','SELECT')]:
   cur.execute(sql.SQL("ALTER DEFAULT PRIVILEGES FOR ROLE {} IN SCHEMA public GRANT {} ON TABLES TO {}").format(sql.Identifier(c['POSTGRESQL_USER']),sql.SQL(privileges),sql.Identifier(ROLE_NAMES[role])))
  cur.execute(sql.SQL("ALTER DEFAULT PRIVILEGES FOR ROLE {} IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO {}, {}").format(sql.Identifier(c['POSTGRESQL_USER']),sql.Identifier(ROLE_NAMES['developer']),sql.Identifier(ROLE_NAMES['qa'])))
  log.info("RBAC configuration PASS")
 finally: cur.close(); conn.close()
def validate():
 c,u=database_rbac_config(DATABASE); log=get_rbac_logger(DATABASE); outcomes=[]
 def check(label,allow,role,statement):
  try:
   x=connect(c,user=u[role]['username'],password=u[role]['password']); x.autocommit=True; q=x.cursor(); q.execute(statement); q.close(); x.close(); actual=True
  except Exception as e: actual=False; print(f"{'PASS' if actual==allow else 'FAIL'} {label}: {e.__class__.__name__}")
  else: print(f"{'PASS' if actual==allow else 'FAIL'} {label}")
  outcomes.append(actual==allow)
 check('admin can create database',True,'admin','CREATE DATABASE dp_rbac_validation_tmp')
 # Cleanup is separately performed as configured DB owner; no user data is touched.
 x=connect(c,'postgres'); x.autocommit=True; q=x.cursor(); q.execute('DROP DATABASE IF EXISTS dp_rbac_validation_tmp'); q.close(); x.close()
 check('developer can create table',True,'developer','CREATE TABLE public.dp_rbac_validation_tmp(id integer)')
 check('developer can insert',True,'developer','INSERT INTO public.dp_rbac_validation_tmp VALUES (1)')
 check('developer can update',True,'developer','UPDATE public.dp_rbac_validation_tmp SET id=2 WHERE id=1')
 check('developer can delete',True,'developer','DELETE FROM public.dp_rbac_validation_tmp WHERE id=2')
 check('developer cannot manage users',False,'developer','CREATE ROLE dp_denied LOGIN')
 check('qa can read',True,'qa','SELECT * FROM public.dp_rbac_validation_tmp')
 check('qa cannot write',False,'qa','INSERT INTO public.dp_rbac_validation_tmp VALUES (1)')
 check('viewer can read',True,'viewer','SELECT * FROM public.dp_rbac_validation_tmp')
 check('viewer cannot insert',False,'viewer','INSERT INTO public.dp_rbac_validation_tmp VALUES (1)')
 check('viewer cannot modify schema',False,'viewer','ALTER TABLE public.dp_rbac_validation_tmp ADD COLUMN x integer')
 x=connect(c); x.autocommit=True; q=x.cursor(); q.execute('DROP TABLE IF EXISTS public.dp_rbac_validation_tmp'); q.close(); x.close()
 log.info('RBAC validation %s','PASS' if all(outcomes) else 'FAIL')
 if not all(outcomes): raise SystemExit(1)
def main():
 a=command_arguments('PostgreSQL RBAC'); configure()
 if a.command=='validate' or not a.skip_validation: validate()
if __name__=='__main__': main()
