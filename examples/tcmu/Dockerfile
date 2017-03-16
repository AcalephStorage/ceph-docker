FROM ubuntu:16.04

# Install packages
RUN apt-get update && \
    apt-get install -y cmake wget curl git less file \
        libglib2.0-dev libkmod-dev libnl-genl-3-dev linux-libc-dev pkg-config psmisc python-tox qemu-utils fuse python-dev \
        devscripts debhelper bash-completion librdmacm-dev libibverbs-dev xsltproc docbook-xsl \
        libconfig-general-perl libaio-dev libc6-dev librbd1 librbd-dev

# Build TCMU
RUN cd /usr/src && \
    git clone https://github.com/open-iscsi/tcmu-runner.git && \
    cd tcmu-runner
RUN cd /usr/src/tcmu-runner && \
    cmake . -Dwith-glfs=false -Dwith-rbd=true -Dwith-qcow=false && \
    make && \
    make install && \
    cp scsi_defs.h /usr/local/include && \
    cp libtcmu_static.a /usr/local/lib/libtcmu.a


VOLUME /tmp
ENV TMPDIR /tmp
ENTRYPOINT ["/bin/bash"]
#CMD [""]
