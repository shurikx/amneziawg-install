#!/bin/bash

# AmneziaWG server installer
# https://github.com/shurikx/amneziawg-install

RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

AMNEZIAWG_DIR="/etc/amnezia/amneziawg"

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi
}

function checkVirt() {
	if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
	fi

	if [ "$(systemd-detect-virt)" == "lxc" ]; then
		echo "LXC is not supported (yet)."
		echo "WireGuard can technically run in an LXC container,"
		echo "but the kernel module has to be installed on the host,"
		echo "the container has to be run with some specific parameters"
		echo "and only the tools need to be installed in the container."
		exit 1
	fi
}

function checkOS() {
	source /etc/os-release

	OS="${ID}"

	case "$OS" in
	"debian" | "raspbian")
		if [[ "$VERSION_ID" -lt 11 ]]; then
			echo "Your version of Debian ($VERSION_ID) is not supported. Please use Debian 11 Bullseye or later."
			exit 1
    	fi
		OS="debian" #overwrite if raspbian
		;;
	"ubuntu")
		MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d'.' -f1)
		if [[ "$MAJOR_VERSION" -lt 22 ]]; then
			echo "Your version of Ubuntu ($VERSION_ID) is not supported. Please use Ubuntu 22.04 or later."
			exit 1
		fi
		;;
	*)
		echo "Only Debian (11+) and Ubuntu (22.04+) are supported."
		exit 1
		;;
	esac
}

function getHomeDirForClient() {
	local CLIENT_NAME=$1

	if [ -z "${CLIENT_NAME}" ]; then
		echo "Error: getHomeDirForClient() requires a client name as argument"
		exit 1
	fi

	# Home directory of the user, where the client configuration will be written
	if [ -e "/home/${CLIENT_NAME}" ]; then
		# if $1 is a user name
		HOME_DIR="/home/${CLIENT_NAME}"
	elif [ "${SUDO_USER}" ]; then
		# if not, use SUDO_USER
		if [ "${SUDO_USER}" == "root" ]; then
			# If running sudo as root
			HOME_DIR="/root"
		else
			HOME_DIR="/home/${SUDO_USER}"
		fi
	else
		# if not SUDO_USER, use /root
		HOME_DIR="/root"
	fi

	echo "$HOME_DIR"
}

function getDirForClientConfig() {
	if [[ ${STORE_CLIENT} == 'y' ]]; then
		CONFIG_DIR=${AMNEZIAWG_DIR}
	else
		CONFIG_DIR=$(getHomeDirForClient $1)
	fi
	echo "$CONFIG_DIR"
}

function initialCheck() {
	isRoot
	checkVirt
	checkOS
}

function readJminAndJmax() {
	SERVER_AWG_JMIN=0
	SERVER_AWG_JMAX=0
	until [[ ${SERVER_AWG_JMIN} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_JMIN} >= 1 )) && (( ${SERVER_AWG_JMIN} <= 1280 )); do
		read -rp "Server AmneziaWG Jmin [1-1280]: " -e -i 32 SERVER_AWG_JMIN
	done
	until [[ ${SERVER_AWG_JMAX} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_JMAX} >= 1 )) && (( ${SERVER_AWG_JMAX} <= 1280 )); do
		read -rp "Server AmneziaWG Jmax [1-1280]: " -e -i 512 SERVER_AWG_JMAX
	done
}

function generateS1AndS2() {
	RANDOM_AWG_S1=$(shuf -i15-150 -n1)
	RANDOM_AWG_S2=$(shuf -i15-150 -n1)
}

function readS1AndS2() {
	SERVER_AWG_S1=0
	SERVER_AWG_S2=0
	until [[ ${SERVER_AWG_S1} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_S1} >= 15 )) && (( ${SERVER_AWG_S1} <= 150 )); do
		read -rp "Server AmneziaWG S1 [15-150]: " -e -i ${RANDOM_AWG_S1} SERVER_AWG_S1
	done
	until [[ ${SERVER_AWG_S2} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_S2} >= 15 )) && (( ${SERVER_AWG_S2} <= 150 )); do
		read -rp "Server AmneziaWG S2 [15-150]: " -e -i ${RANDOM_AWG_S2} SERVER_AWG_S2
	done
}

function generateH1AndH2AndH3AndH4() {
	RANDOM_AWG_H1=$(shuf -i5-2147483647 -n1)
	RANDOM_AWG_H2=$(shuf -i5-2147483647 -n1)
	RANDOM_AWG_H3=$(shuf -i5-2147483647 -n1)
	RANDOM_AWG_H4=$(shuf -i5-2147483647 -n1)
}

function readH1AndH2AndH3AndH4() {
	SERVER_AWG_H1=0
	SERVER_AWG_H2=0
	SERVER_AWG_H3=0
	SERVER_AWG_H4=0
	until [[ ${SERVER_AWG_H1} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_H1} >= 5 )) && (( ${SERVER_AWG_H1} <= 2147483647 )); do
		read -rp "Server AmneziaWG H1 [5-2147483647]: " -e -i ${RANDOM_AWG_H1} SERVER_AWG_H1
	done
	until [[ ${SERVER_AWG_H2} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_H2} >= 5 )) && (( ${SERVER_AWG_H2} <= 2147483647 )); do
		read -rp "Server AmneziaWG H2 [5-2147483647]: " -e -i ${RANDOM_AWG_H2} SERVER_AWG_H2
	done
	until [[ ${SERVER_AWG_H3} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_H3} >= 5 )) && (( ${SERVER_AWG_H3} <= 2147483647 )); do
		read -rp "Server AmneziaWG H3 [5-2147483647]: " -e -i ${RANDOM_AWG_H3} SERVER_AWG_H3
	done
	until [[ ${SERVER_AWG_H4} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_H4} >= 5 )) && (( ${SERVER_AWG_H4} <= 2147483647 )); do
		read -rp "Server AmneziaWG H4 [5-2147483647]: " -e -i ${RANDOM_AWG_H4} SERVER_AWG_H4
	done
}

function installQuestions() {
	echo "AmneziaWG server installer (https://github.com/shurikx/amneziawg-install)"
	echo ""
	echo "I need to ask you a few questions before starting the setup."
	echo "You can keep the default options and just press enter if you are ok with them."
	echo ""

	# Detect public IPv4 or IPv6 address and pre-fill for the user
	SERVER_PUB_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
	if [[ -z ${SERVER_PUB_IP} ]]; then
		# Detect public IPv6 address
		SERVER_PUB_IP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
	fi
	read -rp "Public IPv4 or IPv6 address or domain: " -e -i "${SERVER_PUB_IP}" SERVER_PUB_IP

	# Detect public interface and pre-fill for the user
	SERVER_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
	until [[ ${SERVER_PUB_NIC} =~ ^[a-zA-Z0-9_]+$ ]]; do
		read -rp "Public interface: " -e -i "${SERVER_NIC}" SERVER_PUB_NIC
	done

	until [[ ${SERVER_AWG_NIC} =~ ^[a-zA-Z0-9_]+$ && ${#SERVER_AWG_NIC} -lt 16 ]]; do
		read -rp "AmneziaWG interface name: " -e -i awg0 SERVER_AWG_NIC
	done

	until [[ ${SERVER_AWG_IPV4} =~ ^([0-9]{1,3}\.){3} ]]; do
		read -rp "Server AmneziaWG IPv4: " -e -i 10.0.8.1 SERVER_AWG_IPV4
	done

	until [[ ${SERVER_AWG_IPV6} =~ ^([a-f0-9]{1,4}:){3,4}: ]]; do
		read -rp "Server AmneziaWG IPv6: " -e -i fd42:42:42::1 SERVER_AWG_IPV6
	done

	# Generate random number within private ports range
	RANDOM_PORT=$(shuf -i49152-65535 -n1)
	until [[ ${SERVER_PORT} =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
		read -rp "Server AmneziaWG port [1-65535]: " -e -i "${RANDOM_PORT}" SERVER_PORT
	done

	# Adguard DNS by default
	until [[ ${CLIENT_DNS_1} =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
		read -rp "First DNS resolver to use for the clients: " -e -i 1.1.1.1 CLIENT_DNS_1
	done
	until [[ ${CLIENT_DNS_2} =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; do
		read -rp "Second DNS resolver to use for the clients (optional): " -e -i 1.0.0.1 CLIENT_DNS_2
		if [[ ${CLIENT_DNS_2} == "" ]]; then
			CLIENT_DNS_2="${CLIENT_DNS_1}"
		fi
	done

	until [[ ${STORE_CLIENT} =~ ^[yn]$ ]]; do
		read -rp "Store client config file at ${AMNEZIAWG_DIR}? [y/n]: " -e -i n STORE_CLIENT
		STORE_CLIENT=${STORE_CLIENT,,}
	done

	until [[ ${USE_NFTABLES} =~ ^[yn]$ ]]; do
		read -rp "Use nftables instead of iptables? [y/n]: " -e -i n USE_NFTABLES
		USE_NFTABLES=${USE_NFTABLES,,}
	done

	until [[ ${ALLOWED_IPS} =~ ^.+$ ]]; do
		echo -e "\nAmneziaWG uses a parameter called AllowedIPs to determine what is routed over the VPN."
		read -rp "Allowed IPs list for generated clients (leave default to route everything): " -e -i '0.0.0.0/0,::/0' ALLOWED_IPS
		if [[ ${ALLOWED_IPS} == "" ]]; then
			ALLOWED_IPS="0.0.0.0/0,::/0"
		fi
	done

	# Keepalive interval
	until [[ ${KEEPALIVE} =~ ^[0-9]+$ ]] && [ "${KEEPALIVE}" -ge 0 ] && [ "${KEEPALIVE}" -le 65535 ]; do
		read -rp "Keepalive interval [0-65535]: " -e -i 0 KEEPALIVE
	done

	# Jc
	RANDOM_AWG_JC=$(shuf -i3-10 -n1)
	until [[ ${SERVER_AWG_JC} =~ ^[0-9]+$ ]] && (( ${SERVER_AWG_JC} >= 1 )) && (( ${SERVER_AWG_JC} <= 128 )); do
		read -rp "Server AmneziaWG Jc [1-128]: " -e -i ${RANDOM_AWG_JC} SERVER_AWG_JC
	done

	# Jmin && Jmax
	readJminAndJmax
	until [ "${SERVER_AWG_JMIN}" -le "${SERVER_AWG_JMAX}" ]; do
		echo "AmneziaWG require Jmin < Jmax"
		readJminAndJmax
	done

	# S1 && S2
	generateS1AndS2
	while (( ${RANDOM_AWG_S1} + 56 == ${RANDOM_AWG_S2} )); do
		generateS1AndS2
	done
	readS1AndS2
	while (( ${SERVER_AWG_S1} + 56 == ${SERVER_AWG_S2} )); do
		echo "AmneziaWG require S1 + 56 <> S2"
		readS1AndS2
	done

	# H1 && H2 && H3 && H4
	generateH1AndH2AndH3AndH4
	while (( ${RANDOM_AWG_H1} == ${RANDOM_AWG_H2} )) || (( ${RANDOM_AWG_H1} == ${RANDOM_AWG_H3} )) || (( ${RANDOM_AWG_H1} == ${RANDOM_AWG_H4} )) || (( ${RANDOM_AWG_H2} == ${RANDOM_AWG_H3} )) || (( ${RANDOM_AWG_H2} == ${RANDOM_AWG_H4} )) || (( ${RANDOM_AWG_H3} == ${RANDOM_AWG_H4} )); do
		generateH1AndH2AndH3AndH4
	done
	readH1AndH2AndH3AndH4
	while (( ${SERVER_AWG_H1} == ${SERVER_AWG_H2} )) || (( ${SERVER_AWG_H1} == ${SERVER_AWG_H3} )) || (( ${SERVER_AWG_H1} == ${SERVER_AWG_H4} )) || (( ${SERVER_AWG_H2} == ${SERVER_AWG_H3} )) || (( ${SERVER_AWG_H2} == ${SERVER_AWG_H4} )) || (( ${SERVER_AWG_H3} == ${SERVER_AWG_H4} )); do
		echo "AmneziaWG require H1 and H2 and H3 and H4 be different"
		readH1AndH2AndH3AndH4
	done

	echo ""
	echo "Okay, that was all I needed. We are ready to setup your AmneziaWG server now."
	echo "You will be able to generate a client at the end of the installation."
	read -n1 -r -p "Press any key to continue..."
}

function installAmneziaWG() {
    installQuestions

    if [[ ${USE_NFTABLES} == 'y' ]]; then
        NF_PACKAGE="nftables"
    else
        NF_PACKAGE="iptables"
    fi

    echo -e "${GREEN}Installing AmneziaWG on ${OS}...${NC}"

    if [[ ${OS} == 'ubuntu' ]]; then
        echo -e "${GREEN}Using Ubuntu PPA (automated local DKMS build)...${NC}"
        apt-get update
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:amnezia/ppa
        apt-get update
        apt-get install -y amneziawg amneziawg-tools qrencode ${NF_PACKAGE}

    elif [[ ${OS} == 'debian' ]]; then
        echo -e "${GREEN}Installing AmneziaWG on Debian...${NC}"
        apt-get update
        apt-get install -y git build-essential linux-headers-amd64 \
            libmnl-dev libelf-dev qrencode ${NF_PACKAGE} pkg-config

        DEBIAN_VERSION=$(grep -oP '(?<=VERSION_ID=")\d+' /etc/os-release)

        WORKDIR="/usr/src/amneziawg-build"
        mkdir -p "$WORKDIR"
        cd "$WORKDIR" || exit 1

        git clone https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
        git clone https://github.com/amnezia-vpn/amneziawg-tools.git

        if [[ $DEBIAN_VERSION -ge 13 ]]; then
            # Debian 13+: ручная сборка
            cd "$WORKDIR/amneziawg-linux-kernel-module/src" || exit 1
            make clean
            make

            install -D -m 644 amneziawg.ko \
                /lib/modules/$(uname -r)/kernel/drivers/net/amneziawg.ko

            depmod -a
            modprobe amneziawg
			#
			echo "amneziawg" | tee /etc/modules-load.d/awg.conf >/dev/null
			modprobe amneziawg
			mkdir -p /etc/systemd/system/awg-quick@.service.d
			cat > /etc/systemd/system/awg-quick@.service.d/override.conf <<'EOF'
[Unit]
After=network-online.target
Wants=network-online.target
EOF
			systemctl daemon-reexec
			#
        else
            # Debian 12 и ниже: DKMS
            MODULE_NAME="amneziawg"
            MODULE_VERSION="1.0.0"
            DEST_SRC="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

            mkdir -p "$DEST_SRC"
            cp -r "$WORKDIR/amneziawg-linux-kernel-module/src" "$DEST_SRC/"

            if dkms status | grep -q "${MODULE_NAME}, ${MODULE_VERSION}"; then
                dkms remove -m ${MODULE_NAME} -v ${MODULE_VERSION} --all
            fi

            cat > "${DEST_SRC}/dkms.conf" <<'EOF'
PACKAGE_NAME="amneziawg"
PACKAGE_VERSION="1.0.0"
BUILT_MODULE_NAME[0]="amneziawg"
DEST_MODULE_LOCATION[0]="/kernel/drivers/net"
MAKE[0]="make -C src"
CLEAN="make -C src clean"
AUTOINSTALL="yes"
EOF

            dkms add -m ${MODULE_NAME} -v ${MODULE_VERSION}
            dkms build -m ${MODULE_NAME} -v ${MODULE_VERSION}
            dkms install -m ${MODULE_NAME} -v ${MODULE_VERSION}
        fi

        # Сборка пользовательских инструментов
        cd "$WORKDIR/amneziawg-tools/src" || exit 1
        make
        make install

        cd /
        rm -rf "$WORKDIR"
    fi

	SERVER_AWG_CONF="${AMNEZIAWG_DIR}/${SERVER_AWG_NIC}.conf"

	SERVER_PRIV_KEY=$(awg genkey)
	SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | awg pubkey)

	# Save WireGuard settings
	echo "SERVER_PUB_IP=${SERVER_PUB_IP}
SERVER_PUB_NIC=${SERVER_PUB_NIC}
SERVER_AWG_NIC=${SERVER_AWG_NIC}
SERVER_AWG_IPV4=${SERVER_AWG_IPV4}
SERVER_AWG_IPV6=${SERVER_AWG_IPV6}
SERVER_PORT=${SERVER_PORT}
SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
SERVER_PUB_KEY=${SERVER_PUB_KEY}
CLIENT_DNS_1=${CLIENT_DNS_1}
CLIENT_DNS_2=${CLIENT_DNS_2}
STORE_CLIENT=${STORE_CLIENT}
USE_NFTABLES=${USE_NFTABLES}
ALLOWED_IPS=${ALLOWED_IPS}
KEEPALIVE=${KEEPALIVE}
SERVER_AWG_JC=${SERVER_AWG_JC}
SERVER_AWG_JMIN=${SERVER_AWG_JMIN}
SERVER_AWG_JMAX=${SERVER_AWG_JMAX}
SERVER_AWG_S1=${SERVER_AWG_S1}
SERVER_AWG_S2=${SERVER_AWG_S2}
SERVER_AWG_H1=${SERVER_AWG_H1}
SERVER_AWG_H2=${SERVER_AWG_H2}
SERVER_AWG_H3=${SERVER_AWG_H3}
SERVER_AWG_H4=${SERVER_AWG_H4}" >"${AMNEZIAWG_DIR}/params"

	# Add server interface
	echo "[Interface]
Address = ${SERVER_AWG_IPV4}/24,${SERVER_AWG_IPV6}/64
ListenPort = ${SERVER_PORT}
PrivateKey = ${SERVER_PRIV_KEY}
Jc = ${SERVER_AWG_JC}
Jmin = ${SERVER_AWG_JMIN}
Jmax = ${SERVER_AWG_JMAX}
S1 = ${SERVER_AWG_S1}
S2 = ${SERVER_AWG_S2}
H1 = ${SERVER_AWG_H1}
H2 = ${SERVER_AWG_H2}
H3 = ${SERVER_AWG_H3}
H4 = ${SERVER_AWG_H4}" >"${SERVER_AWG_CONF}"

if [[ $USE_NFTABLES == 'y' ]]; then
    echo "PostUp = nft add table inet amneziawg
PostUp = nft add chain inet amneziawg input { type filter hook input priority 0 \; }
PostUp = nft add rule inet amneziawg input udp dport ${SERVER_PORT} accept
PostUp = nft add chain inet amneziawg forward { type filter hook forward priority 0 \; }
PostUp = nft add rule inet amneziawg forward iifname \"${SERVER_PUB_NIC}\" oifname \"${SERVER_AWG_NIC}\" accept
PostUp = nft add rule inet amneziawg forward iifname \"${SERVER_AWG_NIC}\" accept
PostUp = nft add chain inet amneziawg postrouting { type nat hook postrouting priority 100 \; }
PostUp = nft add rule inet amneziawg postrouting oifname \"${SERVER_PUB_NIC}\" masquerade
PostDown = nft delete table inet amneziawg" >>"${SERVER_AWG_CONF}"
else
    echo "PostUp = iptables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_AWG_NIC} -j ACCEPT
PostUp = iptables -I FORWARD -i ${SERVER_AWG_NIC} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostUp = ip6tables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostUp = ip6tables -I FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_AWG_NIC} -j ACCEPT
PostUp = ip6tables -I FORWARD -i ${SERVER_AWG_NIC} -j ACCEPT
PostUp = ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_AWG_NIC} -j ACCEPT
PostDown = iptables -D FORWARD -i ${SERVER_AWG_NIC} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostDown = ip6tables -D INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostDown = ip6tables -D FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_AWG_NIC} -j ACCEPT
PostDown = ip6tables -D FORWARD -i ${SERVER_AWG_NIC} -j ACCEPT
PostDown = ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE" >>"${SERVER_AWG_CONF}"
fi

	# Enable routing on the server
	echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/awg.conf

	sysctl --system

	systemctl daemon-reload
	systemctl start "awg-quick@${SERVER_AWG_NIC}"
	systemctl enable "awg-quick@${SERVER_AWG_NIC}"

	newClient
	echo -e "${GREEN}If you want to add more clients, you simply need to run this script another time!${NC}"

	# Check if AmneziaWG is running
	systemctl is-active --quiet "awg-quick@${SERVER_AWG_NIC}"
	AWG_RUNNING=$?

	# AmneziaWG might not work if we updated the kernel. Tell the user to reboot
	if [[ ${AWG_RUNNING} -ne 0 ]]; then
		echo -e "\n${RED}WARNING: AmneziaWG does not seem to be running.${NC}"
		echo -e "${ORANGE}You can check if AmneziaWG is running with: systemctl status awg-quick@${SERVER_AWG_NIC}${NC}"
		echo -e "${ORANGE}If you get something like \"Cannot find device ${SERVER_AWG_NIC}\", please reboot!${NC}"
	else # AmneziaWG is running
		echo -e "\n${GREEN}AmneziaWG is running.${NC}"
		echo -e "${GREEN}You can check the status of AmneziaWG with: systemctl status awg-quick@${SERVER_AWG_NIC}\n\n${NC}"
		echo -e "${ORANGE}If you don't have internet connectivity from your client, try to reboot the server.${NC}"
	fi
}

function newClient() {
	# If SERVER_PUB_IP is IPv6, add brackets if missing
	if [[ ${SERVER_PUB_IP} =~ .*:.* ]]; then
		if [[ ${SERVER_PUB_IP} != *"["* ]] || [[ ${SERVER_PUB_IP} != *"]"* ]]; then
			SERVER_PUB_IP="[${SERVER_PUB_IP}]"
		fi
	fi
	ENDPOINT="${SERVER_PUB_IP}:${SERVER_PORT}"

	echo ""
	echo "Client configuration"
	echo ""
	echo "The client name must consist of alphanumeric character(s). It may also include underscores or dashes and can't exceed 15 chars."

	until [[ ${CLIENT_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${CLIENT_EXISTS} == '0' && ${#CLIENT_NAME} -lt 16 ]]; do
		read -rp "Client name: " -e CLIENT_NAME
		CLIENT_EXISTS=$(grep -c -E "^### Client ${CLIENT_NAME}\$" "${SERVER_AWG_CONF}")

		if [[ ${CLIENT_EXISTS} != 0 ]]; then
			echo ""
			echo -e "${ORANGE}A client with the specified name was already created, please choose another name.${NC}"
			echo ""
		fi
	done

	for DOT_IP in {2..254}; do
		DOT_EXISTS=$(grep -c "${SERVER_AWG_IPV4::-1}${DOT_IP}" "${SERVER_AWG_CONF}")
		if [[ ${DOT_EXISTS} == '0' ]]; then
			break
		fi
	done

	if [[ ${DOT_EXISTS} == '1' ]]; then
		echo ""
		echo "The subnet configured supports only 253 clients."
		exit 1
	fi

	BASE_IP=$(echo "$SERVER_AWG_IPV4" | awk -F '.' '{ print $1"."$2"."$3 }')
	until [[ ${IPV4_EXISTS} == '0' ]]; do
		read -rp "Client AmneziaWG IPv4: ${BASE_IP}." -e -i "${DOT_IP}" DOT_IP
		CLIENT_AWG_IPV4="${BASE_IP}.${DOT_IP}"
		IPV4_EXISTS=$(grep -c "$CLIENT_AWG_IPV4/32" "${SERVER_AWG_CONF}")

		if [[ ${IPV4_EXISTS} != 0 ]]; then
			echo ""
			echo -e "${ORANGE}A client with the specified IPv4 was already created, please choose another IPv4.${NC}"
			echo ""
		fi
	done

	BASE_IP=$(echo "$SERVER_AWG_IPV6" | awk -F '::' '{ print $1 }')
	until [[ ${IPV6_EXISTS} == '0' ]]; do
		read -rp "Client AmneziaWG IPv6: ${BASE_IP}::" -e -i "${DOT_IP}" DOT_IP
		CLIENT_AWG_IPV6="${BASE_IP}::${DOT_IP}"
		IPV6_EXISTS=$(grep -c "${CLIENT_AWG_IPV6}/128" "${SERVER_AWG_CONF}")

		if [[ ${IPV6_EXISTS} != 0 ]]; then
			echo ""
			echo -e "${ORANGE}A client with the specified IPv6 was already created, please choose another IPv6.${NC}"
			echo ""
		fi
	done

	# Generate key pair for the client
	CLIENT_PRIV_KEY=$(awg genkey)
	CLIENT_PUB_KEY=$(echo "${CLIENT_PRIV_KEY}" | awg pubkey)
	CLIENT_PRE_SHARED_KEY=$(awg genpsk)

	CONFIG_DIR=$(getDirForClientConfig "${CLIENT_NAME}")
	CLIENT_CONFIG="${CONFIG_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"

	# Create client file and add the server as a peer
	echo "[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${CLIENT_AWG_IPV4}/32,${CLIENT_AWG_IPV6}/128
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}
Jc = ${SERVER_AWG_JC}
Jmin = ${SERVER_AWG_JMIN}
Jmax = ${SERVER_AWG_JMAX}
S1 = ${SERVER_AWG_S1}
S2 = ${SERVER_AWG_S2}
H1 = ${SERVER_AWG_H1}
H2 = ${SERVER_AWG_H2}
H3 = ${SERVER_AWG_H3}
H4 = ${SERVER_AWG_H4}

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
Endpoint = ${ENDPOINT}
AllowedIPs = ${ALLOWED_IPS}" >"${CLIENT_CONFIG}"

	if [[ ${KEEPALIVE} -ne 0 ]]; then
		echo "PersistentKeepalive = ${KEEPALIVE}" >>"${CLIENT_CONFIG}"
	fi

	# Add the client as a peer to the server
	echo -e "\n### Client ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CLIENT_AWG_IPV4}/32,${CLIENT_AWG_IPV6}/128" >>"${SERVER_AWG_CONF}"

	awg syncconf "${SERVER_AWG_NIC}" <(awg-quick strip "${SERVER_AWG_NIC}")

	# Generate QR code if qrencode is installed
	if command -v qrencode &>/dev/null; then
		echo -e "${GREEN}\nHere is your client config file as a QR Code:\n${NC}"
		qrencode -t ansiutf8 -l L <"${CLIENT_CONFIG}"
		echo ""
	fi

	echo -e "${GREEN}Your client config file is in ${CLIENT_CONFIG}${NC}"
}

function listClients() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
	if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
		echo ""
		echo "You have no existing clients!"
		exit 1
	fi

	grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
}

function revokeClient() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
	if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
		echo ""
		echo "You have no existing clients!"
		exit 1
	fi

	echo ""
	echo "Select the existing client you want to revoke"
	grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
	until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
		if [[ ${CLIENT_NUMBER} == '1' ]]; then
			read -rp "Select one client [1]: " CLIENT_NUMBER
		else
			read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
		fi
	done

	# match the selected number to a client name
	CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

	# remove [Peer] block matching $CLIENT_NAME
	sed -i "/^### Client ${CLIENT_NAME}\$/,/^$/d" "${SERVER_AWG_CONF}"

	# remove generated client file
	CONFIG_DIR=$(getDirForClientConfig "${CLIENT_NAME}")
	CLIENT_CONFIG="${CONFIG_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
	rm -f "${CLIENT_CONFIG}"

	# restart AmneziaWG to apply changes
	awg syncconf "${SERVER_AWG_NIC}" <(awg-quick strip "${SERVER_AWG_NIC}")
}

function showClientQR() {
    NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
    if [[ ${NUMBER_OF_CLIENTS} -eq 0 ]]; then
        echo ""
        echo "You have no existing clients!"
        exit 1
    fi

    echo ""
    echo "Select the client to show QR code"
    grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
    until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
        if [[ ${CLIENT_NUMBER} == '1' ]]; then
            read -rp "Select one client [1]: " CLIENT_NUMBER
        else
            read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
        fi
    done

    # match the selected number to a client name
    CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

    # Get the home directory for the client
	CONFIG_DIR=$(getDirForClientConfig "${CLIENT_NAME}")
	CLIENT_CONFIG="${CONFIG_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"

    # Check if the client config file exists
    if [[ -f "${CLIENT_CONFIG}" ]]; then
        echo -e "${GREEN}\nHere is your client config file as a QR Code:\n${NC}"
        qrencode -t ansiutf8 -l L <"${CLIENT_CONFIG}"
        echo ""
    else
        echo -e "${RED}Client config file not found!${NC}"
    fi
}

function uninstallAmneziaWG() {
    echo ""
    echo -e "\n${RED}WARNING: This will uninstall AmneziaWG and remove all configuration files!${NC}"
    echo -e "${ORANGE}Please backup the ${AMNEZIAWG_DIR} directory if you want to keep your configuration files.\n${NC}"
    read -rp "Do you really want to remove AmneziaWG? [y/n]: " -e REMOVE
    REMOVE=${REMOVE:-n}

    if [[ $REMOVE != 'y' ]]; then
        echo "Removal aborted!"
        return
    fi

    # Определяем ОС
    checkOS

    MODULE_NAME="amneziawg"
    MODULE_VERSION="1.0.0"

    # Выгружаем модуль ядра, если загружен
    if lsmod | grep -q "${MODULE_NAME}"; then
        echo -e "${GREEN}Unloading kernel module ${MODULE_NAME}...${NC}"
        modprobe -r "${MODULE_NAME}" 2>/dev/null || true
    fi

    # Останавливаем и отключаем сервис
    if [[ -n "$SERVER_AWG_NIC" ]]; then
        systemctl stop "awg-quick@${SERVER_AWG_NIC}" 2>/dev/null || true
        systemctl disable "awg-quick@${SERVER_AWG_NIC}" 2>/dev/null || true
        rm -f /etc/systemd/system/multi-user.target.wants/awg-quick@${SERVER_AWG_NIC}.service
    fi

    # Удаляем DKMS-модуль, если он установлен
    if dkms status | grep -q "${MODULE_NAME}"; then
        echo -e "${GREEN}Removing DKMS module ${MODULE_NAME}...${NC}"
        dkms remove -m "${MODULE_NAME}" -v "${MODULE_VERSION}" --all 2>/dev/null || true
    fi
    rm -rf "/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

    # Удаляем бинарники, man и bash-completion
    for file in /usr/bin/awg /usr/bin/awg-quick \
                /usr/share/man/man8/awg.8 /usr/share/man/man8/awg-quick.8 \
                /usr/share/bash-completion/completions/awg \
                /usr/share/bash-completion/completions/awg-quick; do
        [[ -f "$file" ]] && rm -f "$file"
    done

    # Удаляем systemd-сервисы
    for svc in /lib/systemd/system/awg-quick@.service /lib/systemd/system/awg-quick.target; do
        [[ -f "$svc" ]] && rm -f "$svc"
    done
    systemctl daemon-reload

    # Удаляем конфиги и sysctl
    [[ -f /etc/sysctl.d/awg.conf ]] && rm -f /etc/sysctl.d/awg.conf
    [[ -d "${AMNEZIAWG_DIR}" ]] && rm -rf "${AMNEZIAWG_DIR}"
    sysctl --system

    # Удаляем интерфейс, если остался
    if [[ -n "$SERVER_AWG_NIC" ]] && ip link show "${SERVER_AWG_NIC}" &>/dev/null; then
        ip link delete "${SERVER_AWG_NIC}" 2>/dev/null || true
    fi

    # Удаляем пакеты через apt для Ubuntu/Debian
    if [[ ${OS} == 'ubuntu' || ${OS} == 'debian' ]]; then
        echo -e "${GREEN}Removing AmneziaWG packages...${NC}"
        apt-get purge -y amneziawg amneziawg-tools 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
    fi

    echo -e "${GREEN}AmneziaWG uninstalled successfully.${NC}"
}

function loadParams() {
	source "${AMNEZIAWG_DIR}/params"
	SERVER_AWG_CONF="${AMNEZIAWG_DIR}/${SERVER_AWG_NIC}.conf"
}

function manageMenu() {
	echo "AmneziaWG server installer"
	echo ""
	echo "It looks like AmneziaWG is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Add a new user"
	echo "   2) List all users"
	echo "   3) Statistics awg"
	echo "   4) Revoke existing user"
	echo "   5) Show client QR code"
	echo "   6) Uninstall AmneziaWG"
	echo "   7) Exit"
	until [[ ${MENU_OPTION} =~ ^[1-7]$ ]]; do
		read -rp "Select an option [1-7]: " MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1)
		newClient
		;;
	2)
		listClients
		;;
    3)
        echo "===== AWG STATUS ====="
        awg show
        echo "======================"
        ;;
	4)
		revokeClient
		;;
	5)
        showClientQR
		;;
	6)
		uninstallAmneziaWG
		;;
	7)
		exit 0
		;;
	esac
}


# Check for root, virt, OS...
initialCheck

# Check if AmneziaWG is already installed and load params
if [[ -e "${AMNEZIAWG_DIR}/params" ]]; then
	loadParams
	manageMenu
else
	installAmneziaWG
fi
