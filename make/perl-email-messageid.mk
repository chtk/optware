###########################################################
#
# perl-email-messageid
#
###########################################################

PERL-EMAIL-MESSAGEID_SITE=http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS
PERL-EMAIL-MESSAGEID_VERSION=1.401
PERL-EMAIL-MESSAGEID_SOURCE=Email-MessageID-$(PERL-EMAIL-MESSAGEID_VERSION).tar.gz
PERL-EMAIL-MESSAGEID_DIR=Email-MessageID-$(PERL-EMAIL-MESSAGEID_VERSION)
PERL-EMAIL-MESSAGEID_UNZIP=zcat
PERL-EMAIL-MESSAGEID_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
PERL-EMAIL-MESSAGEID_DESCRIPTION=Generate world unique message-ids.
PERL-EMAIL-MESSAGEID_SECTION=email
PERL-EMAIL-MESSAGEID_PRIORITY=optional
PERL-EMAIL-MESSAGEID_DEPENDS=perl-email-address
PERL-EMAIL-MESSAGEID_SUGGESTS=
PERL-EMAIL-MESSAGEID_CONFLICTS=

PERL-EMAIL-MESSAGEID_IPK_VERSION=1

PERL-EMAIL-MESSAGEID_CONFFILES=

PERL-EMAIL-MESSAGEID_BUILD_DIR=$(BUILD_DIR)/perl-email-messageid
PERL-EMAIL-MESSAGEID_SOURCE_DIR=$(SOURCE_DIR)/perl-email-messageid
PERL-EMAIL-MESSAGEID_IPK_DIR=$(BUILD_DIR)/perl-email-messageid-$(PERL-EMAIL-MESSAGEID_VERSION)-ipk
PERL-EMAIL-MESSAGEID_IPK=$(BUILD_DIR)/perl-email-messageid_$(PERL-EMAIL-MESSAGEID_VERSION)-$(PERL-EMAIL-MESSAGEID_IPK_VERSION)_$(TARGET_ARCH).ipk

$(DL_DIR)/$(PERL-EMAIL-MESSAGEID_SOURCE):
	$(WGET) -P $(@D) $(PERL-EMAIL-MESSAGEID_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

perl-email-messageid-source: $(DL_DIR)/$(PERL-EMAIL-MESSAGEID_SOURCE) $(PERL-EMAIL-MESSAGEID_PATCHES)

$(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.configured: $(DL_DIR)/$(PERL-EMAIL-MESSAGEID_SOURCE) $(PERL-EMAIL-MESSAGEID_PATCHES) make/perl-email-messageid.mk
	rm -rf $(BUILD_DIR)/$(PERL-EMAIL-MESSAGEID_DIR) $(@D)
	$(PERL-EMAIL-MESSAGEID_UNZIP) $(DL_DIR)/$(PERL-EMAIL-MESSAGEID_SOURCE) | tar -C $(BUILD_DIR) -xvf -
#	cat $(PERL-EMAIL-MESSAGEID_PATCHES) | patch -d $(BUILD_DIR)/$(PERL-EMAIL-MESSAGEID_DIR) -p1
	mv $(BUILD_DIR)/$(PERL-EMAIL-MESSAGEID_DIR) $(@D)
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS)" \
		PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)lib/perl5/site_perl" \
		$(PERL_HOSTPERL) Makefile.PL \
		PREFIX=$(OPTWARE_PREFIX)\
	)
	touch $@

perl-email-messageid-unpack: $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.configured

$(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.built: $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D) \
	PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)lib/perl5/site_perl"
	touch $@

perl-email-messageid: $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.built

$(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.staged: $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.built
	rm -f $@
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
	touch $@

perl-email-messageid-stage: $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.staged

$(PERL-EMAIL-MESSAGEID_IPK_DIR)/CONTROL/control:
	@install -d $(@D)
	@rm -f $@
	@echo "Package: perl-email-messageid" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(PERL-EMAIL-MESSAGEID_PRIORITY)" >>$@
	@echo "Section: $(PERL-EMAIL-MESSAGEID_SECTION)" >>$@
	@echo "Version: $(PERL-EMAIL-MESSAGEID_VERSION)-$(PERL-EMAIL-MESSAGEID_IPK_VERSION)" >>$@
	@echo "Maintainer: $(PERL-EMAIL-MESSAGEID_MAINTAINER)" >>$@
	@echo "Source: $(PERL-EMAIL-MESSAGEID_SITE)/$(PERL-EMAIL-MESSAGEID_SOURCE)" >>$@
	@echo "Description: $(PERL-EMAIL-MESSAGEID_DESCRIPTION)" >>$@
	@echo "Depends: $(PERL-EMAIL-MESSAGEID_DEPENDS)" >>$@
	@echo "Suggests: $(PERL-EMAIL-MESSAGEID_SUGGESTS)" >>$@
	@echo "Conflicts: $(PERL-EMAIL-MESSAGEID_CONFLICTS)" >>$@

$(PERL-EMAIL-MESSAGEID_IPK): $(PERL-EMAIL-MESSAGEID_BUILD_DIR)/.built
	rm -rf $(PERL-EMAIL-MESSAGEID_IPK_DIR) $(BUILD_DIR)/perl-email-messageid_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(PERL-EMAIL-MESSAGEID_BUILD_DIR) DESTDIR=$(PERL-EMAIL-MESSAGEID_IPK_DIR) install
	find $(PERL-EMAIL-MESSAGEID_IPK_DIR)$(OPTWARE_PREFIX)-name 'perllocal.pod' -exec rm -f {} \;
	$(MAKE) $(PERL-EMAIL-MESSAGEID_IPK_DIR)/CONTROL/control
	echo $(PERL-EMAIL-MESSAGEID_CONFFILES) | sed -e 's/ /\n/g' > $(PERL-EMAIL-MESSAGEID_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(PERL-EMAIL-MESSAGEID_IPK_DIR)

perl-email-messageid-ipk: $(PERL-EMAIL-MESSAGEID_IPK)

perl-email-messageid-clean:
	-$(MAKE) -C $(PERL-EMAIL-MESSAGEID_BUILD_DIR) clean

perl-email-messageid-dirclean:
	rm -rf $(BUILD_DIR)/$(PERL-EMAIL-MESSAGEID_DIR) $(PERL-EMAIL-MESSAGEID_BUILD_DIR) $(PERL-EMAIL-MESSAGEID_IPK_DIR) $(PERL-EMAIL-MESSAGEID_IPK)
