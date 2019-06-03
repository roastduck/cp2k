#!/bin/bash -e
[ "${BASH_SOURCE[0]}" ] && SCRIPT_NAME="${BASH_SOURCE[0]}" || SCRIPT_NAME=$0
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_NAME")" && pwd -P)"

source "${SCRIPT_DIR}"/common_vars.sh
source "${SCRIPT_DIR}"/package_versions.sh
source "${SCRIPT_DIR}"/tool_kit.sh
source "${SCRIPT_DIR}"/signal_trap.sh

with_impi=${1:-__INSTALL__}

[ -f "${BUILDDIR}/setup_impi" ] && rm "${BUILDDIR}/setup_impi"

IMPI_CFLAGS=''
IMPI_LDFLAGS=''
IMPI_LIBS=''
! [ -d "${BUILDDIR}" ] && mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"
case "$with_impi" in
    __INSTALL__)
        echo "==================== Installing MKL ===================="
        report_error ${LINENO} "To install MKL you should contact your system administrator."
        exit 1
        ;;
    __SYSTEM__)
        echo "==================== Finding Intel MPI from system paths ===================="
        check_command mpirun "impi"
        check_command mpicc "impi"
        check_command mpif90 "impi"
        check_command mpicxx "impi"
        check_lib -lmpi "impi"
        add_include_from_paths IMPI_CFLAGS "mpi.h" $INCLUDE_PATHS
        add_lib_from_paths IMPI_LDFLAGS "libmpi.*" $LIB_PATHS
        ;;
    __DONTUSE__)
        ;;
    *)
        echo "==================== Linking Intel MPI to user paths ===================="
        pkg_install_dir="$with_impi"
        check_dir "${pkg_install_dir}/bin"
        check_dir "${pkg_install_dir}/lib"
        check_dir "${pkg_install_dir}/include"
        IMPI_CFLAGS="-I'${pkg_install_dir}/include'"
        IMPI_LDFLAGS="-L'${pkg_install_dir}/lib' -Wl,-rpath='${pkg_install_dir}/lib'"
        ;;
esac
if [ "$with_impi" != "__DONTUSE__" ] ; then
    if [ "$with_impi" != "__SYSTEM__" ] ; then
        cat <<EOF > "${BUILDDIR}/setup_impi"
prepend_path PATH "$pkg_install_dir/bin"
prepend_path LD_LIBRARY_PATH "$pkg_install_dir/lib"
prepend_path LD_RUN_PATH "$pkg_install_dir/lib"
prepend_path LIBRARY_PATH "$pkg_install_dir/lib"
prepend_path CPATH "$pkg_install_dir/include"
EOF
        cat "${BUILDDIR}/setup_impi" >> $SETUPFILE
        mpi_bin="$pkg_install_dir/bin/mpirun"
    else
        mpi_bin=mpirun
    fi
    IMPI_LIBS="-lmpi -lmpicxx -lmpifort"
    # Not checking versions here, assuming we are using MPI 3
    cat <<EOF >> "${BUILDDIR}/setup_impi"
export IMPI_CFLAGS="${IMPI_CFLAGS}"
export IMPI_LDFLAGS="${IMPI_LDFLAGS}"
export IMPI_LIBS="${IMPI_LIBS}"
export MPI_CFLAGS="${IMPI_CFLAGS}"
export MPI_LDFLAGS="${IMPI_LDFLAGS}"
export MPI_LIBS="${IMPI_LIBS}"
export CP_DFLAGS="\${CP_DFLAGS} IF_MPI(-D__parallel ${mpi2_dflags}|)"
export CP_CFLAGS="\${CP_CFLAGS} IF_MPI(${IMPI_CFLAGS}|)"
export CP_LDFLAGS="\${CP_LDFLAGS} IF_MPI(${IMPI_LDFLAGS}|)"
export CP_LIBS="\${CP_LIBS} IF_MPI(${IMPI_LIBS}|)"
EOF
fi
cd "${ROOTDIR}"

