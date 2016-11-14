#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   log "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  # Get FSID from ceph.conf
  FSID=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)

  # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
  MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}--add {{.metadata.name}} {{.status.podIP}} {{end}}")

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${FSID} /etc/ceph/monmap-${CLUSTER}

}

function get_config {
   # No-op for static
   log "k8s: config is stored as k8s secrets."
   # K8s currently mounts configmaps/secrets in its own tmpfs.
   # Work around with Symlinks

   echo "k8s: Symlinking secrets"
   ln -s /etc/ceph/secrets/* /etc/ceph/

   echo "k8s: Symlinking ceph.conf"
   ln -s /etc/ceph/conf/ceph.conf /etc/ceph/ceph.conf
}
