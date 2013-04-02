# Copyright owners: Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: autotools-multilib.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @BLURB: autotools-utils wrapper for multilib builds
# @DESCRIPTION:
# The autotools-multilib.eclass is an autotools-utils.eclass(5) wrapper
# introducing support for building for more than one ABI (multilib).
#
# Inheriting this eclass sets the USE flags and exports autotools-utils
# phase function wrappers which build the package for each supported ABI
# when the relevant flag is enabled. Other than that, it works like
# regular autotools-utils.
#
# Note that the multilib support requires out-of-source builds to be
# enabled. Thus, it is impossible to use AUTOTOOLS_IN_SOURCE_BUILD with
# it.

# EAPI=5 is required for meaningful MULTILIB_USEDEP.
case ${EAPI:-0} in
	5|5-progress) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

if [[ ${AUTOTOOLS_IN_SOURCE_BUILD} ]]; then
	die "${ECLASS}: multilib support requires out-of-source builds."
fi

inherit autotools-utils multilib-build

EXPORT_FUNCTIONS src_prepare src_configure src_compile src_test src_install

# @ECLASS-VARIABLE: MULTILIB_WRAPPED_HEADERS
# @DESCRIPTION:
# A list of headers to wrap for multilib support. The listed headers
# will be moved to a non-standard location and replace with a file
# including them conditionally to current ABI.
#
# This variable has to be a bash array. Paths shall be relative to
# installation root (${ED}), and name regular files. Recursive wrapping
# is not supported.
#
# Please note that header wrapping is *discouraged*. It is preferred to
# install all headers in a subdirectory of libdir and use pkg-config to
# locate the headers. Some C preprocessors will not work with wrapped
# headers.
#
# Example:
# @CODE
# MULTILIB_WRAPPED_HEADERS=(
#	/usr/include/foobar/config.h
# )
# @CODE

autotools-multilib_src_prepare() {
	autotools-utils_src_prepare "${@}"
}

autotools-multilib_src_configure() {
	multilib_parallel_foreach_abi autotools-utils_src_configure "${@}"
}

autotools-multilib_src_compile() {
	multilib_foreach_abi autotools-utils_src_compile "${@}"
}

autotools-multilib_src_test() {
	multilib_foreach_abi autotools-utils_src_test "${@}"
}

_autotools-multilib_wrap_headers() {
	debug-print-function ${FUNCNAME} "$@"
	local f

	for f in "${MULTILIB_WRAPPED_HEADERS[@]}"; do
		# drop leading slash if it's there
		f=${f#/}

		if [[ ${f} != usr/include/* ]]; then
			die "Wrapping headers outside of /usr/include is not supported at the moment."
		fi
		# and then usr/include
		f=${f#usr/include}

		local dir=${f%/*}

		# $CHOST shall be set by multilib_toolchain_setup
		dodir "/tmp/multilib-include/${CHOST}${dir}"
		mv "${ED}/usr/include${f}" "${ED}/tmp/multilib-include/${CHOST}${dir}/" || die

		if [[ ! -f ${ED}/tmp/multilib-include${f} ]]; then
			dodir "/tmp/multilib-include${dir}"
			# a generic template
			cat > "${ED}/tmp/multilib-include${f}" <<_EOF_ || die
/* This file is auto-generated by autotools-multilib.eclass
 * as a multilib-friendly wrapper. For the original content,
 * please see the files that are #included below.
 */

#if defined(__x86_64__) /* amd64 */
#	if defined(__ILP32__) /* x32 ABI */
#		error "abi_x86_x32 not supported by the package."
#	else /* 64-bit ABI */
#		error "abi_x86_64 not supported by the package."
#	endif
#elif defined(__i386__) /* plain x86 */
#	error "abi_x86_32 not supported by the package."
#else
#	error "No ABI matched, please report a bug to bugs.gentoo.org"
#endif
_EOF_
		fi

		# XXX: get abi_* directly
		local abi_flag
		case "${ABI}" in
			amd64)
				abi_flag=abi_x86_64;;
			x86)
				abi_flag=abi_x86_32;;
			x32)
				abi_flag=abi_x86_x32;;
			*)
				die "Header wrapping for ${ABI} not supported yet";;
		esac

		# Note: match a space afterwards to avoid collision potential.
		sed -e "/${abi_flag} /s&error.*&include <${CHOST}/${f}>&" \
			-i "${ED}/tmp/multilib-include${f}" || die
	done
}

autotools-multilib_src_install() {
	autotools-multilib_secure_install() {
		autotools-utils_src_install "${@}"

		_autotools-multilib_wrap_headers
		# Make sure all headers are the same for each ABI.
		multilib_check_headers
	}

	multilib_foreach_abi autotools-multilib_secure_install "${@}"

	# merge the wrapped headers
	if [[ -d "${ED}"/tmp/multilib-include ]]; then
		multibuild_merge_root \
			"${ED}"/tmp/multilib-include "${ED}"/usr/include
		# it can fail if something else uses /tmp
		rmdir "${ED}"/tmp &>/dev/null
	fi
}
