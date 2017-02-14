#!/bin/bash
set -e

# defaults to `pod-name`. set to mon-name to use name MON_NAME value instead
: ${K8S_MONMAP_NAME_FROM:=pod-name}

function get_admin_key {
   # No-op for static
   log "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  log "k8s: starting mon."
  # Need to symlink the configs before use
  get_config

  # Get FSID from ceph.conf
  FSID=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)
  log "k8s: fsid=${FSID}"

  timeout=10
  MONMAP_ADD=""
  if [[ "$K8S_MONMAP_NAME_FROM" == "mon-name" ]]; then
    log "k8s: adding mons by mon-name"
    # wait for all pods to be at least running or pending (since we're using kubectl exec')
    expected_pods=$(kubectl get daemonset --namespace=ceph -l daemon=mon --no-headers | awk '{print $2}')
    log "k8s: waiting for mon pods to be running."
    while [[ "$expected_pods" != "$running_pods" ]]; do
      running_pods=$(kubectl get pods --namespace=ceph -l daemon=mon --no-headers | grep 'Running\|Pending' | wc -l)
      sleep 1
    done

    # create the monname and ip of the pods
    monpods=$(kubectl get pods --namespace ceph -l daemon=mon -o template --template="{{ range .items }}{{ .metadata.name }} {{ end }}")
    MONMAP_ADD=""
    for monpod in $monpods; do
      monname=$(kubectl exec --namespace ceph $monpod -- bash -c 'echo ${MON_NAME:=${HOSTNAME}}')
      monip=$(kubectl get pods --namespace ceph $monpod -o template --template="{{ .status.podIP }}")
      MONMAP_ADD="$MONMAP_ADD --add $monname $monip "
      log "k8s: adding $monname=$monip to monmap."
    done
  else
    log "k8s: adding mons by pod-name"
    # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}--add {{.metadata.name}} {{.status.podIP}} {{end}}")
  fi

  while [[ -z "${MONMAP_ADD// }" && "${timeout}" -gt 0 ]]; do
    log "k8s: no monmap string created. retrying."
    # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
    MONMAP_ADD=$(kubectl get pods --namespace=${CLUSTER} -l daemon=mon -o template --template="{{range .items}}{{if .status.podIP}}--add {{.metadata.name}} {{.status.podIP}} {{end}} {{end}}")
    (( timeout-- ))
    sleep 1
  done

  if [[ -z "${MONMAP_ADD// }" ]]; then
      log "k8s: unable to create monmap"
      exit 1
  fi

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${FSID} /etc/ceph/monmap-${CLUSTER}
  log "k8s: monmap created with $MONMAP_ADD"
}

function get_config {
   # No-op for static
   log "k8s: config is stored as k8s secrets."
   # K8s currently mounts configmaps/secrets in its own tmpfs.
   # Work around with Symlinks

   log "k8s: Symlinking secrets"
   if [[ ! -f /etc/ceph/ceph.client.admin.keyring ]]; then
     ln -s /etc/ceph/secrets/* /etc/ceph/
   fi

   log "k8s: Symlinking ceph.conf"
   if [[ ! -f /etc/ceph/ceph.conf ]]; then
     ln -s /etc/ceph/conf/ceph.conf /etc/ceph/ceph.conf
   fi
}
