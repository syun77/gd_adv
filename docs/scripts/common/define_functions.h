//関数名,     命令コード, 引数リスト, ...
WND_CLOSE,    WND_CLOSE,  
MSG_MODE,     MSG_MODE,   mode=0
WAIT,         WAIT,       time
YIELD,        YIELD,      time=0.0
YIELD2,       YIELD2,     
DRB,          DRB,        id, effectId=0
ERB,          ERB,        effectId=0
BG_PARAM,     BG_PARAM,   xscale=1, yscale=1, rot=0
BG_MOVE,      BG_MOVE,    xofs=0, yofs=0, xscale=0, yscale=0, rot=0
BG_COLOR,     BG_COLOR,   color=0, time=0.0
BG_THRETHOLD, BG_THRETHOLD, on=1, color=0, time=0.0, threthold=0.5
DRC,          DRC,        id, pos, effectId=0
ERC,          ERC,        pos, effectId=0
CH_MOVE,      CH_MOVE,    pos, xofs=0, yofs=0
CH_JUMP,      CH_JUMP,    pos, times=1
CH_SHAKE,     CH_SHAKE,   pos, intensity=0.01, time=0.3
CH_FLASH,     CH_FLASH,   pos, color=0, time=1.0
DRS,          DRS,        id, anime=1, xscale=1, yscale=1, rot=0
ERS,          ERS,        
DRI,          DRI,        id, effectId=3
ERI,          ERI,        effectId=3
SEQ_DRAW,     SEQ_DRAW,   "id", xpos=0, ypos=0
SEQ_ERASE,    SEQ_ERASE,
NAME_OFF,     NAME_OFF,   
FACE_OFF,     FACE_OFF,   
CLS,          CLS,
BGM,          BGM,        "id", time=0.0, isLoop=1
BGM_OFF,      BGM_OFF,    time=1.0
BGM_VOL,      BGM_VOL,    vol=1, time=0.0
SE,           SE,         "id"
SE_PITCH,     SE_PITCH,   "id", pitch=1.0
VOICE,        VOICE,      "id"
VOICE_STOP,   VOICE_STOP,
FADE_IN,      FADE_IN,    color, time
FADE_OUT,     FADE_OUT,   color, time
FADE_WAIT,    FADE_WAIT   
SHAKE,        SHAKE,      intensity=0.002, time=0.5
FLASH,        FLASH,      color, time
JUMP,         JUMP,       advId, jumpId=1
JUMP_SCENE,   JUMP_SCENE, sceneId
NAME_INPUT,   NAME_INPUT, caption, init=""
ITEM_ADD,     ITEM_ADD,   itemId
ITEM_ADD2,    ITEM_ADD2,  itemId
ITEM_HAS,     ITEM_HAS,   itemId
ITEM_DEL,     ITEM_DEL,   itemId
ITEM_DEL_ALL, ITEM_DEL_ALL, 
ITEM_CHK,     ITEM_CHK,   itemId
ITEM_UNEQUIP, ITEM_UNEQUIP
CRAFT_CHK,    CRAFT_CHK,  itemId1, itemId2
ITEM_DETAIL,  ITEM_DETAIL,itemId
NUM_INPUT,    NUM_INPUT,  answer, idx, digit, autoCheck=0
PIC_INPUT,    PIC_INPUT,  picId, answer, idx, digit, autoCheck=0
KANA_INPUT,   KANA_INPUT, kanaId
PANEL_INPUT,  PNL_INPUT,  panelId
ESCAPE_EFFECT, ESCAPE_EFFECT, type
SYSBIT_ON,    SYSBIT_ON,  flagId
SYSBIT_OFF,   SYSBIT_OFF, flagId
SYSBIT_CHK,   SYSBIT_CHK, flagId
BIT_ON,       BIT_ON,     flagId
BIT_OFF,      BIT_OFF,    flagId
BIT_CHK,      BIT_CHK,    flagId
BIT_SUM,      BIT_SUM,    start, end
VAR_GET,      VAR_GET,    varId
VAR_SET,      VAR_SET,    varId, val
AUTO_SAVE,    AUTO_SAVE
GOTO_ROOM,    GOTO_ROOM,  room="room_title"
ADS_START,    ADS_START
LIGHT_RESET,  LIGHT_RESET,
PUZZLE,       PUZZLE,     puzzleId
