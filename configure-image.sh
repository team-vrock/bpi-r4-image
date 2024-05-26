export LANG=C
/debootstrap/debootstrap --second-stage

cat > /etc/apt/apt.conf.d/01norecommend << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF


echo "" > /etc/apt/sources.list
echo "deb http://ftp.ch.debian.org/debian bookworm main non-free-firmware">>/etc/apt/sources.list
echo #"deb-src http://ftp.ch.debian.org/debian trixie main non-free-firmware">>/etc/apt/sources.list
echo "deb http://ftp.ch.debian.org/debian-security bookworm-security main non-free-firmware">>/etc/apt/sources.list
echo #"deb-src http://ftp.ch.debian.org/debian trixie universe">>/etc/apt/sources.list

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

apt-get install sudo openssh-server locales pv ca-certificates curl git gnupg -y

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg


echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

apt-get install openvswitch-switch -y