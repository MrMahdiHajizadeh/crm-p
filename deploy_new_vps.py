"""
VPS Deployment Automation Script for 87.107.108.69
"""
import paramiko
import os
import time
import sys

# Force utf-8 encoding for stdout
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

HOST = "87.107.108.69"
PORT = 22
USER = "root"
PASS = "IoC275YMVRF9e7W"

def connect():
    print(f"Connecting to {HOST}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(HOST, port=PORT, username=USER, password=PASS, timeout=30)
    return ssh

def run_cmd(ssh, cmd, print_out=True):
    print(f"\n>>> Running: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore')
    err = stderr.read().decode('utf-8', errors='ignore')
    if print_out and out:
        try:
            print(out)
        except Exception:
            print(out.encode('ascii', errors='ignore').decode('ascii'))
    if err and "warning" not in err.lower() and "already exists" not in err.lower():
        try:
            print("STDERR:", err)
        except Exception:
            print("STDERR:", err.encode('ascii', errors='ignore').decode('ascii'))
    return out, err

def main():
    ssh = connect()
    
    print("\n--- 7. Checking container status & logs ---")
    run_cmd(ssh, "cd /opt/crm-p && docker compose ps")
    run_cmd(ssh, "cd /opt/crm-p && docker compose logs backend --tail=30")

    print("\n--- 8. Configuring Nginx for domains ---")
    nginx_conf = """server {
    listen 80;
    server_name front.crm.valerion.ir;

    location / {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name back.crm.valerion.ir;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
"""
    run_cmd(ssh, "apt-get update -y && apt-get install -y nginx certbot python3-certbot-nginx 2>/dev/null || true")
    run_cmd(ssh, f"cat << 'EOF' > /etc/nginx/sites-available/crm.conf\n{nginx_conf}\nEOF")
    run_cmd(ssh, "ln -sf /etc/nginx/sites-available/crm.conf /etc/nginx/sites-enabled/crm.conf")
    run_cmd(ssh, "nginx -t && systemctl reload nginx")

    # Try certbot for SSL
    print("\n--- 9. Setting up Let's Encrypt SSL ---")
    run_cmd(ssh, "certbot --nginx -d front.crm.valerion.ir -d back.crm.valerion.ir --non-interactive --agree-tos -m admin@valerion.ir --redirect || true")

    ssh.close()
    print("\n==========================================")
    print("      VPS DEPLOYMENT COMPLETE!            ")
    print("==========================================")
    print("Frontend: https://front.crm.valerion.ir")
    print("Backend:  https://back.crm.valerion.ir")

if __name__ == "__main__":
    main()
