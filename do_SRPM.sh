#!/bin/bash

set -e

# upstream revision to checkout
SYMBIOTIC_REV="svcomp19-715-gad622b5"

rm -rf srpm
mkdir srpm
cd srpm

# clone symbiotic git repo, including its submodules
git clone --recurse-submodules --shallow-submodules https://github.com/staticafi/symbiotic.git

pushd symbiotic > /dev/null

# checkout the specified upstream revision
git checkout --recurse-submodules "$SYMBIOTIC_REV"

# generate version files and variables in advance
SYMBIOTIC_VERSION=$(git rev-parse HEAD)

pushd dg > /dev/null
  DG_VERSION=$(git rev-parse HEAD)
  cd tools
  ./git-version.sh
popd > /dev/null

pushd sbt-slicer > /dev/null
  SBT_SLICER_VERSION=$(git rev-parse HEAD)
  cd src
  ./git-version.sh
popd > /dev/null

pushd sbt-instrumentation > /dev/null
  INSTRUMENTATION_VERSION=$(git rev-parse HEAD)
  cd include
  . ../git-version.sh
popd > /dev/null

pushd klee > /dev/null
  KLEE_VERSION=$(git rev-parse HEAD)
popd > /dev/null

popd > /dev/null # leave the `symbiotic` directory

# package version
PKG=symbiotic
NV=$(git describe --tags)
TIMESTAMP=$(git log --pretty="%cd" --date=iso -1 | tr -d ':-' \
            | tr ' ' . | cut -d . -f 1,2)
VER=$(echo "$NV" | sed "s/-.*-/.$TIMESTAMP./")

echo "Making symbiotic-$VER.tar.xz"
mv symbiotic "symbiotic-$VER"
tar -Jcf "symbiotic-$VER.tar.xz" "symbiotic-$VER"

cat > $PKG.spec << EOF
Name:       $PKG
Version:    $VER
Release:    1%{?dist}
Summary:    Tool for analysis of sequential computer programs written in C
License:    MIT
URL:        https://github.com/staticafi/%{name}

Source0:    %{name}-%{version}.tar.xz
Source1:    symbiotic2cs.py
Source2:    csexec-symbiotic.sh

Patch0:     build.patch
Patch1:     hotfix.patch
Patch2:     llvm-dynamic-link.patch
%if 0%{?fedora} > 32
Patch3:     llvm-11.patch
%endif

BuildRequires: gcc-c++
BuildRequires: clang
BuildRequires: cmake
BuildRequires: glibc-devel
BuildRequires: glibc-devel(x86-32)
BuildRequires: jsoncpp-devel
BuildRequires: llvm-devel
BuildRequires: ncurses-devel
BuildRequires: python3
BuildRequires: sqlite-devel
BuildRequires: z3-devel
BuildRequires: zlib-devel

Requires: clang
Requires: llvm

%description
Symbiotic is a tool for analysis of sequential computer programs written in the programming language C. It can check all common safety properties like assertion violations, invalid pointer dereference, double free, memory leaks, etc.

%prep
%autosetup -p1

%build
export SYMBIOTIC_VERSION=$SYMBIOTIC_VERSION
export DG_VERSION=$DG_VERSION
export SBT_SLICER_VERSION=$SBT_SLICER_VERSION
export INSTRUMENTATION_VERSION=$INSTRUMENTATION_VERSION
export KLEE_VERSION=$KLEE_VERSION

%set_build_flags
./system-build.sh %{?_smp_mflags}

%install
mkdir -p %{buildroot}/opt/%{name}
cp -pr install/* %{buildroot}/opt/%{name}

mkdir -p %{buildroot}%{_bindir}
install -m 755 %{SOURCE1} %{buildroot}%{_bindir}/symbiotic2cs
install -m 755 %{SOURCE2} %{buildroot}%{_bindir}/csexec-symbiotic
ln -sf /opt/symbiotic/bin/symbiotic %{buildroot}%{_bindir}/symbiotic

%files
/opt/%{name}/
%{_bindir}/%{name}
%{_bindir}/symbiotic2cs
%{_bindir}/csexec-symbiotic
EOF

cp ../{symbiotic2cs.py,csexec-symbiotic.sh,{build,hotfix,llvm-{11,dynamic-link}}.patch} .

# Needed to build the SRPM with correct patches included
mock --buildsrpm --spec "$PKG.spec" --sources "$PWD" -r fedora-rawhide-x86_64
