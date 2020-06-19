#!/bin/bash

set -e

# upstream revision to checkout
SYMBIOTIC_REV="svcomp19-504-g7aa510d"

rm -rf srpm
mkdir srpm
cd srpm

# clone symbiotic git repo, including its submodules
git clone --recurse-submodules https://github.com/staticafi/symbiotic.git

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

cat > symbiotic.spec << EOF
Name:       $PKG
Version:    $VER
Release:    1%{?dist}
Summary:    Tool for analysis of sequential computer programs written in C
License:    Free
URL:        https://github.com/staticafi/%{name}
Source0:    %{name}-%{version}.tar.xz
Source1:    symbiotic2cs.py
Patch0:     build.patch
Patch1:     hotfix.patch

BuildRequires: gcc
BuildRequires: cmake
BuildRequires: jsoncpp-devel
BuildRequires: llvm-devel
BuildRequires: llvm-static
BuildRequires: clang
BuildRequires: glibc-devel
BuildRequires: glibc-devel(x86-32)
BuildRequires: ncurses-devel
BuildRequires: python3
BuildRequires: sqlite-devel
BuildRequires: z3-devel
BuildRequires: zlib-static

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

./system-build.sh %{?_smp_mflags}

%install
mkdir -p %{buildroot}/opt/%{name}
cp -pr install/* %{buildroot}/opt/%{name}

mkdir -p %{buildroot}%{_bindir}
install -m 755 %{SOURCE1} %{buildroot}%{_bindir}/symbiotic2cs
ln -sf /opt/symbiotic/bin/symbiotic %{buildroot}%{_bindir}/symbiotic

%files
/opt/%{name}/
%{_bindir}/%{name}
%{_bindir}/symbiotic2cs
EOF

cp ../{symbiotic2cs.py,build.patch,hotfix.patch} .

rpmbuild -bs symbiotic.spec --define "_sourcedir $PWD" --define "_srcrpmdir $PWD"
