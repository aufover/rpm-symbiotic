#!/bin/bash

# upstream revision to checkout
SYMBIOTIC_REV="ifm2019-46-gd57bfda"

rm -rf srpm
mkdir srpm
cd srpm || exit $?

# clone symbiotic git repo, including its submodules
git clone --recurse-submodules https://github.com/staticafi/symbiotic.git

(cd symbiotic || exit $?

# checkout the specified upstream revision
git checkout --recurse-submodules "$SYMBIOTIC_REV"

# FIXME: this should be replaced by upstream git submodule (if ever needed)
if [ ! -d jsoncpp ]; then
	git clone https://github.com/open-source-parsers/jsoncpp
	# FIXME: until a bug in building is fixed in the upstream
	(cd jsoncpp && git reset --hard c51d718ead5b)
fi

# git versions
cp ../../symbiotic/git_rev-parse.sh .
./git_rev-parse.sh

# copy scripts
cp ../../symbiotic/system-build.sh .
cp ../../symbiotic/sbt-instrumentation/bootstrap-dg.sh ./sbt-instrumentation/
cp ../../symbiotic/sbt-instrumentation/bootstrap-json.sh ./sbt-instrumentation/

) # leave the `symbiotic` directory

#package version
PKG="symbiotic"
NV="`git describe --tags`"
VER="`echo "$NV" | sed "s/^$PKG-//"`"
TIMESTAMP="`git log --pretty="%cd" --date=iso -1 \
    | tr -d ':-' | tr ' ' . | cut -d. -f 1,2`"
VER="`echo "$VER" | sed "s/-.*-/.$TIMESTAMP./"`"

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
Source1:    symbiotic2cs.py

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
BuildRequires: ncurses-devel
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
sed -i system-build.sh                     -e 's|^export PREFIX=|#&|'
sed -i scripts/precompile_bitcode_files.sh -e 's|^PREFIX=|#&|'

%build
export PREFIX=%{_builddir}/opt/symbiotic
bash -x ./system-build.sh %{?_smp_mflags}

sed -i \"1s/env python\$/python3/\" %{_builddir}/opt/symbiotic/bin/symbiotic
sed -i 's/__file__/os.readlink(__file__)/' %{_builddir}/opt/symbiotic/bin/symbiotic
sed -i \"1s/env python\$/python3/\" %{_builddir}/opt/symbiotic/llvm-*/bin/klee-stats

%install
export QA_RPATHS=$(( 0x0001|0x0010 ))
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/opt/%{name}
install -m 755 %{SOURCE1} %{buildroot}%{_bindir}/symbiotic2cs
cp -pr %{_builddir}/opt/symbiotic/* %{buildroot}/opt/%{name}
ln -sf /opt/symbiotic/bin/symbiotic %{buildroot}/%{_bindir}/symbiotic

%files
/opt/%{name}/
%{_bindir}/%{name}
%{_bindir}/symbiotic2cs

%check
true
" >symbiotic.spec

cp ../symbiotic2cs.py ./

rpmbuild -bs symbiotic.spec --define "_sourcedir $PWD" --define "_srcrpmdir $PWD"
