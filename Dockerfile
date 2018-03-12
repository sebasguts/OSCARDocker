FROM ubuntu:artful

MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

RUN    apt-get update -qq \
    && apt-get install -y \
       sudo vim ant ant-optional autoconf autogen \
       bliss build-essential bzip2 \
       clang debhelper default-jdk git \
       language-pack-en language-pack-el-base libbliss-dev libboost-dev \
       libboost-python1.62-dev libboost-python-dev libcdd0d libcdd-dev libdatetime-perl libflint-2.5.2 \
       libflint-dev libglpk-dev libgmp-dev libgmp10 libgmpxx4ldbl libmpfr-dev libncurses5-dev libnormaliz-dev libntl27 libntl-dev \
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


RUN    wget https://github.com/JuliaLang/julia/releases/download/v0.6.2/julia-0.6.2-full.tar.gz \
    && tar xf julia-0.6.2-full.tar.gz \
    && rm  julia-0.6.2-full.tar.gz \
    && cd julia-0.6.2 \
    && make -j8 \
    && sudo ln -snf /home/oscar/julia-0.6.2/julia /usr/local/bin/julia

COPY install_hecke.jl /home/oscar/install_hecke.jl
RUN   julia install_hecke.jl

ENV JULIA_CXX_RTTI 1

COPY install_cxx.jl /home/oscar/install_cxx.jl
RUN julia install_cxx.jl

RUN    wget https://polymake.org/lib/exe/fetch.php/download/polymake-3.2r1.tar.bz2 \
    && tar xf polymake-3.2r1.tar.bz2 \
    && rm polymake-3.2r1.tar.bz2 \
    && cd polymake-3.2 \
    && ./configure \
    && sudo ninja -C build/Opt install

ENV POLYMAKE_CONFIG polymake-config

COPY install_polymake.jl /home/oscar/install_polymake.jl
RUN julia install_polymake.jl

COPY install_singular.jl /home/oscar/install_singular.jl
RUN julia install_singular.jl
