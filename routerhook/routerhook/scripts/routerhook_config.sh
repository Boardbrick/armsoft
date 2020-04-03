#!/bin/sh

source /koolshare/scripts/base.sh
eval `dbus export routerhook_`
# for long message job remove
remove_cron_job(){
    echo 关闭自动发送状态消息...
    cru d routerhook_check >/dev/null 2>&1
}

# for long message job creat
creat_cron_job(){
    echo 启动自动发送状态消息...
    if [[ "${routerhook_status_check}" == "1" ]]; then
        cru a routerhook_check ${routerhook_check_time_min} ${routerhook_check_time_hour}" * * * /koolshare/scripts/routerhook_check_task.sh"
    elif [[ "${routerhook_status_check}" == "2" ]]; then
        cru a routerhook_check ${routerhook_check_time_min} ${routerhook_check_time_hour}" * * "${routerhook_check_week}" /koolshare/scripts/routerhook_check_task.sh"
    elif [[ "${routerhook_status_check}" == "3" ]]; then
        cru a routerhook_check ${routerhook_check_time_min} ${routerhook_check_time_hour} ${routerhook_check_day}" * * /koolshare/scripts/routerhook_check_task.sh"
    elif [[ "${routerhook_status_check}" == "4" ]]; then
        if [[ "${routerhook_check_inter_pre}" == "1" ]]; then
            cru a routerhook_check "*/"${routerhook_check_inter_min}" * * * * /koolshare/scripts/routerhook_check_task.sh"
        elif [[ "${routerhook_check_inter_pre}" == "2" ]]; then
            cru a routerhook_check "0 */"${routerhook_check_inter_hour}" * * * /koolshare/scripts/routerhook_check_task.sh"
        elif [[ "${routerhook_check_inter_pre}" == "3" ]]; then
            cru a routerhook_check ${routerhook_check_time_min} ${routerhook_check_time_hour}" */"${routerhook_check_inter_day} " * * /koolshare/scripts/routerhook_check_task.sh"
        fi
    elif [[ "${routerhook_status_check}" == "5" ]]; then
        check_custom_time=`dbus get routerhook_check_custom | base64_decode`
        cru a routerhook_check ${routerhook_check_time_min} ${check_custom_time}" * * * /koolshare/scripts/routerhook_check_task.sh"
    else
        remove_cron_job
    fi
}

creat_trigger_dhcp(){
    sed -i '/routerhook_dhcp_trigger/d' /jffs/configs/dnsmasq.d/dhcp_trigger.conf
    echo "dhcp-script=/koolshare/scripts/routerhook_dhcp_trigger.sh" >> /jffs/configs/dnsmasq.d/dhcp_trigger.conf
    [ "${routerhook_info_logger}" == "1" ] && logger "[软件中心] - [routerhook]: 重启DNSMASQ！"
    #service restart_dnsmasq
    killall dnsmasq
    sleep 1
    dnsmasq --log-async
}

remove_trigger_dhcp(){
    sed -i '/routerhook_dhcp_trigger/d' /jffs/configs/dnsmasq.d/dhcp_trigger.conf
    [ "${routerhook_info_logger}" == "1" ] && logger "[软件中心] - [routerhook]: 重启DNSMASQ！"
    service restart_dnsmasq
}

creat_trigger_ifup(){
    rm -f /koolshare/init.d/*routerhook.sh
    if [[ "${routerhook_trigger_ifup}" == "1" ]]; then
        ln -sf /koolshare/scripts/routerhook_ifup_trigger.sh /koolshare/init.d/S99routerhook.sh
    else
        rm -f /koolshare/init.d/*routerhook.sh
    fi
}

remove_trigger_ifup(){
    rm -f /koolshare/init.d/*routerhook.sh
}

onstart(){
    creat_cron_job
    creat_trigger_ifup
    if [ "${routerhook_trigger_dhcp}" == "1" ]; then
        creat_trigger_dhcp
    else
        remove_trigger_dhcp
    fi
}
# used by httpdb

# $1 for startup
case $1 in
start)
    if [ "${routerhook_enable}" == "1" ]; then
        logger "[软件中心]: 启动routerhook！"
        onstart
    else
        logger "[软件中心]: routerhook未设置启动，跳过！"
    fi
    ;;
stop)
    remove_trigger_dhcp
    remove_trigger_ifup
    remove_cron_job
    logger "[软件中心]: 关闭routerhook！"
    ;;
esac

# $2 for web apply
case $2 in
1)
    if [ "${routerhook_enable}" == "1" ]; then
        #logger "[软件中心]: 启动routerhook！"
        # web enable，disable first，incase of reapply
        remove_trigger_dhcp
        remove_trigger_ifup
        remove_cron_job
        sleep 1
        onstart
    else
        # web disable
        onstart
        logger "[软件中心]: routerhook未设置启动，跳过！"
    fi
    ;;
esac
