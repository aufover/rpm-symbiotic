##!/usr/bin/bash

rm -rf srpm
mkdir srpm
cd srpm || exit $?

# git clone symbiotic, dg, jsoncpp
git clone https://github.com/staticafi/symbiotic.git

cd symbiotic || exit $?

if [ ! -d dg ]; then
	git clone https://github.com/mchalupa/dg.git
fi

if [ ! -d jsoncpp ]; then
	git clone https://github.com/open-source-parsers/jsoncpp
	# FIXME: until a bug in building is fixed in the upstream
	(cd jsoncpp && git checkout c51d718ead5b)
fi

# git init submodules
source "$(dirname $0)/scripts/build-utils.sh"
SRCDIR=`dirname $0`
git_submodule_init

# git versions
cp ../../symbiotic/git_rev-parse.sh .
./git_rev-parse.sh

# copy scripts
cp ../../symbiotic/system-build.sh .
cp ../../symbiotic/sbt-instrumentation/bootstrap-dg.sh ./sbt-instrumentation/
cp ../../symbiotic/sbt-instrumentation/bootstrap-json.sh ./sbt-instrumentation/

#package version
PKG="symbiotic"
NV="`git describe --tags`"
VER="`echo "$NV" | sed "s/^$PKG-//"`"
TIMESTAMP="`git log --pretty="%cd" --date=iso -1 \
    | tr -d ':-' | tr ' ' . | cut -d. -f 1,2`"
VER="`echo "$VER" | sed "s/-.*-/.$TIMESTAMP./"`"

cd .. || exit $?
rm -rf ./symbiotic-$VER
mkdir ./symbiotic-$VER
cp -r ./symbiotic/* ./symbiotic-$VER/
tar -Jcf symbiotic-$VER.tar.xz ./symbiotic-$VER

echo "Name:       $PKG
Version:    $VER
Release:    1%{?dist}
Summary:    Tool for analysis of sequential computer programs written in C
License:    Free
URL:        https://github.com/staticafi/%{name}
Source0:    %{name}-%{version}.tar.xz

%global _build_id_links none

BuildRequires: gcc
BuildRequires: cmake
BuildRequires: rsync
BuildRequires: llvm
BuildRequires: llvm-devel
BuildRequires: llvm-static
BuildRequires: clang
BuildRequires: glibc
BuildRequires: glibc-devel
BuildRequires: glibc-devel(x86-32)
BuildRequires: z3
BuildRequires: z3-libs
BuildRequires: z3-devel
BuildRequires: zlib
BuildRequires: zlib-static

BuildRequires: make
BuildRequires: unzip
BuildRequires: tar
BuildRequires: patch
BuildRequires: xz
BuildRequires: python3

%description
Symbiotic is a tool for analysis of sequential computer programs written in the programming language C. It can check all common safety properties like assertion violations, invalid pointer dereference, double free, memory leaks, etc.

%prep
%autosetup

%build
sed -i 's+PREFIX=\`pwd\`/install+PREFIX=%{_builddir}/opt/symbiotic+g' system-build.sh
sed -i '2s+^PREFIX+#PREFIX+' ./scripts/precompile_bitcode_files.sh

./system-build.sh %{?_smp_mflags}

sed -i \"1s/env python\$/python3/\" %{_builddir}/opt/symbiotic/bin/symbiotic
sed -i 's/__file__/os.readlink(__file__)/' %{_builddir}/opt/symbiotic/bin/symbiotic
sed -i \"1s/env python\$/python3/\" %{_builddir}/opt/symbiotic/llvm-8.0.0/bin/klee-stats

%install
export QA_RPATHS=$(( 0x0001|0x0010 ))
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/opt/%{name}
cp -pr %{_builddir}/opt/symbiotic/* %{buildroot}/opt/%{name}
ln -sf /opt/symbiotic/bin/symbiotic %{buildroot}/%{_bindir}/symbiotic

%files
/opt/%{name}/
%{_bindir}/%{name}

%check
true
" >symbiotic.spec

rpmbuild -bs symbiotic.spec --define "_sourcedir $PWD" --define "_srcrpmdir $PWD"
