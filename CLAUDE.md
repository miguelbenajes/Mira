# Mira — Monitor Viewer para macOS

App de barra de menús (sin icono en Dock) que captura monitores externos con ScreenCaptureKit y los muestra en ventanas flotantes always-on-top redimensionables. Casos de uso: vigilar una presentación en pantalla externa, vista grid de todos los monitores.

## Stack

- Swift Package Manager (swift-tools 5.9), target ejecutable único `Mira`
- macOS 13+ (`platforms: [.macOS(.v13)]`), sin dependencias externas
- SwiftUI + AppKit + ScreenCaptureKit (captura 60 FPS) + ServiceManagement (launch at login)
- Bundle ID: `com.coyote.Mira`

## Comandos

```bash
swift build                # build debug
swift build -c release     # build release
./bundle_app.sh            # build release + genera Mira.app (crea Info.plist, copia Assets)
./create_installer.sh      # llama a bundle_app.sh + genera Mira_Installer.dmg
```

No hay tests (no existe carpeta Tests/ ni target de test en Package.swift).

## Arquitectura (Sources/Mira/)

```
MonitorApp.swift        — @main, ciclo de vida de la app
MenuBarManager.swift    — icono de menu bar (ojo) + dropdown con todas las acciones
CaptureEngine.swift     — captura ScreenCaptureKit por display
WindowManager.swift     — creación/gestión de ventanas flotantes (multi-ventana)
Preferences.swift       — ajustes persistentes (always on top, launch at login...)
Views/
  SingleMonitorView.swift  — ventana de un monitor
  AllScreensView.swift     — grid con todos los monitores
  MonitorPreview.swift     — render del frame capturado
  ControlsOverlay.swift    — overlay de controles in-window (gear menu)
  AboutView.swift / LegalView.swift
```

Otros archivos root: `Mira.entitlements`, `Assets/` (icono), `PRIVACY.md`, `SECURITY.md`.

## Gotchas

- **Permiso Screen Recording**: ScreenCaptureKit requiere autorización en Ajustes del Sistema → Privacidad. Sin él, la captura devuelve frames vacíos — primera causa a comprobar si "no se ve nada".
- `bundle_app.sh` genera el `Info.plist` inline (heredoc) — cambios de versión/bundle-id se hacen ahí, no hay plist fuente.
- `Mira.app/` y `Mira_Installer.dmg` en el root son artefactos de build ya generados; se regeneran con los scripts.
- Detección de hotplug de pantallas: la app se actualiza sola al conectar/desconectar monitores (no hace falta reiniciar).
