const STEPS = [
  {
    id: "05",
    name: "user",
    why: "Stops day-to-day work as root so a mistake or compromised session does not own the whole machine.",
  },
  {
    id: "10",
    name: "swap",
    why: "Gives a small VPS headroom so the OOM killer is less likely to stop services under memory pressure.",
  },
  {
    id: "20",
    name: "unattended-upgrades",
    why: "Applies security updates without waiting for someone to log in and run apt upgrade.",
  },
  {
    id: "30",
    name: "fail2ban",
    why: "Bans addresses that hammer SSH with repeated failures.",
  },
  {
    id: "40",
    name: "log-rotation",
    why: "Caps journal growth so logs cannot fill the disk and take the host down.",
  },
  {
    id: "50",
    name: "ufw",
    why: "Default-deny inbound so only SSH, HTTP and HTTPS are reachable by design.",
  },
  {
    id: "60",
    name: "docker",
    why: "Provides container isolation and bounds container log size on disk.",
  },
  {
    id: "70",
    name: "proxy",
    why: "Caddy (default) or Nginx reverse proxy with automatic HTTPS when BOOTSTRAP_DOMAIN is set.",
  },
  {
    id: "80",
    name: "monitoring",
    why: "Optional node exporter so CPU, memory and disk stop being invisible (ENABLE_MONITORING=1).",
  },
  {
    id: "90",
    name: "ssh",
    why: "Disables password and root login last, after a key exists, with a lockout warning and sshd -T verification.",
  },
];

const list = document.getElementById("step-list");
if (list) {
  for (const step of STEPS) {
    const el = document.createElement("details");
    el.className = "step";
    el.innerHTML = `<summary><span class="idx">${step.id}</span><span>${step.name}</span></summary><p class="why">${step.why}</p>`;
    list.appendChild(el);
  }
}

const toggle = document.getElementById("theme-toggle");
if (toggle) {
  toggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    localStorage.setItem("sb-theme", next);
  });
}
