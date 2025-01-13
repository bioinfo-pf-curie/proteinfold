FROM docker.io/4geniac/proteinfold:colabfold-v1.5.5-base

RUN echo $'#! /bin/bash\ncat /app/colabfold/version-info.txt' > /app/get_version.sh \
  && chmod +x /app/get_version.sh

ENV PATH /app:$PATH
