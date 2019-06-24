#!/bin/bash

cd ./symbiotic
version=$(git describe --tags)
version=${version//-/$'.'}
cd ..
rm -rf ./symbiotic-$version
mkdir ./symbiotic-$version
cp -r ./symbiotic/* ./symbiotic-$version/
tar -Jcf symbiotic-$version.tar.xz ./symbiotic-$version

echo "Name:       symbiotic
Version:    $version
Release:    1%{?dist}
Summary:    TODO
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

%description
TODO

%prep
%setup

%build
sh ./system-build.sh

%install
mkdir -p \$RPM_BUILD_ROOT/opt/symbiotic
mkdir -p \$RPM_BUILD_ROOT/usr/bin
find install/ -type f -exec install -Dm 755 {} \$RPM_BUILD_ROOT/opt/symbiotic/{} \;
ln -sf  /opt/symbiotic/install/bin/symbiotic \$RPM_BUILD_ROOT/usr/bin/symbiotic

%files
/opt/symbiotic/
/usr/bin/symbiotic

%check
true
" >symbiotic.spec

rm -rf ./symbiotic-$version
mv ./symbiotic-$version.tar.xz ~/rpmbuild/SOURCES/

rpmbuild -bs symbiotic.spec
