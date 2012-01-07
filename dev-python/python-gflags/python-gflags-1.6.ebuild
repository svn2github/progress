# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="4-python"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="*-jython"

inherit distutils

DESCRIPTION="Google's Python argument parsing library."
HOMEPAGE="http://code.google.com/p/python-gflags/ http://pypi.python.org/pypi/python-gflags"
SRC_URI="http://python-gflags.googlecode.com/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND=""

# http://code.google.com/p/python-gflags/issues/detail?id=7
RESTRICT="test"

PYTHON_MODULES="gflags.py gflags_validators.py"

src_prepare() {
	distutils_src_prepare
	sed -e 's/data_files=\[("bin", \["gflags2man.py"\])\]/scripts=\["gflags2man.py"\]/' -i setup.py
}

src_test() {
	testing() {
		local exit_status="0" test
		for test in tests/*.py; do
			if ! PYTHONPATH="build-${PYTHON_ABI}/lib" "$(PYTHON)" "${test}"; then
				eerror "${test} failed with $(python_get_implementation_and_version)"
				exit_status="1"
			fi
		done

		return "${exit_status}"
	}
	python_execute_function testing
}
