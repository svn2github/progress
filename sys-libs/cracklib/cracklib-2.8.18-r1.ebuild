# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"
PYTHON_DEPEND="python? ( <<>> )"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython"

inherit eutils distutils libtool toolchain-funcs

MY_P=${P/_}
DESCRIPTION="Password Checking Library"
HOMEPAGE="http://sourceforge.net/projects/cracklib"
SRC_URI="mirror://sourceforge/cracklib/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="nls python static-libs"

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	python? ( $(python_abi_depend dev-python/setuptools) )"

S=${WORKDIR}/${MY_P}

PYTHON_MODULES="cracklib.py"
do_python() {
	pushd python > /dev/null || die
	distutils_src_${EBUILD_PHASE}
	popd > /dev/null
}

pkg_setup() {
	# workaround #195017
	if has unmerge-orphans ${FEATURES} && has_version "<${CATEGORY}/${PN}-2.8.10" ; then
		eerror "Upgrade path is broken with FEATURES=unmerge-orphans"
		eerror "Please run: FEATURES=-unmerge-orphans emerge cracklib"
		die "Please run: FEATURES=-unmerge-orphans emerge cracklib"
	fi

	use python && python_pkg_setup
}

src_prepare() {
	elibtoolize #269003
	use python && do_python
}

src_configure() {
	econf \
		--with-default-dict='$(libdir)/cracklib_dict' \
		--without-python \
		$(use_enable nls) \
		$(use_enable static-libs static)
}

src_compile() {
	default
	use python && do_python
}

src_install() {
	emake DESTDIR="${D}" install || die
	use static-libs || rm -f "${ED}"/usr/lib*/libcrack.la
	rm -r "${ED}"/usr/share/cracklib

	use python && do_python

	# move shared libs to /
	gen_usr_ldscript -a crack

	insinto /usr/share/dict
	doins dicts/cracklib-small || die

	dodoc AUTHORS ChangeLog NEWS README*
}

pkg_postinst() {
	if [[ ${ROOT} == "/" ]] ; then
		ebegin "Regenerating cracklib dictionary"
		create-cracklib-dict /usr/share/dict/* > /dev/null
		eend $?
	fi

	use python && distutils_pkg_postinst
}

pkg_postrm() {
	use python && distutils_pkg_postrm
}
