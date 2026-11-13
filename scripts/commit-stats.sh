#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'HELP'
Uso: bash scripts/commit-stats.sh [--all | --help]

Por defecto analiza origin/develop (commits integrados). --all incluye refs
locales, incluidas ramas aún sin publicar, sin duplicar hashes compartidos.
Excluye merges; fecha = fecha de commit con su zona horaria (%cs).
S01: 4–6 nov; S02: 9–13 nov; S03: 17–20 nov; S04: 23–27 nov de 2026.
Solo atribuye pares nombre/correo verificados. PR, revisiones y archivos
binarios no permiten medir contribución en líneas desde Git.
HELP
}

ref=origin/develop
case ${1:-} in
  --help) usage; exit 0 ;;
  --all) ref=--all ;;
  '') ;;
  *) usage >&2; exit 2 ;;
esac
if (( $# > 1 )); then usage >&2; exit 2; fi

repo=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel) || {
  echo 'El script debe estar dentro de un repositorio Git.' >&2; exit 1;
}
if [[ $ref != --all ]] && ! git -C "$repo" rev-parse --verify --quiet "$ref^{commit}" >/dev/null; then
  echo 'Falta origin/develop; usa git fetch origin o --all para refs locales.' >&2
  exit 1
fi

# shortcut: attribute only confirmed name/email pairs; add other members after they verify their Git identity.
member_for() {
  case "$1 <$2>" in
    'Jaime de Jesús Fuentes Cruz <147575398+imDestro1@users.noreply.github.com>') echo I1 ;;
    'Karol Hernán López Ortega <lopezkarol798@gmail.com>') echo I4 ;;
    'Andrés Alvarado Lazcano <146596162+AndresAlvaradoLazcano1@users.noreply.github.com>') echo I5 ;;
    *) echo unknown ;;
  esac
}

week_for() {
  case $1 in
    2026-11-0[4-6]) echo S01 ;;
    2026-11-0[9]|2026-11-1[0-3]) echo S02 ;;
    2026-11-1[7-9]|2026-11-20) echo S03 ;;
    2026-11-2[3-7]) echo S04 ;;
    *) echo other ;;
  esac
}

declare -A commits=() work=() logs=() added=() removed=() binary=() unknown=()
members=(I1 I2 I3 I4 I5)
weeks=(S01 S02 S03 S04 other)
names=('Jaime de Jesús Fuentes Cruz' 'Elizabeth de la Cruz Ramírez' 'Ángel de Jesús López Temporal' 'Karol Hernán López Ortega' 'Andrés Alvarado Lazcano')

record_commit() {
  [[ -n ${hash:-} ]] || return 0
  local member week key identity
  member=$(member_for "$author" "$email")
  if [[ $member == unknown ]]; then
    identity="$author <$email>"
    unknown["$identity"]=$(( ${unknown["$identity"]:-0} + 1 ))
    return 0
  fi
  week=$(week_for "$day")
  key="$member:$week"
  commits["$key"]=$(( ${commits["$key"]:-0} + 1 ))
  if [[ $subject == 'docs(bitacora):'* && $files -eq 1 && $log_file -eq 1 ]]; then
    logs["$key"]=$(( ${logs["$key"]:-0} + 1 ))
  else
    work["$key"]=$(( ${work["$key"]:-0} + 1 ))
  fi
  added["$key"]=$(( ${added["$key"]:-0} + plus_total ))
  removed["$key"]=$(( ${removed["$key"]:-0} + minus_total ))
  binary["$key"]=$(( ${binary["$key"]:-0} + binaries ))
}

# shortcut: paths containing tabs/newlines/control characters are unsupported; switch to Git -z if they appear.
hash=''
while IFS= read -r line; do
  if [[ $line == @@@*$'\x1f'* ]]; then
    record_commit
    IFS=$'\x1f' read -r hash author email day subject <<< "${line#@@@}"
    plus_total=0 minus_total=0 binaries=0 files=0 log_file=0
  elif [[ -n $hash && $line == *$'\t'* ]]; then
    IFS=$'\t' read -r plus minus path <<< "$line"
    if [[ $plus =~ ^[0-9]+$ && $minus =~ ^[0-9]+$ ]]; then
      plus_total=$(( plus_total + plus ))
      minus_total=$(( minus_total + minus ))
    elif [[ $plus == - && $minus == - ]]; then
      binaries=$(( binaries + 1 ))
    else
      continue
    fi
    files=$(( files + 1 ))
    [[ $path == docs/bitacoras/Bitacora_S*.docx ]] && log_file=$(( log_file + 1 ))
  fi
done < <(git -C "$repo" -c core.quotePath=false log "$ref" --no-merges --format='@@@%H%x1f%an%x1f%ae%x1f%cs%x1f%s' --numstat)
record_commit

printf 'Referencia: %s; merges excluidos; semanas según fecha de commit con zona horaria.\n' "$ref"
printf 'Integrante | Semana | Commits | Trabajo | Bitácora | Líneas + | Líneas - | Binarios\n'
for i in "${!members[@]}"; do
  member=${members[$i]}
  printf '%s (%s):\n' "$member" "${names[$i]}"
  for week in "${weeks[@]}"; do
    key="$member:$week"
    printf '  %s | %s | %s | %s | %s | %s | %s\n' "$week" "${commits["$key"]:-0}" "${work["$key"]:-0}" "${logs["$key"]:-0}" "${added["$key"]:-0}" "${removed["$key"]:-0}" "${binary["$key"]:-0}"
  done
done
printf 'Identidades no verificadas (sin atribuir):\n'
if (( ${#unknown[@]} == 0 )); then
  printf '  ninguna\n'
else
  for identity in "${!unknown[@]}"; do
    printf '  %s: %s commits\n' "$identity" "${unknown[$identity]}"
  done
fi
printf 'Los binarios no aportan líneas; PR y revisiones requieren GitHub.\n'
