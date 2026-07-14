# Dead Files

Policy: do not delete, archive, move, or modify. Mark only as DELETE CANDIDATE pending owner approval and pipeline validation.

## High-Confidence Delete Candidates

| Path | Justification |
| --- | --- |
| databases/mongodb/data/WiredTiger | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/WiredTiger.lock | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/WiredTiger.turtle | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/WiredTiger.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/WiredTigerHS.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/_mdb_catalog.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-0-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-11-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-13-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-15-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-2-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-4-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-7-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/collection-9-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-18T17-10-36Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-12-51Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-29-22Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-33-57Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-57-23Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-12-26Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-47-18Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-50-32Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-58-33Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-02-59Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-16-20Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-19-53Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-27-19Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-33-06Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-36-06Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-55-03Z-00000 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-1-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-10-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-12-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-14-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-16-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-17-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-18-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-19-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-20-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-21-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-3-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-5-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-6-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/index-8-11029275549169148852.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/journal/WiredTigerLog.0000000016 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/journal/WiredTigerPreplog.0000000001 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/mongod.lock | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/sizeStorer.wt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/data/storage.bson | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-12-34 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-29-08 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-33-42 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T09-57-06 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-12-09 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-47-02 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-50-14 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T10-58-16 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-02-32 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-15-59 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-19-30 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-26-56 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-32-49 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-35-37 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T11-54-33 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mongodb/logs/mongodb.log.2026-06-23T12-04-10 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#ib_16384_0.dblwr | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#ib_16384_1.dblwr | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo10_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo11_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo12_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo13_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo14_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo15_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo16_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo17_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo18_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo19_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo20_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo21_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo22_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo23_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo24_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo25_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo26_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo27_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo28_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo29_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo30_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo31_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo32_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo33_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo34_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo35_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo36_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo37_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo6 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo7_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo8_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_redo/#ib_redo9_tmp | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_1.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_10.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_2.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_3.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_4.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_5.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_6.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_7.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_8.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/#innodb_temp/temp_9.ibt | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/Nitesh.err | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/Nitesh.pid | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/auto.cnf | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000001 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000002 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000003 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000004 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000005 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000006 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000007 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000008 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000009 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000010 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000011 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000012 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000013 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000014 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.000015 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/binlog.index | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ca-key.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ca.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/client-cert.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/client-key.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/customers.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/databasechangelog.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/databasechangeloglock.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/orderdetails.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/orderstable.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/products.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ecommercemysql/sellers.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ib_buffer_pool | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ibdata1 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/ibtmp1 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/general_log.CSM | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/general_log.CSV | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/general_log_224.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/slow_log.CSM | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/slow_log.CSV | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql/slow_log_225.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/mysql_upgrade_history | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/accounts_153.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/binary_log_trans_200.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/cond_instances_87.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/data_lock_waits_170.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/data_locks_169.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/error_log_88.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_errors_su_147.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_errors_su_148.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_errors_su_149.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_errors_su_150.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_errors_su_151.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_cu_119.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_hi_120.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_hi_121.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_su_122.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_su_123.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_su_124.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_su_125.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_stages_su_126.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_127.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_128.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_129.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_130.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_131.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_132.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_133.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_134.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_135.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_136.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_137.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_statement_138.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_139.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_140.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_141.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_142.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_143.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_144.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_145.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_transacti_146.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_cur_89.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_his_90.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_his_91.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_92.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_93.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_94.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_95.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_96.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/events_waits_sum_97.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/file_instances_98.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/file_summary_by__100.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/file_summary_by__99.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/global_status_190.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/global_variable__197.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/global_variables_193.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/host_cache_101.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/hosts_154.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/keyring_componen_202.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/keyring_keys_160.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/log_status_183.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/memory_summary_b_162.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/memory_summary_b_163.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/memory_summary_b_164.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/memory_summary_b_165.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/memory_summary_g_161.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/metadata_locks_168.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/mutex_instances_102.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/objects_summary__103.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/performance_time_104.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/persisted_variab_198.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/prepared_stateme_184.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/processlist_105.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_174.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_175.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_176.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_177.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_179.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_appl_180.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_asyn_181.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_asyn_182.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_conn_171.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_conn_173.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_grou_172.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/replication_grou_178.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/rwlock_instances_106.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/session_account__159.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/session_connect__158.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/session_status_191.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/session_variable_194.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_actors_107.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_consumers_108.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_instrument_109.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_loggers_110.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_meters_111.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_metrics_112.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_objects_113.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/setup_threads_114.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/socket_instances_155.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/socket_summary_b_156.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/socket_summary_b_157.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/status_by_accoun_186.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/status_by_host_187.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/status_by_thread_188.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/status_by_user_189.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/table_handles_166.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/table_io_waits_s_115.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/table_io_waits_s_116.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/table_lock_waits_117.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/temporary_accoun_167.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/threads_118.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/tls_channel_stat_201.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/user_defined_fun_199.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/user_variables_b_185.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/users_152.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/variables_by_thr_192.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/variables_info_195.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/performance_schema/variables_metada_196.sdi | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/private_key.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/public_key.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/server-cert.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/server-key.pem | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/sys/sys_config.ibd | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/undo_001 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/data/undo_002 | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/LICENSE | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/README | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/abseil_dll-debug.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/abseil_dll-debug.pdb | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/abseil_dll.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/abseil_dll.lib | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/ccapiserver.exe | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/comerr64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/echo.exe | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/fido2.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/fido2.lib | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/gssapi64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/ibd2sdi.exe | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/innochecksum.exe | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/jemalloc.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/jemalloc.pdb | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/k5sprt64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/krb5_64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/krbcc64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libcrypto-3-x64.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libcrypto-3-x64.pdb | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libmecab.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libprotobuf-debug.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libprotobuf-lite-debug.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libprotobuf-lite.dll | Generated/runtime or vendored artifact in repository; not source automation. |
| databases/mysql/server/bin/libprotobuf-lite.lib | Generated/runtime or vendored artifact in repository; not source automation. |

## Static Unreferenced Candidates

These are not proven dead; they were not referenced by exact/static path scan and may be entrypoints invoked externally by Jenkins jobs or humans.

| Path | Justification |
| --- | --- |
| README.md | No static inbound reference found; validate external Jenkins/job usage before action. |
| config/ubuntu/mysql.config | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/Jenkinsfile | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/Jenkinsfile.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/Jenkinsfile.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/custom.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/custom.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/scripts/mongodb_load_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/scripts/mongodb_setup_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/ubuntu/mongodb_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mongodb/ubuntu/mongodb_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mssql/ubuntu/mssql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mssql/ubuntu/mssql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mssql/windows/mssql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mssql/windows/mssql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/ubuntu/mysql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/ubuntu/mysql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/Jenkinsfile.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/Jenkinsfile.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/custom.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/custom.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/localwork/mysql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/localwork/mysql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/mysql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/mysql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/scripts/mysql_load_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/mysql/windows/scripts/mysql_setup_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/Jenkinsfile.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/Jenkinsfile.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/custom.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/custom.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/postgresql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/postgresql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/scripts/postgresql_load_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/scripts/postgresql_setup_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/ubuntu/postgresql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/ubuntu/postgresql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/Jenkinsfile.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/Jenkinsfile.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/custom.load | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/custom.setup | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/localwork/postgresql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/localwork/postgresql_setup_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/postgresql_load_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/scripts/postgresql_load_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/postgresql/windows/scripts/postgresql_setup_pipeline.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/testing/python_debug_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| jenkins/testing/tools_debug_pipeline.groovy | No static inbound reference found; validate external Jenkins/job usage before action. |
| requirements.txt | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/download_mysql_driver.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mongodb/mongodb_load_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mongodb/mongodb_setup_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mongodb/stop_mongodb.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mssql/mssql_load_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mssql/mssql_setup_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mysql/deploy_mysql.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mysql/mysql_load_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mysql/mysql_setup_pipeline.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mysql/stop_mysql.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/bash/mysql/validate_csv.sh | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/install_mssql_driver.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/install_mysql_driver.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/set_project_root.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/setup_liquibase.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/tools.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/common/validate_postgresql_driver.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/cleanup_mongodb.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/destroy_mongodb.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/mongodb_load_with_logging.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/mongodb_setup_with_logging.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/start_mongodb.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/stop_mongodb.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mongodb/validate_mongodb.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/destroy_mssql_environment.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/install_mssql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/install_mssql_driver.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/install_sqlcmd.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/stop_mssql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mssql/validate_mssql_tools.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mysql/cleanup_mysql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/mysql/destroy_mysql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/postgresql/cleanup_postgresql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/postgresql/deploy_postgresql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/postgresql/destroy_postgresql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/postgresql/start_postgresql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/batch/postgresql/stop_postgresql.bat | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mongodb/__pycache__/db_connection.cpython-312.pyc | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mongodb/db_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mongodb/test_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mssql/__pycache__/db_connection.cpython-312.pyc | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mssql/db_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mysql/__pycache__/db_connection.cpython-312.pyc | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mysql/check_port.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mysql/db_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mysql/test_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/mysql/validate_customers.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/check_port.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/create_tables.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/db_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/test_connection.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/validate_customers.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| scripts/python/postgresql/validate_postgresql.py | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/main.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/terraform.tfstate | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/terraform.tfstate.backup | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/terraform.tfvars | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mongodb/variables.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/main.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/outputs.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/terraform.tfstate | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/terraform.tfstate.backup | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/terraform.tfvars | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mssql/windows/variables.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mysql/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/LICENSE.txt | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mysql/.terraform/providers/registry.terraform.io/hashicorp/null/3.3.0/windows_amd64/terraform-provider-null_v3.3.0_x5.exe | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mysql/main.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mysql/terraform.tfstate | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/mysql/terraform.tfstate.backup | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/postgresql/main.tf | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/postgresql/terraform.tfvars | No static inbound reference found; validate external Jenkins/job usage before action. |
| terraform/postgresql/variables.tf | No static inbound reference found; validate external Jenkins/job usage before action. |

## Required Recommendation Fields

- Current Location: `databases/mongodb/data/WiredTiger`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/WiredTiger.lock`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/WiredTiger.turtle`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/WiredTiger.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/WiredTigerHS.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/_mdb_catalog.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-0-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-11-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-13-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-15-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-2-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-4-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-7-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/collection-9-11029275549169148852.wt`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-18T17-10-36Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-12-51Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-29-22Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-33-57Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T09-57-23Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-12-26Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-47-18Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-50-32Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T10-58-33Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-02-59Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion
- Current Location: `databases/mongodb/data/diagnostic.data/metrics.2026-06-23T11-16-20Z-00000`
  Target Location: `DELETE CANDIDATE only`
  Reason: Generated/unreferenced candidate; requires signoff before cleanup
  Risk Level: Medium
  Affected Pipelines: Unknown/external possible
  Affected Databases: mongodb
  Required Path Updates: Yes
  Required Import Updates: As applicable
  Required Jenkins Updates: As applicable
  Required Terraform Updates: As applicable
  Required Liquibase Updates: As applicable
  Required Validation Steps: Run full affected green pipelines before any deletion