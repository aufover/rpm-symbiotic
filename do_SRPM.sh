#!/bin/bash

cd ./symbiotic
version=$(git describe --tags)
version=${version//-/$'.'}
cd ..
rm -rf ./symbiotic-$version
mkdir ./symbiotic-$version
cp -r ./symbiotic/* ./symbiotic-$version/
#git archive --prefix="symbiotic-$version/" --format="tar" HEAD -- . | xz -c > symbiotic-$version.tar.xz
tar -Jcf symbiotic-$version.tar.xz ./symbiotic-$version

echo "Name:       symbiotic
Version:    $version
Release:    1%{?dist}
Summary:    TODO
License:    Free
URL:        https://github.com/staticafi/%{name}
Source0:    %{name}-%{version}.tar.xz

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
true

%files
./install/*

%check
true
" >symbiotic.spec

rm -rf ./symbiotic-$version
mv ./symbiotic-$version.tar.xz ~/rpmbuild/SOURCES/

rpmbuild -bs symbiotic.spec
