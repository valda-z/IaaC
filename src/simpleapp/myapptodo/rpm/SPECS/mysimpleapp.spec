##### HEADER SECTION #####

Name:           mysimpleapp
Version:        0.1.0H
Release:        0
Summary:        Rpm package for MySimpleApp Starter

License:        ASL 2.0
URL:            https://MySimpleApp.io
Source0:        app.jar
Source1:		%{name}.service

Requires:       shadow-utils,bash
BuildRequires:	systemd
%{?systemd_requires}

BuildArch:      noarch

%description
%{summary}

# disable debuginfo, which is useless on binary-only packages
%define debug_package %{nil}

# do not repack jar files
%define __jar_repack %{nil}

##### PREPARATION SECTION #####
%prep

# empty section

##### BUILD SECTION #####
%build

# empty section

##### PREINSTALL SECTION #####
%pre

# create MySimpleApp Starter service group
getent group mysimpleapp >/dev/null || groupadd -f -g 30000 -r mysimpleapp

# create MySimpleApp Starter service user
if ! getent passwd mysimpleapp >/dev/null ; then
    if ! getent passwd 30000 >/dev/null ; then
      useradd -r -u 30000 -g mysimpleapp -d /home/mysimpleapp -s /sbin/nologin -c "MySimpleApp Starter service account" mysimpleapp
    else
      useradd -r -g mysimpleapp -d /home/mysimpleapp -s /sbin/nologin -c "MySimpleApp Starter service account" mysimpleapp
    fi
fi
exit 0

##### INSTALL SECTION #####
%install

app_dir=%{buildroot}/usr/local/mysimpleapp
data_dir=%{buildroot}/var/opt/mysimpleapp
service_dir=%{buildroot}/%{_unitdir}

# cleanup build root
rm -rf %{buildroot}
mkdir -p  %{buildroot}

# create app folder
mkdir -p $app_dir

# create data folder
mkdir -p $data_dir

# create service folder
mkdir -p $service_dir

# copy all files
cp %{SOURCE0} $app_dir/app.jar
cp %{SOURCE1} $service_dir

##### FILES SECTION #####
%files

# define default file attributes
%defattr(-,mysimpleapp,mysimpleapp,-)

# list of directories that are packaged
%dir /usr/local/mysimpleapp
%dir %attr(660, -, -) /var/opt/mysimpleapp

# list of files that are packaged
/usr/local/mysimpleapp/app.jar
/usr/lib/systemd/system/%{name}.service

##### POST INSTALL SECTION #####
%post

# ensure MySimpleApp Starter service is enabled and running
%systemd_post %{name}.service
%{_bindir}/systemctl enable %{name}.service
%{_bindir}/systemctl start %{name}.service

##### UNINSTALL SECTION #####
%preun

# ensure MySimpleApp Starter service is disabled and stopped
%systemd_preun %{name}.service

%postun

case "$1" in
	0) # This is a package remove

		# remove app and data folders
		rm -rf /usr/local/mysimpleapp
		rm -rf /var/opt/mysimpleapp

		# remove MySimpleApp Starter service user and group
		userdel mysimpleapp
	;;
	1) # This is a package upgrade
		# do nothing
	;;
esac

# ensure MySimpleApp Starter service restartet if an upgrade is performed
%systemd_postun_with_restart %{name}.service

##### CHANGELOG SECTION #####
%changelog

* Fri Jun 21 2019 Valdemar Zavadsky <valdemar.zavadsky@microsoft.com> - 0.1.0-0
- First mysimpleapp package