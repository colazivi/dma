dma -- DragonFly Mail Agent
===========================

dma is a small Mail Transport Agent (MTA), designed for home and
office use.  It accepts mails from locally installed Mail User Agents (MUA)
and delivers the mails either locally or to a remote destination.
Remote delivery includes several features like TLS/SSL support and
SMTP authentication.

dma is not intended as a replacement for real, big MTAs like sendmail(8)
or postfix(1).  Consequently, dma does not listen on port 25 for
incoming connections.


Building
--------

mkdir build && cd build
cmake ..
make

Installation
------------

	make install
	
	If traditional sendmail links are desired (beware of existing mailwrapper or update-alternatives configurations!):
	make sendmail-link mailq-link

	If the directories in /var are missing:
	make install-spool-dirs

See INSTALL for requirements and configuration options.


Contact
-------

Simon Schubert <2@0x2c.org>
