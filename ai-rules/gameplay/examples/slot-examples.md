# Примеры Для Slot

Этот файл вторичен. Главный source of truth находится в `ai-rules/gameplay/slot.md`.

## Valid

- Пустой `Slot`: occupant отсутствует.
- `Slot` с `Pot`: слот занят `Pot`, а `Plant` находится внутри `Pot`.
- `Slot` с `Totem`: слот занят `Totem`.

## Invalid

- `Slot` одновременно содержит `Pot` и `Totem`.
- `Slot` хранит `Plant` напрямую как occupant.
- `Slot` сам тикает, слушает события или координирует реакции соседей.
