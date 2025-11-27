# TIEMPOMUERTO - CronosFatal

## Descripción

**CronosFatal** es un juego de acción contra el tiempo desarrollado en Godot. El jugador debe recolectar objetos antes de que se acabe el tiempo. Cada objeto recolectado otorga puntos y tiempo adicional, creando una experiencia de juego tensa y emocionante.

## Características

- 🎮 Controles simples e intuitivos (WASD o flechas)
- ⏱️ Sistema de tiempo dinámico que aumenta la tensión
- 🏆 Sistema de puntuación
- 💎 Objetos coleccionables que aparecen aleatoriamente
- ⏰ Bonus de tiempo al recolectar objetos
- 🎨 Interfaz visual clara con indicadores de tiempo

## Requisitos

- **Godot Engine 4.2+**

## Cómo Jugar

### Instalación

1. Descarga e instala [Godot Engine 4.2 o superior](https://godotengine.org/download)
2. Clona este repositorio:
   ```bash
   git clone https://github.com/DarkNeku/TIEMPOMUERTO.git
   cd TIEMPOMUERTO
   ```
3. Abre el proyecto con Godot Engine
4. Presiona F5 o haz clic en "Ejecutar Proyecto"

### Controles

- **Movimiento**: WASD o Flechas del teclado
- **Reiniciar**: R (cuando el juego termina)

### Objetivo

Recolecta tantos objetos (estrellas doradas) como puedas antes de que se acabe el tiempo. Cada objeto te da:
- **+10 puntos**
- **+2 segundos** de tiempo adicional

¡El juego termina cuando el tiempo llega a 0!

## Estructura del Proyecto

```
TIEMPOMUERTO/
├── project.godot          # Configuración del proyecto Godot
├── icon.svg              # Icono del juego
├── scenes/               # Escenas del juego
│   ├── main.tscn        # Escena principal
│   ├── player.tscn      # Escena del jugador
│   ├── collectible.tscn # Escena de objetos coleccionables
│   └── ui.tscn          # Interfaz de usuario
├── scripts/             # Scripts GDScript
│   ├── main.gd         # Lógica principal del juego
│   ├── player.gd       # Movimiento del jugador
│   ├── collectible.gd  # Lógica de coleccionables
│   └── ui.gd           # Lógica de interfaz
└── assets/             # Recursos (sprites, sonidos, etc.)
```

## Desarrollo

Este proyecto está desarrollado con:
- **Godot Engine 4.2**
- **GDScript** como lenguaje de programación
- **Godot 2D** para los gráficos

## Licencia

Este proyecto está disponible bajo licencia de código abierto.

## Autor

DarkNeku

---

**¡Disfruta del juego y desafía tu velocidad contra el tiempo fatal!** ⏰💀