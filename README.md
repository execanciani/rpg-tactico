# RPG Táctico Isométrico — prototipo fase 3

Prototipo offline realizado con Godot 4.7.2 y GDScript. El arte actual se genera con primitivas propias del motor y no utiliza recursos externos con licencias de terceros.

## Ejecutar

1. Abrí `project.godot` con Godot 4.7.2.
2. Presioná **F6/F5** o **Ejecutar proyecto**.
3. Avanzá los diálogos y seleccioná una unidad azul.

### Controles

- `M`: mover.
- `A`: atacar.
- `S`: habilidad.
- `I`: objetos y equipo.
- `W` o `Espacio`: esperar.
- `Esc`: cancelar el modo actual.
- Flechas: desplazar la cámara.
- Botón central/derecho y arrastre: desplazar la cámara.
- Rueda: zoom.
- Android: toque para seleccionar y gesto de dos dedos para desplazar o ampliar.

## Sistemas implementados

### Combate

- Mapa isométrico 12 × 12 con alturas y obstáculos.
- Movimiento con coste vertical y límite de escalada por clase.
- Línea de visión bloqueada por rocas y crestas.
- Daño físico y mágico con bonificación por altura.
- Escarcha: reduce temporalmente el movimiento.
- Quemadura: causa daño al comienzo del turno.

### Progresión

- Experiencia y niveles persistentes.
- Mejoras de HP, MP, ataque y defensa al subir de nivel.
- Monedas y recompensas por misión.
- Inventario persistente con consumibles, armas y armadura.
- Equipo restringido por clase y aplicado en las siguientes misiones.

### Campaña

La campaña contiene tres tipos de objetivo:

1. Eliminar a todos los enemigos.
2. Alcanzar una casilla de extracción dorada.
3. Sobrevivir una cantidad determinada de rondas.

Cada misión tiene briefing, diálogo introductorio, diálogo de victoria y recompensas configurados desde recursos `.tres`.

### Guardado

Los botones **Guardar** y **Cargar** usan `user://campaign_save.json`. El formato versión 3 conserva:

- Misión y ronda actual.
- HP, MP, posiciones y estados alterados.
- Nivel y experiencia de los héroes.
- Oro, inventario, equipo y misiones completadas.

Sólo se guarda durante el turno del jugador para evitar estados intermedios de animaciones o IA.

## Arquitectura

- `data/abilities`: habilidades y estados aplicados.
- `data/archetypes`: estadísticas base de héroes y enemigos.
- `data/items`: consumibles y equipo.
- `data/status_effects`: escarcha y quemadura.
- `data/missions`: mapa, objetivo, diálogo y recompensas.
- `scripts/domain`: recursos y estado de unidades, objetos e inventario.
- `scripts/core`: reglas, comandos, controlador y simulador determinista.
- `scripts/campaign`: catálogo de misiones y perfil persistente.
- `scripts/grid`: mapa isométrico y navegación con altura.
- `scripts/persistence`: guardado JSON versionado.
- `scripts/presentation`: cámara, unidades procedurales y efectos.
- `scripts/ui`: HUD, inventario, diálogos y resultados.
- `tests`: pruebas automáticas de sistemas y combates completos.

## Pruebas

```powershell
& 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke_test.gd
```

La prueba cubre recursos externos, navegación, altura, visión, inventario, equipo, consumibles, estados, experiencia, recompensas, objetivos, diálogos, guardado real temporal, carga de escena y simulaciones completas de las tres misiones.

## Alcance pendiente

Quedan para fases posteriores una pantalla de gestión entre misiones, tiendas, árboles de habilidades, más objetos y estados, objetivos con múltiples etapas, sprites y animaciones definitivas, audio, localización y multijugador.
