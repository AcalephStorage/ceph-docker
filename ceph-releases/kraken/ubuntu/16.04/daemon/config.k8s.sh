#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   log "k8s: does not generate the admin key. Use Kubernetes secrets instead."
}

function get_mon_config {
  # Get fsid from ceph.conf
  local fsid=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)
  log "k8s: adding this mon to ${fsid}"

  timeout=10
  MONMAP_ADD=""

  while [[ -z "${MONMAP_ADD// }" && "${timeout}" -gt 0 ]]; do
    # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}{{if .status.podIP}}--add ${MON_NAME} {{.status.podIP}} {{end}} {{end}}")
    (( timeout-- ))
    sleep 1
  done

  log "k8s: monmap=$MONMAP_ADD"

  if [[ -z "${MONMAP_ADD// }" ]]; then
      log "k8s: no monmap entries to add. failing."
      exit 1
  fi

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${fsid} $MONMAP
  log "k8s: monmap successfully generated."
}

function get_config {
   # No-op for static
   log "k8s: config is stored as k8s secrets."
}
