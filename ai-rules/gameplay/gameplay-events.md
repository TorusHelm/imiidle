# Контракт Для Gameplay Events

## Назначение

Этот документ фиксирует правила gameplay events в локальной симуляции `Shelf`.

Это строгий архитектурный контракт для агентов, а не гайд по реализации.

## Назначение Gameplay Events

`Gameplay events` существуют для передачи игровых фактов внутри локальной симуляции `Shelf`.

Они:
- используются для реакций actors, например `Totem`,
- описывают gameplay-факты,
- не должны смешиваться со служебными событиями event loop.

## Разделение: Report / Gameplay Event / Request

В системе существуют три разные сущности.

### Report

`Report` означает:
- actor сообщает `Shelf` о факте, который произошел с ним,
- report не является прямым применением эффекта.

Пример:
- actor сообщает о своей activation.

### Gameplay Event

`Gameplay event` означает:
- `Shelf` рассылает локальное игровое событие внутри `Shelf`,
- это событие могут слушать другие actors,
- gameplay event представляет игровой факт, а не намерение что-то сделать.

### Request

`Request` означает:
- actor запрашивает у `Shelf` выполнение действия или применение эффекта,
- request не является gameplay event,
- request выражает намерение, а не игровой факт.

Жесткое правило:
- report, gameplay event и request не должны смешиваться в одну сущность.

## Что Считается Gameplay Event

`Gameplay event` — это событие, которое имеет игровой смысл для механик.

Правила:
- gameplay events используются как вход для реактивных систем,
- gameplay events относятся к gameplay-логике,
- gameplay events не являются частью технической инфраструктуры event loop.

## Что Не Считается Gameplay Event

Не являются gameplay events:
- служебные шаги event loop,
- фазы tick: `APPLY`, `UPDATE`, `COLLECT`, `BUILD NEXT QUEUE`,
- технические события обработки очереди,
- UI-события,
- layout-события,
- drag-and-drop события,
- debug-события,
- editor-события.

Жесткое правило:
- `Totem` и другие gameplay-системы не должны зависеть от таких событий.

## Источники Gameplay Events

Источником gameplay event могут быть только actors.

На текущем этапе это:
- `Plant`,
- `Totem`.

Также:
- `Pot` не является источником gameplay event,
- `Slot` не является источником gameplay event,
- `Shelf` не является обычным gameplay source,
- `Room` не является источником локальных gameplay events внутри `Shelf`.

## Базовый Набор Gameplay Events

На текущем этапе базовый набор включает только:
- `plant_activated`,
- `totem_activated`.

Правило расширения:
- набор gameplay events может расширяться в будущем,
- новые типы не должны добавляться автоматически,
- расширение набора gameplay events требует отдельного осознанного согласования.

## Applied Events

На текущем этапе:
- события вида `modifier_applied`,
- события вида `instant_effect_applied`,
- и аналогичные applied events

не считаются частью базового gameplay event контракта.

Правило:
- системы не должны по умолчанию строиться вокруг реакции на applied events.

## Связь Gameplay Events И Tick

Правила:
- gameplay events из `tick N` становятся доступны только в `tick N+1`,
- actors не видят gameplay events текущего тика,
- actors реагируют только на gameplay events прошлого тика,
- `Shelf` рассылает gameplay events, а actor сам решает, реагировать на них или нет.

## Связь Gameplay Events И Totem

`Totem` реагирует только на gameplay events.

Правила:
- `Totem` не должен слушать служебные события симуляции,
- конкретный `Totem` может слушать все gameplay events,
- конкретный `Totem` может использовать whitelist типов gameplay events.

## Минимальный Смысловой Контракт События

Каждый gameplay event должен содержать:
- тип события,
- источник события,
- минимальный набор данных, необходимых для gameplay-логики этого события.

Правила:
- payload не должен раздуваться без необходимости,
- нельзя вводить абстрактные поля на будущее без явной причины,
- payload должен быть минимальным и понятным.

## Локальность Gameplay Events

Gameplay events локальны для конкретной `Shelf`.

Правила:
- gameplay events не маршрутизируются между разными `Shelf`,
- `Shelf` является границей распространения локальных gameplay events.

## Gameplay Events Не Должны

Gameplay events не должны:
- смешиваться с request,
- смешиваться с техническими событиями event loop,
- описывать уже примененный эффект как основной базовый контракт,
- исходить от не-actor сущностей,
- автоматически расширяться без отдельного согласования,
- использовать перегруженный или раздутый payload без необходимости.

## Source Of Truth

Для текущего этапа source of truth такой:
- gameplay events описывают только игровые факты внутри локальной симуляции `Shelf`,
- report, gameplay event и request являются разными категориями,
- базовый набор gameplay events ограничен `plant_activated` и `totem_activated`,
- gameplay events локальны для одной `Shelf`,
- gameplay events из `N` становятся доступны только в `N+1`,
- gameplay systems, включая `Totem`, реагируют только на gameplay events, а не на технические шаги event loop.
