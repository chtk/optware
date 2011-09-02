###########################################################
#
# perl-algorithm-diff
#
###########################################################

PERL-ALGORITHM-DIFF_SITE=http://search.cpan.org/CPAN/authors/id/T/TY/TYEMQ
PERL-ALGORITHM-DIFF_VERSION=1.1901
PERL-ALGORITHM-DIFF_SOURCE=Algorithm-Diff-$(PERL-ALGORITHM-DIFF_VERSION).zip
PERL-ALGORITHM-DIFF_DIR=Algorithm-Diff-$(PERL-ALGORITHM-DIFF_VERSION)
PERL-ALGORITHM-DIFF_UNZIP=unzip
PERL-ALGORITHM-DIFF_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
PERL-ALGORITHM-DIFF_DESCRIPTION=Algorithm-Diff - Compute *intelligent* differences between two files / lists.
PERL-ALGORITHM-DIFF_SECTION=util
PERL-ALGORITHM-DIFF_PRIORITY=optional
PERL-ALGORITHM-DIFF_DEPENDS=perl
PERL-ALGORITHM-DIFF_SUGGESTS=
PERL-ALGORITHM-DIFF_CONFLICTS=

PERL-ALGORITHM-DIFF_IPK_VERSION=2

PERL-ALGORITHM-DIFF_CONFFILES=

PERL-ALGORITHM-DIFF_BUILD_DIR=$(BUILD_DIR)/perl-algorithm-diff
PERL-ALGORITHM-DIFF_SOURCE_DIR=$(SOURCE_DIR)/perl-algorithm-diff
PERL-ALGORITHM-DIFF_IPK_DIR=$(BUILD_DIR)/perl-algorithm-diff-$(PERL-ALGORITHM-DIFF_VERSION)-ipk
PERL-ALGORITHM-DIFF_IPK=$(BUILD_DIR)/perl-algorithm-diff_$(PERL-ALGORITHM-DIFF_VERSION)-$(PERL-ALGORITHM-DIFF_IPK_VERSION)_$(TARGET_ARCH).ipk

$(DL_DIR)/$(PERL-ALGORITHM-DIFF_SOURCE):
	$(WGET) -P $(DL_DIR) $(PERL-ALGORITHM-DIFF_SITE)/$(PERL-ALGORITHM-DIFF_SOURCE)

perl-algorithm-diff-source: $(DL_DIR)/$(PERL-ALGORITHM-DIFF_SOURCE) $(PERL-ALGORITHM-DIFF_PATCHES)

$(PERL-ALGORITHM-DIFF_BUILD_DIR)/.configured: $(DL_DIR)/$(PERL-ALGORITHM-DIFF_SOURCE) $(PERL-ALGORITHM-DIFF_PATCHES)
	$(MAKE) perl-stage
	rm -rf $(BUILD_DIR)/$(PERL-ALGORITHM-DIFF_DIR) $(PERL-ALGORITHM-DIFF_BUILD_DIR)
	$(PERL-ALGORITHM-DIFF_UNZIP) $(DL_DIR)/$(PERL-ALGORITHM-DIFF_SOURCE) -d $(BUILD_DIR)
#	cat $(PERL-ALGORITHM-DIFF_PATCHES) | patch -d $(BUILD_DIR)/$(PERL-ALGORITHM-DIFF_DIR) -p1
	mv $(BUILD_DIR)/$(PERL-ALGORITHM-DIFF_DIR) $(PERL-ALGORITHM-DIFF_BUILD_DIR)
	(cd $(PERL-ALGORITHM-DIFF_BUILD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS)" \
		PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)lib/perl5/site_perl" \
		$(PERL_HOSTPERL) Makefile.PL \
		PREFIX=$(OPTWARE_PREFIX)\
	)
	touch $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.configured

perl-algorithm-diff-unpack: $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.configured

$(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built: $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.configured
	rm -f $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built
	$(MAKE) -C $(PERL-ALGORITHM-DIFF_BUILD_DIR) \
	PERL5LIB="$(STAGING_DIR)$(OPTWARE_PREFIX)lib/perl5/site_perl"
	touch $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built

perl-algorithm-diff: $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built

$(PERL-ALGORITHM-DIFF_BUILD_DIR)/.staged: $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built
	rm -f $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.staged
	$(MAKE) -C $(PERL-ALGORITHM-DIFF_BUILD_DIR) DESTDIR=$(STAGING_DIR) install
	touch $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.staged

perl-algorithm-diff-stage: $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.staged

$(PERL-ALGORITHM-DIFF_IPK_DIR)/CONTROL/control:
	@install -d $(PERL-ALGORITHM-DIFF_IPK_DIR)/CONTROL
	@rm -f $@
	@echo "Package: perl-algorithm-diff" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(PERL-ALGORITHM-DIFF_PRIORITY)" >>$@
	@echo "Section: $(PERL-ALGORITHM-DIFF_SECTION)" >>$@
	@echo "Version: $(PERL-ALGORITHM-DIFF_VERSION)-$(PERL-ALGORITHM-DIFF_IPK_VERSION)" >>$@
	@echo "Maintainer: $(PERL-ALGORITHM-DIFF_MAINTAINER)" >>$@
	@echo "Source: $(PERL-ALGORITHM-DIFF_SITE)/$(PERL-ALGORITHM-DIFF_SOURCE)" >>$@
	@echo "Description: $(PERL-ALGORITHM-DIFF_DESCRIPTION)" >>$@
	@echo "Depends: $(PERL-ALGORITHM-DIFF_DEPENDS)" >>$@
	@echo "Suggests: $(PERL-ALGORITHM-DIFF_SUGGESTS)" >>$@
	@echo "Conflicts: $(PERL-ALGORITHM-DIFF_CONFLICTS)" >>$@

$(PERL-ALGORITHM-DIFF_IPK): $(PERL-ALGORITHM-DIFF_BUILD_DIR)/.built
	rm -rf $(PERL-ALGORITHM-DIFF_IPK_DIR) $(BUILD_DIR)/perl-algorithm-diff_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(PERL-ALGORITHM-DIFF_BUILD_DIR) DESTDIR=$(PERL-ALGORITHM-DIFF_IPK_DIR) install
	find $(PERL-ALGORITHM-DIFF_IPK_DIR)$(OPTWARE_PREFIX)-name 'perllocal.pod' -exec rm -f {} \;
	(cd $(PERL-ALGORITHM-DIFF_IPK_DIR)$(OPTWARE_PREFIX)lib/perl5 ; \
		find . -name '*.so' -exec chmod +w {} \; ; \
		find . -name '*.so' -exec $(STRIP_COMMAND) {} \; ; \
		find . -name '*.so' -exec chmod -w {} \; ; \
	)
	find $(PERL-ALGORITHM-DIFF_IPK_DIR)$(OPTWARE_PREFIX)-type d -exec chmod go+rx {} \;
	$(MAKE) $(PERL-ALGORITHM-DIFF_IPK_DIR)/CONTROL/control
	echo $(PERL-ALGORITHM-DIFF_CONFFILES) | sed -e 's/ /\n/g' > $(PERL-ALGORITHM-DIFF_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(PERL-ALGORITHM-DIFF_IPK_DIR)

perl-algorithm-diff-ipk: $(PERL-ALGORITHM-DIFF_IPK)

perl-algorithm-diff-clean:
	-$(MAKE) -C $(PERL-ALGORITHM-DIFF_BUILD_DIR) clean

perl-algorithm-diff-dirclean:
	rm -rf $(BUILD_DIR)/$(PERL-ALGORITHM-DIFF_DIR) $(PERL-ALGORITHM-DIFF_BUILD_DIR) $(PERL-ALGORITHM-DIFF_IPK_DIR) $(PERL-ALGORITHM-DIFF_IPK)
