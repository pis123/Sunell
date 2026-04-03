#ifndef __SDKS_NAT_H__
#define __SDKS_NAT_H__
#include "sdk_def.h"

typedef struct _map_addr_info_t_
{
	char        ip[64];
	int         port;
	int			relay_port;
}map_addr_info_t;

// nat client
typedef struct nat_cli_man_t* nat_cli_man_h;
SDKS_API nat_cli_man_h sdks_create_nat_man(bool p_start_dev_search = true);
SDKS_API int sdks_man_config_pre_nat(nat_cli_man_h p_man, const char* p_sn, unsigned short remote_port, int pre_nat_min_num, int pre_nat_max_num);
SDKS_API void sdks_destroy_nat_man(nat_cli_man_h p_man);
SDKS_API int sdks_man_get_map_addr(nat_cli_man_h p_man, const char* p_sn, map_addr_info_t* p_addr, unsigned short remote_port, bool use_relay = false);
SDKS_API void sdks_man_unmap_addr(nat_cli_man_h p_man, const char* p_sn, int port);

SDKS_API void sdks_man_add_third_sn(nat_cli_man_h p_man, const char* p_sn);
SDKS_API void sdks_man_del_third_sn(nat_cli_man_h p_man, const char* p_sn);
SDKS_API int sdks_man_get_third_sn_p2p(nat_cli_man_h p_man, const char* p_sn);
SDKS_API int sdks_man_wlan_stat_chg(nat_cli_man_h p_man);
SDKS_API int sdks_man_get_dev_addr(nat_cli_man_h p_man, const char* p_sn, map_addr_info_t* p_addr);

// nat dev
typedef struct rj_nat_inst_t rj_nat_inst_t;
typedef struct rj_nat_inst_t* rj_nat_inst_h;
SDKS_API rj_nat_inst_h sdks_nat_dev_init(const char* p_sn);
SDKS_API int sdks_nat_dev_start(rj_nat_inst_h p_inst);
SDKS_API int sdks_nat_dev_status(rj_nat_inst_h p_inst);
SDKS_API void sdks_nat_dev_quit(rj_nat_inst_h p_inst);
#endif