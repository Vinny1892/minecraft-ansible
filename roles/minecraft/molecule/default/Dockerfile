FROM {{ image }}

ENV container docker

WORKDIR /app

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 \
    python3-pip \
    ansible \
    ssh \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install molecule

RUN apt-get update \
    && apt-get install -y systemd \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && systemctl mask \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-remount-fs.service \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    systemd-ask-password-wall.path \
    systemd-logind.service \
    NetworkManager.service \
    systemd-ask-password-console.path \
    systemd-user-sessions.service \
    systemd-tmpfiles-setup.service \
    systemd-tmpfiles-setup-dev.service \
    pppd-dns.service \
    systemd-update-utmp.service \
    systemd-backlight@.service \
    systemd-journald-audit.socket \
    systemd-journal-flush.service \
    systemd-journald.socket \
    systemd-networkd.socket \
    systemd-rfkill.socket \
    systemd-suspend.service \
    && systemctl set-default multi-user.target  \
    && rm -rf /var/lib/apt/lists/*


RUN apt-get update && \
    apt-get install -y systemd

VOLUME [ "/sys/fs/cgroup", "/run" ]

CMD ["/lib/systemd/systemd"]