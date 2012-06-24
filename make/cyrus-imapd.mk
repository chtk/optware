#/#########################################################l
#
# cyrus-imapd
#
###########################################################

CYRUS-IMAPD_SITE=ftp://ftp.andrew.cmu.edu/pub/cyrus-mail
CYRUS-IMAPD_VERSION=2.2.12
CYRUS-IMAPD_SOURCE=cyrus-imapd-$(CYRUS-IMAPD_VERSION).tar.gz
CYRUS-IMAPD_DIR=cyrus-imapd-$(CYRUS-IMAPD_VERSION)
CYRUS-IMAPD_UNZIP=zcat
CYRUS-IMAPD_MAINTAINER=Matthias Appel <private_tweety@gmx.net>
CYRUS-IMAPD_DESCRIPTION=The Carnegie Mellon University Cyrus IMAP Server
CYRUS-IMAPD_SECTION=util
CYRUS-IMAPD_PRIORITY=optional
CYRUS-IMAPD_DEPENDS=openssl, libdb, cyrus-sasl, e2fsprogs, perl
CYRUS-IMAPD_SUGGESTS=
CYRUS-IMAPD_CONFLICTS=

CYRUS-IMAPD_IPK_VERSION=15

CYRUS-IMAPD_CONFFILES=$(OPTWARE_PREFIX)/etc/cyrus.conf $(OPTWARE_PREFIX)/etc/imapd.conf $(OPTWARE_PREFIX)/etc/init.d/S59cyrus-imapd

CYRUS-IMAPD_PATCHES=$(CYRUS-IMAPD_SOURCE_DIR)/cyrus.cross.patch \
 $(CYRUS-IMAPD_SOURCE_DIR)/perl.Makefile.in.patch \
 $(CYRUS-IMAPD_SOURCE_DIR)/perl.Makefile.PL.patch \
 $(CYRUS-IMAPD_SOURCE_DIR)/cyrus-imapd-2.2.12-autosievefolder-0.6.diff \
 $(CYRUS-IMAPD_SOURCE_DIR)/cyrus-imapd-2.2.12-autocreate-0.9.4.diff \
 $(CYRUS-IMAPD_SOURCE_DIR)/cyrus-imapd-2.2.12-rmquota+deletemailbox-0.2-1.diff \
 $(CYRUS-IMAPD_SOURCE_DIR)/cyrus-imapd-2.2.12-imapopts.h.patch \

CYRUS-IMAPD_CPPFLAGS=
CYRUS-IMAPD_LDFLAGS=

CYRUS-IMAPD_BUILD_DIR=$(BUILD_DIR)/cyrus-imapd
CYRUS-IMAPD_SOURCE_DIR=$(SOURCE_DIR)/cyrus-imapd

CYRUS-IMAPD_IPK_DIR=$(BUILD_DIR)/cyrus-imapd-$(CYRUS-IMAPD_VERSION)-ipk
CYRUS-IMAPD_IPK=$(BUILD_DIR)/cyrus-imapd_$(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)_$(TARGET_ARCH).ipk
CYRUS-IMAPD-DOC_IPK=$(BUILD_DIR)/cyrus-imapd-doc_$(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)_$(TARGET_ARCH).ipk
CYRUS-IMAPD-DEVEL_IPK=$(BUILD_DIR)/cyrus-imapd-devel_$(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: cyrus-imapd-source cyrus-imapd-unpack cyrus-imapd cyrus-imapd-stage cyrus-imapd-ipk cyrus-imapd-clean cyrus-imapd-dirclean cyrus-imapd-check

$(DL_DIR)/$(CYRUS-IMAPD_SOURCE):
	$(WGET) -P $(DL_DIR) $(CYRUS-IMAPD_SITE)/$(CYRUS-IMAPD_SOURCE)

cyrus-imapd-source: $(DL_DIR)/$(CYRUS-IMAPD_SOURCE) $(CYRUS-IMAPD_PATCHES)

$(CYRUS-IMAPD_BUILD_DIR)/.configured: $(DL_DIR)/$(CYRUS-IMAPD_SOURCE) $(CYRUS-IMAPD_PATCHES) make/cyrus-imapd.mk
	$(MAKE) libdb-stage openssl-stage
	$(MAKE) cyrus-sasl-stage
	$(MAKE) e2fsprogs-stage # for libcom_err.a and friends
ifneq (,$(filter perl, $(PACKAGES)))
	$(MAKE) perl-stage
endif
	rm -rf $(BUILD_DIR)/$(CYRUS-IMAPD_DIR) $(CYRUS-IMAPD_BUILD_DIR)
	$(CYRUS-IMAPD_UNZIP) $(DL_DIR)/$(CYRUS-IMAPD_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	cat $(CYRUS-IMAPD_PATCHES) | patch -d $(BUILD_DIR)/$(CYRUS-IMAPD_DIR) -p1
	mv $(BUILD_DIR)/$(CYRUS-IMAPD_DIR) $(CYRUS-IMAPD_BUILD_DIR)
	cp -f $(CYRUS-IMAPD_SOURCE_DIR)/config.* $(CYRUS-IMAPD_BUILD_DIR)
	(cd $(CYRUS-IMAPD_BUILD_DIR); \
		autoconf; \
		$(TARGET_CONFIGURE_OPTS) \
		CC_FOR_BUILD=$(HOSTCC) \
		BUILD_CFLAGS="$(CYRUS-IMAPD_CPPFLAGS) -I.. -I../et" \
		BUILD_LDFLAGS="$(CYRUS-IMAPD_LDFLAGS)" \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(CYRUS-IMAPD_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(CYRUS-IMAPD_LDFLAGS)" \
		PERL=false \
		cyrus_cv_func_mmap_shared=yes \
		andrew_runpath_switch=none \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=$(OPTWARE_PREFIX) \
		--mandir=$(OPTWARE_PREFIX)/man \
		--sysconfdir=$(OPTWARE_PREFIX)/etc \
		--with-cyrus-prefix=$(OPTWARE_PREFIX)/libexec/cyrus \
		--with-statedir=$(OPTWARE_PREFIX)/var \
		--with-pidfile=$(OPTWARE_PREFIX)/var/run \
		--with-openssl=$(STAGING_PREFIX) \
		--with-sasl=$(STAGING_PREFIX) \
		--with-bdb=$(STAGING_PREFIX) \
		--with-auth=unix \
		--without-krb \
		--with-cyrus-user=mail \
		--with-cyrus-group=mail \
		--with-checkapop \
		--disable-nls \
		--with-com_err \
		--without-perl \
	)
ifneq (,$(filter perl, $(PACKAGES)))
	for i in perl/imap perl/sieve/managesieve; do \
	(cd $(CYRUS-IMAPD_BUILD_DIR)/$$i; \
		CPPFLAGS="$(STAGING_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS)" \
		BDB_LIB=-ldb-$(LIBDB_LIB_VERSION) \
		PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)/lib/perl5/site_perl" \
		$(PERL_HOSTPERL) Makefile.PL \
		$(TARGET_CONFIGURE_OPTS) \
		PREFIX=$(OPTWARE_PREFIX) \
	) \
	done
endif
	touch $(CYRUS-IMAPD_BUILD_DIR)/.configured

cyrus-imapd-unpack: $(CYRUS-IMAPD_BUILD_DIR)/.configured

$(CYRUS-IMAPD_BUILD_DIR)/.built: $(CYRUS-IMAPD_BUILD_DIR)/.configured
	rm -f $(CYRUS-IMAPD_BUILD_DIR)/.built
	PATH="`dirname $(TARGET_CC)`:$$PATH" \
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR)
ifneq (,$(filter perl, $(PACKAGES)))
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR)/perl/imap \
		$(PERL_INC) \
		PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)/lib/perl5/site_perl" \
		LD_RUN_PATH=$(OPTWARE_PREFIX)/lib \
		LDFLAGS="$(STAGING_LDFLAGS)"
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR)/perl/sieve \
		$(PERL_INC) \
		PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)/lib/perl5/site_perl" \
		LD_RUN_PATH=$(OPTWARE_PREFIX)/lib \
		LDFLAGS="$(STAGING_LDFLAGS)" 
endif
	touch $(CYRUS-IMAPD_BUILD_DIR)/.built

cyrus-imapd: $(CYRUS-IMAPD_BUILD_DIR)/.built

$(CYRUS-IMAPD_BUILD_DIR)/.staged: $(CYRUS-IMAPD_BUILD_DIR)/.built
	rm -f $(CYRUS-IMAPD_BUILD_DIR)/.staged
#	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR) DESTDIR=$(STAGING_DIR) install
	echo "Warning: the makefile target 'cyrus-imapd-stage' is not available."
	touch $(CYRUS-IMAPD_BUILD_DIR)/.staged

cyrus-imapd-stage: $(CYRUS-IMAPD_BUILD_DIR)/.staged

$(CYRUS-IMAPD_IPK_DIR)/CONTROL/control:
	@install -d $(CYRUS-IMAPD_IPK_DIR)/CONTROL
	@rm -f $@
	@echo "Package: cyrus-imapd" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(CYRUS-IMAPD_PRIORITY)" >>$@
	@echo "Section: $(CYRUS-IMAPD_SECTION)" >>$@
	@echo "Version: $(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)" >>$@
	@echo "Maintainer: $(CYRUS-IMAPD_MAINTAINER)" >>$@
	@echo "Source: $(CYRUS-IMAPD_SITE)/$(CYRUS-IMAPD_SOURCE)" >>$@
	@echo "Description: $(CYRUS-IMAPD_DESCRIPTION)" >>$@
	@echo "Depends: $(CYRUS-IMAPD_DEPENDS)" >>$@
	@echo "Suggests: cyrus-imapd-doc, $(CYRUS-IMAPD_SUGGESTS)" >>$@
	@echo "Conflicts: $(CYRUS-IMAPD_CONFLICTS)" >>$@

$(CYRUS-IMAPD_IPK_DIR)-doc/CONTROL/control:
	@install -d $(CYRUS-IMAPD_IPK_DIR)-doc/CONTROL
	@rm -f $@
	@echo "Package: cyrus-imapd-doc" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(CYRUS-IMAPD_PRIORITY)" >>$@
	@echo "Section: $(CYRUS-IMAPD_SECTION)" >>$@
	@echo "Version: $(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)" >>$@
	@echo "Maintainer: $(CYRUS-IMAPD_MAINTAINER)" >>$@
	@echo "Source: $(CYRUS-IMAPD_SITE)/$(CYRUS-IMAPD_SOURCE)" >>$@
	@echo "Description: $(CYRUS-IMAPD_DESCRIPTION)" >>$@
	@echo "Depends: " >>$@
	@echo "Suggests: man" >>$@
	@echo "Conflicts: " >>$@

$(CYRUS-IMAPD_IPK_DIR)-devel/CONTROL/control:
	@install -d $(CYRUS-IMAPD_IPK_DIR)-devel/CONTROL
	@rm -f $@
	@echo "Package: cyrus-imapd-devel" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(CYRUS-IMAPD_PRIORITY)" >>$@
	@echo "Section: $(CYRUS-IMAPD_SECTION)" >>$@
	@echo "Version: $(CYRUS-IMAPD_VERSION)-$(CYRUS-IMAPD_IPK_VERSION)" >>$@
	@echo "Maintainer: $(CYRUS-IMAPD_MAINTAINER)" >>$@
	@echo "Source: $(CYRUS-IMAPD_SITE)/$(CYRUS-IMAPD_SOURCE)" >>$@
	@echo "Description: $(CYRUS-IMAPD_DESCRIPTION)" >>$@
	@echo "Depends: $(CYRUS-IMAPD_DEPENDS)" >>$@
	@echo "Suggests: $(CYRUS-IMAPD_SUGGESTS)" >>$@
	@echo "Conflicts: $(CYRUS-IMAPD_CONFLICTS)" >>$@

$(CYRUS-IMAPD_IPK) $(CYRUS-IMAPD-DOC_IPK) $(CYRUS-IMAPD-DEVEL_IPK): $(CYRUS-IMAPD_BUILD_DIR)/.built
	rm -rf $(CYRUS-IMAPD_IPK_DIR)* $(BUILD_DIR)/cyrus-imapd_*_$(TARGET_ARCH).ipk
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/bin
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc
	install -m 644 $(CYRUS-IMAPD_SOURCE_DIR)/imapd.conf $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc/imapd.conf
	install -m 644 $(CYRUS-IMAPD_SOURCE_DIR)/cyrus.conf $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc/cyrus.conf
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/include/cyrus
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/libexec/cyrus/bin
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/run
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib
	install -d -m 750 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/db
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/log
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/msg
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/proc
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/ptclient
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/quota
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/sieve
	install -d -m 750 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/ssl/certs
	install -d -m 750 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/ssl/CA
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/socket
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/user
	(cd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/quota ; \
		for i in a b c d e f g h i j k l m n o p q r s t u v w x y z ; do install -d -m 755 $$i ; done \
	)
	(cd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/sieve ; \
		for i in a b c d e f g h i j k l m n o p q r s t u v w x y z ; do install -d -m 755 $$i ; done \
	)
	(cd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/lib/imap/user ; \
		for i in a b c d e f g h i j k l m n o p q r s t u v w x y z ; do install -d -m 755 $$i ; done \
	)
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/spool/imap
	install -d -m 750 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/spool/imap/mail
	install -d -m 750 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/spool/imap/news
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/spool/imap/stage.
	install -d -m 755 $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/var/spool/imap/user
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR) DESTDIR=$(CYRUS-IMAPD_IPK_DIR) install
	$(STRIP_COMMAND) $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/libexec/cyrus/bin/*
	$(STRIP_COMMAND) $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/lib/*.a
	$(STRIP_COMMAND) $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/bin/imtest
ifneq (,$(filter perl, $(PACKAGES)))
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR)/perl/imap DESTDIR=$(CYRUS-IMAPD_IPK_DIR) install
	$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR)/perl/sieve DESTDIR=$(CYRUS-IMAPD_IPK_DIR) install
	(cd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/lib/perl5/site_perl/$(PERL_VERSION)/$(PERL_ARCH)/auto/Cyrus ; \
		chmod +w IMAP/IMAP.so; \
		chmod +w SIEVE/managesieve/managesieve.so; \
		$(STRIP_COMMAND) IMAP/IMAP.so; \
		$(STRIP_COMMAND) SIEVE/managesieve/managesieve.so; \
		chmod -w IMAP/IMAP.so; \
		chmod -w SIEVE/managesieve/managesieve.so; \
	)
	rm -rf $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/lib/perl5/$(PERL_VERSION)
endif
	find $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/lib -type d -exec chmod go+rx {} \;
	find $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/man -type d -exec chmod go+rx {} \;
	install -d $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc/init.d
	install -m 755 $(CYRUS-IMAPD_SOURCE_DIR)/rc.cyrus-imapd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc/init.d/S59cyrus-imapd
	(cd $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/etc/init.d; \
		ln -s S59cyrus-imapd K41cyrus-imapd \
	)

# Split into the different packages
	rm -rf $(CYRUS-IMAPD_IPK_DIR)-doc
	install -d $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/share/doc/cyrus/html
	install -m 644 $(CYRUS-IMAPD_BUILD_DIR)/README $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/share/doc/cyrus/README
	install -m 644 $(CYRUS-IMAPD_BUILD_DIR)/doc/*.html $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/share/doc/cyrus/html/
	install -m 644 $(CYRUS-IMAPD_BUILD_DIR)/doc/murder.* $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/share/doc/cyrus/html/
	install -d install -d $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man
	mv $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/man/* $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man/
	mv $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man/man8/idled.8 $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man/man8/cyrus_idled.8
	mv $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man/man8/master.8 $(CYRUS-IMAPD_IPK_DIR)-doc$(OPTWARE_PREFIX)/man/man8/cyrus_master.8
	$(MAKE) $(CYRUS-IMAPD_IPK_DIR)-doc/CONTROL/control
	cd $(BUILD_DIR); $(IPKG_BUILD) $(CYRUS-IMAPD_IPK_DIR)-doc

	rm -rf $(CYRUS-IMAPD_IPK_DIR)-devel
	install -d $(CYRUS-IMAPD_IPK_DIR)-devel$(OPTWARE_PREFIX)/lib
	mv $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/lib/*.a $(CYRUS-IMAPD_IPK_DIR)-devel$(OPTWARE_PREFIX)/lib
	mv $(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX)/include $(CYRUS-IMAPD_IPK_DIR)-devel$(OPTWARE_PREFIX)/include
	$(MAKE) $(CYRUS-IMAPD_IPK_DIR)-devel/CONTROL/control
	cd $(BUILD_DIR); $(IPKG_BUILD) $(CYRUS-IMAPD_IPK_DIR)-devel

	$(MAKE) $(CYRUS-IMAPD_IPK_DIR)/CONTROL/control
ifeq ($(OPTWARE_TARGET),ds101g)
	install -m 644 $(CYRUS-IMAPD_SOURCE_DIR)/postinst.ds101g $(CYRUS-IMAPD_IPK_DIR)/CONTROL/postinst
else
	install -m 644 $(CYRUS-IMAPD_SOURCE_DIR)/postinst $(CYRUS-IMAPD_IPK_DIR)/CONTROL/postinst
endif
#	install -m 644 $(CYRUS-IMAPD_SOURCE_DIR)/prerm $(CYRUS-IMAPD_IPK_DIR)/CONTROL/prerm
	echo $(CYRUS-IMAPD_CONFFILES) | sed -e 's/ /\n/g' > $(CYRUS-IMAPD_IPK_DIR)/CONTROL/conffiles
	sed -i -e "s,/opt/,$(OPTWARE_PREFIX),g" \
		$(subst $(OPTWARE_PREFIX),$(CYRUS-IMAPD_IPK_DIR)$(OPTWARE_PREFIX),$(CYRUS-IMAPD_CONFFILES)) \
		$(CYRUS-IMAPD_IPK_DIR)/CONTROL/postinst
	cd $(BUILD_DIR); $(IPKG_BUILD) $(CYRUS-IMAPD_IPK_DIR)

cyrus-imapd-ipk: $(CYRUS-IMAPD_IPK) $(CYRUS-IMAPD-DOC_IPK) $(CYRUS-IMAPD-DEVEL_IPK)

cyrus-imapd-clean:
	-$(MAKE) -C $(CYRUS-IMAPD_BUILD_DIR) clean

cyrus-imapd-dirclean:
	rm -rf $(BUILD_DIR)/$(CYRUS-IMAPD_DIR) $(CYRUS-IMAPD_BUILD_DIR) \
	$(CYRUS-IMAPD_IPK_DIR) $(CYRUS-IMAPD_IPK_DIR)-doc $(CYRUS-IMAPD_IPK_DIR)-devel \
	$(CYRUS-IMAPD_IPK) $(CYRUS-IMAPD-DOC_IPK) $(CYRUS-IMAPD-DEVEL_IPK)

#
# Some sanity check for the package.
#
cyrus-imapd-check: $(CYRUS-IMAPD_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $(CYRUS-IMAPD_IPK) $(CYRUS-IMAPD-DOC_IPK) $(CYRUS-IMAPD-DEVEL_IPK)
