# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "breakpad"
version = v"2020.02.21"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/breakpad.git", "815497495eee92e028320ef96dc5b7ec13d85216"),
    GitSource("https://chromium.googlesource.com/linux-syscall-support.git", "f70e2f1641e280e777edfdad7f73a2cfa38139c7"),
    DirectorySource("./bundled"),

    # These are listed in the `.gclient` generated by `depot_tools`, but they dont' appear to actually be needed.
    #GitSource("https://github.com/google/googletest.git", "5ec7f0c4a113e2f18ac2c6cc7df51ad6afc24081"),
    #GitSource("https://github.com/google/protobuf.git", "cb6dd4ef5f82e41e06179dcd57d3b1d9246ad6ac"),
    #GitSource("https://chromium.googlesource.com/external/gyp.git", "324dd166b7c0b39d513026fa52d6280ac6d56770"; unpack_target="gyp"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/breakpad

# Apply old glibc patch for aarch64
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/glibc_aarch64.patch"

# Link necessary subprojects into their appropriate locations
ln -s ${WORKSPACE}/srcdir/linux-syscall-support src/third_party/lss
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
install_license LICENSE
"""

# musl is broken, same with ppc64le
platforms = filter(p -> arch(p) != "powerpc64le" && libc(p) != "musl", supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("minidump_dump", :minidump_dump),
    # Unfortunately, this is not provided on every platform.  Sigh.
    #ExecutableProduct("minidump-2-core", :minidump_2_core),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
