#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-.}"
cd "$TARGET" || { echo "[ERR] cannot enter: $TARGET"; exit 1; }

JSON="selected.json"
PREV=""

# ---- read selected.json ----
if [[ -f "$JSON" ]]; then
  if command -v jq >/dev/null 2>&1; then
    PREV="$(jq -r '.selected // empty' "$JSON" 2>/dev/null || true)"
  else
    # fallback (simple): extracts first "selected":"..."
    PREV="$(sed -n 's/.*"selected"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$JSON" | head -n1)"
  fi
fi

# ---- collect candidates (base names) ----
mapfile -t candidates < <(
  find . -maxdepth 1 -type f -name '*_e.png' -printf '%f\n' 2>/dev/null \
  | sed 's/_e\.png$//' \
  | while IFS= read -r base; do
      [[ "${base,,}" == "f1" ]] && continue
      [[ -f "${base}.png" ]] && printf '%s\n' "$base"
    done \
  | LC_ALL=C sort
)

COUNT="${#candidates[@]}"
if [[ "$COUNT" -eq 0 ]]; then
  echo "[INFO] No pairs found: base.png + base_e.png; excluding F1"
  read -r -n 1 -s -p $'Press any key to exit...\n'
  exit 0
fi

echo
echo "Found ${COUNT} pair(s):"
echo "-------------------------"
for i in "${!candidates[@]}"; do
  idx=$((i+1))
  base="${candidates[$i]}"
  echo "${idx}) ${base}.png + ${base}_e.png"
done
echo "-------------------------"
echo

# ---- prompt ----
while true; do
  read -r -p "Pick number (1-${COUNT}) or 0 to exit: " choice
  [[ -z "${choice:-}" ]] && continue
  [[ "$choice" =~ ^[0-9]+$ ]] || { echo "[ERR] numbers only"; continue; }
  [[ "$choice" == "0" ]] && exit 0
  (( choice >= 1 && choice <= COUNT )) || { echo "[ERR] out of range"; continue; }
  break
done

SEL="${candidates[$((choice-1))]}"
echo
echo "[INFO] Selected: \"$SEL\""

ts="$(date +%Y%m%d_%H%M%S)"

# ---- helper: safe move (if target exists, add suffix) ----
safe_mv() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    local base="${dst%.*}"
    local ext="${dst##*.}"
    dst="${base}_fromF1_${ts}.${ext}"
  fi
  mv -f -- "$src" "$dst"
  echo "[INFO] mv: $src -> $dst"
}

# ---- restore previous F1 to PREV ----
if [[ -n "$PREV" ]]; then
  if [[ -f "F1.png" ]]; then
    safe_mv "F1.png" "${PREV}.png"
  fi
  if [[ -f "F1_e.png" ]]; then
    safe_mv "F1_e.png" "${PREV}_e.png"
  fi
else
  echo "[WARN] selected.json missing/empty; old F1 names will not be restored"
fi

# ---- apply selected pair to F1 ----
[[ -f "${SEL}.png" ]] || { echo "[ERR] missing: ${SEL}.png"; exit 1; }
[[ -f "${SEL}_e.png" ]] || { echo "[ERR] missing: ${SEL}_e.png"; exit 1; }

# avoid conflicts if something left
if [[ -e "F1.png" ]]; then mv -f -- "F1.png" "F1_leftover_${RANDOM}.png"; fi
if [[ -e "F1_e.png" ]]; then mv -f -- "F1_e.png" "F1_e_leftover_${RANDOM}.png"; fi

mv -f -- "${SEL}.png" "F1.png"
mv -f -- "${SEL}_e.png" "F1_e.png"
echo "[INFO] applied: ${SEL} -> F1"

# ---- write selected.json ----
if command -v jq >/dev/null 2>&1; then
  jq -n --arg s "$SEL" '{selected:$s}' > "$JSON"
else
  printf '{\"selected\":\"%s\"}\n' "$SEL" > "$JSON"
fi

echo
echo "[OK] Done."
read -r -n 1 -s -p $'Press any key to exit...\n'
