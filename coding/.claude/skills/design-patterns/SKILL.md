---
name: design-patterns
description: Directrices para aplicar patrones de diseño en código Python (objetos de datos, protocolos, serializadores). Úsala al diseñar o implementar clases y módulos.
---

# Datos

Cuando se trate de objetos de datos, usa `dataclass`.

# Protocolos

Cuando necesites un contrato para entregar datos de A a B, define un `typing.Protocol` y haz que los consumidores dependan del protocolo, no de la clase concreta.

# Serializadores

Define los serializadores (por ejemplo, JSON) como implementaciones de un `Protocol`, de modo que se puedan inyectar y reemplazar.

# Constructores de objetos

Pendiente de definir por el autor del preset: cuándo usar un objeto constructor (builder) o una factoría.
