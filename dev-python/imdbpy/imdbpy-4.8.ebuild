# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4-python"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"

inherit distutils eutils

MY_PN="IMDbPY"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python package to access the IMDb movie database"
HOMEPAGE="http://imdbpy.sourceforge.net/ http://pypi.python.org/pypi/IMDbPY"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ppc ~sparc ~x86"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND=""

S="${WORKDIR}/${MY_PN}-${PV}"

DISTUTILS_GLOBAL_OPTIONS=("*-jython --without-cutils")
DOCS="docs/*"
PYTHON_MODULES="imdb"

src_prepare() {
	distutils_src_prepare
	epatch "${FILESDIR}/${PN}-4.6-data_location.patch"
	epatch "${FILESDIR}/${P}-locales_location.patch"
}
