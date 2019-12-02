#!/bin/sh

INSTALL_DIR="/usr/lib/throttled"

if pidof systemd 2>&1 1>/dev/null; then
    systemctl stop throttled.service >/dev/null 2>&1
elif pidof runit 2>&1 1>/dev/null; then
    sv down throttled >/dev/null 2>&1
fi

mkdir -p "$INSTALL_DIR" >/dev/null 2>&1
set -e

cd "$(dirname "$0")"

echo "Copying config file..."
if [ ! -f /etc/throttled.conf ]; then
	cp etc/throttled.conf /etc
else
	echo "Config file already exists, skipping."
fi

if pidof systemd 2>&1 1>/dev/null; then
    echo "Copying systemd service file..."
    cp systemd/throttled.service /etc/systemd/system
elif pidof runit 2>&1 1>/dev/null; then
    echo "Copying runit service file"
    cp -R runit/throttled /etc/sv/
fi

echo "Installing package dependencies..."
if pidof runit 2>&1 1>/dev/null; then
    xbps-install -Sy gcc git python3-devel dbus-glib-devel libgirepository-devel cairo-devel python3-wheel pkg-config make
fi

# echo "Building virtualenv..."
# cp -n requirements.txt throttled.py mmio.py "$INSTALL_DIR"
# cd "$INSTALL_DIR"
# /usr/bin/python3 -m venv venv
# . venv/bin/activate
# pip install --upgrade pip
# pip install -r requirements.txt

echo "Copying files and prepare simlinks throttled..."
cp -f throttled.py mmio.py "$INSTALL_DIR"
cd /usr/bin
ln -sf "$INSTALL_DIR/throttled.py" throttled

if pidof systemd 2>&1 1>/dev/null; then
    echo "Enabling and starting systemd service..."
    systemctl daemon-reload
    systemctl enable throttled.service
    systemctl restart throttled.service
elif pidof runit 2>&1 1>/dev/null; then
    echo "Enabling and starting runit service..."
    ln -sfv /etc/sv/throttled /var/service/
    sv up throttled
fi

echo "All done."
