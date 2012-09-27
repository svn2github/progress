# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="2.5 *-jython *-pypy-*"

# XXX: Is the alternatives stuff needed anymore?
inherit alternatives autotools eutils gnome2 python virtualx

DESCRIPTION="GLib's GObject library bindings for Python"
HOMEPAGE="http://www.pygtk.org/"

LICENSE="LGPL-2.1+"
SLOT="3"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+cairo examples test +threads" # doc
REQUIRED_USE="test? ( cairo )"

COMMON_DEPEND=">=dev-libs/glib-2.24.0:2
	>=dev-libs/gobject-introspection-1.29
	virtual/libffi
	cairo? ( $(python_abi_depend ">=dev-python/pycairo-1.10.0") )"
DEPEND="${COMMON_DEPEND}
	test? (
		dev-libs/atk[introspection]
		media-fonts/font-cursor-misc
		media-fonts/font-misc-misc
		x11-libs/gdk-pixbuf:2[introspection]
		x11-libs/gtk+:3[introspection]
		x11-libs/pango[introspection] )
	virtual/pkgconfig"
# docs disabled for now per upstream default since they are very out of date
#	doc? (
#		app-text/docbook-xml-dtd:4.1.2
#		dev-libs/libxslt
#		>=app-text/docbook-xsl-stylesheets-1.70.1 )

# We now disable introspection support in slot 2 per upstream recommendation
# (see https://bugzilla.gnome.org/show_bug.cgi?id=642048#c9); however,
# older versions of slot 2 installed their own site-packages/gi, and
# slot 3 will collide with them.
RDEPEND="${COMMON_DEPEND}
	!<dev-python/pygtk-2.13
	!<dev-python/pygobject-2.28.6-r50:2[introspection]"

pkg_setup() {
	DOCS="AUTHORS ChangeLog* NEWS README"
	# Hard-enable libffi support since both gobject-introspection and
	# glib-2.29.x rdepend on it anyway
	G2CONF="${G2CONF}
		--disable-dependency-tracking
		--with-ffi
		$(use_enable cairo)
		$(use_enable threads thread)"

	python_pkg_setup
}

src_prepare() {
	# Do not build tests if unneeded, bug #226345
	epatch "${FILESDIR}/${PN}-2.90.1-make_check.patch"

	# FIXME: disable tests that require >=gobject-introspection-1.31
	epatch "${FILESDIR}/${PN}-3.0.3-disable-new-gi-tests.patch"

	# https://bugzilla.gnome.org/show_bug.cgi?id=666852
	epatch "${FILESDIR}/${PN}-3.0.3-tests-python3.patch"

	python_clean_py-compile_files

	eautoreconf
	gnome2_src_prepare

	python_copy_sources

	preparation() {
		if [[ "$(python_get_version -l)" == "2.6" ]]; then
			sed -e "/# https:\/\/bugzilla.gnome.org\/show_bug.cgi?id=656554/,+13d" -i tests/test_everything.py
		fi
	}
	python_execute_function -q -s preparation
}

src_configure() {
	configuration() {
		PYTHON="$(PYTHON)" gnome2_src_configure
	}
	python_execute_function -s configuration
}

src_compile() {
	python_src_compile
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	export GIO_USE_VFS="local" # prevents odd issues with deleting ${T}/.gvfs

	testing() {
		export XDG_CACHE_HOME="${T}/${PYTHON_ABI}"
		Xemake check PYTHON=$(PYTHON -a)
		unset XDG_CACHE_HOME
	}
	python_execute_function -s testing
	unset GIO_USE_VFS
}

src_install() {
	python_execute_function -s gnome2_src_install
	python_clean_installation_image

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}

pkg_postinst() {
	python_mod_optimize gi
}

pkg_postrm() {
	python_mod_cleanup gi
}
