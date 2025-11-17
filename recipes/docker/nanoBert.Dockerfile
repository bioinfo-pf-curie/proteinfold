FROM docker.io/4geniac/proteinfold:nanobert-v1.0-base

ENV PATH="/opt/conda/bin:$PATH"
ENV PATH="$PATH:/app"
ENV BASH_EN /opt/etc/bashrc
