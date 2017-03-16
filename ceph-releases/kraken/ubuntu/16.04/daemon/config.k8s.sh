#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   log "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  # Get fsid from ceph.conf
  local fsid=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)

  timeout=10
  MONMAP_ADD=""

  while [[ -z "${MONMAP_ADD// }" && "${timeout}" -gt 0 ]]; do
    # Get the ceph mon pods (name/nodeName and IP) from the Kubernetes API. Formatted as a set of monmap params

    if [[ "${MON_NAME_FROM}" == "HOST" ]]; then
      K8S_MON_NAME="${MON_NAME}"
    else
      K8S_MON_NAME="{{.metadata.name}}"
    fi

    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}{{if .status.podIP}}--add ${K8S_MON_NAME} {{.status.podIP}} {{end}} {{end}}")
    (( timeout-- ))
    sleep 1
  done

  if [[ -z "${MONMAP_ADD// }" ]]; then
      exit 1
  fi

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${fsid} $MONMAP

}

function get_config {
   # No-op for static
   log "k8s: config is stored as k8s secrets."
}
