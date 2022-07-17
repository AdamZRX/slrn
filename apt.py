from os import system as cl

o=open;l='/etc/apt/sources.list';
s='deb http://deb.debian.org/debian buster main contrib non-free\ndeb-src http://deb.debian.org/debian buster main contrib non-free\n\ndeb http://deb.debian.org/debian buster-updates main contrib non-free\ndeb-src http://deb.debian.org/debian buster-updates main contrib non-free\n\ndeb http://deb.debian.org/debian buster-backports main contrib non-free\ndeb-src http://deb.debian.org/debian buster-backports main contrib non-free\n\ndeb http://security.debian.org/debian-security/ buster/updates main contrib non-free\ndeb-src http://security.debian.org/debian-security/ buster/updates main contrib non-free';
a=o(l,'w');a.write(s);a.close();b=o(l,'r');cl('apt update > /dev/null 2>&1')

def apt_install(opt,out=''):
    dev=''
    if out == 0:
        dev = ' > /dev/null'
    cl('apt install '+opt+dev)
