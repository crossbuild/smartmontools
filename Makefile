# Makefile for smartmontools
#
# Home page: http://smartmontools.sourceforge.net
#
# $Id: Makefile,v 1.26 2002/10/28 23:47:39 ballen4705 Exp $
#
# Copyright (C) 2002 Bruce Allen <smartmontools-support@lists.sourceforge.net>
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any later
# version.
# 
# You should have received a copy of the GNU General Public License (for
# example COPYING); if not, write to the Free Software Foundation, Inc., 675
# Mass Ave, Cambridge, MA 02139, USA.
#
# This code was originally developed as a Senior Thesis by Michael Cornwell
# at the Concurrent Systems Laboratory (now part of the Storage Systems
# Research Center), Jack Baskin School of Engineering, University of
# California, Santa Cruz. http://ssrc.soe.ucsc.edu/

CC	= gcc

# Debugging
# CFLAGS = -fsigned-char -Wall -g

# Build against kernel header files.  Change linux-2.4 to correct path for your system
# CFLAGS	= -fsigned-char -Wall -O2 -I./usr/src/linux-2.4/include

# Normal build
CFLAGS	= -fsigned-char -Wall -O2 

releasefiles=atacmds.c atacmds.h ataprint.c ataprint.h CHANGELOG COPYING extern.h Makefile\
  README scsicmds.c scsicmds.h scsiprint.c scsiprint.h smartctl.8 smartctl.c smartctl.h\
  smartd.8 smartd.c smartd.h smartd.initd TODO VERSION smartd.conf

counter=$(shell cat VERSION)
newcounter=$(shell ./add )
pkgname=smartmontools-5.0
pkgname2=$(pkgname)-$(counter)

all: smartd smartctl

smartctl: smartctl.c atacmds.o ataprint.o scsicmds.o scsiprint.o atacmds.h ataprint.h extern.h scsicmds.h scsiprint.h smartctl.h  VERSION Makefile
	${CC} -DSMARTMONTOOLS_VERSION=$(counter) -o smartctl ${CFLAGS} smartctl.c atacmds.o scsicmds.o ataprint.o scsiprint.o

smartd:  smartd.c atacmds.o ataprint.o scsicmds.o atacmds.h ataprint.h extern.h scsicmds.h smartd.h  VERSION Makefile
	${CC} -DSMARTMONTOOLS_VERSION=$(counter) -o smartd ${CFLAGS} smartd.c scsicmds.o atacmds.o ataprint.o

atacmds.o: atacmds.h atacmds.c Makefile
	${CC} ${CFLAGS} -c atacmds.c 

ataprint.o: ataprint.c atacmds.h ataprint.h smartctl.h extern.h Makefile
	${CC} ${CFLAGS} -c ataprint.c

scsicmds.o: scsicmds.c scsicmds.h Makefile
	${CC} ${CFLAGS} -c scsicmds.c

scsiprint.o: scsiprint.c  extern.h scsicmds.h scsiprint.h smartctl.h Makefile
	${CC} ${CFLAGS} -c scsiprint.c 

clean:
	rm -f *.o smartctl smartd *~ \#*\# smartmontools*.tar.gz smartmontools*.rpm temp.* smart*.8.gz

install: smartctl smartd smartctl.8 smartd.8 smartd.initd Makefile
	/bin/gzip -c smartctl.8 > smartctl.8.gz
	/bin/gzip -c smartd.8 > smartd.8.gz
	rm -f /usr/share/man/man8/smartctl.8
	rm -f /usr/share/man/man8/smartd.8
	install -m 755 -o root -g root -D smartctl      $(DESTDIR)/usr/sbin/smartctl
	install -m 755 -o root -g root -D smartd        $(DESTDIR)/usr/sbin/smartd
	install -m 755 -o root -g root -D smartd.initd  $(DESTDIR)/etc/rc.d/init.d/smartd
	install -m 644 -o root -g root -D smartctl.8.gz $(DESTDIR)/usr/share/man/man8/smartctl.8.gz
	install -m 644 -o root -g root -D smartd.8.gz   $(DESTDIR)/usr/share/man/man8/smartd.8.gz
	install -m 644 -o root -g root -D CHANGELOG     $(DESTDIR)/usr/share/doc/smartmontools-5.0/CHANGELOG
	install -m 644 -o root -g root -D COPYING       $(DESTDIR)/usr/share/doc/smartmontools-5.0/COPYING
	install -m 644 -o root -g root -D README        $(DESTDIR)/usr/share/doc/smartmontools-5.0/README
	install -m 644 -o root -g root -D TODO          $(DESTDIR)/usr/share/doc/smartmontools-5.0/TODO
	install -m 644 -o root -g root -D VERSION       $(DESTDIR)/usr/share/doc/smartmontools-5.0/VERSION
	install -m 644 -o root -g root -D smartd.conf   $(DESTDIR)/usr/share/doc/smartmontools-5.0/smartd.conf

	@echo -e "\nTo manually start smartd on bootup, run /etc/rc.d/init.d/smartd start"
	@echo "To Automatically start smartd on bootup, run /sbin/chkconfig --add smartd"
	@echo "Smartd can now use a configuration file /etc/smartd.conf.  Please read man 8 smartd."
	@echo "Note: you must do a \"make install\" or you won't have the wonderful man pages!"

uninstall: Makefile
	rm -f /usr/sbin/smartctl /usr/sbin/smartd /usr/share/man/man8/smartctl.8 /usr/share/man/man8/smartd.8\
           /usr/share/man/man8/smartctl.8.gz /usr/share/man/man8/smartd.8.gz
	/sbin/chkconfig --del smartd
	if [ -f /var/lock/subsys/smartd ] ; then /etc/rc.d/init.d/smartd stop ; fi
	rm -f /etc/rc.d/init.d/smartd

# All this mess is to automatically increment the release numbers.
# The number of the next release is kept in the file "VERSION"
release: $(releasefiles)
	rm -rf $(pkgname)
	mkdir $(pkgname)
	cp -a $(releasefiles) $(pkgname)
	tar zcvf $(pkgname).tar.gz $(pkgname)
	mv -f $(pkgname) $(pkgname2)
	tar zcvf $(pkgname2).tar.gz $(pkgname2)
	rm -rf $(pkgname2)
	mv -f $(pkgname).tar.gz /usr/src/redhat/SOURCES/
	cat smartmontools.spec | sed '/Release:/d' > temp.spec
	echo "Release: " $(counter) > temp.version
	cat temp.version temp.spec > smartmontools.spec
	rm -f temp.spec temp.version
	rpm -ba smartmontools.spec
	mv /usr/src/redhat/RPMS/i386/$(pkgname)*.rpm .
	mv /usr/src/redhat/SRPMS/$(pkgname)*rpm .
	rm -f /usr/src/redhat/SOURCES/$(pkgname).tar.gz
	. cvs-script && cvs commit -m "release $(counter)"
	. cvs-script && cvs tag -d "RELEASE_5_0_$(counter)" && cvs tag "RELEASE_5_0_$(counter)"
	echo `hostname` | grep -q ballen && echo $(newcounter) > VERSION
