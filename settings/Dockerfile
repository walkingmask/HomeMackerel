FROM nvidia/cuda:cudnn

MAINTAINER DOCKERUSER

USER root

COPY jl /usr/local/bin/
COPY tb /usr/local/bin/

RUN chmod 755 /usr/local/bin/jl && chmod 755 /usr/local/bin/tb

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    wget \
    git \
    vim \
    sudo \
    && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN useradd -m DOCKERUSER

COPY jupyter_notebook_config.py /home/DOCKERUSER/
RUN chown -R DOCKERUSER:DOCKERUSER /home/DOCKERUSER/jupyter_notebook_config.py

USER DOCKERUSER
WORKDIR /home/DOCKERUSER

RUN mkdir .pyenv && git clone https://github.com/yyuu/pyenv.git .pyenv

ENV HOME /home/DOCKERUSER
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN pyenv install anaconda3-4.2.0 && \
  pyenv global anaconda3-4.2.0 && \
  pyenv rehash

ENV PATH PYENV_ROOT/versions/anaconda3-4.2.0/bin/:$PATH

RUN conda update -y conda

# Configure jupyter
RUN mkdir .jupyter && \
  openssl req -subj '/CN=SSLDOMAIN/O=ORGANIZATION/C=COUNTRY' -new -newkey rsa:2048 -nodes -x509 -keyout mycert.key -out mycert.pem && \
  mv mycert.key .jupyter/ && \
  mv mycert.pem .jupyter/ && \
  mv /home/DOCKERUSER/jupyter_notebook_config.py .jupyter/

# Install tensorflow
ENV TF_BINARY_URL https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-0.12.1-cp35-cp35m-linux_x86_64.whl
RUN pip install --ignore-installed --upgrade $TF_BINARY_URL

# Install jupyter lab
RUN pip install jupyterlab && jupyter serverextension enable --py jupyterlab

EXPOSE 6006
EXPOSE 8888
