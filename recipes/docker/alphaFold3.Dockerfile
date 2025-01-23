FROM docker.io/4geniac/proteinfold:alphafold-v3.0.1-base

# echo -e does not work with ubuntu shell builtin
RUN /bin/echo -e '#! /bin/bash\npython /app/alphafold/run_alphafold.py "$@"' > /app/launch_alphafold.sh \
  && chmod +x /app/launch_alphafold.sh \
  && /bin/echo -e '#! /bin/bash\ncat /app/alphafold/version-info.txt' > /app/get_version.sh \
  && chmod +x /app/get_version.sh

ENV LC_ALL C
ENV PATH "$PATH:/app"
