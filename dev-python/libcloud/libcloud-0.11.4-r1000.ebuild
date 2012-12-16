# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_DEPEND="<<[ssl]>>"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="2.5 *-jython"
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="3.1"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils

DESCRIPTION="A standard Python library that abstracts away differences among multiple cloud provider APIs"
HOMEPAGE="http://libcloud.apache.org/ http://pypi.python.org/pypi/apache-libcloud"
SRC_URI="mirror://apache/${PN}/apache-${P}.tar.bz2"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="examples test"

RDEPEND="$(python_abi_depend virtual/python-json[external])"
DEPEND="${RDEPEND}
	test? ( $(python_abi_depend dev-python/mock) )"

S="${WORKDIR}/apache-${P}"

src_prepare() {
	distutils_src_prepare
	cp libcloud/test/secrets.py-dist libcloud/test/secrets.py || die "cp failed"
}

src_install() {
	distutils_src_install

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/libcloud/test"
	}
	python_execute_function -q delete_tests

	if use examples; then
		docinto examples
		dodoc example_*.py
	fi
}