cat > setup.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== CONFIGURACIÓN AUTOMÁTICA ==="

# Crear directorio de scripts
mkdir -p ~/scripts
cd ~/scripts

# 1. Script para abrir menú rápido
cat > open_menu.sh << 'MENU'
#!/data/data/com.termux/files/usr/bin/bash
echo "=== MENÚ RÁPIDO ==="
echo "1. Chrome"
echo "2. Ajustes"
echo "3. Termux"
echo "4. GetApps"
echo "5. Salir"

read -p "Opción: " choice

case $choice in
    1) am start-activity --windowing-mode 5 -n com.android.chrome/com.google.android.apps.chrome.MainActivity ;;
    2) am start-activity --windowing-mode 5 -n com.android.settings/.Settings ;;
    3) am start-activity --windowing-mode 5 -n com.termux/.app.TermuxActivity ;;
    4) am start-activity --windowing-mode 5 -n com.xiaomi.market/.ui.MainActivity ;;
    5) exit 0 ;;
    *) echo "Opción inválida" ;;
esac
MENU

chmod +x open_menu.sh

# 2. Script que se ejecuta cada vez que abres Termux
cat > ~/.bashrc << 'BASHRC'
# Auto-ejecutar menú si no hay argumentos
if [ $# -eq 0 ]; then
    echo "Termux cargado. Ejecuta ./scripts/open_menu.sh para menú rápido"
    
    # Intentar silenciar MDM en segundo plano
    (am force-stop com.mediatek.mdmconfig 2>/dev/null; am force-stop com.mediatek.mdmlsample 2>/dev/null) &
fi
BASHRC

# 3. Script de vigilancia MDM
cat > mdm_watchdog.sh << 'WATCHDOG'
#!/data/data/com.termux/files/usr/bin/bash
while true; do
    # Verificar si MDM está corriendo
    if ps -A | grep -q "mediatek.mdm"; then
        echo "[$(date)] MDM detectado, forzando cierre..."
        am force-stop com.mediatek.mdmconfig 2>/dev/null
        am force-stop com.mediatek.mdmlsample 2>/dev/null
        
        # Reabrir Termux por si nos cerraron
        if ! ps -A | grep -q "com.termux"; then
            am start-activity --windowing-mode 5 -n com.termux/.app.TermuxActivity 2>/dev/null
        fi
    fi
    sleep 10
done
WATCHDOG

chmod +x mdm_watchdog.sh

# 4. Iniciar watchdog en segundo plano
nohup ./mdm_watchdog.sh > /dev/null 2>&1 &

echo ""
echo "=== CONFIGURACIÓN COMPLETADA ==="
echo "1. Menú rápido disponible: ./scripts/open_menu.sh"
echo "2. Watchdog MDM ejecutándose en segundo plano"
echo "3. .bashrc configurado para auto-cargar"
echo ""
echo "=== PRÓXIMOS PASOS ==="
echo "1. Abre GetApps en ventana y instala 'Floating Apps'"
echo "2. Configura botones flotantes con los comandos de ~/scripts/"
echo "3. Si instalas 'Activity Launcher', busca actividades no bloqueadas"
EOF
