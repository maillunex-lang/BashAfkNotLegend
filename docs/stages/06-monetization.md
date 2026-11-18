# Этап 06 — VIP, гача, магазин и сезон

Статус ROAD: `NOT_STARTED`  
Зависит от: схемы героев (01); платежи — от BQ-02/03; полный баланс — после 02–05 по мере данных

## Цель

VIP 0–15 с бесплатным XP; AFK 24/36/48; серверные призывы + pity + wishlist + фракционные баннеры; магазин/подписка/battle pass/косметика. Без эксклюзивной боевой силы за деньги.

## Утверждённые требования

VIP-001 C … VIP-005 C, HERO-003 B, AFK-001 C  
Ссылки: [GAME.md](../../GAME.md) §2 этап 08, [ECONOMY.md](../../ECONOMY.md)

## Зависимости

Кошелёк; каталог героев; юридические ответы BQ-02/03; feature flag payments.

## UX

- Баннеры с публичными шансами
- История призывов
- VIP прогресс (free + paid)
- Магазин офферов; battle pass треки
- Косметика отдельно от power

## Модель данных

wallets, gacha_banners, gacha_pity, gacha_history, vip_state, shop_offers, purchases, battlepass_season, entitlements.

## API / события

[API_CONTRACT.md](../../API_CONTRACT.md) §9

## Безопасность

Серверный RNG; идемпотентные purchase; учёт refunds; возраст/рынок gates; audit.

## Edge cases

Двойной callback магазина; refund после выдачи; pity на границе; смена баннера mid-pity policy.

## Производительность

Pull — лёгкий; важнее корректность и аудит, чем throughput.

## Задачи

- [ ] Wallet + currency ledger
- [ ] Gacha engine + published tables (после согласования чисел)
- [ ] Statistical test harness
- [ ] VIP XP table + free path
- [ ] Shop stubs → real providers (после BQ)
- [ ] Battle pass tracks
- [ ] Assert: no pay-only combat stats

## Тесты

QA_PLAN §3.06

## Критерии приёмки

Вероятности документированы и стат-проверены; платежи идемпотентны; возвраты учтены; нет эксклюзивной боевой силы; бесплатный VIP доказуем; entitlements корректны.

## Риски

Юридические блокеры; pay-to-win perception; ошибки pity.

## Открытые вопросы

BQ-02, BQ-03; все числовые таблицы GAME §8.
