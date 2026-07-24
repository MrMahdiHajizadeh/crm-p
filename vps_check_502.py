"""
Check 502 Bad Gateway on VPS 87.107.108.69
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
            print(out)
        if err and "warning" not in err.lower():
            print("ERR:", err)
        return out

    run_cmd("docker compose -f /opt/crm-p/docker-compose.yml ps")
    run_cmd("curl -I http://127.0.0.1:5173 2>&1")
    run_cmd("curl -I http://127.0.0.1:8000 2>&1")
    run_cmd("docker compose -f /opt/crm-p/docker-compose.yml logs frontend --tail=30")
    run_cmd("docker compose -f /opt/crm-p/docker-compose.yml logs backend --tail=30")
    run_cmd("tail -n 30 /var/log/nginx/error.log")

    ssh.close()

if __name__ == "__main__":
    main()
