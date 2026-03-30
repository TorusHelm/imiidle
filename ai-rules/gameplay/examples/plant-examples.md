# Примеры Для Plant

Этот файл вторичен. Основной контракт находится в `ai-rules/gameplay/plant.md`.

## Сцена: Два Растения И Metronome

Раскладка:
- slot 1: `Pot` + `Plant A`
- slot 2: `Totem Metronome`
- slot 3: `Pot` + `Plant B`

Условия:
- `Shelf` тикает дискретно,
- все события проходят через `Shelf`,
- прямых вызовов между `Plant` и `Totem` нет.

## Пример Корректного Flow

1. `tick N`: `Shelf` делает tick и передает `delta`.
2. `tick N`: `Plant A` обновляет только свое внутреннее состояние.
3. `tick N`: `Plant A` доходит до activation и отправляет report в `Shelf`.
4. Конец `tick N`: `Shelf` строит gameplay event для `N+1`.
5. `tick N+1`: `Metronome` видит gameplay event прошлого тика и формирует request на `haste` или `charge` для `Plant B`.
6. Конец `tick N+1`: `Shelf` выбирает конкретную цель.
7. `tick N+2`: `Shelf` применяет эффект к `Plant B`.

## Что Важно В Этом Примере

- `Plant A` не знает о существовании `Plant B`.
- `Plant A` не знает о существовании `Metronome`.
- `Plant A` не выбирает цель эффекта.
- `Plant A` не применяет награду напрямую.
- `Plant B` не получает эффект напрямую от `Metronome`, а только через `Shelf`.
- `Plant A` и `Plant B` не могут иметь больше одной activation за тик.

## Неправильная Модель

Так работать не должно:
- `Plant A` активируется и напрямую вызывает реакцию `Metronome`.
- `Metronome` напрямую вызывает изменение состояния `Plant B`.
- `Plant B` в ответ напрямую активируется в той же actor-to-actor цепочке.

Это нарушает контракт:
- нет прямых actor -> actor взаимодействий,
- все report, gameplay events и request проходят через `Shelf`,
- поведение `Plant` не должно обходить orchestrator,
- реакция не должна происходить в том же тике.
