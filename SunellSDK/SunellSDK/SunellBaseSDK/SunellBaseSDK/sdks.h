///////////////////////////////////////////////////////////////////////////
//  Copyright(c) 2015-2017, All Rights Reserved
//  Created: 2016/01/05
//
/// @file    sdks.h
/// @brief   sdk�ӿ�
/// @author
/// @version 0.3
/// @warning û�о���
///////////////////////////////////////////////////////////////////////////
#ifndef __SDKS_H__
#define __SDKS_H__
#include "sdk_def.h"
#include <stdio.h>

///< sdks��ʼ��/�˳�
SDKS_API int   sdks_dev_init(const char* p_json_setup_in);
SDKS_API void  sdks_dev_quit();
SDKS_API void  sdks_free_result(void* p_result);

///< ���ӣ�����handle


SDKS_API int  sdks_dev_conn(const char* p_ip, unsigned short  port, const char*  p_user, const char* p_passwd, SDK_DISCONN_CB disconn_cb, void* p_obj);
//ssl encryption connect
SDKS_API int  sdks_dev_conn_ssl(const char* p_ip, unsigned short  port, const char*  p_user, const char* p_passwd, SDK_DISCONN_CB disconn_cb, void* p_obj, char *p_ca);
SDKS_API int sdks_dev_get_con_sta(unsigned int handle);
SDKS_API int sdks_create_login_password_param(const char *p_ip, unsigned short port, const char *p_user, const char *p_passwd, const char *p_email,  void *p_obj);

///< �첽���ӽӿ�
SDKS_API int  sdks_dev_conn_async(const char* p_ip, unsigned short  port, const char*  p_user, const char* p_passwd, SDK_DISCONN_CB disconn_cb, SDK_CONNECT_CB conn_cb, void* p_obj);
SDKS_API void  sdks_dev_conn_close(unsigned int handle);

// Live
SDKS_API int sdks_dev_addr_req(unsigned int handle, int ipprotover, char** p_result);
SDKS_API int sdks_dev_live_start(unsigned int handle, int chn, int stream_type, SDK_STREAM_CB stream_cb, void* p_obj);
SDKS_API int sdks_dev_live_stop(unsigned int handle, int stream_id);
SDKS_API int sdks_dev_chg_stream(unsigned int handle, int stream_id, int new_stream_type);
SDKS_API int sdks_get_video_param(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_set_video_param(unsigned int handle, char* p_video_param);
SDKS_API int sdks_dev_video_control(unsigned int handle, char* p_audio_para);

SDKS_API int sdks_set_iframe_video(unsigned int handle, int stream_id);
//Audio
SDKS_API int sdks_dev_audio_start(unsigned int handle, int stream_id);
SDKS_API int sdks_dev_audio_stop(unsigned int handle, int stream_id);

//Snap
SDKS_API int sdks_get_snap_data(unsigned int handle, char* p_snap_param, char  **p_buf, int *len);
SDKS_API int sdks_get_snap_picture(unsigned int handle, char* p_snap_param);
SDKS_API int sdks_open_snap(unsigned int handle, char* p_snap_param);
SDKS_API int sdks_close_snap(unsigned int handle, char* p_snap_param);
// PlayBack
//s_date��e_date �ĸ�ʽ����Ϊ "yyyy-mm-dd"
SDKS_API int sdks_dev_pb_date_list(unsigned int handle, int chn, int mode, const char* s_date, const char* e_date, char** p_result);
//p_date �ĸ�ʽ����Ϊ "yyyy-mm-dd"
SDKS_API int sdks_dev_pb_chns_in_date(unsigned int handle, const char* p_date, char** p_result); //v2
// ��ȡĳ��ͨ��һ���¼��
SDKS_API int sdks_dev_pb_get_rec_list(unsigned int handle, int chn, int mode, const char* p_date, char** p_result);
// ��ȡĳ��ͨ��¼���ʱ���
SDKS_API int sdks_dev_pb_get_rec_date_list(unsigned int handle, int chn, int mode, const char* s_time, const char* e_time, char** p_result);
// s_time��e_time �ĸ�ʽ����Ϊ "yyyy-mm-dd HH:mm:ss"
SDKS_API int sdks_dev_pb_start(unsigned int handle, int chn, int stream_type, const char* s_time, const char* e_time, SDK_STREAM_CB stream_cb, void* p_obj);
SDKS_API int sdks_dev_pb_seek(unsigned int handle, int stream_id, const char* time);
SDKS_API int sdks_dev_pb_pause(unsigned int handle, int stream_id);
SDKS_API int sdks_dev_pb_resume(unsigned int handle, int stream_id);
SDKS_API int sdks_dev_pb_stop(unsigned int handle, int stream_id);
SDKS_API int sdks_get_pb_video_param(unsigned int handle, char** p_result);
SDKS_API int sdks_set_pb_video_speed(unsigned int handle, int stream_id, int rate);
SDKS_API int sdks_dev_grid_start(unsigned int handle, int chn, int stream_type, const char* s_time, const char* e_time, SDK_STREAM_CB stream_cb, void* p_obj);
SDKS_API int sdks_dev_grid_stop(unsigned int handle, int stream_id);
// Record
SDKS_API int sdks_dev_open_rec(const char* p_path,const char* p_filename);
SDKS_API int sdks_dev_record(int record_id, ST_AVFrameData* p_frame);
SDKS_API int sdks_dev_stop_rec(int record_id);

// Alarm
SDKS_API int sdks_dev_start_alarm(unsigned int handle, SDK_ALARM_CB alarm_cb, void* p_obj);
SDKS_API int sdks_dev_stop_alarm(unsigned int handle);
SDKS_API int sdks_dev_start_chn_status(unsigned int handle, SDK_STATUS_CB status_cb, void* p_obj);
SDKS_API int sdks_dev_stop_chn_status(unsigned int handle);

//IO Alarm
SDKS_API int sdks_dev_get_io_alarm_event(unsigned int handle, int chn, int alarm_source_id, char** p_result);
SDKS_API int sdks_dev_set_io_alarm_para(unsigned int handle, const io_alarm_event_para_list* p_io_alarm_para);//updated
SDKS_API int sdks_dev_json_set_io_alarm_para(unsigned int handle, const char* p_io_alarm_para);
SDKS_API int sdks_set_io_alarm_out_param(unsigned int handle, char* param);
SDKS_API int sdks_get_io_alarm_out_param(unsigned int handle, int action_id, char** p_result);

//Audio Alarm
SDKS_API int sdks_dev_get_audio_alarm_event(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_set_audio_alarm_para(unsigned int handle, int chn, const char* p_audio_para);
SDKS_API int sdks_dev_play_audio_alarm(unsigned int handle, int chn, int play_num);
SDKS_API int sdks_dev_get_tonearm_para(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_set_tonearm_para(unsigned int handle, int chn, const char* p_tonearm_para);
SDKS_API int sdks_dev_nvr_play_audio_alarm(unsigned int handle, int chn, int display_id, int play_num);
SDKS_API int sdks_dev_get_loudhailer_para(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_set_loudhailer_para(unsigned int handle, int chn, const char* p_loudhailer_para);

//Disk Alarm
SDKS_API int sdks_dev_json_set_disk_alarm_para(unsigned int handle, const char* p_disk_alarm_para);
SDKS_API int sdks_dev_set_disk_alarm_para(unsigned int handle, const disk_alarm_event_para_list* p_disk_alarm_list);//updated
SDKS_API int sdks_dev_get_disk_alarm_para(unsigned int handle, int chn, char** p_result);

//Query  the alarm   s_time and e_time must "yyyy-mm-dd HH:mm:ss"
SDKS_API int sdks_dev_get_match_alarm_date_list(unsigned int handle, const qry_info_para_list * p_qry_info, char** p_result);//updated
SDKS_API int sdks_dev_json_get_match_alarm_date_list(unsigned int handle, const char* p_qry_info, const char* s_time, const char* e_time, char** p_result);

//Get for information list of alarm 
SDKS_API int sdks_dev_get_alarm_camera_info_list(unsigned int handle, const alarm_info_qry* p_alarm_info_qry, char** p_result);//updated
SDKS_API int sdks_dev_json_get_alarm_camera_info_list(unsigned int handle, const char* s_time, const char* e_time, const char* p_alarm_info_qry, char** p_result);

SDKS_API int sdks_dev_get_alarm_list_manual(unsigned int handle, int chn, const char* s_time, const char* e_time,const char* p_cAlarmTypeList, char** p_result);
SDKS_API int sdks_dev_get_alarm_list(unsigned int handle, int chn, const char* s_time, const char* e_time, char** p_result);
//Manual alarm
SDKS_API int sdks_dev_manual_alarmout(unsigned int handle, int chn, const int alarmout_id, int control_flag);
SDKS_API int sdks_dev_get_general_alarm_rule(unsigned int handle, char** p_result);
SDKS_API int sdks_dev_set_general_alarm_rule(unsigned int handle, const char *p_param);

//Record strategy
SDKS_API int sdks_dev_get_record_policy(unsigned int handle, int chn, int record_mode, char** p_result);
SDKS_API int sdks_dev_set_record_policy(unsigned int handle, int chn, char* p_record_para);

//Record policy ex
SDKS_API int sdks_dev_get_record_policy_ex(unsigned int handle, char *p_param, char** p_result);
SDKS_API int sdks_dev_set_record_policy_ex(unsigned int handle, char *p_param);

//Record state
SDKS_API int sdks_dev_get_record_state(unsigned int handle, int chn, char** p_result);
//time format mast "yyyy-mm-dd HH:mm:ss"
SDKS_API int sdks_dev_get_last_record_time(unsigned int handle, const char* s_time, const char* e_time, char* p_qry_info, char** p_result);
//manual record
SDKS_API int sdks_dev_nvr_manual_record(unsigned int handle, int chn, int record_flag);

//WIFI signal push
SDKS_API int sdks_dev_open_wifi_push(unsigned int handle, SDK_WIFI_CB alarm_cb, void* p_obj);
SDKS_API int sdks_dev_close_wifi_push(unsigned int handle);
 
//PTZ    //v2
SDKS_API int sdks_dev_open_ptz(unsigned int handle); 
SDKS_API int sdks_dev_close_ptz(unsigned int handle); 
SDKS_API int sdks_dev_ptz_stop(unsigned int handle, int chn);
SDKS_API int sdks_dev_ptz_rotate(unsigned int handle, int chn, int operation, int speed);
SDKS_API int sdks_dev_ptz_zoom(unsigned int handle, int chn, int operation, int speed);
SDKS_API int sdks_dev_ptz_focus(unsigned int handle, int chn, int operation);
SDKS_API int sdks_dev_ptz_iris(unsigned int handle, int chn, int operation);
SDKS_API int sdks_dev_ptz_preset(unsigned int handle, int chn, int id, int operation, const char* p_name = NULL);
SDKS_API int sdks_dev_ptz_track(unsigned int handle, int chn, int id, int operation);
SDKS_API int sdks_dev_ptz_scan(unsigned int handle, int chn, int id, int operation);
SDKS_API int sdks_dev_ptz_tour(unsigned int handle, int chn, int id, int operation, int speed,int time);
SDKS_API int sdks_dev_ptz_keeper(unsigned int handle, int chn, int operation, int enable, int type, int id, int time);
SDKS_API int sdks_dev_ptz_threeDimensionalPos(unsigned int handle, int chn, int nX, int nY, float nZoomaTate);
SDKS_API int sdks_dev_ptz_brush(unsigned int handle, int chn, int operation, int mode, int waittime);
SDKS_API int sdks_dev_ptz_light(unsigned int handle, int chn, int operation);
SDKS_API int sdks_dev_ptz_defog(unsigned int handle, int chn, int operation);
SDKS_API int sdks_dev_ptz_postion(unsigned int handle, int chn, int operation, int type, int p_nPan, int p_nTilt, int p_nZoom);
SDKS_API int sdks_dev_get_ptz_postion(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_get_ptz_req(unsigned int handle, int chn, char** p_result); 
SDKS_API int sdks_dev_set_ptz_speed(unsigned int handle, int chn, int speed); 
SDKS_API int sdks_dev_get_ptz_configue(unsigned int handle, int chn, int operation, char** p_result); 
SDKS_API int sdks_dev_get_ptz_timer(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_set_ptz_timer(unsigned int handle, int chn, char* p_param);

//dev cap
SDKS_API int sdks_dev_get_hw_cap(unsigned int handle, dev_hw_cap_t* p_hw_cap);//v2
SDKS_API int sdks_dev_get_hw_cap_by_chn(unsigned int handle, dev_hw_cap_t* p_hw_cap, int chn);//
SDKS_API int sdks_dev_json_get_hw_cap(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_json_get_hw_cap_by_chn(unsigned int handle, int chn, char** p_result);//v2

SDKS_API int sdks_dev_get_sw_cap(unsigned int handle, dev_sw_cap_t* p_sw_cap);//v2
SDKS_API int sdks_dev_json_get_sw_cap(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_get_nw_cap(unsigned int handle, int chn, char** p_result);//v2
SDKS_API int sdks_dev_get_video_cap(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_get_nvr_cap(unsigned int handle, char** p_result);
SDKS_API int sdks_dev_get_language_cap(unsigned int handle, int chn, char **p_result); //v2

//��ͬ���Զ�Ӧ��ͬ��ʱ�������б���
SDKS_API int sdks_dev_get_time_zone_cap(unsigned int handle, int chn, int language_id, char** p_result); //v2
SDKS_API int sdks_dev_get_audio_cap(unsigned int handle, int chn, dev_audio_cap_t* p_audio_cap);//v2
SDKS_API int sdks_dev_json_get_audio_cap(unsigned int handle, int chn, char** p_result);//v2
SDKS_API int sdks_dev_get_ptz_cap(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_get_osd_cap(unsigned int handle, int chn, char** p_result);

// �豸��������
SDKS_API int sdks_dev_get_general_info(unsigned int handle, dev_general_info_t* p_gene_info); //v2
SDKS_API int sdks_dev_get_dev_name(unsigned int handle, dev_name_t* p_dev_name); //v2
SDKS_API int sdks_dev_set_dev_name(unsigned int handle, dev_name_t* p_dev_name); //v2
SDKS_API int sdks_dev_get_dev_time(unsigned int handle, dev_time_t* p_dev_time); //v2
SDKS_API int sdks_dev_set_dev_time(unsigned int handle, dev_time_t* p_dev_time);//v2
SDKS_API int sdks_dev_json_get_general_info(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_dev_json_get_dev_name(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_dev_json_set_dev_name(unsigned int handle, char* p_param); //v2
SDKS_API int sdks_dev_json_get_dev_time(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_json_set_dev_time(unsigned int handle, char* p_param);//v2
SDKS_API int sdks_dev_get_video_system(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_set_video_system(unsigned int handle, char* p_param);//v2
SDKS_API int sdks_dev_get_multi_ability(unsigned int handle,int chn, char** p_result);//v2

//NTP�Զ�Уʱ
SDKS_API int sdks_dev_get_dev_ntp(unsigned int handle, ntp_param_t* p_ntp_param);//v2
SDKS_API int sdks_dev_set_dev_ntp(unsigned int handle, ntp_param_t* p_ntp_param);//v2
SDKS_API int sdks_dev_json_get_dev_ntp(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_json_set_dev_ntp(unsigned int handle, char* p_param);//v2
SDKS_API int sdks_dev_get_dev_id(unsigned int handle, int chn, char** p_result);//v2
SDKS_API int sdks_dev_set_dev_id(unsigned int handle, int chn, char* p_dev_id);//v2
SDKS_API int sdks_dev_get_dev_port(unsigned int handle, dev_port_t* p_dev_port);//v2
SDKS_API int sdks_dev_set_dev_port(unsigned int handle, dev_port_t* p_dev_port);//v2
SDKS_API int sdks_dev_json_get_dev_port(unsigned int handle, char** p_result);//v2
SDKS_API int sdks_dev_json_set_dev_port(unsigned int handle, char* p_param);//v2
SDKS_API int sdks_dev_get_dev_language(unsigned int handle, int chn, char** p_result); //v2
SDKS_API int sdks_dev_set_dev_language(unsigned int handle, int chn, int language_id); //v2
//timezoneʱ��
SDKS_API int sdks_get_dev_time_zone(unsigned int handle, char** result); //v2
SDKS_API int sdks_set_dev_time_zone(unsigned int handle, char* p_dev_time); //v2
SDKS_API int sdks_dev_get_p2p_para(unsigned int handle, int chn, char** p_result); //v2
SDKS_API int sdks_dev_get_web_nat(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_dev_set_web_nat(unsigned int handle, int chn, char* p_param);
//��������(�ƶ���)
SDKS_API int sdks_dev_set_alarm_push_para(unsigned int handle, char* p_alarm_push_para);
SDKS_API int sdks_dev_delete_alarm_push_para(unsigned int handle, char* p_alarm_push_para);
//��ȫ����
SDKS_API int sdks_dev_get_security_para(unsigned int handle, int chn, char** p_result); //v2
SDKS_API int sdks_dev_set_security_para(unsigned int handle, int web_mode, unsigned char encrypt_enable); //v2
SDKS_API int sdks_dev_get_nvr_channel_name(unsigned int handle, int chn, char** p_result); //v2
SDKS_API int sdks_dev_set_channel_name(unsigned int handle, int chn, char *p_param); //v2

SDKS_API int sdks_dev_get_chn_info(unsigned int handle, char** p_result); //v2
// �������
SDKS_API int sdks_dev_get_net_param(unsigned int handle,int chn, char** p_result); //v2
SDKS_API int sdks_dev_set_net_param(unsigned int handle, char* p_net_param); //v2
SDKS_API int sdks_dev_get_ddns(unsigned int handle, int chn, char** p_result); //v2
SDKS_API int sdks_dev_set_ddns(unsigned int handle, char* p_net_ddns); //v2
SDKS_API int sdks_dev_get_ddns_provider(unsigned int handle, int chn, char** p_result); //v2
//FTP����
SDKS_API int sdks_dev_get_ftp(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_dev_set_ftp(unsigned int handle, char* p_net_ftp); //v2
//SMTP����
SDKS_API int sdks_dev_get_smtp(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_dev_set_smtp(unsigned int handle, char* p_net_smtp); //v2
SDKS_API int sdks_dev_get_mtu(unsigned int handle, int* p_mtu); //v2
SDKS_API int sdks_dev_set_mtu(unsigned int handle, int mtu); //v2
//802.1x����
SDKS_API int sdks_dev_get_8021x(unsigned int handle, char **p_result); //v2
SDKS_API int sdks_dev_set_8021x(unsigned int handle, char *p_param); //v2
//PPPOE����
SDKS_API int sdks_dev_get_pppoe(unsigned int handle, char **p_result); //v2
SDKS_API int sdks_dev_set_pppoe(unsigned int handle, char *p_param); //v2
//�˿�ӳ�����
SDKS_API int sdks_dev_get_port_mapping(unsigned int handle, char **p_result); //v2
SDKS_API int sdks_dev_set_port_mapping(unsigned int handle, char *p_param); //v2
//IP���˲���
SDKS_API int sdks_get_ip_filter_param(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_set_ip_filter_param(unsigned int handle, char *p_ip_param); //v2
//��ȫЭ�����
SDKS_API int sdks_get_protocol_security_param(unsigned int handle, char** p_result); //v2
SDKS_API int sdks_set_protocol_security_param(unsigned int handle, char* p_param); //v2


//OSD ����
SDKS_API int sdks_get_osd_param(unsigned int handle,const int chn, char** p_result);
SDKS_API int sdks_set_osd_param(unsigned int handle, int chn, char* p_osd_param);
SDKS_API int sdks_upload_osd_pic(unsigned int handle, int chn, int area_id, char* p_pic_path);

//��˽�ڱβ���
SDKS_API int sdks_get_blind_param(unsigned int handle, const int chn, char** result);
SDKS_API int sdks_set_blind_param(unsigned int handle, int type,char* p_blind_param);

//����������
SDKS_API int sdks_get_svc_stream_para(unsigned int handle, int chn, int stream_id, char** p_result);


//ROI ����
SDKS_API int sdks_get_roi_param(unsigned int handle, char** result);
SDKS_API int sdks_set_roi_param(unsigned int handle, int channel, int stream, char* p_roi_param);

//�ƶ����
SDKS_API int sdks_get_mot_param(unsigned int handle, const int chn, char** result);
SDKS_API int sdks_set_mot_param(unsigned int handle, const int chn, char *p_mot_param);


//�豸����
SDKS_API int sdks_get_dev_list(char **p_json_out);
SDKS_API void sdks_discover_clear_socket_port();
SDKS_API int sdks_get_dev_sddp_list(char **p_json_out);

//�޸�����
SDKS_API int sdks_modify_password_param(unsigned int handle, char* p_system_user_param);
//������¼�û�������
//SDKS_API int sdks_create_login_password_param(unsigned int handle, char* p_creat_login_password_param);

//�û�Ȩ�޹���
SDKS_API int sdks_operator_privilege_user(unsigned int handle, int chn, const char* p_user_list, char** p_result);

//sensor
SDKS_API int sdks_reset_sensor_param(unsigned int handle, int chn);
SDKS_API int sdks_save_sensor_param(unsigned int handle, int chn);
SDKS_API int sdks_reset_sensor_to_last_param(unsigned int handle, int chn);
SDKS_API int sdks_set_sensor_param(unsigned int handle, char* p_sensor_para);
SDKS_API int sdks_get_sensor_param(unsigned int handle, int channel, char** p_result);
SDKS_API int sdks_get_sensor_check(unsigned int handle, int channel, int type, dev_sensor_check_t* _pararm);
SDKS_API int sdks_sensor_start_auto_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_stop_auto_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_start_curve_revise(unsigned int handle, int chn, int distance);
SDKS_API int sdks_sensor_stop_curve_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_start_iris_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_stop_iris_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_start_inf_revise(unsigned int handle, int chn);
SDKS_API int sdks_sensor_stop_inf_revise(unsigned int handle, int chn);

//�����豸
SDKS_API int sdks_dev_reboot(unsigned int handle, int chn);
SDKS_API int sdks_dev_reset(unsigned int handle, int chn,int type);

//�ȳ���ӿ�
SDKS_API int sdks_dev_get_thermal_cap(unsigned int handle, int channel, char **p_result);

SDKS_API int sdks_set_thermal_param(unsigned int handle, int channel, char* p_param);
SDKS_API int sdks_get_thermal_param(unsigned int handle, int channel, char** p_result);

SDKS_API int sdks_set_thermal_area_temperature_measure(unsigned int handle, char* p_param);
SDKS_API int sdks_get_thermal_area_temperature_measure(unsigned int handle, char* p_param, char** p_result);

SDKS_API int sdks_get_thermal_area_feature_temperature(unsigned int handle, char *p_param, char** p_result);

SDKS_API int sdks_get_thermal_one_point_temperature(unsigned int handle, int channel, int x, int y, char** p_result);
SDKS_API int sdks_get_thermal_any_point_temperature(unsigned int handle, int channel, char *p_param, char** p_result);

SDKS_API int sdks_get_map_relation(unsigned int handle, int  channel, char** p_result);
SDKS_API int sdks_set_map_relation(unsigned int handle, char* p_param);

SDKS_API int sdks_get_temperature_calibration(unsigned int handle, int  channel, char** p_result);
SDKS_API int sdks_set_temperature_calibration(unsigned int handle, int channel, char *p_param);

SDKS_API int sdks_get_thermal_version(unsigned int handle, int  channel, char** p_result);

SDKS_API int sdks_test_thermal_bad_point_correct(unsigned int handle, char* p_param);
SDKS_API int sdks_set_thermal_bad_point_correct(unsigned int handle, int channel);
SDKS_API int sdks_reset_thermal_bad_point_correct(unsigned int handle, int channel);

SDKS_API int sdks_get_thermal_alarm_linkage_param(unsigned int handle, int channel, char **p_result);
SDKS_API int sdks_set_thermal_alarm_linkage_param(unsigned int handle, int channel, char *p_param);
//��ȡ��������
SDKS_API int sdks_get_thermal_measurement_parameter(unsigned int handle, int channel, char **p_result);
SDKS_API int sdks_set_thermal_measurement_parameter(unsigned int handle, int channel, char *p_param);

SDKS_API int sdks_thermal_pic_data_start(unsigned int handle, int channel, int stream, SDK_STREAM_THERMAL_PIC_CB stream_cb, void* p_obj);
SDKS_API int sdks_thermal_pic_data_stop(unsigned int handle, int channel, int stream);

//NVR�ȳ���ӿ�
//��������
//SDKS_API int sdks_get_nvr_thermal_place_linkage_param(unsigned int handle, int channel, char **p_result);
//SDKS_API int sdks_set_nvr_thermal_place_linkage_param(unsigned int handle, int channel, char *p_param);
//�߼�����
//SDKS_API int sdks_get_nvr_senior_thermal_param(unsigned int handle, int channel, int *p_advance);
//SDKS_API  int sdks_set_nvr_senior_thermal_param(unsigned int handle, int channel,int advance);

//��ȡ�����¶�
//SDKS_API int sdks_get_thermal_area_temperture_index(unsigned int handle, int channel, char *p_param, char **p_result);
//SDKS_API int sdks_get_thermal_area_temperture_by_index(unsigned int handle, int channel, char *param, char **p_result);



//�ȳ���ԭʼ������
SDKS_API int sdks_dev_thermal_live_start(unsigned int handle, int chn, int stream_type, SDK_DETECT_CB stream_cb, void* p_obj);
SDKS_API int sdks_dev_thermal_live_stop(unsigned int handle, int stream_id);

//�����ӿ�
SDKS_API int sdks_get_face_detect_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_face_detect_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_dev_face_detect_start(unsigned int handle, int chn, int stream_type, int type, SDK_DETECT_CB detect_cb, void* p_obj);
SDKS_API int sdks_dev_face_detect_stop(unsigned int handle, int stream_id);
SDKS_API int sdks_dev_face_get_group_num(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_dev_face_get_member(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_dev_face_check_data(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_dev_face_get_statis(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_dev_face_get_attendance_data(unsigned int handle, int chn, char *p_param, char *path_file);

SDKS_API int sdks_get_channel_type(unsigned int handle, char **p_result);
SDKS_API int sdks_set_channel_type(unsigned int handle, char *p_param);

//����
SDKS_API int sdks_get_lpr_detect_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_lpr_detect_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_lpr_link_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_lpr_link_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_lpr_ipfilter_list_add(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_lpr_ipfilter_list_delete(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_lpr_ipfilter_list_modify(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_lpr_ipfilter_list_num(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_get_lpr_ipfilter_list(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_lpr_ipfilter_list_search_open(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_lpr_ipfilter_list_search_get(unsigned int handle, int chn, char *p_param, char **p_result);
SDKS_API int sdks_lpr_ipfilter_list_search_close(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_lpr_ipfilter_list_file_download(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ai_multi_object_detect_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ai_multi_object_detect_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ai_multi_object_detect_ability(unsigned int handle, int chn, char **p_result);
//��ȡ����ͳ�ƽ������
SDKS_API int sdks_get_ai_multi_person_statistics_param(unsigned int handle, int chn, char *p_param,char **p_result);
//�豸��־
SDKS_API int sdks_get_device_log(unsigned int handle, char *p_param, char **p_result);

//���ܷ���
SDKS_API int sdks_get_ia_version(unsigned int handle, int chn, char **p_result); //�汾��Ϣ
SDKS_API int sdks_get_ia_perimeter_ability(unsigned int handle, int chn, char **p_result); //��������
SDKS_API int sdks_get_ia_svf_ability(unsigned int handle, int chn, char **p_result); //����������
SDKS_API int sdks_get_ia_dvf_ability(unsigned int handle, int chn, char **p_result); //˫����������
SDKS_API int sdks_get_ia_loiter_ability(unsigned int handle, int chn, char **p_result); //�ǻ�����
SDKS_API int sdks_get_ia_multi_loiter_ability(unsigned int handle, int chn, char **p_result); //�����ǻ�����
SDKS_API int sdks_get_ia_object_left_ability(unsigned int handle, int chn, char **p_result); //��Ʒ��������
SDKS_API int sdks_get_ia_object_removed_ability(unsigned int handle, int chn, char **p_result); //��Ʒ��������
SDKS_API int sdks_get_ia_abnormal_speed_ability(unsigned int handle, int chn, char **p_result); //�쳣�ٶ�����
SDKS_API int sdks_get_ia_converse_ability(unsigned int handle, int chn, char **p_result); //��������
SDKS_API int sdks_get_ia_legal_parking_ability(unsigned int handle, int chn, char **p_result); //�Ƿ�ͣ������
SDKS_API int sdks_get_ia_signal_bad_ability(unsigned int handle, int chn, char **p_result); //��Ƶ�ź��쳣����
SDKS_API int sdks_get_ia_advanced_ability(unsigned int handle, int chn, char **p_result); //�߼���������
SDKS_API int sdks_get_ia_perimeter_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_perimeter_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_svf_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_svf_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_dvf_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_dvf_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_loiter_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_loiter_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_multi_loiter_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_multi_loiter_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_object_left_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_object_left_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_object_removed_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_object_removed_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_abnormal_speed_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_abnormal_speed_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_converse_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_converse_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_legal_parking_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_legal_parking_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_signal_bad_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_signal_bad_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_ia_advanced_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_ia_advanced_param(unsigned int handle, int chn, char *p_param);

//fisheye
SDKS_API int sdks_get_fisheye_ability(unsigned int handle, int chn, char **p_result); 
SDKS_API int sdks_get_fisheye_param(unsigned int handle, int chn, char **p_result); 
SDKS_API int sdks_set_fisheye_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_fisheye_video_layout(unsigned int handle, int chn, char **p_result);

//�����Խ�
SDKS_API int sdks_open_microphone(unsigned int handle, int chn, SDK_STREAM_CB microphone_cb, void *p_obj);
SDKS_API int sdks_close_microphone(unsigned int handle, int chn);
SDKS_API int sdks_dev_send_audio_data(unsigned int handle, char *p_data, int audio_len);

//Update
SDKS_API int sdks_update_nvr(unsigned int handle, char *p_path);
SDKS_API int sdks_update_ipc(unsigned int handle, char *p_path);

SDKS_API int sdks_upgrade_nvr(unsigned int handle, char *p_path);
SDKS_API int sdks_upgrade_ipc(unsigned int handle, char *p_path);
SDKS_API int sdks_get_upgrade_progress(unsigned int handle,int *p_progress);

//WIFI
SDKS_API int sdks_get_wifiparam(unsigned int handle, char** result);
SDKS_API int sdks_set_wifiparam(unsigned int handle, char *p_wifi_param);
SDKS_API int sdks_dev_get_wifi_hotspot(unsigned int handle, char** p_result);
SDKS_API int sdks_wifi_conn_hots(unsigned int handle, int chn, char *p_param);

SDKS_API int sdks_get_disk_param(unsigned int handle, int chn, char** result);
SDKS_API int sdks_get_disk_report(unsigned int handle, int chn, char** result);
SDKS_API int sdks_disk_format(unsigned int handle, int chn, int diskid);

//NVR��Ŀ�����
SDKS_API int sdks_mutil_object_downlow_pic_open(unsigned int handle, SDK_MUTI_OBJ_DOWNLOAD_CB cb, void *p_obj);
SDKS_API int sdks_mutil_object_downlow_pic_close(unsigned int handle);
SDKS_API int sdks_multi_object_info_query(unsigned int handle, char *p_param, char **p_result);
SDKS_API int sdks_mutil_object_downlow_pic(unsigned int handle, char *p_param);

SDKS_API int sdks_get_group_compare_alarm_strategy_param(unsigned int handle, int stratege_type, char *p_param, char** p_result);
SDKS_API int sdks_set_group_compare_alarm_strategy_param(unsigned int handle, char *p_param);

SDKS_API int sdks_get_person_temperature_strategy(unsigned int handle, char **p_result);
SDKS_API int sdks_set_person_temperature_strategy(unsigned int handle, char *p_param);

SDKS_API int sdks_get_person_snapshots_num(unsigned int handle, char *p_param, SDK_NVR_SNAP_MSG_CB  cb, void* p_obj);

SDKS_API int sdks_nvr_realtime_compare_start(unsigned int handle, int chn, char  *p_param, SDK_NVR_COMPARE_CB cb, void* p_obj);
SDKS_API int sdks_nvr_realtime_compare_stop(unsigned int handle);

SDKS_API int sdks_get_mask_detect_strategy(unsigned int handle, char **p_result);
SDKS_API int sdks_set_mask_detect_strategy(unsigned int handle, char *p_param);

SDKS_API int sdks_plate_number_add(unsigned int handle, int type, char *param);
SDKS_API int sdks_plate_number_del(unsigned int handle, int type, char *param);
SDKS_API int sdks_plate_number_mod(unsigned int handle, int type, char *param);
SDKS_API int sdks_plate_number_query(unsigned int handle, char *param, char** p_result);

SDKS_API int sdks_get_user_button_param(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_get_master_button_param(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_get_armed_state(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_set_armed_state(unsigned int handle, int chn, int armed_state);
SDKS_API int sdks_get_cur_armed_state(unsigned int handle, int chn, char** p_result);
SDKS_API int sdks_test_user_button_list(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_test_master_button_list(unsigned int handle, int chn, char *p_param);

SDKS_API int sdks_get_white_light_switch_ability(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_get_white_light_switch_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_white_light_switch_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_red_blue_light_switch_ability(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_get_red_blue_light_switch_param(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_set_red_blue_light_switch_param(unsigned int handle, int chn, char *p_param);
SDKS_API int sdks_get_flash_light_switch_ability(unsigned int handle, int chn, char **p_result);
SDKS_API int sdks_get_flash_light_switch_param(unsigned int handle, int chn, char **p_result); //�Ʊ����Ĳ���chnΪ1
SDKS_API int sdks_set_flash_light_switch_param(unsigned int handle, int chn, char *p_param);

SDKS_API int sdks_cloud_server_upgrade_control(unsigned int handle, int command_id, char **p_result);
#ifndef __RJ_WIN__
//��������IP��ַ
SDKS_API void sdks_set_ip_address(const char *p_ip,const int p_size);
#endif
//////////////////////////////////////////////////////////////////////////
#endif // __SDKS_H__
//end
