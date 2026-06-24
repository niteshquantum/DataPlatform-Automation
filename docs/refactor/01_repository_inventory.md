# Repository Inventory

Generated from filesystem inspection only. No source, pipeline, or infrastructure files were moved or changed.

## Summary

- Total files scanned: 1052
- Text files parsed: 370
- Runtime/generated artifact candidates: 604
- Exact duplicate groups: 24

## Top-Level Inventory

| Area | File Count |
| --- | --- |
| .env | 1 |
| .env.example | 1 |
| .gitignore | 1 |
| README.md | 1 |
| archive | 7 |
| config | 13 |
| databases | 608 |
| datasets | 20 |
| docs | 1 |
| failed | 6 |
| incoming | 10 |
| jenkins | 46 |
| liquibase | 19 |
| logs | 2 |
| metadata | 16 |
| requirements.txt | 1 |
| scripts | 221 |
| terraform | 26 |
| tools | 52 |

## Extension Inventory

| Extension | File Count |
| --- | --- |
| .0000000001 | 1 |
| .0000000016 | 1 |
| .000001 | 1 |
| .000002 | 1 |
| .000003 | 1 |
| .000004 | 1 |
| .000005 | 1 |
| .000006 | 1 |
| .000007 | 1 |
| .000008 | 1 |
| .000009 | 1 |
| .000010 | 1 |
| .000011 | 1 |
| .000012 | 1 |
| .000013 | 1 |
| .000014 | 1 |
| .000015 | 1 |
| .2026-06-18t17-10-36z-00000 | 1 |
| .2026-06-23t09-12-34 | 1 |
| .2026-06-23t09-12-51z-00000 | 1 |
| .2026-06-23t09-29-08 | 1 |
| .2026-06-23t09-29-22z-00000 | 1 |
| .2026-06-23t09-33-42 | 1 |
| .2026-06-23t09-33-57z-00000 | 1 |
| .2026-06-23t09-57-06 | 1 |
| .2026-06-23t09-57-23z-00000 | 1 |
| .2026-06-23t10-12-09 | 1 |
| .2026-06-23t10-12-26z-00000 | 1 |
| .2026-06-23t10-47-02 | 1 |
| .2026-06-23t10-47-18z-00000 | 1 |
| .2026-06-23t10-50-14 | 1 |
| .2026-06-23t10-50-32z-00000 | 1 |
| .2026-06-23t10-58-16 | 1 |
| .2026-06-23t10-58-33z-00000 | 1 |
| .2026-06-23t11-02-32 | 1 |
| .2026-06-23t11-02-59z-00000 | 1 |
| .2026-06-23t11-15-59 | 1 |
| .2026-06-23t11-16-20z-00000 | 1 |
| .2026-06-23t11-19-30 | 1 |
| .2026-06-23t11-19-53z-00000 | 1 |
| .2026-06-23t11-26-56 | 1 |
| .2026-06-23t11-27-19z-00000 | 1 |
| .2026-06-23t11-32-49 | 1 |
| .2026-06-23t11-33-06z-00000 | 1 |
| .2026-06-23t11-35-37 | 1 |
| .2026-06-23t11-36-06z-00000 | 1 |
| .2026-06-23t11-54-33 | 1 |
| .2026-06-23t11-55-03z-00000 | 1 |
| .2026-06-23t12-04-10 | 1 |
| .backup | 3 |

## Target Architecture Gaps Seen Immediately

- Missing config targets: config/windows/mysql.conf, config/windows/postgresql.conf, config/ubuntu/mysql.conf, config/ubuntu/postgresql.conf.
- Jenkins contains root, scripts, localwork, custom, testing, and Jenkinsfile artifacts outside the requested two-pipeline model.
- Terraform contains runtime state/artifacts and lacks complete database/OS target folders.
- Tools, databases, logs, .terraform, terraform state, and __pycache__ material should be treated as delete candidates after owner signoff.

## Runtime Artifact Candidates

| Path |
| --- |
| databases/mongodb/data/WiredTiger |
| databases/mongodb/data/WiredTiger.lock |
| databases/mongodb/data/WiredTiger.turtle |
| databases/mongodb/data/WiredTiger.wt |
| databases/mongodb/data/WiredTigerHS.wt |
| databases/mongodb/data/_mdb_catalog.wt |
| databases/mongodb/data/collection-0-11029275549169148852.wt |
| databases/mongodb/data/collection-11-11029275549169148852.wt |
| databases/mongodb/data/collection-13-11029275549169148852.wt |
| databases/mongodb/data/collection-15-11029275549169148852.wt |
| databases/mongodb/data/collection-2-11029275549169148852.wt |
| databases/mongodb/data/collection-4-11029275549169148852.wt |
| databases/mongodb/data/collection-7-11029275549169148852.wt |
| databases/mongodb/data/collection-9-11029275549169148852.wt |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-18T17-10-36Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-12-51Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-29-22Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-33-57Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-57-23Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-12-26Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-47-18Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-50-32Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-58-33Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-02-59Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-16-20Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-19-53Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-27-19Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-33-06Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-36-06Z-00000 |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-55-03Z-00000 |
| databases/mongodb/data/index-1-11029275549169148852.wt |
| databases/mongodb/data/index-10-11029275549169148852.wt |
| databases/mongodb/data/index-12-11029275549169148852.wt |
| databases/mongodb/data/index-14-11029275549169148852.wt |
| databases/mongodb/data/index-16-11029275549169148852.wt |
| databases/mongodb/data/index-17-11029275549169148852.wt |
| databases/mongodb/data/index-18-11029275549169148852.wt |
| databases/mongodb/data/index-19-11029275549169148852.wt |
| databases/mongodb/data/index-20-11029275549169148852.wt |
| databases/mongodb/data/index-21-11029275549169148852.wt |
| databases/mongodb/data/index-3-11029275549169148852.wt |
| databases/mongodb/data/index-5-11029275549169148852.wt |
| databases/mongodb/data/index-6-11029275549169148852.wt |
| databases/mongodb/data/index-8-11029275549169148852.wt |
| databases/mongodb/data/journal/WiredTigerLog.0000000016 |
| databases/mongodb/data/journal/WiredTigerPreplog.0000000001 |
| databases/mongodb/data/mongod.lock |
| databases/mongodb/data/sizeStorer.wt |
| databases/mongodb/data/storage.bson |
| databases/mongodb/logs/mongodb.log |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-12-34 |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-29-08 |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-33-42 |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-57-06 |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-12-09 |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-47-02 |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-50-14 |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-58-16 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-02-32 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-15-59 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-19-30 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-26-56 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-32-49 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-35-37 |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-54-33 |
| databases/mongodb/logs/mongodb.log.2026-06-23T12-04-10 |
| databases/mysql/data/#ib_16384_0.dblwr |
| databases/mysql/data/#ib_16384_1.dblwr |
| databases/mysql/data/#innodb_redo/#ib_redo10_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo11_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo12_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo13_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo14_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo15_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo16_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo17_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo18_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo19_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo20_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo21_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo22_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo23_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo24_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo25_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo26_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo27_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo28_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo29_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo30_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo31_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo32_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo33_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo34_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo35_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo36_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo37_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo6 |
| databases/mysql/data/#innodb_redo/#ib_redo7_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo8_tmp |
| databases/mysql/data/#innodb_redo/#ib_redo9_tmp |
| databases/mysql/data/#innodb_temp/temp_1.ibt |
| databases/mysql/data/#innodb_temp/temp_10.ibt |
| databases/mysql/data/#innodb_temp/temp_2.ibt |
| databases/mysql/data/#innodb_temp/temp_3.ibt |
| databases/mysql/data/#innodb_temp/temp_4.ibt |
| databases/mysql/data/#innodb_temp/temp_5.ibt |
| databases/mysql/data/#innodb_temp/temp_6.ibt |
| databases/mysql/data/#innodb_temp/temp_7.ibt |
| databases/mysql/data/#innodb_temp/temp_8.ibt |
| databases/mysql/data/#innodb_temp/temp_9.ibt |
| databases/mysql/data/Nitesh.err |
| databases/mysql/data/Nitesh.pid |
| databases/mysql/data/auto.cnf |
| databases/mysql/data/binlog.000001 |
| databases/mysql/data/binlog.000002 |
| databases/mysql/data/binlog.000003 |
| databases/mysql/data/binlog.000004 |
| databases/mysql/data/binlog.000005 |
| databases/mysql/data/binlog.000006 |
| databases/mysql/data/binlog.000007 |
| databases/mysql/data/binlog.000008 |
| databases/mysql/data/binlog.000009 |
| databases/mysql/data/binlog.000010 |
| databases/mysql/data/binlog.000011 |
| databases/mysql/data/binlog.000012 |
| databases/mysql/data/binlog.000013 |
| databases/mysql/data/binlog.000014 |
| databases/mysql/data/binlog.000015 |
| databases/mysql/data/binlog.index |
| databases/mysql/data/ca-key.pem |
| databases/mysql/data/ca.pem |
| databases/mysql/data/client-cert.pem |
| databases/mysql/data/client-key.pem |
| databases/mysql/data/ecommercemysql/customers.ibd |
| databases/mysql/data/ecommercemysql/databasechangelog.ibd |
| databases/mysql/data/ecommercemysql/databasechangeloglock.ibd |
| databases/mysql/data/ecommercemysql/orderdetails.ibd |
| databases/mysql/data/ecommercemysql/orderstable.ibd |
| databases/mysql/data/ecommercemysql/products.ibd |
| databases/mysql/data/ecommercemysql/sellers.ibd |
| databases/mysql/data/ib_buffer_pool |
| databases/mysql/data/ibdata1 |
| databases/mysql/data/ibtmp1 |
| databases/mysql/data/mysql.ibd |
| databases/mysql/data/mysql/general_log.CSM |
| databases/mysql/data/mysql/general_log.CSV |
| databases/mysql/data/mysql/general_log_224.sdi |
| databases/mysql/data/mysql/slow_log.CSM |
| databases/mysql/data/mysql/slow_log.CSV |
| databases/mysql/data/mysql/slow_log_225.sdi |
| databases/mysql/data/mysql_upgrade_history |
| databases/mysql/data/performance_schema/accounts_153.sdi |
| databases/mysql/data/performance_schema/binary_log_trans_200.sdi |
| databases/mysql/data/performance_schema/cond_instances_87.sdi |
| databases/mysql/data/performance_schema/data_lock_waits_170.sdi |
| databases/mysql/data/performance_schema/data_locks_169.sdi |
| databases/mysql/data/performance_schema/error_log_88.sdi |
| databases/mysql/data/performance_schema/events_errors_su_147.sdi |
| databases/mysql/data/performance_schema/events_errors_su_148.sdi |
| databases/mysql/data/performance_schema/events_errors_su_149.sdi |
| databases/mysql/data/performance_schema/events_errors_su_150.sdi |
| databases/mysql/data/performance_schema/events_errors_su_151.sdi |
| databases/mysql/data/performance_schema/events_stages_cu_119.sdi |
| databases/mysql/data/performance_schema/events_stages_hi_120.sdi |
| databases/mysql/data/performance_schema/events_stages_hi_121.sdi |
| databases/mysql/data/performance_schema/events_stages_su_122.sdi |
| databases/mysql/data/performance_schema/events_stages_su_123.sdi |
| databases/mysql/data/performance_schema/events_stages_su_124.sdi |
| databases/mysql/data/performance_schema/events_stages_su_125.sdi |
| databases/mysql/data/performance_schema/events_stages_su_126.sdi |
| databases/mysql/data/performance_schema/events_statement_127.sdi |
| databases/mysql/data/performance_schema/events_statement_128.sdi |
| databases/mysql/data/performance_schema/events_statement_129.sdi |
| databases/mysql/data/performance_schema/events_statement_130.sdi |
| databases/mysql/data/performance_schema/events_statement_131.sdi |
| databases/mysql/data/performance_schema/events_statement_132.sdi |
| databases/mysql/data/performance_schema/events_statement_133.sdi |
| databases/mysql/data/performance_schema/events_statement_134.sdi |
| databases/mysql/data/performance_schema/events_statement_135.sdi |
| databases/mysql/data/performance_schema/events_statement_136.sdi |
| databases/mysql/data/performance_schema/events_statement_137.sdi |
| databases/mysql/data/performance_schema/events_statement_138.sdi |
| databases/mysql/data/performance_schema/events_transacti_139.sdi |
| databases/mysql/data/performance_schema/events_transacti_140.sdi |
| databases/mysql/data/performance_schema/events_transacti_141.sdi |
| databases/mysql/data/performance_schema/events_transacti_142.sdi |
| databases/mysql/data/performance_schema/events_transacti_143.sdi |
| databases/mysql/data/performance_schema/events_transacti_144.sdi |
| databases/mysql/data/performance_schema/events_transacti_145.sdi |
| databases/mysql/data/performance_schema/events_transacti_146.sdi |
| databases/mysql/data/performance_schema/events_waits_cur_89.sdi |
| databases/mysql/data/performance_schema/events_waits_his_90.sdi |
| databases/mysql/data/performance_schema/events_waits_his_91.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_92.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_93.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_94.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_95.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_96.sdi |
| databases/mysql/data/performance_schema/events_waits_sum_97.sdi |
| databases/mysql/data/performance_schema/file_instances_98.sdi |
| databases/mysql/data/performance_schema/file_summary_by__100.sdi |
| databases/mysql/data/performance_schema/file_summary_by__99.sdi |
| databases/mysql/data/performance_schema/global_status_190.sdi |
| databases/mysql/data/performance_schema/global_variable__197.sdi |
| databases/mysql/data/performance_schema/global_variables_193.sdi |
| databases/mysql/data/performance_schema/host_cache_101.sdi |
| databases/mysql/data/performance_schema/hosts_154.sdi |
| databases/mysql/data/performance_schema/keyring_componen_202.sdi |
| databases/mysql/data/performance_schema/keyring_keys_160.sdi |
| databases/mysql/data/performance_schema/log_status_183.sdi |
| databases/mysql/data/performance_schema/memory_summary_b_162.sdi |
| databases/mysql/data/performance_schema/memory_summary_b_163.sdi |
| databases/mysql/data/performance_schema/memory_summary_b_164.sdi |
| databases/mysql/data/performance_schema/memory_summary_b_165.sdi |
| databases/mysql/data/performance_schema/memory_summary_g_161.sdi |
| databases/mysql/data/performance_schema/metadata_locks_168.sdi |
| databases/mysql/data/performance_schema/mutex_instances_102.sdi |
| databases/mysql/data/performance_schema/objects_summary__103.sdi |
| databases/mysql/data/performance_schema/performance_time_104.sdi |
| databases/mysql/data/performance_schema/persisted_variab_198.sdi |
| databases/mysql/data/performance_schema/prepared_stateme_184.sdi |
| databases/mysql/data/performance_schema/processlist_105.sdi |
| databases/mysql/data/performance_schema/replication_appl_174.sdi |
| databases/mysql/data/performance_schema/replication_appl_175.sdi |
| databases/mysql/data/performance_schema/replication_appl_176.sdi |
| databases/mysql/data/performance_schema/replication_appl_177.sdi |
| databases/mysql/data/performance_schema/replication_appl_179.sdi |
| databases/mysql/data/performance_schema/replication_appl_180.sdi |
| databases/mysql/data/performance_schema/replication_asyn_181.sdi |
| databases/mysql/data/performance_schema/replication_asyn_182.sdi |
| databases/mysql/data/performance_schema/replication_conn_171.sdi |
| databases/mysql/data/performance_schema/replication_conn_173.sdi |
| databases/mysql/data/performance_schema/replication_grou_172.sdi |
| databases/mysql/data/performance_schema/replication_grou_178.sdi |
| databases/mysql/data/performance_schema/rwlock_instances_106.sdi |
| databases/mysql/data/performance_schema/session_account__159.sdi |
| databases/mysql/data/performance_schema/session_connect__158.sdi |
| databases/mysql/data/performance_schema/session_status_191.sdi |
| databases/mysql/data/performance_schema/session_variable_194.sdi |
| databases/mysql/data/performance_schema/setup_actors_107.sdi |
| databases/mysql/data/performance_schema/setup_consumers_108.sdi |
| databases/mysql/data/performance_schema/setup_instrument_109.sdi |
| databases/mysql/data/performance_schema/setup_loggers_110.sdi |
| databases/mysql/data/performance_schema/setup_meters_111.sdi |
| databases/mysql/data/performance_schema/setup_metrics_112.sdi |
| databases/mysql/data/performance_schema/setup_objects_113.sdi |
| databases/mysql/data/performance_schema/setup_threads_114.sdi |
| databases/mysql/data/performance_schema/socket_instances_155.sdi |
| databases/mysql/data/performance_schema/socket_summary_b_156.sdi |
| databases/mysql/data/performance_schema/socket_summary_b_157.sdi |
| databases/mysql/data/performance_schema/status_by_accoun_186.sdi |
| databases/mysql/data/performance_schema/status_by_host_187.sdi |
| databases/mysql/data/performance_schema/status_by_thread_188.sdi |
| databases/mysql/data/performance_schema/status_by_user_189.sdi |
| databases/mysql/data/performance_schema/table_handles_166.sdi |
| databases/mysql/data/performance_schema/table_io_waits_s_115.sdi |
| databases/mysql/data/performance_schema/table_io_waits_s_116.sdi |
| databases/mysql/data/performance_schema/table_lock_waits_117.sdi |
| databases/mysql/data/performance_schema/temporary_accoun_167.sdi |
| databases/mysql/data/performance_schema/threads_118.sdi |
| databases/mysql/data/performance_schema/tls_channel_stat_201.sdi |
| databases/mysql/data/performance_schema/user_defined_fun_199.sdi |
| databases/mysql/data/performance_schema/user_variables_b_185.sdi |
| databases/mysql/data/performance_schema/users_152.sdi |
| databases/mysql/data/performance_schema/variables_by_thr_192.sdi |
| databases/mysql/data/performance_schema/variables_info_195.sdi |
| databases/mysql/data/performance_schema/variables_metada_196.sdi |
| databases/mysql/data/private_key.pem |
| databases/mysql/data/public_key.pem |
| databases/mysql/data/server-cert.pem |
| databases/mysql/data/server-key.pem |
| databases/mysql/data/sys/sys_config.ibd |
| databases/mysql/data/undo_001 |
| databases/mysql/data/undo_002 |
| databases/mysql/server/LICENSE |
| databases/mysql/server/README |
| databases/mysql/server/bin/abseil_dll-debug.dll |
| databases/mysql/server/bin/abseil_dll-debug.pdb |
| databases/mysql/server/bin/abseil_dll.dll |
| databases/mysql/server/bin/abseil_dll.lib |
| databases/mysql/server/bin/ccapiserver.exe |
| databases/mysql/server/bin/comerr64.dll |
| databases/mysql/server/bin/echo.exe |
| databases/mysql/server/bin/fido2.dll |
| databases/mysql/server/bin/fido2.lib |
| databases/mysql/server/bin/gssapi64.dll |
| databases/mysql/server/bin/ibd2sdi.exe |
| databases/mysql/server/bin/innochecksum.exe |
| databases/mysql/server/bin/jemalloc.dll |
| databases/mysql/server/bin/jemalloc.pdb |
| databases/mysql/server/bin/k5sprt64.dll |
| databases/mysql/server/bin/krb5_64.dll |
| databases/mysql/server/bin/krbcc64.dll |
| databases/mysql/server/bin/libcrypto-3-x64.dll |
| databases/mysql/server/bin/libcrypto-3-x64.pdb |
| databases/mysql/server/bin/libmecab.dll |
| databases/mysql/server/bin/libprotobuf-debug.dll |
| databases/mysql/server/bin/libprotobuf-lite-debug.dll |
| databases/mysql/server/bin/libprotobuf-lite.dll |
| databases/mysql/server/bin/libprotobuf-lite.lib |
