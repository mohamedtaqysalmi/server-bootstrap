# Post-run verification checklist

Print or save this after `sudo ./bootstrap.sh`. Tick each item from a **second** SSH session when possible.

## Before you disconnect the first session

- [ ] `BOOTSTRAP_USER` can log in with a key (`ssh deploy@HOST`)
- [ ] `sudo -n true` works for that user (if passwordless sudo was left on)
- [ ] `sudo ufw status` shows SSH (and 80/443) allowed, status active
- [ ] `sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication|port'` matches expectations
- [ ] fail2ban: `sudo fail2ban-client status sshd` (or status) without errors
- [ ] Docker: `docker info` as the bootstrap user (re-login after group add)
- [ ] Caddy: `curl -I http://127.0.0.1` or your domain over HTTPS
- [ ] Swap: `swapon --show` (on a real VPS, not a container)
- [ ] Unattended upgrades: `apt-config dump | grep Unattended-Upgrade`
- [ ] Optional monitoring: `curl -s http://127.0.0.1:9100/metrics | head` only if enabled

## Cloud provider

- [ ] Provider firewall / security group allows the SSH port you configured
- [ ] Console / VNC recovery still works if SSH fails

## What to keep open

Do not close the original root/sudo session until the second session proves login, sudo, and (if changed) the new SSH port.
