# 1) Reconfigure Locales
sudo locale-gen en_US.UTF-8
export LC_ALL="en_US.UTF-8"
sudo dpkg-reconfigure locales
echo 'LC_ALL="en_US.UTF-8"' | sudo tee -a /etc/default/locale

# 2) Update and install needed packages
sudo apt-get update
sudo apt-get upgrade -y


# 3) Update and install needed packages
sudo apt-get install -y libcurl4-openssl-dev libxml2-dev gdebi-core libapparmor1 git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libgdbm-dev libncurses5-dev automake libtool bison libffi-dev

# 4) Install R

#Add CRAN mirror to custom sources.list file
echo "deb http://cran.r-project.org/bin/linux/ubuntu/ trusty/" | sudo tee -a /etc/apt/sources.list.d/sources.list

# add keys to server
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-get update

# install R base
sudo apt-get install -y r-base

# install needed packages

sudo Rscript -e "install.packages(c('sp','maps','maptools'), repos='http://cran.rstudio.com/')"

# 5) Install Ruby
curl -L https://get.rvm.io | bash -s stable
source /home/ubuntu/.rvm/scripts/rvm
echo "source /home/ubuntu/.rvm/scripts/rvm" >> ~/.bashrc
rvm install 2.1.2
rvm use 2.1.2 --default
echo "gem: --no-ri --no-rdoc" | sudo tee ~/.gemrc

# 6) Install Gems
gem install bundler
bundle install
