cat > simple_bypass.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== BYPASS SIMPLE SIN DUMPSYS ==="
echo ""

# Función para verificar si un comando funciona
check_cmd() {
    if command -v $1 >/dev/null 2>&1; then
        echo "✓ $1 disponible"
        return 0
    else
        echo "✗ $1 no disponible"
        return 1
    fi
}

echo "1. VERIFICANDO HERRAMIENTAS:"
check_cmd cmd
check_cmd am
check_cmd pm
check_cmd settings

echo ""
echo "2. DESHABILITANDO MDM MEDIATEK:"

# Lista de paquetes MDM a deshabilitar
MDM_PACKAGES="com.mediatek.mdmconfig com.mediatek.mdmlsample"
SUCCESS=0

for pkg in $MDM_PACKAGES; do
    echo -n "   Deshabilitando $pkg... "
    
    # Intentar múltiples métodos
    if cmd package disable-user --user 0 "$pkg" 2>/dev/null; then
        echo "✓ (con cmd)"
        SUCCESS=1
    elif cmd package hide "$pkg" 2>/dev/null; then
        echo "✓ (ocultado con cmd)"
        SUCCESS=1
    elif pm disable "$pkg" 2>/dev/null; then
        echo "✓ (con pm)"
        SUCCESS=1
    else
        echo "✗"
        
        # Intentar forzar cierre
        am force-stop "$pkg" 2>/dev/null && echo "     Forzado cierre"
    fi
    
    # Verificar si quedó deshabilitado
    if cmd package list packages -d | grep -q "$pkg"; then
        echo "   ✓ Confirmado: $pkg está deshabilitado"
        SUCCESS=1
    fi
done

echo ""
echo "3. LIMPIANDO DATOS DE MDM:"
for pkg in $MDM_PACKAGES; do
    echo -n "   Limpiando datos de $pkg... "
    if cmd package clear "$pkg" 2>/dev/null; then
        echo "✓"
    else
        echo "✗"
    fi
done

echo ""
echo "4. CONFIGURANDO SISTEMA:"
echo -n "   Configurando device_provisioned... "
if settings put global device_provisioned 1 2>/dev/null; then
    echo "✓"
else
    echo "✗"
fi

echo -n "   Configurando user_setup_complete... "
if settings put secure user_setup_complete 1 2>/dev/null; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "5. PROBANDO ACCESO:"

# Probar con apps comunes
APPS=(
    "com.android.settings/.Settings"
    "com.android.chrome/com.google.android.apps.chrome.MainActivity"
    "com.termux/.app.TermuxActivity"
)

for app in "${APPS[@]}"; do
    package=$(echo "$app" | cut -d'/' -f1)
    
    # Verificar si la app está instalada
    if cmd package list packages | grep -q "$package"; then
        echo -n "   Probando $package... "
        
        # Intentar abrir en modo ventana
        if am start-activity --windowing-mode 5 -n "$app" 2>/dev/null; then
            echo "✓ Abierta en ventana"
        elif am start -n "$app" 2>/dev/null; then
            echo "✓ Abierta normal"
        else
            echo "✗ Falló"
        fi
    else
        echo "   $package no instalado"
    fi
done

echo ""
if [ $SUCCESS -eq 1 ]; then
    echo "=== RESULTADO: PARCIALMENTE EXITOSO ==="
    echo "El MDM fue deshabilitado temporalmente."
    echo "Puede reactivarse al reiniciar el dispositivo."
else
    echo "=== RESULTADO: FALLÓ ==="
    echo "No se pudo deshabilitar el MDM."
    echo "Probablemente necesitas permisos de superusuario."
fi

echo ""
echo "=== OPCIONES ==="
echo "1. Crear atajo en escritorio para Termux"
echo "2. Instalar app de gestión de ventanas"
echo "3. Intentar método alternativo"
echo "4. Salir"

while true; do
    echo ""
    read -p "Selecciona (1-4): " choice
    
    case $choice in
        1)
            echo "Creando atajo..."
            # Crear shortcut usando am
            am start -a android.intent.action.CREATE_SHORTCUT \
                -n com.android.launcher3/.InstallShortcutReceiver \
                --eu android.intent.extra.shortcut.NAME "Termux Window" \
                --ei android.intent.extra.shortcut.ICON_RESOURCE 17301527 \
                --eu android.intent.extra.shortcut.INTENT \
                "intent:#Intent;action=android.intent.action.MAIN;component=com.termux/.app.TermuxActivity;launchFlags=0x10808000;end" \
                2>/dev/null && echo "✓ Atajo creado" || echo "✗ Falló"
            ;;
        2)
            echo "Instalando Floating Apps desde GetApps..."
            # Abrir GetApps en ventana
            am start-activity --windowing-mode 5 \
                -n com.xiaomi.market/.ui.MainActivity \
                --es search "floating" 2>/dev/null
            ;;
        3)
            echo "Método alternativo: Usar modo seguro forzado"
            echo "Intenta: Mantén presionado botón de apagado"
            echo "         Toca 'Apagar'"
            echo "         Mantén presionado 'Apagar' hasta ver 'Modo seguro'"
            echo "         Toca 'OK' para reiniciar en modo seguro"
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
done
EOF

