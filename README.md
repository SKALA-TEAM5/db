# DB 가이드

## 개요

- 이 프로젝트의 DB 스키마 변경 관리는 Flyway로 수행합니다.
- 마이그레이션 SQL 파일은 `db/migrations`에 둡니다.
- PostgreSQL `docker-entrypoint-initdb.d` 방식으로 스키마를 만들지 않습니다.

## 디렉토리 구조

- `db/migrations`: Flyway 버전 마이그레이션 SQL (`V...__...sql`)
- `db/Dockerfile`: PostgreSQL 이미지 정의

## 로컬 개발 기본 순서

1. DB 컨테이너 실행
```bash
make db-up
```
2. 마이그레이션 상태 확인
```bash
make db-migrate-info
```
3. 마이그레이션 적용
```bash
make db-migrate
```

## 마이그레이션 파일 규칙
- 파일명 형식: `V{버전}__{설명}.sql`
- 예시:
  - `V1__init.sql`
  - `V2__add_projects_index.sql`
  - `V3__add_file_metadata.sql`

## 팀 협업 규칙
- 공유 브랜치/환경에 이미 적용된 마이그레이션 파일은 수정하지 않습니다.
- 변경이 필요하면 새 버전 파일을 추가합니다.
- 가능하면 마이그레이션 1개 파일은 1개 논리 변경만 담습니다.
- 인덱스/제약조건 생성 시 재실행 안전성을 고려합니다.

## 현재 설정 참고
- Flyway 설정:
  - `baselineOnMigrate=true`
  - `baselineVersion=1`
- 기존 스키마가 Flyway 도입 전에 생성되어 있었기 때문에, 현재 `V1__init.sql`은 baseline으로 기록되어 재실행되지 않습니다.

## Makefile 상세 설명
- `make db-up`
  - `postgres` 서비스를 백그라운드로 실행합니다.
  - 실행 후 `.env`의 `POSTGRES_*` 값을 읽어 접속 정보를 출력합니다.
- `make db-stop`
  - DB 컨테이너만 중지합니다(데이터 볼륨 유지).
- `make db-down`
  - `db-stop` 후 DB 컨테이너를 제거합니다(데이터 볼륨 유지).
- `make db-clean`
  - 현재는 `db-down`과 동일한 동작입니다.
- `make db-fclean`
  - `db-clean` 후 `./volumes/db`를 삭제해 로컬 DB 데이터를 완전히 초기화합니다.
  - 실행 전 확인 프롬프트가 있습니다.
- `make db-re`
  - `db-fclean` 후 `db-up`을 수행합니다.
  - DB를 완전 초기화한 뒤 다시 띄울 때 사용합니다.
- `make db-logs`
  - DB 로그를 실시간으로 확인합니다.
- `make db-migrate-info`
  - Flyway `info`를 실행해 현재 스키마 버전/상태를 확인합니다.
- `make db-migrate`
  - Flyway `migrate`를 실행해 신규 마이그레이션을 적용합니다.
- `make db`
  - `make db-up`의 별칭입니다.
- `make db-reset`
  - `make db-re`의 별칭입니다.

## 로컬 DB 완전 초기화 절차
```bash
make db-re
make db-migrate
```

## 자주 쓰는 명령어
```bash
make db-up
make db-migrate-info
make db-migrate
make db-logs
make db-stop
```
