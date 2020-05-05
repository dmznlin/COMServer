{*******************************************************************************
  作者: dmzn@163.com 2007-10-09
  描述: 项目通用常,变量定义单元
*******************************************************************************}
unit UCommonConst;

interface

uses
  CPort, CPortTypes;

type
  PSplitWord = ^TSplitWord;
  TSplitWord = packed record
    FLo: Byte;
    FHi: Byte;
  end;
  
  TDeviceType = (dtStation, dtDevice);
  //设备类型: 上位机;下位机

  TCOMType = (ctDD, ctWQ);
  //类型: 大灯仪,尾气检测仪
  
  TDDType = (NHD6108, MQD6A);
  //大灯仪类型: 南华6108,明泉

  TWQType = (MQW50A, GB5160);
  //尾气仪类型: 明泉50A,锐意5160

  TWQStatus = (wsTL, wsHK, wsHKStop, wsCQ);
  //尾气业务状态: 调零,环境空气,环境空气停止,抽背景空气
         
  TWQCheckType = (CTvmas, CTsds, CTlugdown, CTzyjs, CTUnknown);
  //尾气检测方式: vams,双怠速,加载减速,自由加速,不支持

  TMonStatusItem = (msNoRun, msReset, ms2K5, ms3K5,
                    msVStart, msVRun, msVEnd, msVError,
                    msDStart, msDRun_2K5, msDRun_DS, msDEnd, msDError,
                    ms1K8, ms1Pack, msIdle);
  //尾气检测状态: 未运行;业务重置;2K5模式,3K5模式;
  //        VMAS: vmas开始;vmas运行中;vmas结束;vmas异常
  //      双怠速: 开始,2K5取样,怠速取样,怠速结束,结束,异常
  //    车辆状态: 1K8模式;发送首包;低转速(怠速)
  TMonStatus = set of TMonStatusItem;

  TWQValue = array[0..1] of Char;
  //尾气双字节值

  PWQData = ^TWQData;
  TWQData = record
    FHead   : array[0..2] of Char;    //协议头
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //碳氢
    FNO     : TWQValue;               //氮氧
    FO2     : TWQValue;               //氧气
    FSD     : array[0..1] of Char;    //湿度
    FYW     : array[0..1] of Char;    //油温
    FHJWD   : array[0..1] of Char;    //环境温度
    FZS     : array[0..1] of Char;    //转速
    FQLYL   : array[0..1] of Char;    //气路压力
    FKRB    : array[0..1] of Char;    //空燃比
    FHJYL   : array[0..1] of Char;    //环境压力
    FCRC    : array[0..0] of Char;    //校验位
  end;

  PWQData5160_A3 = ^TWQData5160_A3;
  TWQData5160_A3 = record
    FStart  : Char;                   //起始字节
    FCMD    : Char;                   //命令号
    FLength : Char;                   //长度
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //碳氢
    FNO     : TWQValue;               //氮氧
    FO2     : TWQValue;               //氧气
    FYW     : array[0..1] of Char;    //油温
    FZS     : array[0..1] of Char;    //转速
    FQLYL   : array[0..1] of Char;    //气路压力
    FKRB    : array[0..1] of Char;    //空燃比
    FPEF    : array[0..1] of Char;    //PEF
    FCS     : array[0..0] of Char;    //和校验
  end;

  PWQData5160_A8 = ^TWQData5160_A8;
  TWQData5160_A8 = record
    FStart  : Char;                   //起始字节
    FCMD    : Char;                   //命令号
    FLength : Char;                   //长度
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //碳氢
    FNOx    : TWQValue;               //氮氧
    FO2     : TWQValue;               //氧气
    FYW     : array[0..1] of Char;    //油温
    FZS     : array[0..1] of Char;    //转速
    FQLYL   : array[0..1] of Char;    //气路压力
    FKRB    : array[0..1] of Char;    //空燃比
    FPEF    : array[0..1] of Char;    //PEF
    FNO     : TWQValue;               //no
    FNO2    : TWQValue;               //no2
    FCS     : array[0..0] of Char;    //和校验
  end;

  TWQSimpleData = record
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //碳氢
    FNO     : TWQValue;               //氮氧
    FO2     : TWQValue;               //氧气
  end;
  TWQDataList = array of TWQSimpleData;

  TWQSimpleItem = record
    FXH: string;                      //检测序号
    FTruck: string;                   //检测车辆
    FType: string;                    //检测类型
    FIsBlack: Boolean;                //是否黑名单
    FUsed: Word;                      //使用次数
    FData: TWQDataList;               //数据列表
  end;
  TWQSimpleItems = array of TWQSimpleItem;

  PWQBiliData = ^TWQBiliData;
  TWQBiliData = record
    FType  : string;              //分配
    FName  : string;              //比例名称
    FStart : Integer;             //开始值
    FEnd   : Integer;             //结束值
    FBili  : Double;              //比例值
  end;
  TWQBiliDataList = array of TWQBiliData;

  TCOMItem = record
    FItemName: string;            //节点名
    FItemGroup: string;           //节点分组
    FItemType: TCOMType;          //节点类型
    FDDType: TDDType;             //大灯型号

    FLineNo: Integer;             //检测线号
    FTruckNo: string;             //检测车辆
    
    FPortName: string;            //端口名称
    FBaudRate: TBaudRate;         //波特率
    FDataBits: TDataBits;         //数据位
    FStopBits: TStopBits;         //起停位

    FCOMObject: TComPort;         //串口对象
    FMemo: string;                //描述信息
    FBuffer: string;              //数据缓存
    FData: string;                //协议数据
    FDataLast: Int64;             //接收时间

    FAdj_Val_HC: Word;            //碳氢值(80<x<100,大于100校正)
    FAdj_Dir_HC: Boolean;         //增减方向
    FAdj_Kpt_HC: Word;            //保持次数
    FAdj_Val_NO: Word;            //氧氮值(200<x<600,大于400校正)
    FAdj_Dir_NO: Boolean;
    FAdj_Kpt_NO: Word;
    FAdj_Val_CO: Word;            //碳氧值(0.01<x<0.3,大于0.3校正)
    FAdj_Dir_CO: Boolean;
    FAdj_Kpt_CO: Word;
    FAdj_Chg_KR: Boolean;         //空燃比变动
    FAdj_Val_KR: Word;            //空燃比(0.97<x<1.03,大于1.03校正)
    FAdj_Val_BS: Word;            //空燃比基数
    FAdj_Val_O2: Word;
    FAdj_Kpt_O2: Word;
    FAdj_BSE_O2: Word;            //氧气参数
    FAdj_Val_CO2:Word;
    FAdj_BSE_CO2:Word;            //二氧化碳
    FAdj_LastActive: Int64;       //上次触发
                                              
    FWQType: TWQType;             //尾气仪类型
    FWQStatus: TWQStatus;         //业务状态
    FWQStatusTime: Int64;         //业务时间戳

    FDeviceType: TDeviceType;     //设备类型
    FGWCheckType: TWQCheckType;   //检测类型
    FGWStatus: TMonStatus;        //已处理状态清单

    FGWDataIndex: Integer;        //发送数据索引
    FGWDataIndexTime: TDateTime;  //数据索引计时
    FGWDataIndexSDS: Integer;     //双怠速索引(由转速服务控制)
    FGWDataTruck: string;         //样本车牌
    FGWDataLast: Int64;           //采样时间
    FGWDataList: TWQDataList;     //样本数据

                                  //尾气比例
    FWQBiliStart: Cardinal;       //开始计算计时
    FWQBiliHC: Double;            //比例: HC
    FWQBiliNO: Double;            //比例: NO
    FWQBiliNO2: Double;           //比例: NO2
    FWQBiliCO: Double;            //比例: CO
    FWQBiliCO2: Double;           //比例: CO2
  end;

  PDataItem = ^TDataItem;
  TDataItem = record
    Fsoh    : array[0..0] of Char;    //协议头
    Fno     : array[0..0] of Char;    //数据描述
    Fylr    : array[0..4] of Char;    //远光左右偏移
    Fyud    : array[0..4] of Char;    //远光上下便宜
    Fyi     : array[0..3] of Char;    //远光强度
    Fjh     : array[0..2] of Char;    //近光灯高
    Fjlr    : array[0..4] of Char;    //近光左右偏移
    Fjud    : array[0..4] of Char;    //近光上下偏移
    Fjp     : array[0..3] of Char;    //灯高比值
    Fend    : array[0..0] of Char;    //协议尾
  end;

  TLightData_6A = record
    Fsppc   : array[0..4] of Char;    //水平偏差
    Fczpc   : array[0..4] of Char;    //垂直偏差
    Fgq     : array[0..3] of Char;    //光强
    Fdg     : array[0..3] of Char;    //灯高
  end;

  PDataItem_6A = ^TDataItem_6A;
  TDataItem_6A = record
    FHead   : array[0..0] of Char;    //协议头
    FPos    : array[0..0] of Char;    //左右(L,R)
    FFar    : TLightData_6A;          //远光
    FNear   : TLightData_6A;          //近光
    FCRC    : array[0..0] of Char;    //校验位
  end;

var
  gPath: string;                            //程序路径
  gWQCO2AfterPipe: Integer;                 //插管后CO2最小值
  gWQStartInterval: Integer;                //插管后多少毫秒开始计算比例
  gWQBili: TWQBiliDataList;                 //尾气校正比例

function MonStatusToStr(const nStatus: TMonStatusItem): string;
function Item2Word(const nItem: array of Char): Word;
procedure Word2Item(var nItem: array of Char; const nWord: Word);
//入口函数

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

implementation

const
  cStatusName: array[msNoRun..msIdle] of string = (
    '未运行', '业务重置', '2K5模式', '3K5模式',
    'vmas开始', 'vmas运行中', 'vmas结束', 'vmas异常',
    '双怠速开始', '双怠速-2K5', '双怠速-怠速', '双怠速结束', '双怠速异常',
    '1K8模式', '发送首包数据', '低速(怠速)');
  //status desc

function MonStatusToStr(const nStatus: TMonStatusItem): string;
begin
  Result := cStatusName[nStatus];
end;

function Item2Word(const nItem: array of Char): Word;
var nWord: TSplitWord;
begin
  nWord.FHi := Ord(nItem[0]);
  nWord.FLo := Ord(nItem[1]);
  Result := Word(nWord);
end;

procedure Word2Item(var nItem: array of Char; const nWord: Word);
var nW: TSplitWord;
begin
  nW := TSplitWord(nWord);
  nItem[0] := Char(nW.FHi);
  nItem[1] := Char(nW.FLo);
end;

end.


