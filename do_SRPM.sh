#!/bin/bash
set -euxo pipefail

# upstream revision to checkout
SYMBIOTIC_REV="svcomp19-871-g7c96642"

rm -rf srpm
mkdir srpm
cd srpm

# clone symbiotic git repo, including its submodules
git clone --recurse-submodules --shallow-submodules https://github.com/staticafi/symbiotic.git

# checkout the specified upstream revision
git -C symbiotic checkout --recurse-submodules "$SYMBIOTIC_REV"

# package version
PKG=symbiotic
NV=$(grep 'VERSION=' symbiotic/lib/symbioticpy/symbiotic/options.py \
     | cut -d "'" -f 2 | head -n 1 | sed 's/-/\./g')
TIMESTAMP=$(git log --pretty="%cd" --date=iso -1 | tr -d ':-' \
            | tr ' ' . | cut -d . -f 1,2)
VER="$NV.$TIMESTAMP"

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
Patch3:     llvm-11.patch
Patch4:     llvm-13.patch

BuildRequires: gcc
BuildRequires: gcc-c++

# a bit hacky, but we tar the whole repository structure, so we can use git
# to generate all version tags during the build
BuildRequires: git

BuildRequires: clang
BuildRequires: cmake
BuildRequires: glibc-devel
BuildRequires: glibc-devel(x86-32)
BuildRequires: jsoncpp-devel
BuildRequires: llvm-devel
BuildRequires: make
BuildRequires: ncurses-devel
BuildRequires: python3
BuildRequires: sqlite-devel
BuildRequires: z3-devel
BuildRequires: zlib-devel

Requires: clang
Requires: llvm
Requires: python3

%description
Symbiotic is a tool for analysis of sequential computer programs written in the
programming language C. It can check all common safety properties like assertion
violations, invalid pointer dereference, double free, memory leaks, etc.

%prep
%autosetup -p1

%build
%set_build_flags
./system-build.sh %{?_smp_mflags}

%install
mkdir -p %{buildroot}/opt/%{name}
cp -pr install/* %{buildroot}/opt/%{name}

mkdir -p %{buildroot}%{_bindir}
install -m 755 %{SOURCE1} %{buildroot}%{_bindir}/symbiotic2cs
install -m 755 %{SOURCE2} %{buildroot}%{_bindir}/csexec-symbiotic
ln -sf /opt/symbiotic/bin/symbiotic %{buildroot}%{_bindir}/symbiotic

%check
cd tests
./run_tests.sh --with-integrity-check

%files
/opt/%{name}/
%{_bindir}/%{name}
%{_bindir}/symbiotic2cs
%{_bindir}/csexec-symbiotic
EOF

echo "Making $PKG-$VER.tar.xz"
mv symbiotic "$PKG-$VER"
tar -Jcf "$PKG-$VER.tar.xz" "$PKG-$VER"

cp ../{symbiotic2cs.py,csexec-symbiotic.sh,{build,hotfix,llvm-*}.patch} .

# Needed to build the SRPM with correct patches included
mock --buildsrpm --spec "$PKG.spec" --sources "$PWD" -r fedora-rawhide-x86_64
