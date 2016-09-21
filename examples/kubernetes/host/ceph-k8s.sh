#!/bin/bash

function config() {
  case "$1" in
    generate)		shift; config_generate "$@";;
    create)		shift; config_create "$@";;
    *)			usage;;
  esac
}

function config_generate() {
  cd generator && ./generate_secrets.sh all `./generate_secrets.sh fsid`
}

function config_create() {
  kubectl create namespace ceph

  cd generator
  kubectl create secret generic ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
  kubectl create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=ceph.rgw.keyring --namespace=ceph
  kubectl create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
  kubectl create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph
  kubectl create secret generic ceph-client-key --from-file=ceph-client-key --namespace=ceph
}

function ceph() {
  case "$1" in
    get)		shift; ceph_get "$@";;
    status)		shift; ceph_status "$@";;
    delete)		shift; ceph_delete "$@";;
    *)			usage;;
  esac
}

function ceph_get() {
  kubectl get pods --namespace=ceph
}

function ceph_status() {
  mon_pod
  kubectl --namespace=ceph exec ${PODNAME} -t -i -- ceph -s
}

function ceph_delete() {
  kubectl delete namespace ceph
}

function mon() {
  case "$1" in
    get)		shift; mon_get "$@";;
    create)		shift; mon_create "$@";;
    command)		shift; mon_command "$@";;
    *)			usage;;
  esac
}

function mon_get() {
  kubectl get pods --selector="app=ceph,daemon=mon" --namespace=ceph
}

function mon_create() {
  kubectl create \
  -f ceph-mon-v1-svc.yaml \
  -f ceph-mon-v1-dp.yaml \
  -f ceph-mon-check-v1-dp.yaml \
  --namespace=ceph

}

function mon_command() {
  mon_pod
  kubectl exec -it $PODNAME --namespace=ceph -- "$@"
}


# function prepare_disks() {
#
# }

# function label_nodes() {
#
# }

function osd() {
  case "$1" in
    get)		shift; osd_get "$@";;
    create)		shift; osd_create "$@";;
    command)		shift; osd_command "$@";;
    *)			usage;;
  esac
}

function osd_get() {
  kubectl get pods --selector="app=ceph,daemon=osd" --namespace=ceph
}


function osd_create() {

  kubectl create \
  -f ceph-osd-v1-ds-sd*.yaml \
  --namespace=ceph

}

function osd_command() {
  osd_pod
  kubectl exec -it $PODNAME --namespace=ceph -- "$@"
}


function mds() {
  case "$1" in
    get)		shift; mds_get "$@";;
    create)		shift; mds_create "$@";;
    *)			usage;;
  esac
}

function mds_get() {
  kubectl get pods --selector="app=ceph,daemon=mds" --namespace=ceph
}

function mds_create() {
  kubectl create \
  -f ceph-mds-v1-dp.yaml \
  --namespace=ceph
}

function rgw() {
  case "$1" in
    get)		shift; rgw_get "$@";;
    create)		shift; rgw_create "$@";;
    command)		shift; rgw_command "$@";;
    *)			usage;;
  esac
}

function rgw_get() {
  kubectl get pods --selector="app=ceph,daemon=rgw" --namespace=ceph
}

function rgw_create() {
  kubectl create \
  -f ceph-rgw-v1-dp.yaml \
  --namespace=ceph
}

function rgw_command() {
  rgw_pod
  kubectl exec -it $PODNAME --namespace=ceph -- "$@"
}

function nfs_get() {
  kubectl get pods --selector="app=ceph,daemon=nfs-rgw" --namespace=ceph
}

function nfs_create() {
  kubectl create \
  -f ceph-rgw-v1-dp.yaml \
  --namespace=ceph
}

function rgw_command() {
  rgw_pod
  kubectl exec -it $PODNAME --namespace=ceph -- "$@"
}

function exp() {
  case "$1" in
    get)    shift; exp_get "$@";;
    create)   shift; exp_create "$@";;
    *)      usage;;
  esac
}

function exp_get() {
  kubectl get pods --selector="app=ceph-exporter" --namespace=ceph
}

function exp_create() {
  kubectl create \
  -f ceph-exporter.yaml
}

function mon_pod() {
  PODNAME=`kubectl get pods --selector="app=ceph,daemon=mon" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}" --namespace=ceph`
}

function osd_pod() {
  PODNAME=`kubectl get pods --selector="app=ceph,daemon=osd" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}" --namespace=ceph`
}

function rgw_pod() {
  PODNAME=`kubectl get pods --selector="app=ceph,daemon=rgw" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}" --namespace=ceph`
}

function nfs_pod() {
  PODNAME=`kubectl get pods --selector="app=ceph,daemon=nfs-rgw" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}" --namespace=ceph`
}

function usage() {
	echo "Usage: ceph-k8s <subcommand>"
	echo
	echo "Subcommands:"
  echo "  config generate - Generate config files (under /generator)"
  echo "  config create - Create config/secret files in Kubernetes"
  echo "  ceph get - Query Kubernetes for all Ceph related pods"
  echo "  ceph delete - Delete all Ceph resources (DESTRUCTIVE!!)"
  echo "  ceph status - Gets ceph health"
  echo "  mon get - Query Kubernetes for all Mon pods"
  echo "  mon create - Launch MON resources on Kubernetes"
  echo "  mon command <ceph|rbd> - Execute raw ceph or rbd commands on a MON"
  echo "  osd get - Query Kubernetes for all OSD pods"
  echo "  osd create - Launch OSD resources on Kubernetes"
  echo "  osd command <ceph|rbd> - Execute raw ceph or rbd commands on an OSD"
  echo "  mds get - Query Kubernetes for all MDS pods"
  echo "  mds create  - Launch MDS resource on Kubernetes"
  echo "  rgw get - Query Kubernetes for all RGW pods"
  echo "  rgw create  - Launch RGW resource on Kubernetes"
  echo "  rgw command <radosgw-admin>  - Execute radosgw-admin on an RGW"
  echo "  nfs get - Query Kubernetes for all NFS pods"
  echo "  nfs create <cephfs|rgw> - Launch NFS resource on Kubernetes"
	echo "  exp create - Create prometheus ceph exporter"
  echo "  exp get - Query prometheus ceph exporter"
}

function main() {
	set -eo pipefail; [[ "$TRACE" ]] && set -x
	case "$1" in
		config)		shift; config "$@";;
    ceph)		shift; ceph "$@";;
    mon)		shift; mon "$@";;
    osd)		shift; osd "$@";;
    mds)		shift; mds "$@";;
    rgw)		shift; rgw "$@";;
    nfs)		shift; nfs "$@";;
    exp)    shift; exp "$@";;
		*)			usage;;
	esac
}

main "$@"
