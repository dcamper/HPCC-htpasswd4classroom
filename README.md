# HTPASSWD for Classrooms

Copyright (C) 2021 HPCC Systems

## Motivation

Classroom settings that involve grading the students' work should not allow easy cheating.  Unfortunately, a wide-open HPCC Systems cluster is exactly that, unless user authorization is enabled.  A student can use ECL Watch to look at another student's workunit and therefore the workunit's code, then do with it what they will.

There are two security manager plugins for the HPCC Systems cluster that provide both authentication and authorization:

- LDAP:  Requires a separate LDAP server and is relatively complicated to set up.  If an LDAP server is already available then this is perhaps a good solution.  If not, then standing one up and managing it just for a classroom is probably overkill.
- JWT:  A plugin that uses bearer tokens to provide authorization rights.  It also requires a separate server to manage the users and their authorizations.  While probably simpler than LDAP, it is still a lot of work.

The above plugins are really overkill if the only thing we're trying to do is prevent a student from accessing another student's workunit.

## Solution

The HPCC Systems cluster provides an authentication-only plugin that leverages Apache's htpasswd scheme.  We decided to modify that plugin so that it also enforces the workunit restriction we need while leaving everything else wide open.  This is a solution with a very narrow use case, so this plugin is not generally available, but it _is_ very simple.

## Building the Plugin

This plugin requires access to the HPCC Systems source code, found on GitHub at [https://github.com/hpcc-systems/HPCC-Platform](https://github.com/hpcc-systems/HPCC-Platform).  You will need to actually build the platform code, so you'll need to get that done first.  See the "Build From Source" link in the README there.

It is also **very important** that match the platform's source code version with the version of the running cluster on which you will be installing this plugin (or at least the major.ninor version parts, like 7.10 or 7.12).  Checkout the correct git branch in the platform.

This plugin's code is built out-of-source, so we'll need to create a directory in which to build the plugin.  The following assumes this directory structure (~ means your home directory):

    ~/
        HPCC-Plugin/                          <- our build directory
        Projects/
            HPCC-Platform/                    <- HPCC platform source code
            HPCC-htpasswd4classroom/          <- this plugin's source code

Build steps:

    cd ~/HPCC-Plugin
    cmake -DHPCC_SOURCE_DIR=~/Projects/HPCC-Platform ~/Projects/HPCC-htpasswd4classroom
    make
    make package

At this point you will have a .rpm or .deb installation package that you can install onto your cluster.  The package will have a name like `htpasswd4ClassroomSecurity_1.0.0_focal_amd64.deb` (this was built on an Ubuntu 20.04 system).

## Cluster Requirements

Make sure the htpasswd utility is installed on the HPCC Systems node that runs the esp process (the one you connect to for ECL Watch).  This is usually not a stand-alone utility; you need to install the `apache2-utils` package instead, and htpassword is part of that.  Use either apt (Debian) or yum (CentOS) to perform that installation.

## Installing the Plugin

Installation is straightforward:  Copy the package file you just build to the HPCC node running the esp process (this is typically the one you connect to with ECL Watch) and install it using whatever tool you use to install packages.  On the command line, that would be either dpkg (Debian) or yum (CentOS), but you could also use a GUI application if you wish.

## Configuring the Plugin

This plugin is configured basically the same as the htpasswd plugin that is included with the HPCC platform code.  There are two differences, outlined below.  Instructions for configuring the built-in htpasswd plugin can be found at [https://hpccsystems.com/training/documentation/all](https://hpccsystems.com/training/documentation/all), in the "HPCC Systems Administrator's Guide" document.  Within that document, search for "Using htpasswd authentication" and you will find the configuration instructions.

The first difference between configuring the built-in plugin and this one is the name of the plugin you choose in the various popup lists.  Instead of selecting "Htpasswdsecmgr" you should select "Htpasswd4Classroomsecmgr".  Both will be available in some places, so make sure you choose the right one.

The only other change is a new addition to this classroom plugin:  You can specify the usernames of the users that should be considered administrators of the cluster.  The administrators do not have the workunit restriction imposed on them; they can see all workunits.  In configmgr, when you configure the plugin itself, there is a field labeled "adminUsers" -- that is where you define those administrator users.  The username "admin" is populated by default.  To add more usernames, just edit the field and use a comma to separate the usernames.  If you submit an empty field then the username "admin" will be added to the internal list at runtime.

## Configuring Users in the .htpasswd File

You should define at least one of the administrator's usernames and passwords in the .htpasswd file before you restart the cluster.  If you used the recommended default configuration for plugin and you do not have an existing .htpasswd file, and the you want to define the username "admin" then steps would be:

    cd /etc/HPCCSystems
    sudo htpasswd -c .htpasswd admin

If already have an existing .htpasswd file, omit the `-c` argument.  This example also assumes your file is at `/etc/HPCCSystems/.htpasswd` which is the recommended default location for this file.

To add other users, such as other administrators or students, use the same technique as with the admin user above.  Be sure to omit the `-c` argument though, or you will be constantly truncating your .htpasswd file.

## HPCC Cluster After Plugin Installation

There are only a few changes from a "standard" HPCC usage:

* All users will have to authenticate with a username and password.
* Regular users will not be able to view other users' workunits.
* Only the admin users can view all workunits.
* All other permissions remain the same as with cluster not running any security policies (i.e. wide open).
