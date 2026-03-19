#!/bin/sh
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# 타임존 설정 (root 필요)
ln -snf /usr/share/zoneinfo/${TZ:-Asia/Seoul} /etc/localtime
echo "${TZ:-Asia/Seoul}" > /etc/timezone

# 백업 디렉토리 생성 및 소유권 설정
mkdir -p /backups/hourly /backups/daily /backups/permanent
chown -R "$PUID:$PGID" /backups

# 크론탭 등록 (root 필요)
cat > /etc/crontabs/root << 'EOF'
# 타임백업: 매시 정각 실행, 30시간 보관
0 * * * * /backup.sh hourly 30

# 데일리백업: 매일 자정 실행, 30일(720시간) 보관
0 0 * * * /backup.sh daily 720

# 영구백업: 매월 1일 새벽 1시 실행, 삭제 안 함
0 1 1 * * /backup.sh permanent
EOF

echo "백업 스케줄러 시작"
echo "  타임백업  : 매시 정각 (30시간 보관)"
echo "  데일리백업: 매일 자정  (30일 보관)"
echo "  영구백업  : 매월 1일   (영구 보관)"

exec su-exec "$PUID:$PGID" supercronic /etc/crontabs/root
