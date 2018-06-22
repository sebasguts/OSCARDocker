FROM ubuntu:xenial

MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

RUN    apt-get update -qq \
    && apt-get install -y \
       sudo vim ant ant-optional autoconf autogen \
       bliss build-essential bzip2 \
       clang debhelper default-jdk git \
       language-pack-en language-pack-el-base libbliss-dev libboost-dev \
      libboost-python-dev libcdd0d libcdd-dev libdatetime-perl \
       libflint-dev libglpk-dev libgmp-dev libgmp10 libgmpxx4ldbl libmpfr-dev libncurses5-dev libnormaliz-dev libntl-dev \
       libperl-dev libppl-dev libreadline6-dev libterm-readline-gnu-perl libterm-readkey-perl \
       libsvn-perl libtool libxml-libxml-perl libxml-libxslt-perl libxml-perl libxml-writer-perl libxml2-dev libxslt-dev \
       m4 make nano python-dev sudo wget xsltproc ninja-build \
       4ti2 graphviz gfortran cmake pkg-config patch libjson-perl curl

RUN    adduser --quiet --shell /bin/bash --gecos "OSCAR user,101,," --disabled-password oscar \
    && adduser oscar sudo \
    && chown -R oscar:oscar /home/oscar/ \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && cd /home/oscar \
    && touch .sudo_as_admin_successful

USER oscar

ENV HOME /home/oscar
WORKDIR /home/oscar

COPY Make.user /home/oscar/Make.user

ENV MARCH x86-64

RUN    wget https://github.com/JuliaLang/julia/releases/download/v0.6.3/julia-0.6.3-full.tar.gz \
    && tar xf julia-0.6.3-full.tar.gz \
    && rm  julia-0.6.3-full.tar.gz \
    && cd julia-0.6.3 \
    && export MARCH=x86-64 \
    && cp ../Make.user . \
    && make \
    && sudo ln -snf /home/oscar/julia-0.6.3/julia /usr/local/bin/julia

RUN    wget https://polymake.org/lib/exe/fetch.php/download/polymake-3.2r2.tar.bz2 \
    && tar xf polymake-3.2r2.tar.bz2 \
    && rm polymake-3.2r2.tar.bz2 \
    && cd polymake-3.2 \
    && ./configure --without-native \
    && sudo ninja -C build/Opt install

COPY install_hecke.jl /home/oscar/install_hecke.jl
RUN   julia install_hecke.jl

ENV JULIA_CXX_RTTI 1

COPY install_cxx.jl /home/oscar/install_cxx.jl
RUN julia install_cxx.jl

COPY compile_cxx.jl /home/oscar/compile_cxx.jl
RUN julia < compile_cxx.jl

ENV POLYMAKE_CONFIG polymake-config

COPY install_polymake.jl /home/oscar/install_polymake.jl
RUN julia install_polymake.jl

COPY install_singular.jl /home/oscar/install_singular.jl
RUN sudo julia install_singular.jl

COPY install_oscar.jl /home/oscar/install_oscar.jl
RUN julia install_oscar.jl

RUN    sudo apt-get install -y python3-pip \
    && sudo pip3 install notebook

COPY install_ijulia.jl /home/oscar/install_ijulia.jl
RUN julia install_ijulia.jl

RUN touch /home/oscar/.julia/v0.6/Cxx/src/Cxx.jl
