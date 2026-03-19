# Obsidian 서버 싱크 & 자동 백업

Ubuntu 서버에서 Obsidian 노트를 실시간으로 싱크하고 자동 백업하는 Docker Compose 서비스입니다.
[obsidian-headless](https://www.npmjs.com/package/obsidian-headless) 공식 패키지 기반입니다.

**필요한 것**: Docker & Docker Compose, Obsidian Sync 유료 구독

---

## 시작하기

### 1. 프로젝트 다운로드

```bash
git clone https://github.com/<your-repo>/obsidian-manager.git
cd obsidian-manager
```

### 2. 환경변수 설정

```bash
cp .env.example .env
nano .env
```

```env
TZ=Asia/Seoul   # 타임존
```

### 3. 빌드 및 서비스 시작

```bash
docker compose up -d --build
```

### 4. 로그인

새 터미널에서 아래 명령어를 실행합니다.

```bash
docker compose run --rm obsidian-sync ob login
```

이메일과 비밀번호를 입력합니다.

```
? Email: your@email.com
? Password: ********
Logged in successfully.
```

이중인증(MFA) 사용 시 인증코드도 입력합니다.

```
? MFA code: 123456
Logged in successfully.
```

### 5. 볼트 연결

로그인 후, 볼트 이름을 확인합니다.

```bash
docker compose run --rm obsidian-sync ob sync-list-remote
```

확인한 볼트 이름으로 연결합니다. E2E 암호화를 사용 중이면 `--password` 입력 프롬프트가 뜹니다.

```bash
docker compose run --rm obsidian-sync ob sync-setup \
  --vault <볼트이름> \
  --path /vault \
  --device-name <디바이스이름>
```

```
? End-to-end encryption password: ********   ← E2E 암호화 사용 시에만 표시
Vault configured successfully!
```

### 6. 정상 동작 확인

```bash
docker compose logs -f
```

아래처럼 파일이 다운로드되기 시작하면 싱크와 백업이 모두 정상 작동 중입니다.

```
obsidian-sync  | 로그인 확인 완료.
obsidian-sync  | 실시간 싱크 시작...
obsidian-sync  | Downloading 노트파일.md
obsidian-sync  | Downloaded 노트파일.md
obsidian-backup  | 백업 스케줄러 시작
obsidian-backup  |   타임백업  : 매시 정각 (30시간 보관)
obsidian-backup  |   데일리백업: 매일 자정  (30일 보관)
obsidian-backup  |   영구백업  : 매월 1일   (영구 보관)
```

`Ctrl + C` 로 로그 확인 종료. 싱크된 파일은 `./data/vault/` 에 저장됩니다.

---

## 백업

싱크된 노트는 3단계로 자동 백업됩니다.

| 이름 | 주기 | 보관 | 저장 위치 |
|------|------|------|-----------|
| 타임백업 | 매시 정각 | 30시간 초과 자동 삭제 | `./data/backups/hourly/` |
| 데일리백업 | 매일 자정 | 30일 초과 자동 삭제 | `./data/backups/daily/` |
| 영구백업 | 매월 1일 01:00 | 삭제 안 함 | `./data/backups/permanent/` |

**즉시 백업 실행** (정상 작동 확인용)

```bash
docker compose exec backup /backup.sh hourly
docker compose exec backup /backup.sh daily
docker compose exec backup /backup.sh permanent
```

**백업 복원**

```bash
tar -xzf ./data/backups/daily/obsidian_daily_20260319.tar.gz -C /복원할/경로/
```

---

## 관리 명령어

```bash
# 실시간 로그 확인
docker compose logs -f

# 싱크 상태 확인
docker compose exec obsidian-sync ob sync-status

# .env 수정 후 재시작
docker compose restart

# 서비스 중지 (data/ 데이터 유지됨)
docker compose down
```

---

## 디렉토리 구조

```
obsidian-manager/
├── docker-compose.yml
├── .env                     # 환경변수 (직접 수정)
├── .env.example             # 환경변수 예시
├── sync/
│   ├── Dockerfile
│   └── entrypoint.sh
├── backup/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── backup.sh
└── data/                    # 런타임 데이터 (자동 생성)
    ├── vault/               # 싱크된 Obsidian 노트
    ├── obsidian-config/     # 로그인 자격증명
    └── backups/
        ├── hourly/
        ├── daily/
        └── permanent/
```
