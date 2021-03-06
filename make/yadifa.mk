###########################################################
#
# yadifa
#
###########################################################

# You must replace "yadifa" and "YADIFA" with the lower case name and
# upper case name of your new package.  Some places below will say
# "Do not change this" - that does not include this global change,
# which must always be done to ensure we have unique names.

#
# YADIFA_VERSION, YADIFA_SITE and YADIFA_SOURCE define
# the upstream location of the source code for the package.
# YADIFA_DIR is the directory which is created when the source
# archive is unpacked.
# YADIFA_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
# Please make sure that you add a description, and that you
# list all your packages' dependencies, seperated by commas.
# 
# If you list yourself as MAINTAINER, please give a valid email
# address, and indicate your irc nick if it cannot be easily deduced
# from your name or email address.  If you leave MAINTAINER set to
# "NSLU2 Linux" other developers will feel free to edit.
#
YADIFA_SITE=http://cdn.yadifa.eu/sites/default/files/releases
YADIFA_VERSION=1.0.0-2075
YADIFA_SOURCE=yadifa-$(YADIFA_VERSION).tar.gz
YADIFA_DIR=yadifa-$(YADIFA_VERSION)
YADIFA_UNZIP=zcat
YADIFA_MAINTAINER=Bob Novas <bob@shinkuro.com>
YADIFA_DESCRIPTION=YADIFA is a nameserver implementation developed from scratch.
YADIFA_SECTION=net
YADIFA_PRIORITY=optional
YADIFA_DEPENDS=openssl-devel, openssl
YADIFA_SUGGESTS=
YADIFA_CONFLICTS=

#
# YADIFA_IPK_VERSION should be incremented when the ipk changes.
#
YADIFA_IPK_VERSION=1

#
# YADIFA_CONFFILES should be a list of user-editable files
#YADIFA_CONFFILES=/opt/etc/yadifa.conf /opt/etc/init.d/SXXyadifa

#
# YADIFA_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
YADIFA_PATCHES=$(YADIFA_SOURCE_DIR)/configure.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
YADIFA_CPPFLAGS=-Os -std=gnu99
YADIFA_LDFLAGS=

#
# YADIFA_BUILD_DIR is the directory in which the build is done.
# YADIFA_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# YADIFA_IPK_DIR is the directory in which the ipk is built.
# YADIFA_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
YADIFA_BUILD_DIR=$(BUILD_DIR)/yadifa
YADIFA_SOURCE_DIR=$(SOURCE_DIR)/yadifa
YADIFA_IPK_DIR=$(BUILD_DIR)/yadifa-$(YADIFA_VERSION)-ipk
YADIFA_IPK=$(BUILD_DIR)/yadifa_$(YADIFA_VERSION)-$(YADIFA_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: yadifa-source yadifa-unpack yadifa yadifa-stage yadifa-ipk yadifa-clean yadifa-dirclean yadifa-check

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(YADIFA_SOURCE):
	$(WGET) -P $(@D) $(YADIFA_SITE)/$(@F) || \
	$(WGET) -P $(@D) $(SOURCES_NLO_SITE)/$(@F)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
yadifa-source: $(DL_DIR)/$(YADIFA_SOURCE) $(YADIFA_PATCHES)

#
# This target unpacks the source code in the build directory.
# If the source archive is not .tar.gz or .tar.bz2, then you will need
# to change the commands here.  Patches to the source code are also
# applied in this target as required.
#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
# If the package uses  GNU libtool, you should invoke $(PATCH_LIBTOOL) as
# shown below to make various patches to it.
#
$(YADIFA_BUILD_DIR)/.configured: $(DL_DIR)/$(YADIFA_SOURCE) $(YADIFA_PATCHES) make/yadifa.mk
	$(MAKE) OPENSSL_VERSION=1.0.1 openssl-stage
	rm -rf $(BUILD_DIR)/$(YADIFA_DIR) $(@D)
	$(YADIFA_UNZIP) $(DL_DIR)/$(YADIFA_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	if test -n "$(YADIFA_PATCHES)" ; \
		then cat $(YADIFA_PATCHES) | \
		patch -d $(BUILD_DIR)/$(YADIFA_DIR) -p0 ; \
	fi
	if test "$(BUILD_DIR)/$(YADIFA_DIR)" != "$(@D)" ; \
		then mv $(BUILD_DIR)/$(YADIFA_DIR) $(@D) ; \
	fi
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(YADIFA_CPPFLAGS)" \
		LDFLAGS="$(YADIFA_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=/opt \
		--with-openssl=$(STAGING_DIR)/opt \
	)
	$(PATCH_LIBTOOL) $(@D)/libtool
	touch $@

yadifa-unpack: $(YADIFA_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(YADIFA_BUILD_DIR)/.built: $(YADIFA_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D)
	touch $@

#
# This is the build convenience target.
#
yadifa: $(YADIFA_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(YADIFA_BUILD_DIR)/.staged: $(YADIFA_BUILD_DIR)/.built
	rm -f $@
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
	touch $@

yadifa-stage: $(YADIFA_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/yadifa
#
$(YADIFA_IPK_DIR)/CONTROL/control:
	@install -d $(@D)
	@rm -f $@
	@echo "Package: yadifa" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(YADIFA_PRIORITY)" >>$@
	@echo "Section: $(YADIFA_SECTION)" >>$@
	@echo "Version: $(YADIFA_VERSION)-$(YADIFA_IPK_VERSION)" >>$@
	@echo "Maintainer: $(YADIFA_MAINTAINER)" >>$@
	@echo "Source: $(YADIFA_SITE)/$(YADIFA_SOURCE)" >>$@
	@echo "Description: $(YADIFA_DESCRIPTION)" >>$@
	@echo "Depends: $(YADIFA_DEPENDS)" >>$@
	@echo "Suggests: $(YADIFA_SUGGESTS)" >>$@
	@echo "Conflicts: $(YADIFA_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(YADIFA_IPK_DIR)/opt/sbin or $(YADIFA_IPK_DIR)/opt/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(YADIFA_IPK_DIR)/opt/{lib,include}
# Configuration files should be installed in $(YADIFA_IPK_DIR)/opt/etc/yadifa/...
# Documentation files should be installed in $(YADIFA_IPK_DIR)/opt/doc/yadifa/...
# Daemon startup scripts should be installed in $(YADIFA_IPK_DIR)/opt/etc/init.d/S??yadifa
#
# You may need to patch your application to make it use these locations.
#
$(YADIFA_IPK): $(YADIFA_BUILD_DIR)/.built
	rm -rf $(YADIFA_IPK_DIR) $(BUILD_DIR)/yadifa_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(YADIFA_BUILD_DIR) DESTDIR=$(YADIFA_IPK_DIR) install-strip
#	install -d $(YADIFA_IPK_DIR)/opt/etc/
#	install -m 644 $(YADIFA_SOURCE_DIR)/yadifa.conf $(YADIFA_IPK_DIR)/opt/etc/yadifa.conf
#	install -d $(YADIFA_IPK_DIR)/opt/etc/init.d
#	install -m 755 $(YADIFA_SOURCE_DIR)/rc.yadifa $(YADIFA_IPK_DIR)/opt/etc/init.d/SXXyadifa
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(YADIFA_IPK_DIR)/opt/etc/init.d/SXXyadifa
	$(MAKE) $(YADIFA_IPK_DIR)/CONTROL/control
#	install -m 755 $(YADIFA_SOURCE_DIR)/postinst $(YADIFA_IPK_DIR)/CONTROL/postinst
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(YADIFA_IPK_DIR)/CONTROL/postinst
#	install -m 755 $(YADIFA_SOURCE_DIR)/prerm $(YADIFA_IPK_DIR)/CONTROL/prerm
#	sed -i -e '/^#!/aOPTWARE_TARGET=${OPTWARE_TARGET}' $(YADIFA_IPK_DIR)/CONTROL/prerm
#	if test -n "$(UPD-ALT_PREFIX)"; then \
		sed -i -e '/^[ 	]*update-alternatives /s|update-alternatives|$(UPD-ALT_PREFIX)/bin/&|' \
			$(YADIFA_IPK_DIR)/CONTROL/postinst $(YADIFA_IPK_DIR)/CONTROL/prerm; \
	fi
	echo $(YADIFA_CONFFILES) | sed -e 's/ /\n/g' > $(YADIFA_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(YADIFA_IPK_DIR)
	$(WHAT_TO_DO_WITH_IPK_DIR) $(YADIFA_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
yadifa-ipk: $(YADIFA_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
yadifa-clean:
	rm -f $(YADIFA_BUILD_DIR)/.built
	-$(MAKE) -C $(YADIFA_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
yadifa-dirclean:
	rm -rf $(BUILD_DIR)/$(YADIFA_DIR) $(YADIFA_BUILD_DIR) $(YADIFA_IPK_DIR) $(YADIFA_IPK)
#
#
# Some sanity check for the package.
#
yadifa-check: $(YADIFA_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $^
