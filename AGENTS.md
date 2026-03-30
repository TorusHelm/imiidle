# Правила Для Агентов

Базовые агентские правила проекта находятся в корне `ai-rules/`:
- [ai-rules/core.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/core.md)
- [ai-rules/git.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/git.md)
- [ai-rules/test.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/test.md)

Их нужно читать:
- перед любой работой по коду,
- игровой логике,
- UI-логике,
- тестах.

Игровые архитектурные и механические контракты находятся в `ai-rules/gameplay/`:
- [ai-rules/gameplay/game-loop.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/game-loop.md)
- [ai-rules/gameplay/shelf-event-loop.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/shelf-event-loop.md)
- [ai-rules/gameplay/modifiers.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/modifiers.md)
- [ai-rules/gameplay/slot.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/slot.md)
- [ai-rules/gameplay/plant.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/plant.md)
- [ai-rules/gameplay/pot.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/pot.md)
- [ai-rules/gameplay/totem.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/totem.md)

Их нужно читать:
- перед изменениями в игровой симуляции и game loop,
- перед изменениями в логике `Shelf`, `Plant`, `Totem`, `Pot`, `Slot`,
- перед изменениями в modifiers, aura, targeting и event flow,
- перед любыми архитектурными изменениями механик.

Примеры лежат в `ai-rules/gameplay/examples/`:
- [ai-rules/gameplay/examples/game-loop-examples.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/examples/game-loop-examples.md)
- [ai-rules/gameplay/examples/plant-examples.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/examples/plant-examples.md)
- [ai-rules/gameplay/examples/slot-examples.md](C:/Users/TorusHelm/Documents/imiidle/ai-rules/gameplay/examples/slot-examples.md)

Их нужно смотреть:
- когда нужно быстро восстановить ожидаемый flow,
- когда нужен anti-example,
- когда проверяется, не ломает ли изменение уже зафиксированный контракт.

Правила в `ai-rules` считаются частью рабочего соглашения для этого проекта.
