FROM node:22-bookworm-slim

ARG TZ=America/Sao_Paulo
ENV TZ="$TZ"

# ─── System packages ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    unzip \
    less \
    procps \
    sudo \
    fzf \
    zsh \
    nano \
    ca-certificates \
    gnupg \
    dnsutils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── GitHub CLI ─────────────────────────────────────────────────────────────
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Infisical CLI ──────────────────────────────────────────────────────────
RUN curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | bash \
    && apt-get install -y infisical \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── Python + cli-anything-obsidian ─────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages \
    "git+https://github.com/Ianfr13/Douravita-cli.git#subdirectory=obsidian"

# ─── User + dirs ────────────────────────────────────────────────────────────
RUN echo "node ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node \
    && mkdir -p /usr/local/share/npm-global \
    && chown -R node:node /usr/local/share \
    && mkdir -p /workspace /home/node/.claude \
    && chown -R node:node /workspace /home/node/.claude \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R node /commandhistory

WORKDIR /workspace

# ─── Claude Code: bypass permissions (container = sandbox) ────────────────
COPY claude-settings.json /home/node/.claude/settings.json
RUN chown node:node /home/node/.claude/settings.json

# ─── VS Code: Claude Code extension bypass por default ────────────────────
RUN mkdir -p /home/node/.vscode-server/data/Machine \
    && echo '{"claudeCode.initialPermissionMode":"bypassPermissions"}' \
       > /home/node/.vscode-server/data/Machine/settings.json \
    && chown -R node:node /home/node/.vscode-server

# ─── RTK CLI + Claude Code hook ─────────────────────────────────────────────
# Instala e configura no mesmo RUN (root) para garantir PATH correto.
# HOME=/home/node faz rtk init escrever no settings do usuário node.
RUN ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then ARCHIVE="rtk-x86_64-unknown-linux-musl.tar.gz"; \
       else ARCHIVE="rtk-aarch64-unknown-linux-gnu.tar.gz"; fi \
    && curl -fsSL "https://github.com/rtk-ai/rtk/releases/latest/download/${ARCHIVE}" -o /tmp/rtk.tar.gz \
    && tar -xzf /tmp/rtk.tar.gz -C /usr/local/bin/ rtk \
    && rm /tmp/rtk.tar.gz
COPY hooks/rtk-rewrite.sh /home/node/.claude/hooks/rtk-rewrite.sh
RUN chmod +x /home/node/.claude/hooks/rtk-rewrite.sh \
    && chown -R node:node /home/node/.claude

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/node/.local/bin:/home/node/.bun/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano

# ─── Bun (requerido pelo plugin Honcho) ──────────────────────────────────────
RUN curl -fsSL https://bun.sh/install | bash

# ─── Global npm: Claude Code + Google Workspace CLI + Playwright CLI ─────────
RUN npm install -g \
    @anthropic-ai/claude-code \
    @googleworkspace/cli \
    @upstash/context7-mcp \
    firecrawl-cli \
    @openai/codex \
    @google/gemini-cli

# ─── Plugin Honcho (memória persistente para Claude Code) ────────────────────
RUN claude plugin marketplace add plastic-labs/claude-honcho \
    && claude plugin install honcho@honcho

ENTRYPOINT []
CMD ["zsh"]
