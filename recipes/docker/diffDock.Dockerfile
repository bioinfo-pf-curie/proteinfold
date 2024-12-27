FROM docker.io/4geniac/proteinfold/diffdock-v1.1.2-base

COPY diffDock/diffDock.patch /app/diffdock/diffDock.patch

RUN apt update \
  && apt install -y patch
  cd /app/diffdock \
  && patch -p1 < diffDock.patch

ENV LC_ALL=C
ENV PATH="/opt/conda/bin:$PATH"
ENV PATH="$PATH:/app"
ENV BASH_EN /opt/etc/bashrc
