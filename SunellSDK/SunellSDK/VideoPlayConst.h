#ifndef  PLAYER_DEFINE_CONST
#define PLAYER_DEFINE_CONST

#include <string>

typedef struct _VIDEO_DEVICE_INFO
{
    int      nPort;
    int      nNetType;
    int      nType;
    int      nDeviceType;
    int      pIsFaceDevice;
    char*    pzUserID;
    char*    pzPassword;
    char*    pzDeviceID;
    char*    pzAddr;
    char*    pzMacID;
    char*    pzPhoneNum;
}VideoDevice,*PVideoDevice;

typedef struct _PB_STREAM_TIME
{
    int       nChannelID;
    long long nFrameBeginTime;
    long long nDateBeginTime;
    long long nOneSleepTime;
    long long nSleepTime;
}PBStreamTime,*PPBStreamTime;

typedef enum{
    CommandNone = 0,
    CommandCloseVideo = 1,
    CommandOpenVideo = 2,
    CommandCloseDevice = 3,
    CommandRecvClose = 4,
	CommandSeek = 5,
	CommandStreamChg = 6,
	CommandOpenPtz = 7,
	CommandClosePtz = 8,
    CommandOpenAudio = 9,
    CommandCloseAudio = 10,
	CommandRotatePtz = 11,
	CommandZoomPtz = 12,
	CommandStopPtz = 13,
	CommandIOAlarm = 14,
	CommandPlaybackVideoSpeed = 15,
    CommandGetVideoParam = 16,
	CommandSetVideoParam = 17,
    CommandOpenTalkback = 18,
    CommandCloseTalkback = 19,
    CommandSendTalkbackData = 20,
    CommandIrisPtz = 21,
    CommandFocusPtz = 22,
    CommandPresetPtzCall = 23,
    CommandCurrentRecordPlayOver = 24,
    CommandBrushPZT = 25,
    CommandLightPZT = 26,
    CommandDefogPZT = 27,
    CommandTourPTZ = 28,
    CommandTourPTZEx = 29,
}CommandType;

typedef struct{
    int channelID;
	int streamType;
	int is_hw_dec;
    CommandType commandType;
	int alarmId;
	int control_flag;
	float speed;
	int playId;
    int presetId;
    double ptz_operation;
    int nStreamType;
    char szTime[64];
    char szCloudFile[256];
	int operation;
	double ptzSinValue;
	double ptzCosValue;
    int tourId;
    int during;
    char tourName[128];
}ControlInfo;


//Listener Event ID
const int       OPEN_VIDEO_SUCCESS                  = 100;
const int       OPEN_VIDEO_FAILED                   = 101;
const int       CLOSE_VIDEO_SUCCESS                 = 102;
const int       CLOSE_VIDEO_FAILED                  = 103;
const int       READ_STREAM_TIMEOUT                 = 104;
const int       READ_STREAM_FAILED                  = 105;
const int       OPEN_AUDIO_SUCCESS                  = 106;
const int       OPEN_AUDIO_FAILED                   = 107;
const int       CLOSE_AUDIO_SUCCESS                 = 108;
const int       CLOSE_AUDIO_FAILED                  = 109;
const int       NoAlarmPb                           = 110;
const int       PTZ_ROTATE_RETURN                   = 111;
const int       WIFI_CB                   			= 112;
const int       OPEN_IO_ALARM_OUT_FAILED            = 113;
const int       CLOSE_IO_ALARM_OUT_FAILED           = 114;
const int       OPEN_IO_ALARM_OUT_SUCCESS           = 115;
const int       CLOSE_IO_ALARM_OUT_SUCCESS          = 116;
const int       SET_VIDEO_PARAM_FAILED              = 117;
const int       GET_VIDEO_PARAM_FAILED              = 118;
const int       VIDEO_PARAM_SUCCESS                 = 119;
const int       VIDEO_NO_LIMIT                      = 200;
const int       OPEN_TALKBACK_SUCCESS               = 201;
const int       OPEN_TALKBACK_FAILED                = 202;
const int       CLOSE_TALKBACK_SUCCESS              = 203;
const int       CLOSE_TALKBACK_FAILED               = 204;
const int       AUDIO_DB                      		= 205;
const int       DETECT_FACE                      	= 206;
const int       PTZ_PRESET_GET_SUCCESS              = 207;
const int       PTZ_PRESET_GET_FAILED               = 208;
const int       CURRENT_RECORD_PLAY_OVER            = 209;
const int       VIDEO_DISCONN                 		= 210;

const int       CONNCECT_NOT_ESTABLISHED            = 211;
const int       TIME_OUT                			= 212;
const int       DISCONNCECT                			= 213;
const int       OPEN_PTZ_SUCCESS                	= 214;
const int       RENDER_FIRST_FRAME               	= 215;


//SDK Return
const int       SUCCESS_VIDEO                       = 0;
const int       PLAYER_MAX_CONNECTION               = -511;
const int       SOMEBODY_IS_TALKING               	= -505;
const int       PLAYER_NOT_RUNNING                  = -1001;
const int       SCREENSHOT_FAILTD                   = -1002;
const int       PTZ_NOT_OPENED                      = -1003;
const int       PTZ_OPEN_FAILED                     = -1004;
const int       RECORD_NOT_OPEN                     = -1005;
const int       RECORD_OPENED_NOT_REGISTER          = -1006;
const int       NOT_REGISTER_PLAYER                 = -1007;
const int       RECORD_OPENED_FAILED                = -1008;
const int       OPEN_DEVICE_FAILED                  = -1009;
const int       SESSION_ID_NOT                      = -1010;

//Insight 智能分析
const int       INVADE                  = 1;  //入侵
const int       CORDON                  = 2;  //入侵

#endif
