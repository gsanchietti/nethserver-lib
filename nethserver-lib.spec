Name: nethserver-lib
Summary: NethServer library module
Version: 2.2.7
Release: 1%{?dist}
License: GPL
Source: %{name}-%{version}.tar.gz
BuildArch: noarch
URL: %{url_prefix}/%{name}

BuildRequires: nethserver-devtools
Requires: cronie

%description
Common script libraries for the e-smith system

%prep
%setup

%build
%{__install} -d root%{perl_vendorlib} root%{python_sitelib} 
cp -av lib/perl/NethServer root%{perl_vendorlib}
cp -av lib/perl/esmith root%{perl_vendorlib}
cp -av lib/python/nethserver root%{python_sitelib}

%install
(cd root ; find . -depth -not -name '*.orig' -print | cpio -dump %{buildroot})
%{genfilelist} %{buildroot} > %{name}-%{version}-%{release}-filelist
install -d %{buildroot}{/var/spool/ptrack,/var/lib/nethserver/db}

%files -f %{name}-%{version}-%{release}-filelist
%defattr(-,root,root)
%doc COPYING
%dir %attr(2750,root,adm)  /var/lib/nethserver/db
%dir %attr(1770,root,adm)  /var/spool/ptrack

%changelog
* Mon Apr 23 2018 Davide Principi <davide.principi@nethesis.it> - 2.2.7-1
- Upgrade rspamd to 1.7.3 - NethServer/dev#5437

* Fri Sep 08 2017 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.2.6-1
- NS 6 upgrade: avoid restore-data when possible - NethServer/dev#5343
- Support masked unit

* Wed Jul 12 2017 Davide Principi <davide.principi@nethesis.it> - 2.2.5-1
- Backup config history - NethServer/dev#5314

* Wed Jun 14 2017 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.2.4-1
- Add db setjson command

* Tue Apr 04 2017 Davide Principi <davide.principi@nethesis.it> - 2.2.3-1
- Runlevel-adjust fails if service not exists - Bug NethServer/dev#5243

* Fri Mar 10 2017 Davide Principi <davide.principi@nethesis.it> - 2.2.2-1
- Avoid warning from esmith::util::isValidIP() -- NethServer/nethserver-lib#4

* Thu Jul 21 2016 Stefano Fancello <stefano.fancello@nethesis.it> - 2.2.1-1
- Undefined subroutine &esmith::util::genRandomHash - Bug NethServer/dev#5057

* Thu Jul 07 2016 Stefano Fancello <stefano.fancello@nethesis.it> - 2.2.0-1
- First NS7 release

* Mon Mar 23 2015 Davide Principi <davide.principi@nethesis.it> - 2.1.5-1
- Server Manager: admin login still possible - #3089 [NethServer]

* Tue Mar 03 2015 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.1.4-1
- Cosmetic: change e-smith db header - Enhancement #3029 [NethServer]
- nethserver-devbox replacements - Feature #3009 [NethServer]

* Thu Nov 27 2014 Davide Principi <davide.principi@nethesis.it> - 2.1.3-1.ns6
- Permission denied when creating VPN users - Bug #2965 [NethServer]

* Wed Nov 19 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.1.2-1.ns6
- Notify user if event fails - Enhancement #2927 [NethServer]

* Thu Oct 02 2014 Davide Principi <davide.principi@nethesis.it> - 2.1.1-1.ns6
- Cannot access Server Manager after migration - Bug #2786 [NethServer]

* Wed Aug 20 2014 Davide Principi <davide.principi@nethesis.it> - 2.1.0-1.ns6
- Embed Nethgui 1.6.0 into httpd-admin RPM - Enhancement #2820 [NethServer]
- Remove obsolete console and bootstrap-console commands - Enhancement #2734 [NethServer]

* Fri Jun 06 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.0.3-1.ns6
- signal-event and db: avoid failure when no syslog available - Enhancement #2755

* Mon Mar 24 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.2-1.ns6
- Bad file descriptor handling in _silent_system function - Bug #2696 [NethServer]

* Wed Feb 26 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.1-1.ns6
- Clear event log format - Enhancement #2652 [NethServer]

* Wed Feb 05 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.0-1.ns6
- Move admin user in LDAP DB - Feature #2492 [NethServer]

* Wed Dec 18 2013 Davide Principi <davide.principi@nethesis.it> - 1.4.0-1.ns6
- Directory: backup service accounts passwords  - Enhancement #2063 [NethServer]
- Process tracking and notifications - Feature #2029 [NethServer]
- Service supervision with Upstart - Feature #2014 [NethServer]

* Thu Oct 17 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.3.2-1.ns6
- Add support for IPsec/L2TP #1957 

* Wed Jul 31 2013 Davide Principi <davide.principi@nethesis.it> - 1.3.1-1.ns6
- Could not start smb/slapd - Bug #2092 [NethServer]

* Thu Jul 25 2013 Davide Principi <davide.principi@nethesis.it> - 1.3.0-1.ns6
- Lib: synchronize service status prop and running state - Feature #2078 [NethServer]
- Signal update events from yum posttrans hook  - Feature #1871 [NethServer]

* Wed Jul 17 2013 Davide Principi <davide.principi@nethesis.it> - 1.2.0-1.ns6
- NethServer::Service: synchronize service status prop and chkconfig - Feature #2067 [NethServer]
- NethServer::Event: removed old event-queue component - Feature #1871 [NethServer]

* Mon Jun 17 2013 Davide Principi <davide.principi@nethesis.it> - 1.1.2-1.ns6
- Remove escaped #012 (LF) in system logs - Enhancement #2018 [NethServer]

* Tue Apr 30 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.1.1-1.ns6
- Rebuild for automatic package handling. #1870
- Read locale settings from /etc/sysconfig. Refs #1754

* Tue Mar 19 2013 Davide Principi <davide.principi@nethesis.it> - 1.1.0-1.ns6
- Added NethServer::Migrate module, for migration support. Refs #1690 #1655 #1657
- esmith::ConfigDB (wins_server): obsolete function returns always undef. Refs #7 #1081
- *.spec: use url_prefix macro in URL tag; update changelog for release 1.0.3-1. Refs #1654 

* Thu Feb 21 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> 1.0.3-1.ns6
- util.pm: add genRandomHash function to generate random sha1 hash
- Update template-default with Nethesis copyright. Fix: #1649
 
* Mon Jan 21 2013 Davide Principi <davide.principi@nethesis.it> - 1.0.2-1.ns6
- DB/db.pm: fixed $initScript command execution. Only networks DB was actually initialized.

* Fri Jan 18 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.0.1-1.ns6
- adjust-services: stop service if not enabled
- added a new getnRandomPassword function
- esmith/console.pm: read separate Version and Release props from key "sysconfig"
- Removed old LDAP libs (moved to nethserver-directory)

* Fri Dec 21 2012 Davice Principi <davide.principi@nethesis.it> - 1.0.0-1.ns6
- First release
