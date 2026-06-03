Name:           nixlper
Version:        %{nixlper_version}
Release:        1%{?dist}
Summary:        Bash helper for keyboard-driven file and directory management
License:        MIT
BuildArch:      noarch
URL:            https://github.com/Minhounet/nixlper

# Source0: pre-built tar produced by build.sh
Source0:        nixlper-%{nixlper_version}.tar
# Source1: system-wide config (admin-editable, preserved on upgrade)
Source1:        nixlper.conf
# Source2: profile.d loader — one line, activates nixlper for all users at login
Source2:        nixlper-profile.d.sh
# Source3: upstream license
Source3:        LICENSE

Requires:       bash >= 4.0
Recommends:     vim
Recommends:     tree

%description
Nixlper is a keyboard-driven bash helper for Linux environments inspired
by Total Commander. It provides directory bookmarks, navigation, file
operations, process management, macros, clipboard support, and a command
palette, all driven from the keyboard.

Activation is automatic for all users via /etc/profile.d/nixlper.sh.
System defaults are in /etc/nixlper/nixlper.conf (admin-editable, never
overwritten on upgrade). Each user can override any setting in
~/.config/nixlper/nixlper.conf. Per-user data (bookmarks, snapshots,
custom scripts) is stored under ~/.local/share/nixlper/ and
~/.config/nixlper/ and is never touched by the package manager.


%prep
# Nothing to prepare — nixlper.sh is a pre-built merged bash script from build.sh.


%build
# Nothing to compile — pure bash.


%install
install -dm 755 %{buildroot}%{_datadir}/nixlper
install -dm 755 %{buildroot}%{_datadir}/nixlper/help
install -dm 755 %{buildroot}%{_sysconfdir}/nixlper
install -dm 755 %{buildroot}%{_sysconfdir}/profile.d

# Unpack the built scripts and help files
tar -xf %{SOURCE0} -C %{buildroot}%{_datadir}/nixlper
chmod 644 %{buildroot}%{_datadir}/nixlper/nixlper.sh
chmod 644 %{buildroot}%{_datadir}/nixlper/version
chmod 644 %{buildroot}%{_datadir}/nixlper/help/*

# System config — admin editable, preserved on upgrade via %%config(noreplace)
install -m 644 %{SOURCE1} %{buildroot}%{_sysconfdir}/nixlper/nixlper.conf

# profile.d loader — not editable, replaced on upgrade
install -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/profile.d/nixlper.sh

# License
install -Dm 644 %{SOURCE3} %{buildroot}%{_datadir}/licenses/%{name}/LICENSE


%files
%license %{_datadir}/licenses/%{name}/LICENSE
%dir %{_datadir}/nixlper
%dir %{_datadir}/nixlper/help
%{_datadir}/nixlper/nixlper.sh
%{_datadir}/nixlper/version
%{_datadir}/nixlper/help/*
%dir %{_sysconfdir}/nixlper
%config(noreplace) %{_sysconfdir}/nixlper/nixlper.conf
%{_sysconfdir}/profile.d/nixlper.sh


%post
# profile.d handles activation at next login — nothing to do here.
# User data directories (~/.local/share/nixlper/, ~/.config/nixlper/) are
# created automatically on first login by nixlper.sh itself.


%preun
# Intentionally empty — user data in ~/.local/share/nixlper/ and
# ~/.config/nixlper/ is never removed by the package manager.


%changelog
* %{nixlper_changelog_date} Quang-Minh TRAN <qgmh.tran@gmail.com> - %{nixlper_version}-1
- Initial RPM packaging
