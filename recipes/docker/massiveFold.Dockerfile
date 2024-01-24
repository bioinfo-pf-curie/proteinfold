FROM registrygitlab.curie.fr/cubic-registry/proteinfold/massivefold:MFv1.0.0-hhsuite-compile-avx2

RUN echo -e '#! /bin/bash\npython /app/alphafold/run_alphafold.py "$@"' > /app/launch_alphafold.sh \
  && chmod +x /app/launch_alphafold.sh

ENV LC_ALL C
ENV PATH /app:$PATH

