# Truco: Hacer que el sistema piense que estamos usando una app permitida
cat > spoof.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== SUPLANTACIÓN DE PAQUETE ==="
echo ""

# Idea: Usar am start con flags especiales
echo "1. Probando diferentes flags de intent..."

# Flags comunes que podrían bypass restricciones
FLAGS=(
    "0x10000000"  # FLAG_ACTIVITY_NEW_TASK
    "0x20000000"  # FLAG_ACTIVITY_CLEAR_TASK
    "0x08000000"  # FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
    "0x00400000"  # FLAG_ACTIVITY_CLEAR_WHEN_TASK_RESET
    "0x00080000"  # FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
    "0x10808000"  # Combinación común
)

echo "2. Probando abrir Chrome con diferentes flags..."
for flag in "${FLAGS[@]}"; do
    echo -n "   Probando flag $flag... "
    
    if am start -a android.intent.action.VIEW \
        -d "https://google.com" \
        --activity-launch-flag "$flag" \
        --windowing-mode 5 \
        2>/dev/null; then
        echo "✓"
        BEST_FLAG="$flag"
        break
    else
        echo "✗"
    fi
done

echo ""
echo "3. Creando intent mágico..."
# Intent más complejo que podría engañar al MDM
cat > /data/data/com.termux/files/home/magic_intent.sh << 'MAGIC'
#!/data/data/com.termux/files/usr/bin/bash

# Este intent intenta parecerse a uno del sistema
am start -a android.intent.action.MAIN \
  -c android.intent.category.LAUNCHER \
  -c android.intent.category.DEFAULT \
  -c android.intent.category.BROWSABLE \
  --activity-launch-flag 0x10808000 \
  --activity-single-top \
  --activity-clear-task \
  --windowing-mode 5 \
  -n com.android.chrome/com.google.android.apps.chrome.MainActivity \
  --es "from_system" "true" \
  --ez "is_trusted" "true" \
  --eu "android.intent.extra.REFERRER" "android-app://com.android.settings"
MAGIC

chmod +x /data/data/com.termux/files/home/magic_intent.sh

echo ""
echo "4. Probando método de 'split-screen' forzado..."
# Forzar split-screen podría bypass algunas restricciones
cat > force_split_screen.sh << 'SPLIT'
#!/data/data/com.termux/files/usr/bin/bash

# Método 1: Usar am start con display-id
am start --display 0 -n com.android.settings/.Settings

# Esperar y luego intentar split
sleep 1
input keyevent KEYCODE_APP_SWITCH
sleep 0.5
input keyevent KEYCODE_V

# Abrir segunda app
sleep 1
am start-activity --windowing-mode 5 -n com.android.chrome/com.google.android.apps.chrome.MainActivity
SPLIT

chmod +x force_split_screen.sh

echo ""
echo "=== MÉTODO NUCLEAR: REINSTALACIÓN ==="
echo "Si todo falla, podrías intentar:"
echo "1. Usar GetApps para instalar 'Activity Launcher'"
echo "2. Con Activity Launcher, buscar actividades ocultas"
echo "3. Buscar actividades de 'com.android.settings' que no estén bloqueadas"
echo ""
echo "Comando para buscar actividades disponibles:"
echo "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
EOF

