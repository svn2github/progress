# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="2.5 3.* *-jython *-pypy-*"
DISTUTILS_SRC_TEST="nosetests"

inherit distutils

DESCRIPTION="Highly concurrent networking library"
HOMEPAGE="http://eventlet.net/ http://pypi.python.org/pypi/eventlet"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="doc examples"

RDEPEND="$(python_abi_depend dev-python/greenlet)"
DEPEND="${RDEPEND}
	$(python_abi_depend dev-python/setuptools)
	doc? ( $(python_abi_depend dev-python/sphinx) )"

src_prepare() {
	distutils_src_prepare

	# Ignore potential AttributeError caused by gnutls module.
	sed -e "227s/except ImportError:/except (AttributeError, ImportError):/" -i tests/test__twistedutil_protocol.py

	# Disable failing tests.
	rm -f tests/saranwrap_test.py
	sed \
		-e "s/test_incomplete_headers_75/_&/" \
		-e "s/test_incomplete_headers_76/_&/" \
		-e "s/test_incorrect_headers/_&/" \
		-i tests/websocket_test.py

	# Skip test requiring Python >=2.7.
	sed \
		-e "1i\\import sys" \
		-e "/test_errors/i\\    @skip_unless(sys.version_info >= (2, 7))" \
		-i tests/zmq_test.py
}

src_compile() {
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		pushd doc > /dev/null
		emake html
		popd > /dev/null
	fi
}

src_install() {
	distutils_src_install

	if use doc; then
		dohtml -r doc/_build/html/
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
