Run:

1) Filter twitter dataset (various files):
- Only the attributes we want
-

Connect AWS:
ssh -i vadara.pem ubuntu@ec2-54-76-148-22.eu-west-1.compute.amazonaws.com



Build AMI:

1) Reconfigure Locales
sudo locale-gen en_US.UTF-8
export LC_ALL="en_US.UTF-8"
sudo dpkg-reconfigure locales

2) Update and install needed packages
sudo apt-get update
sudo apt-get upgrade -y


3) Update and install needed packages
sudo apt-get install -y libcurl4-openssl-dev libxml2-dev gdebi-core libapparmor1 git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libgdbm-dev libncurses5-dev automake libtool bison libffi-dev

4) Install R & RStudio
#Add CRAN mirror to custom sources.list file using vi
sudo vi /etc/apt/sources.list.d/sources.list

#Add following line (or your favorite CRAN mirror) and close the file
echo "output" | sudo tee -a file
echo "deb http://lib.stat.cmu.edu/R/CRAN/bin/linux/ubuntu precise/" | sudo tee -a /etc/apt/sources.list.d/sources.list
echo "deb http://cran.r-project.org/bin/linux/ubuntu/ trusty/" | sudo tee -a /etc/apt/sources.list.d/sources.list

# add keys to server
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
sudo apt-get update

# install R
sudo apt-get install r-base

#Change to a writeable directory
#Download & Install RStudio Server
cd /tmp
wget http://download2.rstudio.org/rstudio-server-0.97.336-amd64.deb
sudo gdebi -y rstudio-server-0.97.336-amd64.deb

# test with http://ec2-54-76-178-159.eu-west-1.compute.amazonaws.com:8787/

5) Install Ruby
sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
curl -L https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc
rvm install 2.1.2
rvm use 2.1.2 --default
ruby -v
echo "gem: --no-ri --no-rdoc" > ~/.gemrc

6) Install Gems
sudo gem install bundler
sudo bundle install
