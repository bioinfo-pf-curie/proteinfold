FROM docker.io/4geniac/proteinfold:alphabridge-v0.0.2-base

ENV PATH="/opt/conda/bin:$PATH"
ENV PATH="$PATH:/app"
ENV BASH_EN /opt/etc/bashrc
