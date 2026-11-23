#!/usr/bin/env bash
# Corre los 15 testbenches con Icarus Verilog (probado con la versión 12).
# Uso, desde la raíz del repositorio:   bash sim/run_all.sh
# Para un solo testbench:               bash sim/run_all.sh tb_snake_cuerpo
set -u
cd "$(dirname "$0")/.."
mkdir -p sim/out
if [ $# -gt 0 ]; then TBS="$*"; else TBS=$(ls tb/*.v | xargs -n1 basename | sed 's/\.v$//'); fi
fallos=0
for tb in $TBS; do
  printf '%-24s ' "$tb"
  if ! iverilog -g2012 -s "$tb" -o "sim/out/$tb.vvp" src/*.v "tb/$tb.v" 2> "sim/out/$tb.log"; then
    echo "ERROR DE COMPILACION (ver sim/out/$tb.log)"; fallos=$((fallos+1)); continue
  fi
  (cd sim/out && vvp -n "$tb.vvp" > "$tb.log" 2>&1)
  resumen=$(grep -E 'PASARON|TODO OK|^OK [A-Z]+:' "sim/out/$tb.log" | tail -n 1)
  if [ -n "$resumen" ] && ! grep -qE 'ERROR|FALL|FAIL' "sim/out/$tb.log"; then
    echo "OK    $resumen"
  else
    echo "FALLA (ver sim/out/$tb.log)"; fallos=$((fallos+1))
  fi
done
echo "Testbenches con falla: $fallos"
exit $fallos
