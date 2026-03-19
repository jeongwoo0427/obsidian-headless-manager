#!/bin/sh
set -e

TYPE=$1
RETENTION_HOURS=$2
VAULT_DIR="/vault"
BACKUP_DIR="/backups/$TYPE"

if [ -z "$TYPE" ]; then
    echo "Usage: backup.sh <hourly|daily|permanent> [retention_hours]"
    exit 1
fi

# 볼트가 비어있으면 스킵
if [ -z "$(ls -A "$VAULT_DIR" 2>/dev/null)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 볼트가 비어있어 백업을 건너뜁니다."
    exit 0
fi

# 파일명 형식: 타입별로 다르게
case "$TYPE" in
    hourly)
        FILENAME="obsidian_hourly_$(date '+%Y%m%d_%H%M%S').7z"
        ;;
    daily)
        FILENAME="obsidian_daily_$(date '+%Y%m%d').7z"
        ;;
    permanent)
        FILENAME="obsidian_permanent_$(date '+%Y%m').7z"
        ;;
esac

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$TYPE] 백업 시작..."

# 백업 생성 (암호화 여부 분기)
if [ -n "$BACKUP_PASSWORD" ]; then
    7z a -mx=5 -mhe=on -p"$BACKUP_PASSWORD" "$BACKUP_DIR/$FILENAME" "$VAULT_DIR/" > /dev/null
else
    7z a -mx=5 "$BACKUP_DIR/$FILENAME" "$VAULT_DIR/" > /dev/null
fi

SIZE=$(du -sh "$BACKUP_DIR/$FILENAME" | cut -f1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$TYPE] 완료: $FILENAME ($SIZE)"

# 보관 기간 초과 파일 삭제 (영구백업은 삭제 안 함)
if [ -n "$RETENTION_HOURS" ] && [ "$RETENTION_HOURS" -gt 0 ]; then
    RETENTION_MINUTES=$((RETENTION_HOURS * 60))
    DELETED=$(find "$BACKUP_DIR" -name "obsidian_${TYPE}_*.7z" -mmin +${RETENTION_MINUTES} -print)

    if [ -n "$DELETED" ]; then
        echo "$DELETED" | while read -r f; do
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$TYPE] 삭제: $(basename "$f")"
        done
        find "$BACKUP_DIR" -name "obsidian_${TYPE}_*.7z" -mmin +${RETENTION_MINUTES} -delete
    fi

    COUNT=$(find "$BACKUP_DIR" -name "obsidian_${TYPE}_*.7z" | wc -l)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$TYPE] 현재 보관 중: ${COUNT}개"
fi
