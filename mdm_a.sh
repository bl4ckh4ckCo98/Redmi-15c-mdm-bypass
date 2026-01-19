cat > mdm_a.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== ANÁLISIS USANDO SOLO CMD ==="
echo ""

# 1. Listar todos los paquetes
echo "1. TODOS LOS PAQUETES (primeros 30):"
cmd package list packages | head -30

echo ""
echo "2. PAQUETES DE SISTEMA:"
cmd package list packages -s | head -20

echo ""
echo "3. PAQUETES DESHABILITADOS:"
cmd package list packages -d

echo ""
echo "4. ANALIZANDO PAQUETES MEDIATEK MDM:"

for PKG in com.mediatek.mdmconfig com.mediatek.mdmlsample; do
    echo "=== $PKG ==="
    
    # Verificar si existe
    if cmd package list packages | grep -q "$PKG"; then
        echo "  ✓ Existe"
        
        # Ver estado
        if cmd package list packages -e | grep -q "$PKG"; then
            echo "  ✓ Habilitado"
        elif cmd package list packages -d | grep -q "$PKG"; then
            echo "  ✗ Deshabilitado"
        fi
        
        # Ver información
        echo "  Información del paquete:"
        cmd package dump "$PKG" 2>/dev/null | grep -E "versionName|packageName" | head -2
        
        # Ver actividades
        echo "  Actividad principal:"
        cmd package dump "$PKG" 2>/dev/null | grep -B1 "android.intent.action.MAIN" | grep "activity name=" | head -1
        
    else
        echo "  ✗ No encontrado"
    fi
    echo ""
done

echo "5. BUSCANDO OTROS ADMINS:"
echo "   Paquetes con actividad de administrador de dispositivo:"

# Listar todos los paquetes y buscar actividad DEVICE_ADMIN
cmd package list packages | sed 's/package://' | while read pkg; do
    if cmd package resolve-activity --brief -c android.intent.category.DEVICE_ADMIN "$pkg" 2>/dev/null | grep -q "$pkg"; then
        echo "   - $pkg (tiene actividad DEVICE_ADMIN)"
    fi
done

echo ""
echo "6. VERIFICANDO PERMISOS DE APPS CRÍTICAS:"
for app in com.android.settings com.google.android.gms com.android.launcher3; do
    if cmd package list packages | grep -q "$app"; then
        echo "   $app existe"
    fi
done
EOF

