---
name: design-patterns
description: Guidelines for applying design patterns in Python code (data objects, protocols, serializers). Use it when designing or implementing classes and modules.
---

# Data

For data objects, use `dataclass`.

# Protocols

When you need a contract to hand data from A to B, define a `typing.Protocol` and make consumers depend on the protocol, not on the concrete class.

# Serializers

Define serializers (for example, JSON) as implementations of a `Protocol`, so they can be injected and replaced.

# Object constructors

Pending definition by the preset author: when to use a builder or a factory.
