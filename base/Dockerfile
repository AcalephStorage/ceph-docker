# CEPH BASE IMAGE
# CEPH VERSION: Firefly
# CEPH VERSION DETAIL: 0.80.8

FROM ubuntu:14.04
MAINTAINER Sébastien Han "seb@redhat.com"

ENV CEPH_VERSION firefly
ENV CONSULORETCD_VERSION v0.2

ENV CONFD_VERSION 0.7.1
ENV CONFD_ARCH linux-amd64

# Install prerequisites
RUN apt-get update
RUN apt-get install -y wget

# Install Ceph
RUN wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | apt-key add -
RUN echo deb http://ceph.com/debian-$CEPH_VERSION/ trusty main | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list
RUN apt-get update
RUN apt-get install -y --force-yes ceph


#install consuloretcd-kv
RUN wget -q -O- "https://github.com/TelanJ/consuloretcd-kv/releases/download/v0.2/consuloretcd-kv-${CONSULORETCD_VERSION}-05-14-2015.tar" |tar xfz - -C/tmp/consuloretcd-${CONSULORETCD_VERSION}/consuloretcd
RUN mv /tmp/consuloretcd-${CONSULORETCD_VERSION}/consuloretcd /usr/local/bin/consuloretcd


# Install confd
ADD https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-${CONFD_ARCH} /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd
RUN mkdir -p /etc/confd/{conf.d,templates}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
