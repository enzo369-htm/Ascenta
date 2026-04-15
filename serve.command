#!/bin/bash
# Servidor local: primero levanta Python, después abre el navegador (evita ERR_EMPTY_RESPONSE).
cd "$(dirname "$0")" || exit 1

PORT="${PORT:-8765}"
HOST="127.0.0.1"

pick_port() {
  local p="$PORT"
  while lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; do
    p=$((p + 1))
    if [ "$p" -gt 8800 ]; then
      echo "No hay puerto libre entre ${PORT} y 8800."
      exit 1
    fi
  done
  echo "$p"
}

PORT="$(pick_port)"

echo ""
echo "  Ascenta — servidor local"
echo "  Carpeta: $(pwd)"
echo "  URL:     http://${HOST}:${PORT}/"
echo "  Cerrá esta ventana o Ctrl+C para detener."
echo ""

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null
  fi
}
trap cleanup EXIT INT TERM

# Arranca el servidor antes de abrir el navegador
python3 -m http.server "$PORT" --bind "$HOST" &
SERVER_PID=$!

# Espera a que responda HTTP (hasta ~6 s)
READY=0
for _ in $(seq 1 40); do
  if curl -s -o /dev/null --connect-timeout 1 "http://${HOST}:${PORT}/" 2>/dev/null; then
    READY=1
    break
  fi
  sleep 0.15
done

if [ "$READY" != "1" ]; then
  echo "Error: el servidor no respondió en http://${HOST}:${PORT}/"
  echo "Probá: python3 -m http.server $PORT --bind $HOST"
  exit 1
fi

open "http://${HOST}:${PORT}/" 2>/dev/null || true
wait "$SERVER_PID"
