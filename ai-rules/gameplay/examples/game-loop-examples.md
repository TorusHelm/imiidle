# Примеры Для Game Loop

Этот файл вторичен. Главный source of truth находится в `ai-rules/gameplay/game-loop.md`.

## Пример Одного Цикла Реакции

Ситуация:
- `Shelf` имеет несколько слотов,
- один `Plant` готов активироваться,
- рядом есть `Totem`, который реагирует на gameplay events.

Правильная схема:
1. `tick N`: `Plant` обновляется и делает activation report.
2. Конец `tick N`: `Shelf` строит gameplay event для `N+1`.
3. `tick N+1`: `Totem` видит gameplay event прошлого тика и создает request.
4. Конец `tick N+1`: `Shelf` выполняет target selection и строит очередь применения.
5. `tick N+2`: `Shelf` применяет эффект в `APPLY`.

## Пример Metronome

Ситуация:
- слот 1: `Pot` + `Plant A`
- слот 2: `Totem Metronome`
- слот 3: `Pot` + `Plant B`

Поведение:
- `tick N`: `Plant A` активируется и делает report.
- Конец `tick N`: `Shelf` строит gameplay event для `N+1`.
- `tick N+1`: `Metronome` видит это событие и создает request на `charge` или `haste` для зеркальной цели.
- Конец `tick N+1`: `Shelf` определяет конкретную цель `Plant B`.
- `tick N+2`: `Shelf` применяет эффект к `Plant B`.

## Неправильная Модель

Так работать не должно:
1. `Plant A` активируется.
2. `Totem` немедленно реагирует в том же тике.
3. `Plant B` немедленно получает эффект в том же тике.
4. `Plant B` мгновенно активируется в той же цепочке.

Это запрещено, потому что нарушает deferred-модель и ведет к event hell.

## Допустимая Задержка

Если схема выглядит как:
- `N`: activation,
- `N+1`: reaction,
- `N+2`: apply,

это считается нормальным поведением, а не багом.
