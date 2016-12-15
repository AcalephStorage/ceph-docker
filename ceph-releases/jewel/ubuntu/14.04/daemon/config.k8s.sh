#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   log "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  # Need to symlink the configs before use
  get_config

  # Get FSID from ceph.conf
  FSID=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)

  timeout=10
  MONMAP_ADD=""

  while [[ -z "${MONMAP_ADD// }" && "${timeout}" -gt 0 ]]; do
    # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}{{if .status.podIP}}--add {{.metadata.name}} {{.status.podIP}} {{end}} {{end}}")
    (( timeout-- ))
    sleep 1
  done

  if [[ -z "${MONMAP_ADD// }" ]]; then
      exit 1
  fi

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${FSID} /etc/ceph/monmap-${CLUSTER}

}

function get_config {
   # No-op for static
   log "k8s: config is stored as k8s secrets."
   # K8s currently mounts configmaps/secrets in its own tmpfs.
   # Work around with Symlinks

   log "k8s: Symlinking secrets"
   ln -s /etc/ceph/secrets/* /etc/ceph/

   log "k8s: Symlinking ceph.conf"
   ln -s /etc/ceph/conf/ceph.conf /etc/ceph/ceph.conf
}
