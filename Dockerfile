FROM ubuntu:xenial

MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

RUN    apt-get update -qq \
    && apt-get install -y \
       4ti2 \
       ant \
       ant-optional \
       autoconf \
       autogen \
       bliss \
       build-essential \
       bzip2 \
       clang \
       cmake \
       curl \
       debhelper \
       default-jdk \
       gfortran \
       git \
       graphviz \
       language-pack-el-base \
       language-pack-en \
       libbliss-dev \
       libboost-dev \
       libboost-python-dev \
       libcdd-dev \
       libcdd0d \
       libdatetime-perl \
       libflint-dev \
       libglpk-dev \
       libgmp-dev \
       libgmp10 \
       libgmpxx4ldbl \
       libjson-perl \
       libmpfr-dev \
       libncurses5-dev \
       libnormaliz-dev \
       libntl-dev \
       libperl-dev \
       libppl-dev \
       libreadline6-dev \
       libsvn-perl \
       libterm-readkey-perl \
       libterm-readline-gnu-perl \
       libtool \
       libxml-libxml-perl \
       libxml-libxslt-perl \
       libxml-perl \
       libxml-writer-perl \
       libxml2-dev \
       libxslt-dev \
       libzmq3-dev \
       m4 \
       make \
       nano \
       ninja-build \
       patch \
       pkg-config \
       python-dev \
       python3-pip \
       sudo \
       unzip \
       vim \
       wget \
       xsltproc \
       zlib1g-dev

RUN    adduser --quiet --shell /bin/bash --gecos "OSCAR user,101,," --disabled-password oscar \
    && adduser oscar sudo \
    && chown -R oscar:oscar /home/oscar/ \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && cd /home/oscar \
    && touch .sudo_as_admin_successful

USER oscar

ENV HOME /home/oscar
WORKDIR /home/oscar

RUN sudo pip3 install notebook jupyterlab_launcher jupyterlab traitlets ipython vdom
RUN    mkdir .jupyter \
    && echo "c.NotebookApp.token = ''" > /home/oscar/.jupyter/jupyter_notebook_config.py

### Install Julia

ENV JULIA_VERSION julia-1.1.0

RUN    wget https://julialang-s3.julialang.org/bin/linux/x64/1.1/${JULIA_VERSION}-linux-x86_64.tar.gz \
    && tar xf ${JULIA_VERSION}-linux-x86_64.tar.gz \
    && rm ${JULIA_VERSION}-linux-x86_64.tar.gz \ 
    && sudo ln -snf /home/oscar/${JULIA_VERSION}/bin/julia /usr/local/bin/julia

### Install Polymake

RUN    git clone https://github.com/polymake/polymake.git \
    && cd polymake \
    && git checkout Snapshots \
    && ./configure --without-native \
    && sudo ninja -j8 -C build/Opt install

### Install GAP & related

RUN    wget -q https://github.com/gap-system/gap/archive/master.zip \
    && unzip -q master.zip \
    && rm master.zip \
    && cd gap-master \
    && ./autogen.sh \
    && ./configure --with-julia=/home/oscar/${JULIA_VERSION} --with-gc=julia \
    && make \
    && make bootstrap-pkg-full \
    && cd pkg \
    && ../bin/BuildPackages.sh \
    && sudo ln -snf /home/oscar/gap-master/gap /usr/local/bin/gap

RUN    cd /home/oscar/gap-master/pkg \
    && git clone https://github.com/gap-packages/JupyterKernel.git \
    && cd JupyterKernel \
    && python3 setup.py install --user \
    && cd .. \
    && git clone https://github.com/oscar-system/GAPJulia \
    && cd GAPJulia \
    && ./configure \
    && make

ENV PATH /home/oscar/gap-master/pkg/JupyterKernel/bin:${PATH}
ENV JUPYTER_GAP_EXECUTABLE /home/oscar/gap-master/bin/gap.sh

### Install Julia packages

ENV POLYMAKE_CONFIG /usr/local/bin/polymake-config

RUN julia -e "import Pkg; Pkg.add( \"CxxWrap\" )"
RUN julia -e "import Pkg; Pkg.add( \"IJulia\" )"
RUN julia -e "import Pkg; Pkg.add( \"AbstractAlgebra\" )"
RUN julia -e "import Pkg; Pkg.add( \"Nemo\" )"
RUN julia -e "import Pkg; Pkg.add(Pkg.PackageSpec(url=\"https://github.com/oscar-system/Polymake.jl\", rev=\"master\" ))"
RUN julia -e "import Pkg; Pkg.add(Pkg.PackageSpec(url=\"https://github.com/oscar-system/Singular.jl\", rev=\"master\" ))"
RUN julia -e "import Pkg; Pkg.add(Pkg.PackageSpec(url=\"https://github.com/oscar-system/OSCAR.jl\", rev=\"master\" ))"
RUN julia -e "import Pkg; Pkg.add( \"Hecke\" )"

COPY Examples Examples

