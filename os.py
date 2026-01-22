import os
import subprocess

print("=== ENUMERACIÓN DEL SISTEMA ===")

# 1. Intentar listar procesos
try:
    print("\n[+] Intentando listar procesos...")
    result = subprocess.run(['ps', '-A'], capture_output=True, text=True)
    print(result.stdout[:500])  # Primeros 500 chars
except Exception as e:
    print(f"Error: {e}")

# 2. Ver archivos accesibles
print("\n[+] Directorios accesibles:")
dirs_to_check = ['/sdcard', '/storage', '/data/data', '/system']
for d in dirs_to_check:
    try:
        files = os.listdir(d)[:5]
        print(f"{d}: {files}")
    except:
        print(f"{d}: No accesible")

# 3. Intentar comunicación con servicios Android
print("\n[+] Intentando comunicación Android...")
try:
    import jnius
    from jnius import autoclass
    print("Jnius disponible!")
except:
    print("Jnius no disponible")
