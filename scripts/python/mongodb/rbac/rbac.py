"""MongoDB RBAC provisioning using native custom roles and authenticated users."""
from __future__ import annotations
import sys
from pathlib import Path
from pymongo import MongoClient
from pymongo.errors import OperationFailure
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT))
from scripts.python.common.rbac_config import database_rbac_config
from scripts.python.common.rbac_logging import get_rbac_logger
from scripts.python.common.rbac_cli import command_arguments
DATABASE='mongodb'
def client(c,user=None,password=None):
 kw={'host':c['MONGODB_HOST'],'port':int(c['MONGODB_PORT']),'serverSelectionTimeoutMS':10000}
 if user: kw.update(username=user,password=password,authSource='admin')
 return MongoClient(**kw)
def configure():
 c,u=database_rbac_config(DATABASE);log=get_rbac_logger(DATABASE)
 if c.get('RBAC_ENABLED','true').lower()=='false':log.info('RBAC disabled by configuration');return
 # With --auth, MongoDB's localhost exception permits bootstrap of the first admin user.
 bootstrap=client(c);admin=bootstrap['admin']
 try:
  command_line = admin.command('getCmdLineOpts')
  authorization = command_line.get('parsed', {}).get('security', {}).get('authorization')
  if authorization != 'enabled':
   raise RuntimeError('MongoDB authorization is not enabled; restart mongod with --auth before configuring RBAC')
  info=admin.command('usersInfo',u['admin']['username'])
  if not info.get('users'): admin.command('createUser',u['admin']['username'],pwd=u['admin']['password'],roles=['root']);log.info('bootstrap admin created')
 finally: bootstrap.close()
 x=client(c,u['admin']['username'],u['admin']['password']);a=x['admin'];db=c['MONGODB_DATABASE']
 role_specs={
  'developer': [{'resource':{'db':db,'collection':''},'actions':['find','insert','update','remove','createCollection','createIndex','dropIndex','collMod']}],
  'qa': [{'resource':{'db':db,'collection':''},'actions':['find']}],
  'viewer': [{'resource':{'db':db,'collection':''},'actions':['find']}],
 }
 try:
  for role,privileges in role_specs.items():
   role_name=f'dp_{role}'
   if a.command('rolesInfo',role_name,showPrivileges=False).get('roles'): a.command('updateRole',role_name,privileges=privileges,roles=[])
   else:a.command('createRole',role_name,privileges=privileges,roles=[])
   log.info('role reconciled: %s',role_name)
  for role,z in u.items():
   role_value=['root'] if role=='admin' else [{'role':f'dp_{role}','db':'admin'}]
   if a.command('usersInfo',z['username']).get('users'):a.command('updateUser',z['username'],pwd=z['password'],roles=role_value)
   else:a.command('createUser',z['username'],pwd=z['password'],roles=role_value)
   log.info('user reconciled: %s',z['username'])
  log.info('RBAC configuration PASS')
 finally:x.close()
def validate():
 c,u=database_rbac_config(DATABASE);db=c['MONGODB_DATABASE'];out=[];log=get_rbac_logger(DATABASE)
 def check(label,allow,role,fn):
  try:
   x=client(c,u[role]['username'],u[role]['password']);fn(x[db]);x.close();actual=True
  except Exception as e:actual=False;print(f"{'PASS' if actual==allow else 'FAIL'} {label}: {e.__class__.__name__}")
  else:print(f"{'PASS' if actual==allow else 'FAIL'} {label}")
  out.append(actual==allow)
 check('admin can create users',True,'admin',lambda d:d.client['admin'].command('usersInfo'))
 check('developer can write',True,'developer',lambda d:d['dp_rbac_validation_tmp'].insert_one({'value':1}))
 check('qa cannot modify data',False,'qa',lambda d:d['dp_rbac_validation_tmp'].insert_one({'value':2}))
 check('viewer cannot modify data',False,'viewer',lambda d:d['dp_rbac_validation_tmp'].insert_one({'value':3}))
 x=client(c,u['admin']['username'],u['admin']['password']);x[db].drop_collection('dp_rbac_validation_tmp');x.close()
 log.info('RBAC validation %s','PASS' if all(out) else 'FAIL')
 if not all(out):raise SystemExit(1)
def main():
 a=command_arguments('MongoDB RBAC');configure()
 if a.command=='validate' or not a.skip_validation:validate()
if __name__=='__main__':main()
