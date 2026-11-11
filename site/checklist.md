# server-bootstrap post-run checklist

Tick from a second SSH session before disconnecting the first.

- [ ] Key login works as BOOTSTRAP_USER
- [ ] sudo works for that user
- [ ] ufw status: SSH (+ 80/443) allowed, active
- [ ] sshd -T: PermitRootLogin no, PasswordAuthentication no, PubkeyAuthentication yes
- [ ] fail2ban-client status sshd
- [ ] docker info (re-login after docker group)
- [ ] Caddy responds on :80 or your HTTPS domain
- [ ] swapon --show (real VPS)
- [ ] apt-config dump | grep Unattended-Upgrade
- [ ] Provider firewall allows the SSH port
- [ ] Console / VNC recovery still available

Full notes: https://github.com/mohamedtaqysalmi/server-bootstrap/blob/main/docs/post-run-checklist.md
