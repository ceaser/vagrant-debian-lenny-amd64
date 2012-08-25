date > /etc/vagrant_box_build_time

#Updating the box
apt-get -y update
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline5-dev libyaml-0-1 libyaml-dev git-core
apt-get clean

#Setting up sudo
cp /etc/sudoers /etc/sudoers.orig
sed -i -e 's/vagrant ALL=(ALL) ALL/vagrant ALL=NOPASSWD:ALL/g' /etc/sudoers

# Installing rbenv to manage ruby
RBENV_ROOT="$HOME/.rbenv"

git clone git://github.com/sstephenson/rbenv.git $RBENV_ROOT

# Installing rbenv plugins
PLUGINS=(
  "sstephenson:rbenv-vars"
  "sstephenson:ruby-build"
)
for plugin in ${PLUGINS[@]} ; do

  KEY=${plugin%%:*}
  VALUE=${plugin#*:}

  RBENV_PLUGIN_ROOT="${RBENV_ROOT}/plugins/$VALUE"
  git clone git://github.com/$KEY/$VALUE.git $RBENV_PLUGIN_ROOT
done

# .profile
cat <<'EOP' >> /$HOME/.profile
if [ -d $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi
EOP

# .gemrc
cat << EOF > .gemrc
---
:sources:
- http://gems.rubyforge.org
install: --no-rdoc --no-ri
update: --no-ri --no-rdoc
EOF

# Installing ruby-1.9.3-p194
source ~/.profile
rbenv install 1.9.3-p194
rbenv global 1.9.3-p194
rbenv rehash
gem update --system
rbenv rehash
gem install chef --no-ri --no-rdoc
gem install puppet  --no-ri --no-rdoc
rbenv rehash

# Installing ruby-1.9.3-p194
source ~/.profile
rbenv install 1.9.3-p194
rbenv global 1.9.3-p194
rbenv rehash
gem update --system
rbenv rehash
gem install chef --no-ri --no-rdoc
gem install puppet  --no-ri --no-rdoc
rbenv rehash

#Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

#Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get -y autoremove

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
exit
