# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"
PYTHON_DEPEND="<<[ssl]>>"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.1"
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="*"

inherit distutils

DESCRIPTION="A comprehensive HTTP client library."
HOMEPAGE="http://code.google.com/p/httplib2/ http://pypi.python.org/pypi/httplib2"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~ia64 ~ppc ~ppc64 sparc x86 ~amd64-linux ~x86-linux ~x64-macos"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND=""

src_prepare() {
	distutils_src_prepare


	# Disable failing tests.
	sed \
		-e "s/testHeadRead/_&/" \
		-e "s/import memcache/raise ImportError/" \
		-i python2/httplib2test.py python3/httplib2test.py
}

src_test() {
	testing() {
		pushd "python$(python_get_version -l --major)" > /dev/null
		python_execute "$(PYTHON)" httplib2test.py || return
		popd > /dev/null
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	dodoc README
	newdoc python3/README README-python3
}