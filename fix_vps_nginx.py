"""
Fix Nginx 502 Bad Gateway by updating port 3000 -> 5173 on VPS 87.107.108.69
"""
import paramiko
import sys

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
            try:
                print(out)
            except Exception:
                print(out.encode('ascii', errors='ignore').decode('ascii'))
        if err and "warning" not in err.lower():
            try:
                print("ERR:", err)
            except Exception:
                print("ERR:", err.encode('ascii', errors='ignore').decode('ascii'))
        return out

    print("--- 1. Inspecting Nginx sites-enabled ---")
    run_cmd("grep -rn '3000' /etc/nginx/ 2>/dev/null || true")

    print("\n--- 2. Updating Nginx configs from port 3000 to port 5173 ---")
    run_cmd("sed -i 's/127.0.0.1:3000/127.0.0.1:5173/g' /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* /etc/nginx/conf.d/* 2>/dev/null || true")

    print("\n--- 3. Testing and reloading Nginx ---")
    run_cmd("nginx -t && systemctl reload nginx")

    print("\n--- 4. Testing HTTP/HTTPS response for frontend & backend ---")
    run_cmd("curl -I https://front.crm.valerion.ir 2>&1")
    run_cmd("curl -I https://back.crm.valerion.ir 2>&1")

    ssh.close()
    print("\nNginx Port Fix Complete!")

if __name__ == "__main__":
    main()
