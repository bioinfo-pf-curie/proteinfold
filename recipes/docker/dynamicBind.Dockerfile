FROM docker.io/4geniac/proteinfold:dynamicbind-v1.0-base

RUN /bin/echo -e '#! /bin/bash\nldconfig -C ld.so.cache\npython /app/dynamicbind/run_single_protein_inference.py "$@"' > /app/launch_dynamicbind.sh \
  && chmod +x /app/launch_dynamicbind.sh \
  && /bin/echo -e '#! /bin/bash\nldconfig -C ld.so.cache\npython /app/dynamicbind/movie_generation.py "$@"' > /app/movie_generation.sh \
  && chmod +x /app/movie_generation.sh \
  && /bin/echo -e '#! /bin/bash\ncat /app/dynamicbind/version-info.txt' > /app/get_version.sh \
  && chmod +x /app/get_version.sh \
  && mkdir -p /opt/etc \
  && /bin/echo -e '#! /bin/bash\n\n# script to activate the conda environment dynamicbind' > ~/.bashrc \
  && conda init bash \
  && echo 'conda activate dynamicbind' >> ~/.bashrc \
  && cp ~/.bashrc /opt/etc/bashrc

ENV LC_ALL C
ENV PATH /opt/conda/bin:/usr/local/cuda/bin:/usr/local/bin/$PATH
ENV PATH $PATH:/app
ENV BASH_ENV /opt/etc/bashrc
