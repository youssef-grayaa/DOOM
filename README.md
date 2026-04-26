# DOOM
DOOM is a containerized offensive security workspace built for pentesting, CTFs, exploit development, and research. It provides a clean, reproducible environment packed with tooling so you can drop into any machine and start working without polluting the host OS

## setup and stuff to know


To build the container:

```
docker compose up --build
```

You can create a local `doom/` folder to store scripts, VPN files, notes, wordlists, and other operator files. This directory is mounted into the container through Docker volumes, making it persistent and directly accessible from both host and container.

### tmux

Make sure to run `ctrl-b + I` when you use tmux to update plugins.

### zsh

The Zsh config adds the `tun0` ip address to the prompt which can be useful for revshells.
