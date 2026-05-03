# DB 가이드

## 1. 개요

- 이 프로젝트의 DB 스키마 변경 관리는 Flyway로 수행합니다.
- 마이그레이션 SQL 파일은 `db/migrations`에 둡니다.

## 2. 디렉토리 구조

- `db/Dockerfile`: PostgreSQL 이미지 정의
- `db/migrations`: Flyway 버전 마이그레이션 SQL (`V...__...sql`)
  - 파일명 형식: `V{버전}__{설명}.sql`
  - 현재 적재된 파일:
    - `V1__init.sql` : 기본 스키마 설정
    - `V2__law.sql` : 법률 스키마 설정
    - `V3__roles_and_grants.sql`: 권한별 유저 생성
    - `V4__seed_types.sql` : 카테고리 및 증빙 자료 기본 설정 insert
    - ~~`V5__seed_service_dummy_data.sql` : 더미데이터 insert~~
    - ...


## 3. 로컬 개발 기본 순서

```bash

# 0. 프로젝트 루트의 Makefile 활용

# 1. DB 컨테이너 실행
make db-up

# 2. 마이그레이션 상태 확인
make db-migrate-info

# 3. 마이그레이션 적용
make db-migrate


# 4. 만약 로컬 DB 꼬였을 때 초기화 절차
make db-re
make db-migrate
```

## 4. DBeaver 접속

1. DB 실행
```bash
make db-up
```

2. DBeaver에서 새 연결 생성
- Database: `PostgreSQL`
- Host: `localhost` (=`POSTGRES_HOST`)
- Port: `5432` (=`POSTGRES_PORT`)
- Database: `safety` (=`POSTGRES_DB`)
- Username: `safety_user` (=`POSTGRES_USER`)
- Password: `safety_password` (=`POSTGRES_PASSWORD`)

3. 연결 테스트
- DBeaver의 `Test Connection` 클릭 후 `Finish`
- 실패하면 먼저 `make db-logs`로 DB 상태 확인

4. 앱 계정으로도 접속 가능
- 서비스 스키마 확인용: `SERVICE_APP_USER` / `SERVICE_APP_PASSWORD`
- 법률 스키마 확인용: `LAW_APP_USER` / `LAW_APP_PASSWORD`
- 관리자 확인용: `DEV_ADMIN_USER` / `DEV_ADMIN_PASSWORD`

## 5. 기타 사항 정리

### 5.1. 유저 권한 한눈에 보기

- 앱 계정 (총 3개)
  - `${SERVICE_APP_USER}`: `service` 스키마 전용
  - `${LAW_APP_USER}`: `legal_rag` 스키마 전용
  - `${DEV_ADMIN_USER}`: 로컬 개발용 관리자 계정(`SUPERUSER`)
- 두 계정 모두 자기 스키마에서는 CRUD(`SELECT/INSERT/UPDATE/DELETE`) 가능합니다.
- 서로의 스키마는 접근 못 하게 막혀있습니다.
- 새로 만드는 테이블/시퀀스에도 같은 권한이 자동 적용됩니다(`ALTER DEFAULT PRIVILEGES`).
- `dev_admin`도 하드코딩이 아니라 `.env`(`DEV_ADMIN_USER`, `DEV_ADMIN_PASSWORD`)로 관리합니다.

### 5.2. 참고할 점

- 변경은 새 마이그레이션 파일로 추가
- 계정명/비밀번호는 `.env` 값(`SERVICE_APP_USER`, `LAW_APP_USER`, `DEV_ADMIN_USER` 등)으로 관리
- DB 권한 문제 의심 시 확인 순서:
  1. `make db-migrate-info`
  2. `make db-migrate`
  3. 필요한 경우 `make db-re` 후 `make db-migrate`

### 5.3. 현재 설정 참고
- Flyway 설정:
  - `baselineOnMigrate=true`
  - `baselineVersion=1`
