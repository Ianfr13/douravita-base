# Douravita Base Image

Imagem Docker base (`ghcr.io/ianfr13/douravita-base:latest`) usada por todos os devcontainers Douravita. Node 22 + ferramentas de sistema + CLIs.

## Estrutura

- `Dockerfile` — definição da imagem base
- `claude-settings.json` — settings padrão do Claude Code baked na imagem
- `.github/workflows/build.yml` — CI: build multi-arch (amd64/arm64) + push para GHCR

## Routing

| Tarefa | Ler |
|--------|-----|
| Adicionar/remover pacote ou CLI | `Dockerfile` |
| Mudar settings padrão do Claude | `claude-settings.json` |
| Mudar CI/build | `.github/workflows/build.yml` |

## O que está na imagem

**Sistema:** git, curl, wget, jq, fzf, zsh, nano, dnsutils
**CLIs:** gh, infisical, cli-anything-obsidian, claude, gws, playwright-cli
**Runtime:** Node 22, Python 3, pip3
**Config:** bypass permissions (container = sandbox), npm global em `/usr/local/share/npm-global`

## Convenções

- Push para `main` com mudança no `Dockerfile` → CI rebuilda e publica automaticamente
- Rebuild manual: `workflow_dispatch` no GitHub Actions
- Testar localmente: `docker build -t douravita-base:test .`
- CLIs Douravita instalam via pip do repo `Ianfr13/Douravita-cli` — cada CLI é um subdirectory

## Stack

- Base: `node:22-bookworm-slim`
- Registry: GitHub Container Registry (ghcr.io)
- CI: GitHub Actions
- Sem devcontainer próprio — edita no host
