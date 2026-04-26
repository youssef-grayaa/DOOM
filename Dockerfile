############################
# BASE STAGE
############################
FROM python:3.12-slim AS base
ENV DEBIAN_FRONTEND=noninteractive
# essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget \
    zsh tmux \
    gdb gdb-multiarch \
    build-essential gcc-multilib python3-dev \
    file strace ltrace binutils ca-certificates sudo \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt

############################
# PWN STAGE
############################
FROM base AS pwn
WORKDIR /opt/pwn-tools
# virtualenv for exploit tooling
RUN python3 -m venv /opt/pwn-venv
RUN /opt/pwn-venv/bin/pip install --upgrade pip setuptools wheel
RUN /opt/pwn-venv/bin/pip install --no-cache-dir \
    pwntools \
    ropper \
    one_gadget \
    git-dumper

# pwndbg from github
RUN git clone --depth 1 https://github.com/pwndbg/pwndbg.git /opt/pwn-tools/pwndbg

# pwninit

RUN apt-get update && apt-get install -y --no-install-recommends \
  cargo \
  liblzma-dev pkg-config \
  libssl-dev

RUN cargo install pwninit --locked

############################
# MALWARE / REVERSE STAGE
############################
FROM base AS malware
WORKDIR /opt/malware-tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    mingw-w64 yara \
    && rm -rf /var/lib/apt/lists/*

# Use venv for consistency with pwn stage
RUN python3 -m venv /opt/malware-venv
RUN /opt/malware-venv/bin/pip install --upgrade pip setuptools wheel
RUN /opt/malware-venv/bin/pip install --no-cache-dir \
    lief \
    volatility3 \
    capstone \
    unicorn

############################
# RED TEAM STAGE
############################
FROM base AS redteam
WORKDIR /opt/redteam-tools

RUN python3 -m venv /opt/ad-venv
RUN /opt/ad-venv/bin/pip install --upgrade pip setuptools wheel

RUN /opt/ad-venv/bin/pip install --no-cache-dir \
    impacket \
    certipy-ad


RUN /opt/ad-venv/bin/pip install --no-cache-dir git+https://github.com/Pennyw0rth/NetExec

############################
# FINAL STAGE
############################
FROM base AS doom
# Final PATH - order matters (pwn and malware venvs first, then pipx)

# Copy pwn tools venv and directory (includes pwndbg clone)
COPY --from=pwn /opt/pwn-tools /opt/pwn-tools
COPY --from=pwn /opt/pwn-venv /opt/pwn-venv


# Copy malware tools venv
COPY --from=malware /opt/malware-venv /opt/malware-venv

# COPY red team venv

COPY --from=redteam /opt/ad-venv /opt/ad-venv

#PATH

ENV PATH="/home/doom/.cargo/bin:/opt/pwn-venv/bin:/opt/malware-venv/bin:/opt/ad-venv/bin:$PATH"

# Additional tools via apt
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools \
    openvpn \
    vim \
    nmap \
    smbclient \
    sqlmap \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-traditional \
    ssh \
    && rm -rf /var/lib/apt/lists/*

#QEMU
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system \
    qemu-user \
    && rm -rf /var/lib/apt/lists/*






# Create doom user with passwordless sudo
RUN useradd -m -s /bin/zsh doom && \
    echo "doom ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers



# Copy configs and switch user
COPY --chown=doom:doom tmux_config /home/doom/.tmux.conf
COPY --chown=doom:doom zsh_config /home/doom/.zshrc
RUN chown doom:doom /opt/pwn-tools/pwndbg


#FFUF

RUN wget "https://github.com/ffuf/ffuf/releases/download/v2.1.0/ffuf_2.1.0_linux_amd64.tar.gz"
RUN tar -xf ffuf_2.1.0_linux_amd64.tar.gz
RUN mv ffuf /usr/bin

#Add custom scripts to PATH
ENV PATH="$PATH:/home/doom/volume/work/scripts"


USER doom
WORKDIR /home/doom

## install ffuf
# Setup gdb config - source pwndbg from git clone
RUN echo 'source /opt/pwn-tools/pwndbg/gdbinit.py' >> .gdbinit

CMD ["zsh"]
