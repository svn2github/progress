# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_ABI_TYPE="multiple"
PYTHON_BDEPEND="test? ( <<[{*-cpython *-pypy}sqlite]>> )"
PYTHON_DEPEND="<<[{*-cpython *-pypy}sqlite?]>>"
PYTHON_RESTRICTED_ABIS="3.1"
PYTHON_TESTS_RESTRICTED_ABIS="*-jython"
# 3.[4-9]: https://code.djangoproject.com/ticket/21721
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="3.[4-9]"
WEBAPP_NO_AUTO_INSTALL="yes"

inherit bash-completion-r1 distutils versionator webapp

MY_P="Django-${PV}"

DESCRIPTION="High-level Python web framework"
HOMEPAGE="https://www.djangoproject.com/ https://github.com/django/django https://pypi.python.org/pypi/Django"
SRC_URI="https://www.djangoproject.com/m/releases/$(get_version_component_range 1-2)/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="doc sqlite test"

RDEPEND="$(python_abi_depend -e "*-jython" dev-python/imaging)"
DEPEND="${RDEPEND}
	doc? ( $(python_abi_depend dev-python/sphinx) )"

S="${WORKDIR}/${MY_P}"

WEBAPP_MANUAL_SLOT="yes"

pkg_setup() {
	python_pkg_setup
	webapp_pkg_setup
}

src_prepare() {
	distutils_src_prepare

	# Disable invalid warning.
	sed -e "s/overlay_warning = True/overlay_warning = False/" -i setup.py

	# Avoid test failures with unittest2 and Python 3.
	sed -e "s/from unittest2 import \*/raise ImportError/" -i django/utils/unittest/__init__.py

	# Fix generation of documentation with Python 3.
	# https://github.com/django/django/commit/a5733fcd7be7adb8b236825beff4ccda19900f9e
	sed -e "s/with open(outfilename, 'wb') as fp:/with open(outfilename, 'w') as fp:/" -i docs/_ext/djangodocs.py

	# Fix django.contrib.markup.tests.Templates.test_textile() with Python 3.
	sed -e "s/textile.textile(force_bytes(value)/textile.textile(force_text(value) if __import__('sys').version_info[0] >= 3 else force_bytes(value)/" -i django/contrib/markup/templatetags/markup.py

	# Fix regressiontests.templates.tests.Templates.test_templates() with NumPy >=1.9.
	# https://code.djangoproject.com/ticket/23489
	# https://github.com/django/django/commit/12809e160995eb617fe394c75e5b9f3211c056ff
	sed -e "s/except (TypeError, AttributeError, KeyError, ValueError):$/except (TypeError, AttributeError, KeyError, ValueError, IndexError):/" -i django/template/base.py

	# Fix encoding declaration.
	sed -e "1{h;d};2G" -i tests/regressiontests/utils/jslex.py

	# Disable failing tests.
	# https://code.djangoproject.com/ticket/21092
	sed -e "s/test_runner_deprecation_verbosity_zero/_&/" -i tests/regressiontests/test_runner/tests.py
	# https://code.djangoproject.com/ticket/21093
	sed -e "s/test_dont_base64_encode/_&/" -i tests/regressiontests/mail/tests.py
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
		# Tests have non-standard assumptions about PYTHONPATH and work not with usual "build-${PYTHON_ABI}/lib".
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

pkg_postinst() {
	distutils_pkg_postinst

	elog "A copy of the admin media is available to webapp-config for installation in a webroot,"
	elog "as well as the traditional location in Python's site-packages directory for easy development."
	webapp_pkg_postinst
}
