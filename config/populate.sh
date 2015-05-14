#!/bin/bash
#populate the KV store with ceph.conf parameters


#mon hosts
#monitor
consuloretcd put -c mon_host/host1 192.168.42.20:6789
consuloretcd put -c mon_host/host2 192.168.42.21:6789
consuloretcd put -c mon_host/host3 192.168.42.22:6789
consuloretcd put -c mon_host/host4 192.168.42.23:6789
consuloretcd put -c mon_host/host5 192.168.42.24:6789

#ceph-common
consuloretcd put -c common/fsid 4a158d27-f750-41d5-9e7f-26ce4c9d2d45
consuloretcd put -c common/cephx true
consuloretcd put -c common/cephx_require_signatures false
consuloretcd put -c common/cephx_cluster_require_signatures true
consuloretcd put -c common/cephx_service_require_signatures false
consuloretcd put -c common/max_open_files 131072
consuloretcd put -c common/disable_in_memory_logs true

#monitor
consuloretcd put -c mon/mon_osd_down_out_interval 600
consuloretcd put -c mon/mon_osd_min_down_reporters 4
consuloretcd put -c mon/mon_clock_drift_allowed .15
consuloretcd put -c mon/mon_clock_drift_warn_backoff 30
consuloretcd put -c mon/mon_osd_full_ratio .95
consuloretcd put -c mon/mon_osd_nearfull_ratio .85
consuloretcd put -c mon/mon_osd_report_timeout 300

#osd
consuloretcd put -c osd/journal_size 100
consuloretcd put -c osd/pool_default_pg_num 128
consuloretcd put -c osd/pool_default_pgp_num 128
consuloretcd put -c osd/pool_default_size 3
consuloretcd put -c osd/pool_default_min_size 1
consuloretcd put -c osd/cluster_network 192.168.42.0/24
consuloretcd put -c osd/public_network 192.168.42.0/24
consuloretcd put -c osd/osd_mkfs_type xfs
consuloretcd put -c osd/osd_mkfs_options_xfs -f -i size=2048
consuloretcd put -c osd/osd_mount_options_xfs noatime,largeio,inode,swalloc
consuloretcd put -c osd/osd_mon_heartbeat_interval 30

#crush
consuloretcd put -c crush/pool_default_crush_rule 0
consuloretcd put -c crush/osd_crush_update_on_start true

#backend
consuloretcd put -c backend/osd_objectstore filestore

#performance tuning
consuloretcd put -c perf/filestore_merge_threshold 40
consuloretcd put -c perf/filestore_split_multiple 8
consuloretcd put -c perf/osd_op_threads 8
consuloretcd put -c perf/filestore_op_threads 8
consuloretcd put -c perf/filestore_max_sync_interval 5
consuloretcd put -c perf/osd_max_scrubs 1

#recovery tuning
consuloretcd put -c rec/osd_recovery_max_active 5
consuloretcd put -c rec/osd_max_backfills 2
consuloretcd put -c rec/osd_recovery_op_priority 2
consuloretcd put -c rec/osd_client_op_priority 63
consuloretcd put -c rec/osd_recovery_max_chunk 1048576
consuloretcd put -c rec/osd_recovery_threads 1

#ports
consuloretcd put -c ports/mon_port 6789
consuloretcd put -c ports/ms_bind_port_min 6800
consuloretcd put -c ports/ms_bind_port_max 7100


#rbd
consuloretcd put -c rbd/rbd_cache_enabled true
consuloretcd put -c rbd/rbd_cache_writethrough_until_flush true

#other
consuloretcd put -c other/use_inktank_ceph_repo true
consuloretcd put -c other/iscsi_support false
consuloretcd put -c other/ceph_reduced_log_verbosity false
consuloretcd put -c other/radosgw false
consuloretcd put -c other/mds false