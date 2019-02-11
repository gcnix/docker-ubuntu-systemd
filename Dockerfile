FROM ubuntu:18.04
MAINTAINER "Brett Delle Grazie" <brett.dellegrazie@gmail.com>

ENV container=docker init=/lib/systemd/systemd DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical LANG=C.UTF-8

# Disable source repositories
RUN sed -i 's/# deb/deb/g' /etc/apt/sources.list

# Limit auto-installed dependencies
RUN echo 'APT::Install-Recommends "0";\nAPT::Get::Assume-Yes "true";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf.d/01buildconfig

RUN apt-get update && \
    apt-get install -y \
    dbus systemd systemd-cron rsyslog iproute2 python3-minimal sudo && \
    apt-get clean && \
    rm -rf /usr/share/doc /usr/share/man /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;

RUN systemctl set-default multi-user.target
RUN systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount

COPY setup /sbin/

VOLUME ["/sys/fs/cgroup", "/tmp", "/run", "/run/lock"]
STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init", "--log-target=journal"]
