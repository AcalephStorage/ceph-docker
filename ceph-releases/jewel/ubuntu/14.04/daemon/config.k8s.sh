#!/bin/bash
set -e

# defaults to `pod-name`. set to mon-name to use name MON_NAME value instead
: ${K8S_MONMAP_NAME_FROM:=pod-name}

function get_admin_key {
   # No-op for static
   log "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  # Need to symlink the configs before use
  get_config

  # Get FSID from ceph.conf
  FSID=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)

  if [[ "$K8S_MONMAP_NAME_FROM" == "mon-name" ]]; then
    MONMAP_ADD=$(echo --add "${MON_NAME} ${MON_IP} ")
  else
    # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}--add {{.metadata.name}} {{.status.podIP}} {{end}}")
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
