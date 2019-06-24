Name:       symbiotic
Version:    svcomp19.192.g4674a26
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
mkdir -p $RPM_BUILD_ROOT/usr/share/symbiotic
mkdir -p $RPM_BUILD_ROOT/usr/bin
find install/ -type f -exec install -Dm 755 {} $RPM_BUILD_ROOT/usr/share/symbiotic/{} \;
ln -sf  /usr/share/symbiotic/install/bin/symbiotic $RPM_BUILD_ROOT/usr/bin/symbiotic

%files
/usr/share/symbiotic/
/usr/bin/symbiotic

%check
true

