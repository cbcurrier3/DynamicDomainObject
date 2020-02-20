#!/bin/bash
# Version 1
# Date 02/20/2020 09:50:00
# Author: CB Currier ccurrier@checkpoint.com

timeout=43200
LOG_FILE="$FWDIR/log/dom_dyn_obj.log"

y=0
x=0
z=0

#is_fw_module=$($CPDIR/bin/cpprod_util FwIsFirewallModule)
is_fw_module=1

IS_FW_MODULE=$($CPDIR/bin/cpprod_util FwIsFirewallModule)

MY_PROXY=$(clish -c 'show proxy address'|awk '{print $2}'| grep  '\.')
MY_PROXY_PORT=$(clish -c 'show proxy port'|awk '{print $2}'| grep -E '[0-9]+')
if [ ! -z "$MY_PROXY" ]; then
        HTTPS_PROXY="$MY_PROXY:$MY_PROXY_PORT"
fi

function log_line {
        # add timestamp to all log lines
        message=$1
        local_log_file=$2
        echo "$(date) $message" >> $local_log_file
}
function convert {
        for ip in ${addrs[@]}; do
#        if ! [[ "$ip" =~ [^0-9.-] ]];
#        then
                todo[$y]+=" $ip $ip"
#                if [ $z -eq 2000 ]
#                        then
#                                z=0
#                                let y=$y+1
#                        else
#                                let z=$z+1
#                        fi
#        fi
        done

        dynamic_objects -do "$domain"
        dynamic_objects -n "$domain"

        for i in "${todo[@]}" ;
        do
                dynamic_objects -o "$domain" -r $i -a
        done
        unset addrs
}
function check_url {
        if [ ! -z $domain ]; then
                test_url=$domain

                #verify curl is working and the internet access is avaliable
                if [ -z "$HTTPS_PROXY" ]
                then

                        test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 2 --retry-delay 20 $test_url | grep HTTP)
                else
                        test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt $test_url --proxy $HTTPS_PROXY | grep HTTP)
                fi

                if [ -z "$test_curl" ]
                then
                        echo "Warning, cannot connect to $test_url"
                        exit 1
                fi
                log_line "done testing http connection" $LOG_FILE
        fi
}

function remove_existing_sam_rules {
        log_line "remove existing sam rules for $domain" $LOG_FILE
        dynamic_objects -do $domain
}

function print_help {
                echo ""
                echo "This script is intended to run on a Check Point Firewall"
                echo ""
                echo "Usage:"
                echo "  dynam_obj_upd.sh <options>"
                echo ""
                echo "Options:"
                echo "  -d                      Domain Name to become Dynamic Object (required)"
                echo "  -a                      action to perform (required) includes:"
                echo "                          run (once), on (schedule), off (from schedule), stat (status)"
                echo "  -h                      show help"
                echo ""
                echo ""
}

while getopts d:a:h: option
  do
        case "${option}"
        in
        d) domain=${OPTARG};;
        a) action=${OPTARG};;
        h) dohelp=${OPTARG};;
        ?) dohelp=${OPTARG};;
        esac
done

if [[ "$is_fw_module" -eq 1 && /etc/appliance_config.xml ]]; then
        case "$action" in

                on)
                log_line "adding dynamic object $domain to cpd_sched " $LOG_FILE
                $CPDIR/bin/cpd_sched_config add "DYOBJ_"$domain -c "$CPDIR/bin/dom_dyn_obj.sh" -v "-a run -d $domain $optin" -e $timeout -r -s
                log_line "Automatic updates of $domain is ON" $LOG_FILE
                ;;

                off)
                log_line "Turning off dyamic object updates for $domain" $LOG_FILE
                $CPDIR/bin/cpd_sched_config delete "DYOBJ_"$domain -r
                remove_existing_sam_rules
                log_line "Automatic updates of $domain is OFF" $LOG_FILE
                ;;

                stat)
                cpd_sched_config print | awk 'BEGIN{res="OFF"}/Task/{flag=0}/'$domain'/{flag=1}/Active: true/{if(flag)res="ON"}END{print "'$domain' list status is "res}'
                ;;

                run)
                log_line "Looking up IPs for $domain" $LOG_FILE
                addrs=$( nslookup $domain |grep Address:|awk '$0 !~ "#" {print $2}' )
                if [ -z "$addrs" ]
                then
                        log_line "Domain $domain Not found exiting." $LOG_FILE
                        echo "Domain $domain Not found exiting."
                        exit 1
                else
                        log_line "Creating dynamic object $domain and adding IPs" $LOG_FILE
                        echo "Creating dynamic object $domain and adding IPs"
                        convert
                        log_line "domain dyamic object $domain updated" $LOG_FILE
                fi
                ;;

                *)
                print_help
        esac
fi
