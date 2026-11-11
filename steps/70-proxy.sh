# shellcheck shell=bash
# Step: proxy
# Protects against: serving apps without TLS, and hand-maintained certificate renewals.
# Re-run: does nothing if the chosen proxy, its site config and service are already in place.
# Dry-run: prints the install and file writes it would do.
#
# BOOTSTRAP_PROXY selects the engine: caddy (default), nginx, or none.
# Automatic HTTPS needs a public DNS name. Set BOOTSTRAP_DOMAIN. Without it,
# the chosen engine listens on :80 with a placeholder so the reverse-proxy
# path is ready before DNS exists. Nginx HTTPS uses certbot when a domain is set.

BOOTSTRAP_PROXY="${BOOTSTRAP_PROXY:-caddy}"
BOOTSTRAP_DOMAIN="${BOOTSTRAP_DOMAIN:-}"
BOOTSTRAP_ACME_EMAIL="${BOOTSTRAP_ACME_EMAIL:-}"
BOOTSTRAP_PROXY_UPSTREAM="${BOOTSTRAP_PROXY_UPSTREAM:-127.0.0.1:8080}"

step_proxy() {
  case "${BOOTSTRAP_PROXY}" in
  none | off | skip)
    log_ok "BOOTSTRAP_PROXY=${BOOTSTRAP_PROXY}, skipping reverse proxy"
    return 0
    ;;
  caddy)
    _proxy_caddy
    ;;
  nginx)
    _proxy_nginx
    ;;
  *)
    die "BOOTSTRAP_PROXY must be caddy, nginx, or none (got '${BOOTSTRAP_PROXY}')"
    ;;
  esac
}

_proxy_caddy() {
  local caddyfile email_line=""

  pkg_install caddy

  if [ -n "${BOOTSTRAP_ACME_EMAIL}" ]; then
    email_line="{
  email ${BOOTSTRAP_ACME_EMAIL}
}
"
  fi

  if [ -n "${BOOTSTRAP_DOMAIN}" ]; then
    caddyfile="# Managed by server-bootstrap.
${email_line}${BOOTSTRAP_DOMAIN} {
  encode gzip
  reverse_proxy ${BOOTSTRAP_PROXY_UPSTREAM}
}"
  else
    log_warn "BOOTSTRAP_DOMAIN is empty; writing a :80 placeholder. Set BOOTSTRAP_DOMAIN for automatic HTTPS."
    caddyfile="# Managed by server-bootstrap.
# Set BOOTSTRAP_DOMAIN and re-run to enable automatic HTTPS.
${email_line}:80 {
  respond \"server-bootstrap placeholder - set BOOTSTRAP_DOMAIN for TLS\" 200
}"
  fi

  ensure_file /etc/caddy/Caddyfile 644 "${caddyfile}"

  if [ "${DRY_RUN}" -eq 0 ]; then
    if ! caddy validate --config /etc/caddy/Caddyfile >/dev/null 2>&1; then
      die "caddy rejected /etc/caddy/Caddyfile. Run 'caddy validate --config /etc/caddy/Caddyfile' to see why"
    fi
  fi

  if [ "${FILE_CHANGED}" -eq 1 ]; then
    service_restart_if_running caddy
  fi
  service_enable_now caddy
}

_proxy_nginx() {
  local site="/etc/nginx/sites-available/server-bootstrap"
  local enabled="/etc/nginx/sites-enabled/server-bootstrap"
  local conf

  pkg_install nginx

  if [ -n "${BOOTSTRAP_DOMAIN}" ]; then
    conf="# Managed by server-bootstrap.
server {
  listen 80;
  listen [::]:80;
  server_name ${BOOTSTRAP_DOMAIN};

  location / {
    proxy_pass http://${BOOTSTRAP_PROXY_UPSTREAM};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}"
  else
    log_warn "BOOTSTRAP_DOMAIN is empty; writing a :80 placeholder. Set BOOTSTRAP_DOMAIN then re-run, and use certbot for HTTPS."
    conf="# Managed by server-bootstrap.
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  location / {
    return 200 'server-bootstrap placeholder - set BOOTSTRAP_DOMAIN then enable TLS with certbot\n';
    add_header Content-Type text/plain;
  }
}"
  fi

  ensure_file "${site}" 644 "${conf}"
  if [ ! -L "${enabled}" ] || [ "$(readlink -f "${enabled}" 2>/dev/null || true)" != "$(readlink -f "${site}")" ]; then
    log_change "enable nginx site server-bootstrap"
    run ln -sfn "${site}" "${enabled}"
  else
    log_ok "nginx site server-bootstrap is enabled"
  fi

  if [ -e /etc/nginx/sites-enabled/default ]; then
    log_change "disable nginx default site"
    run rm -f /etc/nginx/sites-enabled/default
  fi

  if [ "${DRY_RUN}" -eq 0 ]; then
    nginx -t >/dev/null 2>&1 || die "nginx rejected its configuration. Run 'nginx -t' to see why"
  fi

  if [ "${FILE_CHANGED}" -eq 1 ]; then
    service_restart_if_running nginx
  fi
  service_enable_now nginx

  if [ -n "${BOOTSTRAP_DOMAIN}" ]; then
    pkg_install certbot python3-certbot-nginx
    if [ "${DRY_RUN}" -eq 1 ]; then
      log_change "would request Let's Encrypt cert for ${BOOTSTRAP_DOMAIN} via certbot"
      return 0
    fi
    if [ -d "/etc/letsencrypt/live/${BOOTSTRAP_DOMAIN}" ]; then
      log_ok "Let's Encrypt cert for ${BOOTSTRAP_DOMAIN} already present"
    else
      local email_args=(--register-unsafely-without-email)
      if [ -n "${BOOTSTRAP_ACME_EMAIL}" ]; then
        email_args=(--email "${BOOTSTRAP_ACME_EMAIL}")
      fi
      log_change "request Let's Encrypt cert for ${BOOTSTRAP_DOMAIN}"
      run certbot --nginx --non-interactive --agree-tos --redirect \
        "${email_args[@]}" -d "${BOOTSTRAP_DOMAIN}"
    fi
  fi
}
