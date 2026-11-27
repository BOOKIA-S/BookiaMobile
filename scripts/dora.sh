#!/usr/bin/env bash
# Calcula las 4 métricas DORA (docs/CONSTITUTION.md §9.1, docs/QUALITY.md §2)
# con la API de GitHub y el historial de Git, y escribe docs/DORA.md.
set -euo pipefail

usage() {
  cat <<'HELP'
Uso: bash scripts/dora.sh [--repo OWNER/REPO] [--out RUTA] [--help]

Requiere gh (con GH_TOKEN o sesión iniciada), jq y un clon con los tags
(git fetch --tags). Por defecto usa $GITHUB_REPOSITORY y docs/DORA.md.

- Despliegue: GitHub Release publicado (no borrador ni prerelease), S-3.
- Tiempo de entrega: mediana desde el primer commit de cada PR fusionado en
  develop hasta el primer release cuyo tag contiene su merge.
- Tasa de fallo: releases seguidos de un PR hotfix/* fusionado en main o de
  un commit revert antes del siguiente release, entre releases totales.
- MTTR: mediana de apertura a cierre de issues con etiqueta incident.
Lo que no tiene datos queda como «no calculable», nunca como 0.
HELP
}

repo=${GITHUB_REPOSITORY:-}
root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
out="$root/docs/DORA.md"
while (( $# )); do
  case $1 in
    --repo) repo=${2:?}; shift 2 ;;
    --out) out=${2:?}; shift 2 ;;
    --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
[[ -n $repo ]] || { echo 'Falta --repo OWNER/REPO o GITHUB_REPOSITORY.' >&2; exit 2; }
for tool in gh jq git; do
  command -v "$tool" >/dev/null || { echo "Falta $tool." >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
api() { gh api --paginate "repos/$repo/$1" | jq -s 'add // []'; }

# 1) Releases publicados, del más antiguo al más reciente.
api 'releases?per_page=100' | jq '[.[] | select(.draft | not)
  | select(.prerelease | not) | {tag: .tag_name, at: .published_at}]
  | sort_by(.at)' >"$work/releases.json"

# 2) PRs fusionados en develop (sin back-merges de main) y hotfix en main.
api 'pulls?state=closed&base=develop&per_page=100' | jq '[.[]
  | select(.merged_at != null and .head.ref != "main")
  | {number, created_at, merged_at, sha: .merge_commit_sha}] | sort_by(.number)' \
  >"$work/prs.json"
api 'pulls?state=closed&base=main&per_page=100' | jq '[.[]
  | select(.merged_at != null and (.head.ref | startswith("hotfix/")))
  | .merged_at]' >"$work/hotfixes.json"

# 3) Issues de incidente (la API de issues también lista PRs: se quitan).
api 'issues?state=all&labels=incident&per_page=100' | jq '[.[]
  | select(.pull_request | not)
  | {number, created_at, closed_at}]' >"$work/incidents.json"

# 4) Primer commit de cada PR y release que lo incluye (por ancestros en Git).
echo '[]' >"$work/lead.json"
mapfile -t tags < <(jq -r '.[].tag' "$work/releases.json")
while read -r number sha merged; do
  # Con merge commit, los commits del PR son los de su segundo padre; si se
  # fusionó de otra forma (squash/rebase) se consultan en la API.
  if git -C "$root" rev-parse --verify --quiet "$sha^2" >/dev/null; then
    first=$(git -C "$root" log --format=%at "$sha^1..$sha^2" | sort -n | head -n1)
    first=$(date -u -d "@$first" +%Y-%m-%dT%H:%M:%SZ)
  else
    first=$(gh api "repos/$repo/pulls/$number/commits?per_page=100" \
      --jq '[.[].commit.author.date] | min')
  fi
  tag=''
  for candidate in "${tags[@]}"; do
    if git -C "$root" merge-base --is-ancestor "$sha" "$candidate" 2>/dev/null; then
      tag=$candidate; break
    fi
  done
  jq --argjson n "$number" --arg first "$first" --arg tag "$tag" --arg merged "$merged" \
    '. + [{number: $n, first: $first, merged_at: $merged,
           tag: (if $tag == "" then null else $tag end)}]' \
    "$work/lead.json" >"$work/tmp.json" && mv "$work/tmp.json" "$work/lead.json"
done < <(jq -r '.[] | "\(.number) \(.sha) \(.merged_at)"' "$work/prs.json")

# 5) Commits revert entre cada release y el siguiente (o HEAD de main).
echo '{}' >"$work/reverts.json"
for i in "${!tags[@]}"; do
  next=${tags[i+1]:-origin/main}
  count=$(git -C "$root" log --format=%s "${tags[i]}..$next" 2>/dev/null \
    | grep -ciE '^revert' || true)
  jq --arg t "${tags[i]}" --argjson c "${count:-0}" '. + {($t): $c}' \
    "$work/reverts.json" >"$work/tmp.json" && mv "$work/tmp.json" "$work/reverts.json"
done

jq -n -r \
  --slurpfile releases "$work/releases.json" \
  --slurpfile lead "$work/lead.json" \
  --slurpfile hotfixes "$work/hotfixes.json" \
  --slurpfile reverts "$work/reverts.json" \
  --slurpfile incidents "$work/incidents.json" \
  --arg repo "$repo" \
  --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -f "$root/scripts/dora_report.jq" >"$out"
echo "DORA escrito en $out"
