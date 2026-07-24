"""
Update vite.config.js and restart frontend on VPS 87.107.108.69
"""
import paramiko
import sys
import os

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

HOST = "87.107.108.69"
PORT = 22
USER = "root"
PASS = "IoC275YMVRF9e7W"

def main():
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, port=PORT, username=USER, password=PASS, timeout=30)

    def run_cmd(cmd):
        print(f"\n>>> {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.read().decode('utf-8', errors='ignore')
        err = stderr.read().decode('utf-8', errors='ignore')
        if out:
            print(out)
        if err and "warning" not in err.lower():
            print("ERR:", err)
        return out

    print("--- 1. Uploading updated vite.config.js ---")
    sftp = ssh.open_sftp()
    local_vite = r"c:\Users\mrmah\OneDrive\Desktop\CRM p\Django-CRM\frontend\vite.config.js"
    sftp.put(local_vite, "/opt/crm-p/frontend/vite.config.js")
    sftp.close()

    print("\n--- 2. Restarting frontend container ---")
    run_cmd("cd /opt/crm-p && docker compose restart frontend")

    print("\n--- 3. Testing frontend response ---")
    import time
    time.sleep(5)
    run_cmd("curl -I https://front.crm.valerion.ir 2>&1")

    ssh.close()

if __name__ == "__main__":
    main()
