#!/bin/bash

binary='/usr/bin/barrierc'
name='anthill'
remote_ip_work='172.22.0.1'
remote_ip_home='172.18.0.141'
work_interface_ip_pattern='172.22.0'
home_interface_ip_pattern='172.18.0'

function get_local_ips {
    # shellcheck disable=SC2046
    local_ip_addresses="$( ( (which ip && ip -4 addr show) || (whichs ifconfig && ifconfig) || awk '/32 host/ { print "inet " f } {f=$2}' <<< \"$(</proc/net/fib_trie)\") | grep -v 127. | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | sort -u)"
}

if [ "${DISPLAY:-}" == ':0' ] ; then
    pkill --full "${binary} --display :1"
elif [ "${DISPLAY:-}" == ':1' ] ; then
    pkill --full "${binary} --display :0"
fi

get_local_ips

if echo "${local_ip_addresses}" | grep -q "${work_interface_ip_pattern}" ; then
    ${binary} --display "${DISPLAY}" --enable-crypto --restart --name "${name}" "${remote_ip_work}"
elif echo "${local_ip_addresses}" | grep -q "${home_interface_ip_pattern}" ; then
    ${binary} --display "${DISPLAY}" --enable-crypto --restart --name "${name}" "${remote_ip_home}"
else
    echo 'Unable to find any matching interface/ip'
fi

if [ "${DISPLAY:-}" == ':1' ] ; then
    ( while true; do
        get_local_ips
        if ! pgrep --full "${binary} --display :1" ; then
            if echo "${local_ip_addresses}" | grep -q "${work_interface_ip_pattern}" ; then
                pgrep "${binary}" > /dev/null || XAUTHORITY=/var/run/lightdm/root/:0 "${binary}" --display ':0' --enable-crypto --restart --name "${name}" "${remote_ip_work}" && exit
            elif echo "${local_ip_addresses}" | grep -q "${home_interface_ip_pattern}" ; then
                pgrep "${binary}" > /dev/null || XAUTHORITY=/var/run/lightdm/root/:0 "${binary}" --display ':0' --enable-crypto --restart --name "${name}" "${remote_ip_home}" && exit
            fi
        fi
        sleep 3
    done ) &
fi
