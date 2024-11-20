FROM registrygitlab.curie.fr/cubic-registry/proteinfold/afmassive:v1.1.0-hhsuite-compile-avx2

COPY afMassive/afMassive.patch /app/alphafold/afMassive.patch

RUN echo $'#! /bin/bash\nldconfig -C ld.so.cache\npython /app/alphafold/run_AFmassive.py "$@"' > /app/launch_alphafold.sh \
  && chmod +x /app/launch_alphafold.sh \
  && echo $'#! /bin/bash\ncat /app/alphafold/version-info.txt' > /app/get_version.sh \
  && chmod +x /app/get_version.sh
  cd /app/alphafold \
  && patch -p1 < afMassive.patch

ENV LC_ALL C
ENV PATH "/opt/conda/bin:/usr/local/cuda/bin:$PATH"
ENV PATH "$PATH:/app"
ENV PATH /app:$PATH
ENV PYTHONPATH /app/alphafold/:$PYTHONPATH
