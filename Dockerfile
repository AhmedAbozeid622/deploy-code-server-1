# Start from the code-server Debian base image
FROM codercom/code-server:4.0.2

USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install unzip + rclone (support for remote filesystem)
RUN sudo apt-get update && sudo apt-get install unzip -y
RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local

RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | sudo apt-key add -
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/bionic.list | sudo tee /etc/apt/sources.list.d/tailscale.list
RUN sudo apt-get update
RUN sudo apt-get install tailscale -y
RUN rm -rf /tmp/tailscaled
RUN mkdir -p /tmp/tailscaled
RUN chown irc.irc /tmp/tailscaled
RUN rm -rf /var/run/tailscale
RUN mkdir -p /var/run/tailscale
RUN chown irc.irc /var/run/tailscale
RUN cp /var/lib/tailscaled/tailscaled.state /tmp/tailscaled/tailscaled.state
RUN chown irc.irc /tmp/tailscaled/tailscaled.state
RUN nohup sudo -u irc tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=/tmp/tailscaled/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --port 41641 &
RUN until tailscale up --auth-key tskey-auth-k3YCpW3CNTRL-MNk8e6mjETLNUHPnZJasVLDtcgJJmheQ; do sleep 1; done
RUN echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
RUN echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
RUN sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
RUN sudo tailscale up --advertise-exit-node

# You can add custom software and dependencies for your environment below
# -----------

# Install a VS Code extension:
# Note: we use a different marketplace than VS Code. See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
# RUN code-server --install-extension esbenp.prettier-vscode

# Install apt packages:
# RUN sudo apt-get install -y ubuntu-make

# Copy files: 
# COPY deploy-container/myTool /home/coder/myTool

# -----------

# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
