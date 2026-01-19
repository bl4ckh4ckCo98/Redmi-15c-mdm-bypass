# Crear un servicio simple que intercepte intentos del MDM
cat > interceptor.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Directorio para logs
LOG_DIR="/data/data/com.termux/files/home/mdm_logs"
mkdir -p "$LOG_DIR"

echo "=== INTERCEPTOR MDM ACTIVO ===" > "$LOG_DIR/interceptor.log"
echo "Iniciado: $(date)" >> "$LOG_DIR/interceptor.log"

# Monitorear actividad del sistema
monitor_activity() {
    while true; do
        # Registrar timestamp
        echo "" >> "$LOG_DIR/activity.log"
        echo "=== $(date) ===" >> "$LOG_DIR/activity.log"
        
        # Verificar procesos MDM
        if ps -A | grep -i "mediatek\|mdm" >> "$LOG_DIR/activity.log" 2>/dev/null; then
            echo "¡MDM detectado en ejecución!" >> "$LOG_DIR/interceptor.log"
            
            # Intentar detenerlo
            for pkg in com.mediatek.mdmconfig com.mediatek.mdmlsample; do
                am force-stop "$pkg" 2>/dev/null && \
                echo "Forzado cierre de $pkg" >> "$LOG_DIR/interceptor.log"
            done
        fi
        
        # Verificar si nuestras apps están abiertas
        for app in com.termux com.android.chrome; do
            if ! ps -A | grep -q "$app"; then
                echo "Restaurando $app..." >> "$LOG_DIR/interceptor.log"
                am start-activity --windowing-mode 5 -n "$app/.app.TermuxActivity" 2>/dev/null
            fi
        done
        
        sleep 15
    done
}

# Iniciar monitoreo
monitor_activity
EOF

