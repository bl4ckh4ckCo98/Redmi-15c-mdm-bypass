# Script que aprovecha que PUEDES abrir apps en ventanas
cat > window.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== EXPLOTANDO MODO VENTANA ==="
echo ""

# 1. Primero, intentar encontrar actividades del MDM que podamos abrir
echo "1. Buscando actividades del MDM..."
for pkg in com.mediatek.mdmconfig com.mediatek.mdmlsample; do
    echo "=== $pkg ==="
    
    # Listar actividades (método alternativo)
    echo "Actividades encontradas:"
    
    # Método 1: Buscar en manifest (si tenemos acceso a aapt)
    if [ -f "/system/bin/aapt" ]; then
        apk_path=$(cmd package path "$pkg" 2>/dev/null | cut -d: -f2)
        if [ -f "$apk_path" ]; then
            aapt dump badging "$apk_path" 2>/dev/null | grep "launchable-activity" | head -3
        fi
    fi
    
    # Método 2: Intentar actividades comunes
    COMMON_ACTIVITIES=(
        ".MainActivity"
        ".SettingsActivity"
        ".AdminSettings"
        ".ConfigActivity"
        ".MdmActivity"
        ".SetupWizard"
        ".LoginActivity"
    )
    
    for activity in "${COMMON_ACTIVITIES[@]}"; do
        if am start -n "$pkg/$activity" 2>/dev/null; then
            echo "  ✓ $activity - ABIERTA"
            sleep 1
            input keyevent KEYCODE_BACK 2>/dev/null
        fi
    done
done

echo ""
echo "2. Creando 'falso launcher' en ventana..."
# El truco: crear una app simple que actúe como launcher
cat > /data/data/com.termux/files/home/fake_launcher.py << 'PYEOF'
import os
import time

# Lista de apps para mostrar
apps = [
    ("Chrome", "com.android.chrome", "com.google.android.apps.chrome.MainActivity"),
    ("Ajustes", "com.android.settings", ".Settings"),
    ("Archivos", "com.android.documentsui", ".FilesActivity"),
    ("Cámara", "com.android.camera2", ".CameraActivity"),
    ("Termux", "com.termux", ".app.TermuxActivity"),
]

print("=== FAKE LAUNCHER ===")
for i, (name, pkg, activity) in enumerate(apps, 1):
    print(f"{i}. {name}")

try:
    choice = int(input("Selecciona app (1-5): ")) - 1
    if 0 <= choice < len(apps):
        name, pkg, activity = apps[choice]
        print(f"Abriendo {name}...")
        os.system(f"am start-activity --windowing-mode 5 -n {pkg}/{activity}")
except:
    print("Opción inválida")
PYEOF

echo "  Fake launcher creado en Termux"

echo ""
echo "3. Configurando acceso persistente via Taskbar..."
# Crear script para Taskbar
cat > /data/data/com.termux/files/home/taskbar_launcher.sh << 'TSKEOF'
#!/data/data/com.termux/files/usr/bin/bash

# Este script se puede asignar a un botón en Taskbar

# Primero, intentar deshabilitar MDM temporalmente
for pkg in com.mediatek.mdmconfig com.mediatek.mdmlsample; do
    # Forzar cierre sin deshabilitar (menos detectable)
    am force-stop "$pkg" 2>/dev/null
    
    # Suspender app (Android 7+)
    cmd appops set "$pkg" RUN_IN_BACKGROUND ignore 2>/dev/null
done

# Abrir menú de selección
python /data/data/com.termux/files/home/fake_launcher.py
TSKEOF

chmod +x /data/data/com.termux/files/home/taskbar_launcher.sh

echo ""
echo "4. Configurando atajos de teclado..."
# Asignar teclas de volumen para acciones (si Taskbar lo permite)
cat > /data/data/com.termux/files/home/volume_shortcuts.sh << 'VOLEOF'
#!/data/data/com.termux/files/usr/bin/bash

# Monitorear estado de botones (esto es conceptual, requiere app específica)
echo "Atajos configurados:"
echo "- Volumen+ + Volumen-: Abrir Termux en ventana"
echo "- Volumen+ x3: Abrir Chrome en ventana"
echo "- Volumen- x3: Abrir Ajustes en ventana"

# En la práctica necesitarías una app como 'Button Mapper' o similar
VOLEOF

echo ""
echo "5. Método de 'overlay' permanente..."
echo "   Instalar 'Floating Apps' desde GetApps y configurar:"
echo "   1. Abrir Floating Apps"
echo "   2. Crear nuevo floating button"
echo "   3. Asignar acción: 'Execute shell command'"
echo "   4. Comando: am start-activity --windowing-mode 5 -n com.termux/.app.TermuxActivity"
echo "   5. Posicionar en esquina de pantalla"

echo ""
echo "=== SCRIPT COMPLETO ==="
echo "Ejecuta 'python fake_launcher.py' en Termux para abrir el menú"
EOF
