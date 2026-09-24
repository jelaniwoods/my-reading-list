# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=4.0.5
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# GitHub Codespaces supplies an ephemeral public key for `gh codespace ssh`.
# Keep the feature's listener key-only and bound to the non-root remote user.
USER root
RUN install -d -m 0755 /etc/ssh/sshd_config.d && \
    printf '%s\n' \
      'AuthenticationMethods publickey' \
      'PermitRootLogin no' \
      'PasswordAuthentication no' \
      'KbdInteractiveAuthentication no' \
      'PubkeyAuthentication yes' \
      > /etc/ssh/sshd_config.d/99-foundation.conf
USER vscode

# The Rails image installs Ruby through mise, whose activation normally happens
# only in interactive shells. Lifecycle commands are noninteractive, so expose
# both mise and its shims at the image level; the Node feature prepends its own
# pinned bin directory while preserving this path.
ENV PATH="/home/vscode/.local/bin:/home/vscode/.local/share/mise/shims:${PATH}"

# Ensure binding is always 0.0.0.0
# Binds the server to all IP addresses of the container, so it can be accessed from outside the container.
ENV BINDING="0.0.0.0"
