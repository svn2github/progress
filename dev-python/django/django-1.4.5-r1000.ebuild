# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.*"
PYTHON_TESTS_RESTRICTED_ABIS="*-jython"

inherit bash-completion-r1 distutils versionator webapp

MY_P="Django-${PV}"

DESCRIPTION="High-level Python web framework"
HOMEPAGE="http://www.djangoproject.com/ https://github.com/django/django https://pypi.python.org/pypi/Django"
SRC_URI="https://www.djangoproject.com/m/releases/$(get_version_component_range 1-2)/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="doc mysql postgres sqlite test"

RDEPEND="$(python_abi_depend -e "2.5 *-jython" dev-python/imaging)
	$(python_abi_depend virtual/python-json[external])
	mysql? ( $(python_abi_depend -e "*-jython" dev-python/mysql-python) )
	postgres? ( $(python_abi_depend -e "*-jython *-pypy-*" dev-python/psycopg:2) )
	sqlite? ( $(python_abi_depend -e "*-jython" virtual/python-sqlite[external]) )"
DEPEND="${RDEPEND}
	doc? ( $(python_abi_depend dev-python/sphinx) )
	test? ( $(python_abi_depend -e "*-jython" virtual/python-sqlite[external]) )"

S="${WORKDIR}/${MY_P}"

WEBAPP_MANUAL_SLOT="yes"

pkg_setup() {
	python_pkg_setup
	webapp_pkg_setup
}

src_prepare() {
	distutils_src_prepare

	# Disable tests requiring network connection.
	sed \
		-e "s/test_correct_url_value_passes/_&/" \
		-e "s/test_correct_url_with_redirect/_&/" \
		-i tests/modeltests/validation/tests.py
	sed \
		-e "s/test_urlfield_3/_&/" \
		-e "s/test_urlfield_4/_&/" \
		-e "s/test_urlfield_10/_&/" \
		-i tests/regressiontests/forms/tests/fields.py
}

src_compile() {
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		pushd docs > /dev/null
		emake html
		popd > /dev/null
	fi
}

src_test() {
	testing() {
		# Tests have non-standard assumptions about PYTHONPATH and
		# don't work with usual "build-${PYTHON_ABI}/lib".
		python_execute PYTHONPATH="." "$(PYTHON)" tests/runtests.py --settings=test_sqlite -v1
	}
	python_execute_function testing
}

src_install() {
	distutils_src_install

	newbashcomp extras/django_bash_completion ${PN}

	if use doc; then
		dohtml -r docs/_build/html/
	fi

	insinto "${MY_HTDOCSDIR#${EPREFIX}}"
	doins -r django/contrib/admin/static/admin/*

	webapp_src_install
}

pkg_preinst() {
	:
}

pkg_postinst() {
	distutils_pkg_postinst

	elog "A copy of the admin media is available to"
	elog "webapp-config for installation in a webroot,"
	elog "as well as the traditional location in python's"
	elog "site-packages dir for easy development"
	ewarn "If you build Django ${PV} without USE=\"vhosts\""
	ewarn "webapp-config will automatically install the"
	ewarn "admin media into the localhost webroot."
}
