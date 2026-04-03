#ifndef __SDKS_JY_H__
#define __SDKS_JY_H__
#include "sdk_def.h"
//#include "sdks_nat.h"
#include "new_sdks_nat.h"

SDKS_API int sdks_dev_alarm_add_push(unsigned int handle, int app_type, const char* p_app_id);
SDKS_API int sdks_dev_alarm_add_push_ex(unsigned int handle, char *p_param);
SDKS_API int sdks_dev_get_alarm_push_list(unsigned int handle, char **p_result);
SDKS_API int sdks_dev_get_alarm_push_param(unsigned int handle, int app_type, const char* p_app_id, char **p_result);
SDKS_API int sdks_dev_alarm_del_push(unsigned int handle, int app_type, const char* p_app_id);
SDKS_API int sdks_dev_get_dev_ver(unsigned int handle);
//SDKS_API int sdks_md_glconsumer_stop(unsigned int handle, int stream_id);

SDKS_API int sdk_reset_req(unsigned int handle);
SDKS_API int sdk_reboot_req(unsigned int handle);

//#ifndef __RJ_WIN32__
SDKS_API void sdk_set_stream_datelen_cb(SDK_STREAM_DATE_LEN stream_len_cb);
//#endif
SDKS_API void sdks_md_handle_roate_vr(unsigned int handle, int stream_id, int p_is_vr);
SDKS_API void sdks_md_handle_roate_gravity(unsigned int handle, int stream_id, int p_isOpenGravity);
SDKS_API void sdks_md_handle_roate_matrix(unsigned int handle, int stream_id, float* p_rotationMatrix);
SDKS_API void sdks_md_handle_set_image_adjust_value(unsigned int handle, int stream_id, int p_imageMode, int p_value);
SDKS_API void sdks_md_handle_init_image_adjust_value(unsigned int handle, int stream_id, int p_brightness, int p_sharpness, int p_contrast, int p_saturation);
SDKS_API void sdks_md_handle_image_param(unsigned int handle, int stream_id, float brightness, float contrast, float acuteness, float saturation);
//tw03 commission
SDKS_API unsigned int  sdks_dev_conn_phone_num(const char* p_ip, unsigned short  port, const char*  p_user, const char* p_passwd, const char* p_phone_num, const char* p_phone_uuid, SDK_DISCONN_CB disconn_cb, void* p_obj);
SDKS_API unsigned int  sdks_dev_conn_phone_num_async(const char* p_ip, unsigned short  port, const char*  p_user, const char* p_passwd, const char* p_phone_num, const char* p_phone_uuid, SDK_DISCONN_CB disconn_cb, SDK_CONNECT_CB conn_cb, void* p_obj);

#ifdef ANDROID
SDKS_API void sdks_md_reset_play_view(unsigned int handle, int stream_id, void *p_objPlayView);
SDKS_API void sdks_md_set_play_view(unsigned int handle, int stream_id, void *p_objPlayView,void *env);
#endif
#endif
