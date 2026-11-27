# Arma docs/DORA.md con los datos que reúne scripts/dora.sh.
# Entradas (--slurpfile): releases, lead, hotfixes, reverts, incidents;
# --arg: repo, now. Fechas en UTC (ISO 8601).

def ts: sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601;
def hours($a; $b): (($b | ts) - ($a | ts)) / 3600;
def median:
  sort | length as $n
  | if $n == 0 then null
    elif $n % 2 == 1 then .[($n - 1) / 2]
    else (.[$n / 2 - 1] + .[$n / 2]) / 2 end;
def round1: . * 10 | round / 10;
def day: .[0:10];
def fmt_hours:
  if . == null then "no calculable"
  elif . >= 48 then "\(. / 24 | round1) días"
  else "\(round1) h" end;
def status($ok): if $ok == null then "—" elif $ok then "✅ cumple" else "❌ no cumple" end;

# Semanas del calendario (docs/PLAN.md §2), de lunes a domingo.
def weeks: [
  {id: "S01", from: "2026-11-02", to: "2026-11-08"},
  {id: "S02", from: "2026-11-09", to: "2026-11-15"},
  {id: "S03", from: "2026-11-16", to: "2026-11-22"},
  {id: "S04", from: "2026-11-23", to: "2026-11-29"}
];
def in_week($w): day >= $w.from and day <= $w.to;

$releases[0] as $rel
| $lead[0] as $lead
| $hotfixes[0] as $hot
| $reverts[0] as $rev
| $incidents[0] as $inc
| ($rel | map({key: .tag, value: .at}) | from_entries) as $at
| [$lead[] | select(.tag != null and .first != null)
    | . + {hours: hours(.first; $at[.tag])}] as $shipped
| [weeks[] | select(.from <= ($now | day))] as $elapsed
| ($elapsed | length | if . == 0 then 1 else . end) as $nweeks
# Frecuencia de despliegue
| ($rel | length) as $deploys
| ($deploys / $nweeks | round1) as $freq
# Tiempo de entrega
| ($shipped | map(.hours) | median) as $leadh
# Tasa de fallo: hotfix fusionado o revert antes del siguiente release
| [range(0; $rel | length) as $i
    | $rel[$i] as $r
    | ($rel[$i + 1].at // $now) as $until
    | {tag: $r.tag,
       failed: (($hot | any(. > $r.at and . <= $until)) or (($rev[$r.tag] // 0) > 0))}
  ] as $outcomes
| ($outcomes | map(select(.failed)) | length) as $failed
| (if $deploys == 0 then null else ($failed * 100 / $deploys | round1) end) as $cfr
# MTTR
| ([$inc[] | select(.closed_at != null) | hours(.created_at; .closed_at)] | median) as $mttr
| "# Métricas DORA · BOOKIA Móvil\n\n"
  + "> Archivo generado por `scripts/dora.sh` (workflow `dora.yml`). No se edita a mano.\n\n"
  + "- **Repositorio:** `\($repo)`\n"
  + "- **Generado:** \($now | sub("T"; " ") | sub("Z"; "")) UTC\n"
  + "- **Despliegue (S-3):** GitHub Release publicado desde `main` con su APK e imágenes.\n"
  + "- **Semanas transcurridas:** \($nweeks) (\([$elapsed[].id] | join(", ")))\n\n"
  + "## Resumen\n\n"
  + "| Métrica | Valor | Meta (Constitución §9.1) | Estado | Base |\n"
  + "| --- | --- | --- | --- | --- |\n"
  + "| Frecuencia de despliegue | \($freq) releases/semana | ≥ 1 por semana | \(status($freq >= 1)) | \($deploys) releases en \($nweeks) semanas |\n"
  + "| Tiempo de entrega de cambios | \($leadh | fmt_hours) | < 7 días | \(status(if $leadh == null then null else $leadh < 168 end)) | \($shipped | length) PRs ya liberados |\n"
  + "| Tasa de fallo de cambios | \(if $cfr == null then "no calculable" else "\($cfr) %" end) | ≤ 15 % | \(status(if $cfr == null then null else $cfr <= 15 end)) | \($failed) de \($deploys) releases con hotfix o revert |\n"
  + "| Tiempo de recuperación (MTTR) | \($mttr | fmt_hours) | < 24 h | \(status(if $mttr == null then null else $mttr < 24 end)) | \([$inc[] | select(.closed_at != null)] | length) incidentes cerrados (etiqueta `incident`) |\n\n"
  + "Sin releases, incidentes o PRs liberados la métrica queda **no calculable**, no en 0 (docs/QUALITY.md §2).\n\n"
  + "## Por semana\n\n"
  + "| Semana | Fechas | Releases | PRs fusionados en `develop` |\n| --- | --- | --- | --- |\n"
  + ([weeks[] as $w
      | "| \($w.id) | \($w.from[5:]) a \($w.to[5:]) | \([$rel[] | select(.at | in_week($w))] | length) | \([$lead[] | select(.merged_at != null and (.merged_at | in_week($w)))] | length) |\n"]
     | add)
  + "\n## Releases\n\n"
  + (if $deploys == 0 then "Aún no hay releases publicados.\n"
     else "| Release | Publicado (UTC) | PRs incluidos | Mediana de entrega | Hotfix o revert después |\n| --- | --- | --- | --- | --- |\n"
       + ([$rel[] as $r
           | [$shipped[] | select(.tag == $r.tag)] as $prs
           | "| `\($r.tag)` | \($r.at | sub("T"; " ") | sub("Z"; "")) | \($prs | length) | \($prs | map(.hours) | median | fmt_hours) | \(if ($outcomes[] | select(.tag == $r.tag) | .failed) then "sí" else "no" end) |\n"]
          | add)
     end)
  + "\n## Pendiente de liberar\n\n"
  + "\([$lead[] | select(.tag == null)] | length) PRs fusionados en `develop` todavía no están en ningún release.\n"
