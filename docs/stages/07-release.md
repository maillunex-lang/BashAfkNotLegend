# Этап 07 — Релиз и эксплуатация

Статус ROAD: `NOT_STARTED`  
Зависит от: 01–06 (MVP всех систем)

## Цель

Админка и визуальная студия; доставка ассетов по manifest/hash; минимальный APK; PWA service worker; мониторинг; бэкапы; DR; безопасный деплой после разрешения; античит; нагрузочные тесты.

## Утверждённые требования

TECH-001 B … TECH-004 C, критерии GAME.md §7 п.12  
Ссылки: [ARCHITECTURE.md](../../ARCHITECTURE.md), [QA_PLAN.md](../../QA_PLAN.md)

## Зависимости

Стабильные API; контент-пайплайн; ответы BQ-10; явное разрешение на VPS/деплой.

## UX

- Admin RBAC workflows: preview → publish → rollback
- Клиенты: первый запуск качает ассеты; понятные ошибки сети
- PWA installability на iPhone

## Модель данных

admin_users/roles, audit_log, content_releases, asset_manifests, feature_flags.

## API / события

Admin `/admin/v1/*`; content/assets manifests — API_CONTRACT §10–11.

## Безопасность

RBAC + audit; secrets; no remote code execution via assets; backup encryption at rest policy TBD; rollback plan.

## Edge cases

Частично скачанный manifest; откат контента mid-season; failed migration; split brain WS.

## Производительность

Load test целевого VPS; AI/war throttles; APK size budget (BQ-10).

## Задачи

- [ ] Admin MVP + visual studio scope
- [ ] Asset CDN/Caddy pipeline
- [ ] Android APK minify + install test
- [ ] PWA SW + iPhone install test
- [ ] Monitoring + alerts
- [ ] Backup + restore drill
- [ ] Load tests
- [ ] Release checklist
- [ ] Deploy **только** после явного разрешения

## Тесты

QA_PLAN §3.07

## Критерии приёмки

APK ставится; PWA на реальном iPhone работает; один сервер на оба клиента; ассеты докачиваются/кэшируются; restore БД проверен; метрики CPU/RAM; сценарий отката; релизный чеклист.

## Риски

Safari quirks; VPS capacity; деплой без разрешения — запрещён.

## Открытые вопросы

BQ-02/03/10; хостинг ассетов; домен/HTTPS сертификаты.
