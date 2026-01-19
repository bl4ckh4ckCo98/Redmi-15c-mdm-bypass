# Crear un servicio de accesibilidad que controle el MDM
cat > service.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "=== CREANDO SERVICIO DE ACCESIBILIDAD ==="
echo ""

# Primero, verificar si podemos instalar una app de accesibilidad
echo "1. Buscando apps de accesibilidad instaladas..."
cmd package list packages | grep -i "accessibility\|button\|float"

echo ""
echo "2. Si tienes 'Floating Apps' o similar, puedes configurar:"
echo "   - Botón flotante que ejecute comandos shell"
echo "   - Gestos en pantalla"
echo "   - Overlay transparente"

echo ""
echo "3. Alternativa: Usar Termux como 'pseudo-accessibility'"
cat > /data/data/com.termux/files/home/mdm_watcher.py << 'PYEOF'
import subprocess
import time
import re

class MDMWatcher:
    def __init__(self):
        self.mdm_packages = ["com.mediatek.mdmconfig", "com.mediatek.mdmlsample"]
        self.blocked_windows = [
            "mdm", "lock", "bloqueo", "restricted", "device policy"
        ]
    
    def get_current_window(self):
        """Obtener ventana actual (método aproximado)"""
        try:
            # Intentar con dumpsys si está disponible
            result = subprocess.run(
                "dumpsys window windows",
                shell=True,
                capture_output=True,
                text=True
            )
            
            # Buscar línea con mCurrentFocus
            for line in result.stdout.split('\n'):
                if "mCurrentFocus" in line:
                    return line
        except:
            pass
        
        # Método alternativo: verificar paquetes en ejecución
        result = subprocess.run(
            "ps -A | grep -v termux",
            shell=True,
            capture_output=True,
            text=True
        )
        
        return result.stdout[:200]  # Primeros 200 caracteres
    
    def is_mdm_window(self, window_info):
        """Detectar si es una ventana del MDM"""
        window_lower = window_info.lower()
        for keyword in self.blocked_windows:
            if keyword in window_lower:
                return True
        
        # Verificar si es de paquetes MDM
        for pkg in self.mdm_packages:
            if pkg in window_info:
                return True
        
        return False
    
    def close_mdm_window(self):
        """Cerrar ventana del MDM"""
        print("Cerrando ventana MDM...")
        
        # Enviar BACK
        subprocess.run("input keyevent KEYCODE_BACK", shell=True)
        time.sleep(0.5)
        
        # Enviar HOME (por si acaso)
        subprocess.run("input keyevent KEYCODE_HOME", shell=True)
        
        # Abrir nuestra app en ventana
        subprocess.run(
            "am start-activity --windowing-mode 5 -n com.termux/.app.TermuxActivity",
            shell=True
        )
    
    def run(self):
        print("Iniciando watcher MDM...")
        
        while True:
            current_window = self.get_current_window()
            
            if self.is_mdm_window(current_window):
                print("¡Ventana MDM detectada!")
                print(f"Contenido: {current_window[:100]}...")
                
                self.close_mdm_window()
            
            time.sleep(2)  # Verificar cada 2 segundos

if __name__ == "__main__":
    watcher = MDMWatcher()
    watcher.run()
PYEOF

echo "4. Para ejecutar el watcher:"
echo "   python mdm_watcher.py"
echo ""
echo "5. Configurar para que se ejecute automáticamente:"
echo "   Agrega 'python mdm_watcher.py &' al final de ~/.bashrc"
EOF
