# CronosFatal - Documentación Técnica

## Arquitectura del Juego

### Estructura de Escenas

#### Main Scene (main.tscn)
La escena principal coordina todos los elementos del juego:
- **GameTimer**: Temporizador principal (60 segundos)
- **ObjectSpawner**: Genera objetos coleccionables cada 2 segundos
- **Player**: Instancia del personaje controlable
- **UI**: Interfaz de usuario superpuesta
- **Objects**: Contenedor para objetos coleccionables

#### Player Scene (player.tscn)
- **CharacterBody2D**: Permite movimiento y colisiones
- **CollisionShape2D**: Forma circular para detección
- **Polygon2D**: Representación visual (hexágono verde)

#### Collectible Scene (collectible.tscn)
- **Area2D**: Detecta colisiones con el jugador
- **CollisionShape2D**: Forma circular de colisión
- **Polygon2D**: Representación visual (estrella dorada)

#### UI Scene (ui.tscn)
- **HUD**: Muestra tiempo y puntuación durante el juego
- **GameOver**: Panel que aparece cuando termina el tiempo

## Mecánicas de Juego

### Sistema de Tiempo
- Tiempo inicial: 60 segundos
- Cada objeto colectado añade 2 segundos
- El juego termina cuando el tiempo llega a 0
- Feedback visual:
  - Blanco: > 30 segundos
  - Amarillo: 10-30 segundos
  - Rojo parpadeante: < 10 segundos

### Sistema de Puntuación
- +10 puntos por cada objeto coleccionado
- Sin penalización por tiempo
- Puntuación final mostrada al terminar

### Movimiento del Jugador
- Velocidad constante: 300 unidades/segundo
- Movimiento en 8 direcciones (normalizado para diagonal)
- Confinado a los límites de la pantalla

### Generación de Objetos
- Aparece un nuevo objeto cada 2 segundos
- Posición aleatoria dentro de márgenes (50px de borde)
- Los objetos persisten hasta ser colectados
- No hay límite de objetos simultáneos

## Señales y Eventos

### Señales Principales
- `collected` (Collectible): Emitida cuando el jugador recoge un objeto
- `timeout` (GameTimer): Termina el juego
- `timeout` (ObjectSpawner): Genera nuevo objeto
- `body_entered` (Collectible): Detecta colisión con jugador

## Extensiones Futuras

### Posibles Mejoras
1. **Sonidos y Música**
   - Efectos de sonido para colección
   - Música de fondo
   - Sonido de advertencia cuando queda poco tiempo

2. **Power-ups**
   - Objetos especiales con efectos únicos
   - Multiplicadores de puntuación
   - Congelación temporal del tiempo

3. **Dificultad Progresiva**
   - Objetos que se mueven
   - Obstáculos que evitar
   - Tiempo reducido a medida que avanza

4. **Niveles y Modos**
   - Sistema de niveles con objetivos
   - Modo infinito
   - Tabla de clasificación

5. **Visual y Arte**
   - Sprites personalizados
   - Efectos de partículas
   - Animaciones de personaje

## Requisitos Técnicos

- Godot Engine 4.2 o superior
- Resolución base: 1280x720 (escalable)
- Lenguaje: GDScript
- Modo de renderizado: Forward Plus

## Configuración de Input

Todas las acciones están definidas en `project.godot`:
- `move_left`: A, Flecha Izquierda
- `move_right`: D, Flecha Derecha
- `move_up`: W, Flecha Arriba
- `move_down`: S, Flecha Abajo
- `action`: Espacio (reservado para futuras mecánicas)
