# RPG Táctico Isométrico — prototipo fase 3

Prototipo offline realizado con Godot 4.7.2 y GDScript. El arte actual se genera con primitivas propias del motor y no utiliza recursos externos con licencias de terceros.

## Ejecutar

1. Abrí `project.godot` con Godot 4.7.2.
2. Presioná **F6/F5** o **Ejecutar proyecto**.
3. Creá entre uno y tres personajes en los espacios vacíos.
4. Elegí la formación y pulsá **COMENZAR AVENTURA**.
5. Avanzá los diálogos; la unidad activa se selecciona automáticamente según su velocidad.

### Selección de personajes

- Una partida nueva comienza con tres espacios vacíos y no agrega héroes automáticamente.
- El botón `+` abre un flujo de cuatro pasos: raza, profesión compatible, vista previa y nombre.
- Los nombres deben tener entre 3 y 16 caracteres, no pueden repetirse ni contener controles.
- Cada tarjeta permite seleccionar, consultar información o solicitar la eliminación del personaje.
- La eliminación siempre requiere confirmación.
- La creación, eliminación y formación se guardan automáticamente.
- Se puede comenzar el combate con uno, dos o tres integrantes.

### Controles

- `M`: mover.
- `A`: atacar.
- `S`: habilidad.
- `W` o `Espacio`: esperar.
- `Esc`: cancelar el modo actual.
- Flechas: desplazar la cámara.
- Botón central/derecho y arrastre: desplazar la cámara.
- Rueda: zoom.
- Android: toque para seleccionar y gesto de dos dedos para desplazar o ampliar.
- Botón **Progreso**: abre Personaje, Profesiones y Habilidades durante un turno disponible.

## Sistemas implementados

### Combate

- Mapa isométrico 12 × 12 con alturas y obstáculos.
- Movimiento con coste vertical y límite de escalada por clase.
- Línea de visión bloqueada por rocas y crestas.
- Daño físico y mágico con bonificación por altura.
- Iniciativa individual ordenada por velocidad, con desempate estable y exclusión inmediata de derrotados.
- Seis habilidades de héroe externas: Golpe poderoso, Guardia de acero, Lanza glacial, Escarcha paralizante, Flecha precisa y Disparo doble.
- Coste de MP, enfriamientos, objetivos propios/aliados/enemigos, área y múltiples impactos.
- Previsualización de ruta antes de confirmar el movimiento y animación casilla por casilla.
- Escarcha acumulable: reduce temporalmente el movimiento.
- Guardia de acero: aumenta temporalmente las defensas.
- Quemadura: causa daño al comienzo del turno.
- IA determinista que prioriza habilidades según daño, área y estados.

### Mago humano pixel art

- La composición `assets/sprites/characters/mage/mage_spritesheet.png` se procesa mediante `tools/extract_mage_assets.py`.
- Los cuadros de combate se normalizan sobre lienzos transparentes de 96×96, alineados por los pies y sin interpolación.
- El mago humano utiliza `AnimatedSprite2D` para idle, caminar, ataque básico, lanzamiento, daño y derrota.
- Las habilidades mágicas muestran preparación, proyectil y un impacto de hielo o explosión sin modificar daño ni MP.
- La pantalla de creación usa `portrait_human_mage.png` únicamente para la combinación Humano + Mago; las demás razas conservan su retrato correspondiente.
- La hoja solo incluye caminar, atacar y lanzar lateralmente. Frente y espalda utilizan sus poses idle hasta que existan cuadros adicionales.

### Terreno isometrico de cesped

- La composicion `assets/tilesets/grass/grass_tileset.png` se procesa de forma reproducible mediante `tools/extract_grass_tileset.py`.
- Las superficies transitables se normalizan en lienzos transparentes de 72x48 y conservan el diamante logico de 64x32 sin interpolacion.
- El renderizador personalizado selecciona variantes de cesped normal, flores, piedras y hierba alta de forma determinista segun la mision y las coordenadas.
- Las texturas son solo presentacion: alturas, obstaculos, costes, seleccion, rutas y linea de vision siguen usando los datos existentes.
- Los bloques, bordes y escaleras se extraen como recursos preparados. Las caras laterales siguen dibujandose por codigo porque las misiones actuales no almacenan direccion o tipo de escalera; mostrar una pieza arbitraria indicaria conexiones falsas.

### Equipamiento visual por capas

- `tools/prepare_equipment_assets.py` extrae cinco cuerpos base limpios de la composicion original y genera iconos y capas provisionales transparentes para vista previa y combate.
- Cada personaje conserva un `appearance_id` independiente de su profesion, inventario con cantidades y ocho slots persistidos mediante IDs estables.
- Los 22 objetos iniciales son Resources externos con requisitos, bonificaciones, icono y variantes visuales por modelo corporal.
- La pestaña **Equipo** permite equipar y desequipar con mouse o tactil, recalcula las estadisticas desde sus fuentes y guarda el cambio automaticamente.
- Las capas de casco, torso, manos, pies, arma y escudo se muestran sobre los sprites de combate; armas, escudos y capas cambian su orden segun la orientacion.
- El arte inicial de equipo usa una pose corporal estatica coherente sobre las animaciones existentes. Todavia faltan overlays dibujados cuadro por cuadro para cada direccion y estado.

### Progresión

- Cinco razas originales configuradas en recursos: Humanos, Elfos, Elfos oscuros, Orcos y Enanos.
- Atributos STR, DEX, CON, INT, WIS y MEN con modificadores raciales.
- Estadísticas derivadas centralizadas: HP/MP, ataques, defensas, precisión, evasión, crítico, velocidad, movimiento y resistencia.
- Cinco profesiones iniciales y árbol externo de evoluciones para niveles 20 y 40.
- Rama Guerrero → Espadachín/Guardián → Maestro de Espadas/Protector de Hierro completamente funcional.
- Curva de experiencia configurable de nivel 1 a 80, incluyendo varias subidas simultáneas.
- Skill Points obtenidos al subir de nivel, requisitos, gasto y prevención de aprendizajes duplicados.
- Seis habilidades aprendibles nuevas, además de las habilidades de combate existentes.
- Pantallas táctiles de personaje, profesiones y aprendizaje de habilidades.
- Pantalla inicial independiente para creación, selección y gestión de hasta tres personajes.
- Los cinco retratos raciales se extraen de la referencia original mediante `tools/extract_character_selection_assets.py`.
- Si falta una imagen se utiliza un retrato provisional generado mediante código.
- Para reemplazarlos, se puede colocar `assets/portraits/races/portrait_<race_id>.png` o `assets/portraits/classes/portrait_<profession_id>.png`; la interfaz los carga automáticamente con filtrado nearest-neighbor.

### Campaña

La campaña contiene tres tipos de objetivo:

1. Eliminar a todos los enemigos.
2. Alcanzar una casilla de extracción dorada.
3. Sobrevivir una cantidad determinada de rondas.

Cada misión tiene briefing, diálogo introductorio, diálogo de victoria y recompensas configurados desde recursos `.tres`.

### Guardado

Los botones **Guardar** y **Cargar** usan `user://campaign_save.json`. El formato versión 7 conserva y migra partidas desde la versión 3:

- Misión y ronda actual.
- HP, MP, posiciones, estados alterados y enfriamientos.
- Cola de iniciativa, unidad activa y acciones ya realizadas en la ronda.
- Raza, profesión e historial profesional de cada personaje.
- Nivel, experiencia total, SP disponible/gastado y habilidades aprendidas.
- Atributos base permanentes; las estadísticas derivadas se recalculan al cargar.
- Personajes creados, espacios ocupados, formación seleccionada y misiones completadas.
- Apariencia corporal, inventario, cantidades y equipamiento por IDs estables.

Sólo se guarda durante el turno del jugador para evitar estados intermedios de animaciones o IA.

## Arquitectura

- `data/abilities`: habilidades y estados aplicados.
- `data/archetypes`: estadísticas base de héroes y enemigos.
- `data/races`: cinco razas y sus profesiones iniciales permitidas.
- `data/professions`: árbol profesional definido completamente mediante datos.
- `data/status_effects`: escarcha, quemadura y mejoras defensivas.
- `data/equipment` y `data/appearances`: objetos equipables y modelos corporales externos.
- `data/missions`: mapa, objetivo, diálogo y recompensas.
- `scripts/domain`: recursos y estado permanente o temporal de personajes y unidades.
- `scripts/core`: reglas, comandos, controlador y simulador determinista.
- `scripts/campaign`: catálogo de misiones y perfil persistente.
- `scripts/grid`: mapa isométrico y navegación con altura.
- `scripts/persistence`: guardado JSON versionado.
- `scripts/presentation`: cámara, unidades procedurales y efectos.
- `scenes/presentation`: visual animado y efectos reutilizables del mago.
- `scripts/ui`: HUD, progresión, creación de personajes, diálogos y resultados.
- `scenes/ui`: escenas reutilizables de selección, tarjetas, razas, profesiones, vista previa y confirmación.
- `assets/portraits` y `assets/sprites`: ubicaciones preparadas para reemplazar retratos y sprites provisionales.
- `tests`: pruebas automáticas de sistemas y combates completos.

## Pruebas

```powershell
& 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke_test.gd
```

La prueba cubre modificadores raciales, cálculo idempotente de estadísticas, experiencia, múltiples niveles, límite 80, SP, aprendizaje, profesiones, persistencia de personajes, navegación, combate y simulaciones completas de las tres misiones.

## Alcance pendiente

Quedan para fases posteriores overlays de equipo cuadro por cuadro, variantes corporales por raza, habilidades exclusivas para todas las ramas avanzadas, tercera evolución de nivel 76, sprites definitivos, audio, localización y multijugador.
