cat > analyze_mediatek_mdm.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== ANÁLISIS DETALLADO MEDIATEK MDM ==="
echo ""

# Analizar cada paquete
for PKG in com.mediatek.mdmconfig com.mediatek.mdmlsample; do
    echo "========================================"
    echo "ANALIZANDO: $PKG"
    echo "========================================"
    
    # 1. Información básica
    echo "1. INFORMACIÓN BÁSICA:"
    cmd package dump "$PKG" 2>/dev/null | grep -E "versionName|packageName|sharedUserId|installTime" | head -5
    
    # 2. Verificar si está activo como administrador
    echo ""
    echo "2. ¿ADMINISTRADOR ACTIVO?:"
    if dumpsys device_policy | grep -q "$PKG"; then
        echo "  ✓ SÍ - Es administrador de dispositivo"
        dumpsys device_policy | grep -A3 -B3 "$PKG"
    else
        echo "  ✗ NO - No aparece como admin activo"
    fi
    
    # 3. Componentes principales
    echo ""
    echo "3. ACTIVIDADES PRINCIPALES:"
    cmd package dump "$PKG" 2>/dev/null | grep -B1 "android.intent.action.MAIN" | grep "activity name=" | sed 's/.*activity name="//' | sed 's/".*//'
    
    # 4. Ver actividades exportadas
    echo ""
    echo "4. ACTIVIDADES EXPORTADAS (peligrosas):"
    cmd package dump "$PKG" 2>/dev/null | grep -A2 "Activity {" | grep " exported=\"true\"" | head -5
    
    # 5. Servicios
    echo ""
    echo "5. SERVICIOS:"
    cmd package dump "$PKG" 2>/dev/null | grep -B1 "Service {" | grep "  [a-z0-9]" | head -5
    
    # 6. Permisos peligrosos
    echo ""
    echo "6. PERMISOS PELIGROSOS:"
    cmd package dump "$PKG" 2>/dev/null | grep "android.permission" | grep -iE "device_admin|manage_device|control|wipe|lock" | sort | uniq
    
    # 7. Estado actual del paquete
    echo ""
    echo "7. ESTADO:"
    if cmd package list packages -e | grep -q "$PKG"; then
        echo "  ✓ HABILITADO"
    elif cmd package list packages -d | grep -q "$PKG"; then
        echo "  ✗ DESHABILITADO"
    else
        echo "  ? ESTADO DESCONOCIDO"
    fi
    
    # 8. Archivos APK
    echo ""
    echo "8. UBICACIÓN APK:"
    pm path "$PKG" 2>/dev/null || cmd package path "$PKG" 2>/dev/null
    
    echo ""
done

echo "========================================"
echo "INFORMACIÓN DEL SISTEMA:"
echo "========================================"

# Ver políticas aplicadas
echo "9. POLÍTICAS ACTIVAS:"
dumpsys device_policy | grep -iE "password.*quality|camera.*disabled|storage.*encrypted|policy.*flags"

# Ver otros administradores potenciales
echo ""
echo "10. OTROS ADMINS POTENCIALES:"
dumpsys device_policy | grep "AdminInfo" | grep -v "mediatek"
EOF

chmod +x analyze_mediatek_mdm.sh
./analyze_mediatek_mdm.sh