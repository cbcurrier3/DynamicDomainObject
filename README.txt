
Version 1
UPDATED 02/20/2020


------------------------------
Description
------------------------------
This is a shell script to add/update on a regular schedule 
a domain to a Dynamic Object on a Check Point Firewall. 
The Dynamic Object should be defined (using the domain name itself. e.g. "mydomain.com") and used in the Security 
Policy before populating the object or each Firewall.
Requires R80.10 or higher. 

------------------------------
INSTALL
------------------------------

cp dom_dyn_obj.sh $CPDIR/bin
chmod 755 $CPDIR/bin/dom_dyn_obj.sh


------------------------------
RUN
------------------------------
This script is intended to run on a Check Point Firewall

Usage:
  dyn_obj_upd.sh <options>

Options:
  -d                      Domain Name to become Dynamic Object (required)
  -a                      action to perform (required) includes:
                              run (once), on (schedule), off (from schedule), stat (status)
  -h                    show help

------------------------------
EXAMPLES
------------------------------
IMPORTANT:  Be sure that the dynamic object you are working with has been created
	    in your security policy and pushed out to the gateway. If not you will
	    be updating an object that will have no effect.

Activate an object
  dom_dyn_obj.sh -d mydomain.com -a on

Activate a web based list
  dom_dyn_obj.sh -d mydomain.com -a on

Run Right away
     dom_dyn_obj.sh -d mydomain.com -a run

Deactivate an object
    dom_dyn_obj.sh --d mydomain.com -a off

Get Object status
       dom_dyn_obj.sh -d mydomain.com -a stat

------------------------------
LOGS
------------------------------

A Log of events can be found at $FWDIR/log/dom_dyn_obj.log. 

------------------------------
Change Log
------------------------------

V1 - 07/13/18 - 1st Build

------------------------------
Authors
------------------------------
CB Currier - ccurrier@checkpoint.com
