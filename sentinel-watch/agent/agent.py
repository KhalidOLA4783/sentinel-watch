#!/usr/bin/env python3
"""
SentinelWatch — Agent Multi-Plateforme (Linux / Windows / macOS)
Permet d'auditer la sécurité de serveurs d'entreprise et de remonter les failles et solutions.
"""

import os
import sys
import socket
import platform
import subprocess
import requests
import json
from datetime import datetime

API_URL = os.getenv("SENTINEL_API_URL", "http://127.0.0.1:8000/api/v1/audits")

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
        return res.stdout.strip()
    except Exception:
        return ""

def audit_system():
    hostname = socket.gethostname()
    os_info = f"{platform.system()} {platform.release()}"
    
    # IP locale
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip_address = s.getsockname()[0]
        s.close()
    except Exception:
        ip_address = "127.0.0.1"

    score = 100
    findings = []
    dangerous_ports = 0
    firewall_enabled = True
    antivirus_active = True

    # 1. Vérification Firewall sous Linux (UFW ou iptables)
    if platform.system() == "Linux":
        ufw_status = run_cmd("ufw status")
        if "inactive" in ufw_status or not ufw_status:
            score -= 25
            firewall_enabled = False
            findings.append({
                "title": "Pare-feu UFW Inactif sur le Serveur",
                "severity": "CRITICAL",
                "category": "FIREWALL",
                "observation": "Le pare-feu logiciel ufw n'est pas actif.",
                "risk": "Tous les services et ports de ce serveur sont accessibles directement sans filtrage.",
                "solution": "Activer le pare-feu UFW et autoriser uniquement le port SSH.",
                "remediation_command": "sudo ufw default deny incoming && sudo ufw allow 22/tcp && sudo ufw enable"
            })

        # 2. Vérification Root Login SSH
        sshd_config = run_cmd("grep -E '^PermitRootLogin' /etc/ssh/sshd_config")
        if "yes" in sshd_config.lower():
            score -= 20
            findings.append({
                "title": "Connexion SSH Root Directe Autorisée",
                "severity": "HIGH",
                "category": "USER_ACCOUNTS",
                "observation": "PermitRootLogin est configuré à 'yes' dans /etc/ssh/sshd_config.",
                "risk": "Les attaquants peuvent tenter de forcer le compte super-administrateur 'root' en continu par dictionnaire.",
                "solution": "Désactiver la connexion directe en root et utiliser un utilisateur non privilégié avec sudo.",
                "remediation_command": "sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && sudo systemctl restart sshd"
            })

    # 3. Ports Réseau Ouverts
    common_risky_ports = {
        21: ("FTP", "Protocole obsolète non chiffré"),
        23: ("Telnet", "Identifiants en texte clair"),
        3389: ("RDP", "Cible prioritaire de ransomware"),
        5900: ("VNC", "Accès graphique distant non chiffré")
    }

    for port, (name, risk_text) in common_risky_ports.items():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(0.2)
        res = sock.connect_ex(("127.0.0.1", port))
        sock.close()
        if res == 0:
            dangerous_ports += 1
            score -= 15
            findings.append({
                "title": f"Service Risqué Détecté : {name} (Port {port})",
                "severity": "HIGH",
                "category": "NETWORK_PORTS",
                "observation": f"Le port {port} ({name}) est ouvert et écoute en local.",
                "risk": risk_text,
                "solution": f"Arrêter et désactiver le service {name} si non indispensable.",
                "remediation_command": f"Vérifier quel processus écoute via : netstat -tulnp | grep :{port}"
            })

    # Niveau de risque
    score = max(0, score)
    if score < 45: risk_level = "CRITICAL"
    elif score < 70: risk_level = "HIGH"
    elif score < 90: risk_level = "MEDIUM"
    else: risk_level = "SECURE"

    return {
        "hostname": hostname,
        "os_version": os_info,
        "ip_address": ip_address,
        "domain_name": "local",
        "security_score": score,
        "risk_level": risk_level,
        "firewall_enabled": firewall_enabled,
        "antivirus_active": antivirus_active,
        "dangerous_ports_count": dangerous_ports,
        "failed_logins_24h": 0,
        "findings": findings
    }

def main():
    print("=" * 60)
    print("🛡️  SENTINELWATCH — AUDIT DE SÉCURITÉ SERVEUR")
    print("=" * 60)
    report = audit_system()
    
    print(f"Machine : {report['hostname']} ({report['os_version']})")
    print(f"Score   : {report['security_score']}/100 [{report['risk_level']}]")
    print(f"Failles : {len(report['findings'])}")
    print("-" * 60)
    
    for idx, f in enumerate(report['findings'], 1):
        print(f"\n[{idx}] {f['title']} [{f['severity']}]")
        print(f"  • Risque   : {f['risk']}")
        print(f"  • Solution : {f['solution']}")
        if f.get('remediation_command'):
            print(f"  • Action   : {f['remediation_command']}")

    print("\nTransmission du rapport à SentinelWatch...")
    try:
        r = requests.post(API_URL, json=report, timeout=4)
        if r.status_code == 201:
            print("✓ Rapport envoyé avec succès au SOC SentinelWatch !")
        else:
            print(f"! Échec HTTP {r.status_code}")
    except Exception as e:
        print(f"ℹ️ Serveur non joignable ({e}). Bilan affiché en local.")

if __name__ == "__main__":
    main()
