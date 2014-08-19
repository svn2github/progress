# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython"
PYTHON_TESTS_RESTRICTED_ABIS="2.6"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils

DESCRIPTION="Python Git Library"
HOMEPAGE="http://www.samba.org/~jelmer/dulwich/ https://github.com/jelmer/dulwich https://pypi.python.org/pypi/dulwich"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="doc examples ssh"

RDEPEND="ssh? ( $(python_abi_depend -e "*-pypy-*" dev-python/paramiko) )"
DEPEND="${RDEPEND}
	$(python_abi_depend dev-python/setuptools)
	doc? ( $(python_abi_depend dev-python/sphinx) )"

src_compile() {
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		pushd docs > /dev/null
		emake html
		popd > /dev/null
	fi
}

src_install() {
	distutils_src_install
	python_clean_installation_image

	delete_tests() {
		rm -r "${ED}$(python_get_sitedir)/dulwich/"{contrib/test_*.py,tests}
	}
	python_execute_function -q delete_tests

	if use doc; then
		dohtml -r docs/build/html/
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
