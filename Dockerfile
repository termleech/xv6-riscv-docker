FROM ubuntu:jammy AS builder-riscv
RUN apt-get -y update && \
      apt-get install -y autoconf automake autotools-dev curl python3 python3-pip libmpc-dev \
      libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
      libexpat-dev ninja-build git cmake libglib2.0-dev gcc-12 g++-12 && \
      rm -rf /var/lib/apt/lists/*
ENV HOME /home/csc401
WORKDIR $HOME
# Installing RiscV Toolchain
ENV RISCV $HOME/install/riscv
ENV PATH "$RISCV/bin:${PATH}"
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
WORKDIR $HOME/riscv-gnu-toolchain
RUN CC=gcc-12 CXX=g++-12 ./configure --prefix=$RISCV
RUN CC=gcc-12 CXX=g++-12 make -j4

# Installing Spike simulator
FROM ubuntu:jammy AS builder-spike
ENV HOME /home/csc401
WORKDIR $HOME
ENV RISCV $HOME/install/riscv
ENV PATH "$RISCV/bin:${PATH}"
RUN apt-get -y update && \
      apt-get install -y autoconf automake autotools-dev gcc g++ curl python3 python3-pip libmpc-dev \
      libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
      libexpat-dev ninja-build git cmake libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
      device-tree-compiler gcc-12 g++-12 && \
      rm -rf /var/lib/apt/lists/*
COPY --from=builder-riscv $HOME/install $HOME/install
RUN git clone https://github.com/riscv/riscv-isa-sim.git
WORKDIR $HOME/riscv-isa-sim
# RUN git checkout v1.1.0
WORKDIR $HOME/riscv-isa-sim/build
RUN CC=gcc-12 CXX=g++-12 ../configure --prefix=$RISCV && CC=gcc-12 CXX=g++-12 make -j4 && make install
WORKDIR $HOME
# Installing riscv-pk proxy kernel
RUN git clone https://github.com/riscv/riscv-pk.git
WORKDIR $HOME/riscv-pk/build
RUN ../configure --prefix=$RISCV --host=riscv64-unknown-elf --with-arch=rv64gc_zicsr_zifencei && make -j4 && make install
# Installing qemu
WORKDIR $HOME
ENV QEMU /home/csc401/install/qemu
ENV PATH "$QEMU/bin:${PATH}"
RUN git clone https://github.com/qemu/qemu.git
WORKDIR $HOME/qemu
RUN git checkout v8.0.4
RUN CC=gcc-12 CXX=g+-12 ./configure --target-list=riscv64-softmmu --prefix=$QEMU && CC=gcc-12 CXX=g+-12 make -j4 && make install

# Final image
FROM ubuntu:jammy
ENV HOME /home/csc401
WORKDIR $HOME
ENV RISCV $HOME/install/riscv
ENV PATH "$RISCV/bin:${PATH}"
RUN apt-get -y update && \
      apt-get install -y autoconf automake autotools-dev gcc g++ curl python3 python3-pip libmpc-dev \
      libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
      libexpat-dev ninja-build git cmake libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
      device-tree-compiler gcc-12 g++-12 && \
      rm -rf /var/lib/apt/lists/*
COPY --from=builder-spike $HOME/install $HOME/install
ENV QEMU $HOME/install/qemu
ENV PATH "$QEMU/bin:${PATH}"
WORKDIR $HOME
