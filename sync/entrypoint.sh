#!/bin/sh
set -e

# 인자가 있으면 직접 실행 (ob login, ob sync-setup 등)
if [ $# -gt 0 ]; then
    exec "$@"
fi

VAULT_PATH="/vault"
VAULT_NAME="${OBSIDIAN_VAULT_NAME:-}"

# 로그인 대기 루프
until ob sync-list-remote > /dev/null 2>&1; do
    echo "============================================================"
    echo "  로그인이 필요합니다. 아래 명령어를 새 터미널에서 실행하세요:"
    echo ""
    echo "    docker compose run --rm obsidian-sync ob login"
    echo ""
    echo "  30초 후 재시도합니다..."
    echo "============================================================"
    sleep 30
done

echo "로그인 확인 완료."

# 볼트 연결 대기 루프
cd "$VAULT_PATH"
until ob sync-status > /dev/null 2>&1; do
    echo "============================================================"
    echo "  볼트 연결이 필요합니다. 아래 명령어를 새 터미널에서 실행하세요:"
    echo ""
    echo "    docker compose run --rm obsidian-sync ob sync-setup \\"
    echo "      --vault \"${VAULT_NAME:-<볼트이름>}\" \\"
    echo "      --path /vault \\"
    echo "      --device-name <디바이스이름>"
    echo ""
    echo "  볼트 이름을 모르면 먼저 아래 명령어로 확인하세요:"
    echo "    docker compose run --rm obsidian-sync ob sync-list-remote"
    echo ""
    echo "  30초 후 재시도합니다..."
    echo "============================================================"
    sleep 30
done

echo "실시간 싱크 시작..."
exec ob sync --continuous
