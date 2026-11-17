# Swagger API 대조 (2026-11-17)

제공받은 Swagger의 `/v3/api-docs`를 내려받아 현재 `Core/Networking`의 메서드·경로·DTO와 대조했습니다. 인증된 운영 계정으로 모든 API를 실행한 결과는 아닙니다.

## 확인 및 이번 수정

- 구현된 API의 메서드·경로는 명세에 존재합니다. 경로가 없는 문제와 화면 바인딩 문제를 구분했습니다.
- 커뮤니티 `GET /api/community/posts/{postId}` 호출이 빠져 목록 preview를 본문으로 표시하던 문제를 수정했습니다. 상세 응답의 content, 좋아요, 댓글 수, 소유권을 바인딩합니다.
- 상태 갱신 시 게시글/댓글의 서버 ID를 잃는 문제와 본인 글의 수정·삭제 액션 연결을 수정했습니다.
- 댓글/상세 조회 실패 시 재시도 진입점을 제공합니다.
- 명세의 페이지 응답 items/hasNext, 채팅 응답 messages, 추천 items/nextRefreshToken 구조는 현재 DTO와 대응합니다. 페이지를 끝까지 읽는 기능까지 검증한 것은 아닙니다.

## 누락과 남은 확인

- 개인정보 정책·추천 수집 동의 조회/수정, 저장된 채팅 선호 조회, 문의 목록, 일반 테마, 캠퍼스 지도/시설/길찾기 및 첨부 상세/원본 조회는 아래 표처럼 앱에 연결돼 있지 않습니다. 관리자 API는 관리자 기능으로 구분합니다.
- 채팅 답변 좋아요는 로컬 선택 상태이며 Swagger에 답변 평가 API는 없습니다. 커뮤니티 게시글 좋아요 API와 구분합니다.
- 커뮤니티 댓글·게시글 일부 변경은 기존 낙관적 로컬 갱신과 syncWithServer 경로를 사용합니다. 실패 복구, 페이지네이션, 같은 제목의 글에 대한 ID 우선 처리, 최신 세션과 운영 계정 검증은 후속 협업 검토가 필요합니다.
- HTTPS 배포와 개인정보 보존 정책은 #149/#148/#298에서 추적합니다.

## 전체 경로 목록

명세 61개 메서드·경로 중 앱 호출 있음 40개. 아래 연결 여부는 소스 호출 존재 기준입니다.

| 메서드 | 경로 | 앱 연결 |
|---|---|---|
| GET | `/api/privacy/recommendation-consent` | 앱 연결 없음 |
| PUT | `/api/privacy/recommendation-consent` | 앱 연결 없음 |
| PUT | `/api/community/posts/{postId}/like` | 연결됨 |
| DELETE | `/api/community/posts/{postId}/like` | 연결됨 |
| POST | `/api/signup` | 연결됨 |
| POST | `/api/signup/email-verifications` | 연결됨 |
| POST | `/api/signup/email-verifications/confirm` | 연결됨 |
| POST | `/api/setting/inquiry` | 연결됨 |
| POST | `/api/password/reset` | 연결됨 |
| POST | `/api/password/request` | 연결됨 |
| POST | `/api/logout` | 연결됨 |
| POST | `/api/login` | 연결됨 |
| POST | `/api/community/reports` | 연결됨 |
| GET | `/api/community/posts` | 연결됨 |
| POST | `/api/community/posts` | 연결됨 |
| GET | `/api/community/posts/{postId}/comments` | 연결됨 |
| POST | `/api/community/posts/{postId}/comments` | 연결됨 |
| POST | `/api/chats` | 연결됨 |
| POST | `/api/chats/{id}/messages` | 연결됨 |
| POST | `/api/chats/{id}/location-check` | 앱 연결 없음 |
| POST | `/api/campus/location-check` | 연결됨 |
| POST | `/api/attachments` | 연결됨 |
| POST | `/api/admin/inquiries/{id}/reply` | 관리자 기능 — 앱 연결 없음 |
| POST | `/api/admin/community/reports/{reportId}/actions` | 관리자 기능 — 앱 연결 없음 |
| PATCH | `/api/setting` | 연결됨 |
| GET | `/api/mypage` | 연결됨 |
| PATCH | `/api/mypage` | 연결됨 |
| PATCH | `/api/general` | 앱 연결 없음 |
| GET | `/api/community/posts/{postId}` | 연결됨 |
| DELETE | `/api/community/posts/{postId}` | 연결됨 |
| PATCH | `/api/community/posts/{postId}` | 연결됨 |
| DELETE | `/api/community/comments/{commentId}` | 연결됨 |
| PATCH | `/api/community/comments/{commentId}` | 연결됨 |
| GET | `/api/chat-preferences` | 앱 연결 없음 |
| PATCH | `/api/chat-preferences` | 연결됨 |
| GET | `/api/specialties` | 연결됨 |
| GET | `/api/setting/main` | 연결됨 |
| GET | `/api/setting/inquiries` | 앱 연결 없음 |
| GET | `/api/question-recommendations` | 연결됨 |
| GET | `/api/privacy/policy` | 앱 연결 없음 |
| GET | `/api/main` | 연결됨 |
| GET | `/api/departments` | 연결됨 |
| GET | `/api/community/me/posts` | 연결됨 |
| GET | `/api/community/me/comments` | 연결됨 |
| GET | `/api/community/boards` | 연결됨 |
| GET | `/api/chats/{id}` | 연결됨 |
| DELETE | `/api/chats/{id}` | 연결됨 |
| GET | `/api/campus/navigation/route` | 앱 연결 없음 |
| GET | `/api/campus/navigation/places` | 앱 연결 없음 |
| GET | `/api/campus/map` | 앱 연결 없음 |
| GET | `/api/campus/floor-plans/{planId}/image` | 앱 연결 없음 |
| GET | `/api/campus/facilities` | 앱 연결 없음 |
| GET | `/api/campus/buildings/{buildingId}/floor-plans` | 앱 연결 없음 |
| GET | `/api/attachments/{attachmentId}` | 앱 연결 없음 |
| DELETE | `/api/attachments/{attachmentId}` | 연결됨 |
| GET | `/api/attachments/{attachmentId}/content` | 앱 연결 없음 |
| GET | `/api/admin/inquiries` | 관리자 기능 — 앱 연결 없음 |
| GET | `/api/admin/inquiries/{id}` | 관리자 기능 — 앱 연결 없음 |
| GET | `/api/admin/community/reports` | 관리자 기능 — 앱 연결 없음 |
| GET | `/api/admin/community/reports/{reportId}` | 관리자 기능 — 앱 연결 없음 |
| DELETE | `/api/account` | 연결됨 |
