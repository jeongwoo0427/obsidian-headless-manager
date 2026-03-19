#!/bin/sh
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# 데이터 디렉토리 소유권을 실행 유저로 설정 (root로 실행 중일 때만)
if [ "$(id -u)" = "0" ]; then
    chown -R "$PUID:$PGID" /vault /home/node/.config
    exec su-exec "$PUID:$PGID" "$0" "$@"
fi

# 인자가 있으면 직접 실행 (ob login, ob sync-setup 등)
if [ $# -gt 0 ]; then
    exec "$@"
fi

VAULT_PATH="/vault"

# ── 로그인 ────────────────────────────────────────────────────────────────────
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

# ── 볼트 연결 ─────────────────────────────────────────────────────────────────
cd "$VAULT_PATH"
until ob sync-status > /dev/null 2>&1; do
    # 볼트 정보가 env에 있으면 자동 연결 시도
    if [ -n "${OBSIDIAN_VAULT_NAME}" ] && [ -n "${OBSIDIAN_DEVICE_NAME}" ]; then
        echo "볼트 자동 연결 시도 중..."
        if [ -n "${OBSIDIAN_E2E_PASSWORD}" ]; then
            if printf '%s\n' "${OBSIDIAN_E2E_PASSWORD}" | ob sync-setup \
                --vault "${OBSIDIAN_VAULT_NAME}" \
                --path "$VAULT_PATH" \
                --device-name "${OBSIDIAN_DEVICE_NAME}" > /dev/null 2>&1; then
                echo "볼트 연결 성공."
                continue
            else
                echo "볼트 자동 연결 실패. OBSIDIAN_VAULT_NAME / OBSIDIAN_E2E_PASSWORD를 확인하세요."
            fi
        else
            if ob sync-setup \
                --vault "${OBSIDIAN_VAULT_NAME}" \
                --path "$VAULT_PATH" \
                --device-name "${OBSIDIAN_DEVICE_NAME}" > /dev/null 2>&1; then
                echo "볼트 연결 성공."
                continue
            else
                echo "볼트 자동 연결 실패. OBSIDIAN_VAULT_NAME을 확인하세요."
            fi
        fi
    fi
    echo "============================================================"
    echo "  볼트 연결이 필요합니다. .env에 아래 항목을 설정하거나,"
    echo "  새 터미널에서 직접 실행하세요:"
    echo ""
    echo "    OBSIDIAN_VAULT_NAME=볼트이름"
    echo "    OBSIDIAN_DEVICE_NAME=디바이스이름"
    echo "    OBSIDIAN_E2E_PASSWORD=암호화비밀번호  # E2E 사용 시"
    echo ""
    echo "  볼트 이름 확인:"
    echo "    docker compose run --rm obsidian-sync ob sync-list-remote"
    echo ""
    echo "  30초 후 재시도합니다..."
    echo "============================================================"
    sleep 30
done

echo "볼트 연결 확인 완료."

# ── 싱크 설정 적용 ────────────────────────────────────────────────────────────
SYNC_CONFIG_ARGS=""
[ -n "${SYNC_CONFIGS}" ]            && SYNC_CONFIG_ARGS="$SYNC_CONFIG_ARGS --configs \"${SYNC_CONFIGS}\""
[ -n "${SYNC_FILE_TYPES}" ]         && SYNC_CONFIG_ARGS="$SYNC_CONFIG_ARGS --file-types \"${SYNC_FILE_TYPES}\""
[ -n "${SYNC_CONFLICT_STRATEGY}" ]  && SYNC_CONFIG_ARGS="$SYNC_CONFIG_ARGS --conflict-strategy \"${SYNC_CONFLICT_STRATEGY}\""
[ -n "${SYNC_MODE}" ]               && SYNC_CONFIG_ARGS="$SYNC_CONFIG_ARGS --mode \"${SYNC_MODE}\""
[ -n "${SYNC_EXCLUDED_FOLDERS}" ]   && SYNC_CONFIG_ARGS="$SYNC_CONFIG_ARGS --excluded-folders \"${SYNC_EXCLUDED_FOLDERS}\""

if [ -n "$SYNC_CONFIG_ARGS" ]; then
    echo "싱크 설정 적용 중..."
    eval ob sync-config --path "$VAULT_PATH" $SYNC_CONFIG_ARGS
    echo "싱크 설정 적용 완료."
fi

echo "실시간 싱크 시작..."
exec ob sync --continuous
