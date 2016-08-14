Ceph on Kubernetes
==================

This Guide will take you through the process of deploying a more advanced Ceph cluster on Kubernetes.

Client Requirements
===================

In addition to kubectl, Sigil is required for template handling and must be installed in your system PATH. Instructions can be found here: [https://github.com/gliderlabs/sigil](https://github.com/gliderlabs/sigil)

Cluster Requirements
====================

At a High level:

-	Ceph and RBD utilities must be installed on masters and nodes (or alternatively using Hyperkube with ceph-common baked in: https://github.com/AcalephStorage/hyperkube\)
-	Linux Kernel should be newer than 4.2.0

### Ceph and RBD utilities installed on the nodes

The Kubernetes kubelet shells out to system utilities to mount Ceph volumes. This means that every system must have these utilities installed. This requirement extends to the control plane, since there may be interactions between kube-controller-manager and the Ceph cluster.

For Debian-based distros:

```
apt-get install ceph-fs-common ceph-common
```

For Redhat-based distros:

```
yum install ceph
```

### Linux Kernel version 4.2.0 or newer

You'll need a newer kernel to use this. Kernel panics have been observed on older versions. Your kernel should also have RBD support.

This has been tested on:

-	Ubuntu 15.10

This will not work on:

-	Debian 8.5

Tutorial
========

### Generate keys and configuration

By default, 10.0.0.0/8 is used for the `cluster_network` and `public_network` in ceph.conf. To change these defaults, set the following environment variables according to your network requirements. These IPs should be set according to the range of your Pod IPs in your kubernetes cluster:

```
export osd_cluster_network=192.168.0.0/16
export osd_public_network=192.168.0.0/16
```

These will be picked up by sigil when generating the kubernetes secrets in the next section.

You can run the `ceph-k8s.sh` tool to generate a config:

```
./ceph-k8s generate_config
```

or alternatively generate manually:

```
cd generator
./generate_secrets.sh all `./generate_secrets.sh fsid`
```

Since this is running with host networking, it is recommended to edit the ceph.conf to add details of the `mon_host` and `mon_addr`. For example:

```
mon_host = kube-test-1,kube-test-2,kube-test-3
mon_addr = 10.140.0.3:6789,10.140.0.4:6789,10.140.0.5:6789
```

Please note that you should save the output files of this command, future invocations of scripts will overwrite existing keys and configuration.

### Create keys and configuration in Kubernetes

Run the following command to generate the create configuration and keys in Kubernetes.

```
./ceph-k8s create_config
```

or manually:

```
cd generator
kubectl create namespace ceph

kubectl create secret generic ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
kubectl create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=ceph.rgw.keyring --namespace=ceph
kubectl create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
kubectl create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph
kubectl create secret generic ceph-client-key --from-file=ceph-client-key --namespace=ceph

cd ..
```

If you lose the original secret files locally they can still be retrieved from Kubernetes via `kubectl get secret`.

### Deploy Mons Components

With the secrets created, you can now deploy the Mons.

```
./ceph-k8s create_mons
```

Your cluster should now look something like this.

```
$ kubectl get all --namespace=ceph
NAME                   DESIRED      CURRENT       AGE
ceph-mon-check         1            1             24s
NAME                   CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
ceph-mon               None         <none>        6789/TCP   24s
NAME                   READY        STATUS        RESTARTS   AGE
ceph-mon-6kz0n         0/1          Pending       0          24s
ceph-mon-check-deek9   1/1          Running       0          24s
```

### Label your storage nodes

You must label your storage nodes in order to run Ceph pods on them.

```
kubectl label node <nodename> node-type=storage
```

Importantly for a more advanced configuration with local devices, it is required to create a ceph-osd daemonset for each devices that is common across the OSD nodes. For an environment with disks using `/dev/sdb` and `/dev/sdb`, the following steps should be followed:

1.	Create a DaemonSet for each Device and type (eg. `ceph-osd-v1-ds-sdb-hdd.yaml`\)
2.	Edit the metadata and selectors labels to match the Device (and type for future features around Crushmaps)
3.	Deploy with `kubectl create -f ceph-osd-v1-ds-sdb-hdd.yaml --namespace=ceph`
4.	Label node with disk type: `kubectl label node <nodename> device_sdb=hdd`

(More to come...)
