# Copyright © 2010, Tomas Edwardsson 
# Copyright © 2011, Jon Dowland <jmtd@debian.org>
#
# This puppet recipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This puppet recipe distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class auth {

	package { "augeas": ensure => installed }

	exec { "authconfig-update":
		command => "/usr/sbin/authconfig --updateall",
		refreshonly => true,
	}
	class mkhomedir {
		augeas { "mkhomedir":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USEMKHOMEDIR yes",
			onlyif => "get USEMKHOMEDIR != yes",
			notify => Exec["authconfig-update"],
		}
	}
        class sssd {
		augeas { "authconfig-sssd":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USESSSD yes",
			onlyif => "get USESSSD != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["sssd"],
		}
                service { "sssd": ensure => running, require => Package["sssd"] }
		package { "sssd": ensure => installed }
        }
	class kerberos {
                include sssd

		exec { "set-authconfig-krb5realm":
			command => "/usr/sbin/authconfig --krb5realm=$krb5realm --update",
			unless  => "/bin/grep '^krb5_realm = $krb5realm\$' /etc/sssd/sssd.conf",
			notify => Exec["authconfig-update"],
		}

		exec { "set-authconfig-kdc":
			command => "/usr/sbin/authconfig --krb5kdc=$krb5kdc --update",
			unless  => "/bin/grep '^krb5_server = $krb5kdc\$' /etc/sssd/sssd.conf",
			notify => Exec["authconfig-update"],
		}

		augeas { "authconfig-kerberos":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USEKERBEROS yes",
			onlyif => "get USEKERBEROS != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["pam_krb5"],
		}
		package { "pam_krb5": ensure => installed }
	}
	class ldap {
                include sssd

		exec { "set-ldap-server":
			command => "/usr/sbin/authconfig --ldapserver=$ldapserver --update",
			unless  => "/bin/grep '^ldap_uri =.*$ldapserver' /etc/sssd/sssd.conf",
			notify => Exec["authconfig-update"],
		}

		exec { "set-ldap-basedn":
			command => "/usr/sbin/authconfig --ldapbasedn=$ldapbasedn --update",
			unless  => "/bin/grep '^ldap_search_base = $ldapbasedn\$' /etc/sssd/sssd.conf",
			notify => Exec["authconfig-update"],
		}

		augeas { "authconfig-ldap":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAP yes",
			onlyif => "get USELDAP != yes",
			notify => Exec["authconfig-update"],
			subscribe => Package["sssd"],
		}
		augeas { "ldapauth":
			context => "/files/etc/sysconfig/authconfig",
			changes => "set USELDAPAUTH no",
			onlyif => "get USELDAPAUTH != no",
			notify => Exec["authconfig-update"],
			subscribe => Package["sssd"],
		}
	}
}


