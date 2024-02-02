FROM registrygitlab.curie.fr/cubic-registry/proteinfold/massivefold:MFv1.0.0-hhsuite-compile-avx2

RUN echo $'#! /bin/bash\nldconfig -C ld.so.cache\npython /app/alphafold/run_alphafold.py "$@"' > /app/launch_alphafold.sh \
  && chmod +x /app/launch_alphafold.sh

ENV LC_ALL C
ENV PATH /app:$PATH

