FROM docker.io/4geniac/proteinfold:alphafold-v2.3.2-hhsuite-compile-avx2

COPY alphaFold/alphaFold.patch /app/alphafold/alphaFold.patch

# echo -e does not work with ubuntu shell builtin
RUN /bin/echo -e '#! /bin/bash\nldconfig -C ld.so.cache\npython /app/alphafold/run_alphafold.py "$@"' > /app/launch_alphafold.sh \
  && chmod +x /app/launch_alphafold.sh \
  && /bin/echo -e '#! /bin/bash\ncat /app/alphafold/version-info.txt' > /app/get_version.sh \
  && chmod +x /app/get_version.sh
  cd /app/alphafold \
  && patch -p1 < alphaFold.patch

ENV LC_ALL C
ENV PATH "/opt/conda/bin:/usr/local/cuda/bin:$PATH"
ENV PATH "$PATH:/app"
ENV PYTHONPATH /app/alphafold/:$PYTHONPATH

