#!/usr/bin/env bash
# verify.sh – read-only; uruchamiany na mon-01:  bash verify.sh <F0|F1|...|all>
set -u

# ===== KONFIGURACJA (jedyne miejsce z nazwami/adresami) =====
MON_HOST="mon-01"
WEB_HOSTS=("web-01" "web-02")
ALL_HOSTS=("$MON_HOST" "${WEB_HOSTS[@]}")
PROM_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"
BLACKBOX_URL="http://localhost:9115"
NODE_PORT=9100
SSH_USER="${SSH_USER:-ubuntu}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0; FAIL=0
check() {  # check "opis" komenda...
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "[PASS] $desc"; PASS=$((PASS+1))
  else echo "[FAIL] $desc"; FAIL=$((FAIL+1)); fi
}
skip() { echo "[SKIP] $1 – jeszcze nie zaimplementowane"; }
section() { echo; echo "=== $1 ==="; }

no_crlf() { ! grep -q $'\r' "$1"; }

f0() {
  section "F0 Przygotowanie"
  for f in README.md verify.sh .gitignore .gitattributes .env.example; do
    check "plik $f istnieje" test -f "$REPO_DIR/$f"
  done
  for d in vms web mon/prometheus mon/blackbox mon/grafana/provisioning mon/grafana/dashboards; do
    check "katalog $d istnieje" test -d "$REPO_DIR/$d"
  done
  check "verify.sh ma końce linii LF" no_crlf "$REPO_DIR/verify.sh"
}

f1() {
  section "F1 VM + sieć"
  for h in "${ALL_HOSTS[@]}"; do
    check "ping $h po nazwie" ping -c1 -W2 "$h"
  done
  check "verify.sh widoczny na $MON_HOST" test -f "$REPO_DIR/verify.sh"
}

run() {
  case "$1" in
    F0|f0) f0 ;;
    F1|f1) f1 ;;
    F2|F3|F4|F5|F6|F7|F8|F9|F10|f2|f3|f4|f5|f6|f7|f8|f9|f10) skip "$1" ;;
    all) f0; f1; for p in F2 F3 F4 F5 F6 F7 F8 F9; do skip "$p"; done ;;
    *) echo "Użycie: $0 <F0|F1|...|F10|all>"; exit 2 ;;
  esac
}

run "${1:-all}"
echo; echo "=== PODSUMOWANIE: $PASS/$((PASS+FAIL)) PASS ==="
[ "$FAIL" -eq 0 ]
