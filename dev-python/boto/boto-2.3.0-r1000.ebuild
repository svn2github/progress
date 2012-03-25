# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"

inherit distutils

DESCRIPTION="Amazon Web Services Library"
HOMEPAGE="https://github.com/boto/boto http://pypi.python.org/pypi/boto"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~ppc sparc x86 ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

RDEPEND="$(python_abi_depend dev-python/m2crypto)"
DEPEND="${RDEPEND}
	$(python_abi_depend dev-python/setuptools)"

src_install() {
	distutils_src_install

	delete_tests() {
		find "${ED}$(python_get_sitedir)/boto" -name "test_*.py" -delete
	}
	python_execute_function -q delete_tests
}
