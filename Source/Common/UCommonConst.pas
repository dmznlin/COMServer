{*******************************************************************************
  ����: dmzn@163.com 2007-10-09
  ����: ��Ŀͨ�ó�,�������嵥Ԫ
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
  //�豸����: ��λ��;��λ��

  TCOMType = (ctDD, ctWQ);
  //����: �����,β�������
  
  TDDType = (NHD6108, MQD6A);
  //���������: �ϻ�6108,��Ȫ

  TWQType = (MQW50A, GB5160);
  //β��������: ��Ȫ50A,����5160

  TWQStatus = (wsTL, wsHK, wsHKStop, wsCQ);
  //β��ҵ��״̬: ����,��������,��������ֹͣ,�鱳������
         
  TWQCheckType = (CTvmas, CTsds, CTlugdown, CTzyjs, CTUnknown);
  //β����ⷽʽ: vams,˫����,���ؼ���,���ɼ���,��֧��

  TMonStatusItem = (msNoRun, msReset, ms2K5, ms3K5,
                    msVStart, msVRun, msVEnd, msVError,
                    msDStart, msDRun_2K5, msDRun_DS, msDEnd, msDError,
                    ms1K8, ms1Pack, msIdle);
  //β�����״̬: δ����;ҵ������;2K5ģʽ,3K5ģʽ;
  //        VMAS: vmas��ʼ;vmas������;vmas����;vmas�쳣
  //      ˫����: ��ʼ,2K5ȡ��,����ȡ��,���ٽ���,����,�쳣
  //    ����״̬: 1K8ģʽ;�����װ�;��ת��(����)
  TMonStatus = set of TMonStatusItem;

  TWQValue = array[0..1] of Char;
  //β��˫�ֽ�ֵ

  PWQData = ^TWQData;
  TWQData = record
    FHead   : array[0..2] of Char;    //Э��ͷ
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //̼��
    FNO     : TWQValue;               //����
    FO2     : TWQValue;               //����
    FSD     : array[0..1] of Char;    //ʪ��
    FYW     : array[0..1] of Char;    //����
    FHJWD   : array[0..1] of Char;    //�����¶�
    FZS     : array[0..1] of Char;    //ת��
    FQLYL   : array[0..1] of Char;    //��·ѹ��
    FKRB    : array[0..1] of Char;    //��ȼ��
    FHJYL   : array[0..1] of Char;    //����ѹ��
    FCRC    : array[0..0] of Char;    //У��λ
  end;

  PWQData5160_A3 = ^TWQData5160_A3;
  TWQData5160_A3 = record
    FStart  : Char;                   //��ʼ�ֽ�
    FCMD    : Char;                   //�����
    FLength : Char;                   //����
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //̼��
    FNO     : TWQValue;               //����
    FO2     : TWQValue;               //����
    FYW     : array[0..1] of Char;    //����
    FZS     : array[0..1] of Char;    //ת��
    FQLYL   : array[0..1] of Char;    //��·ѹ��
    FKRB    : array[0..1] of Char;    //��ȼ��
    FPEF    : array[0..1] of Char;    //PEF
    FCS     : array[0..0] of Char;    //��У��
  end;

  PWQData5160_A8 = ^TWQData5160_A8;
  TWQData5160_A8 = record
    FStart  : Char;                   //��ʼ�ֽ�
    FCMD    : Char;                   //�����
    FLength : Char;                   //����
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //̼��
    FNOx    : TWQValue;               //����
    FO2     : TWQValue;               //����
    FYW     : array[0..1] of Char;    //����
    FZS     : array[0..1] of Char;    //ת��
    FQLYL   : array[0..1] of Char;    //��·ѹ��
    FKRB    : array[0..1] of Char;    //��ȼ��
    FPEF    : array[0..1] of Char;    //PEF
    FNO     : TWQValue;               //no
    FNO2    : TWQValue;               //no2
    FCS     : array[0..0] of Char;    //��У��
  end;

  TWQSimpleData = record
    FCO2    : TWQValue;               //co2
    FCO     : TWQValue;               //co
    FHC     : TWQValue;               //̼��
    FNO     : TWQValue;               //����
    FO2     : TWQValue;               //����
  end;
  TWQDataList = array of TWQSimpleData;

  TWQSimpleItem = record
    FXH: string;                      //������
    FTruck: string;                   //��⳵��
    FType: string;                    //�������
    FIsBlack: Boolean;                //�Ƿ������
    FUsed: Word;                      //ʹ�ô���
    FData: TWQDataList;               //�����б�
  end;
  TWQSimpleItems = array of TWQSimpleItem;

  PWQBiliData = ^TWQBiliData;
  TWQBiliData = record
    FType  : string;              //����
    FName  : string;              //��������
    FStart : Integer;             //��ʼֵ
    FEnd   : Integer;             //����ֵ
    FBili  : Double;              //����ֵ
  end;
  TWQBiliDataList = array of TWQBiliData;

  TCOMItem = record
    FItemName: string;            //�ڵ���
    FItemGroup: string;           //�ڵ����
    FItemType: TCOMType;          //�ڵ�����
    FDDType: TDDType;             //����ͺ�

    FLineNo: Integer;             //����ߺ�
    FTruckNo: string;             //��⳵��
    
    FPortName: string;            //�˿�����
    FBaudRate: TBaudRate;         //������
    FDataBits: TDataBits;         //����λ
    FStopBits: TStopBits;         //��ͣλ

    FCOMObject: TComPort;         //���ڶ���
    FMemo: string;                //������Ϣ
    FBuffer: string;              //���ݻ���
    FData: string;                //Э������
    FDataLast: Int64;             //����ʱ��

    FAdj_Val_HC: Word;            //̼��ֵ(80<x<100,����100У��)
    FAdj_Dir_HC: Boolean;         //��������
    FAdj_Kpt_HC: Word;            //���ִ���
    FAdj_Val_NO: Word;            //����ֵ(200<x<600,����400У��)
    FAdj_Dir_NO: Boolean;
    FAdj_Kpt_NO: Word;
    FAdj_Val_CO: Word;            //̼��ֵ(0.01<x<0.3,����0.3У��)
    FAdj_Dir_CO: Boolean;
    FAdj_Kpt_CO: Word;
    FAdj_Chg_KR: Boolean;         //��ȼ�ȱ䶯
    FAdj_Val_KR: Word;            //��ȼ��(0.97<x<1.03,����1.03У��)
    FAdj_Val_BS: Word;            //��ȼ�Ȼ���
    FAdj_Val_O2: Word;
    FAdj_Kpt_O2: Word;
    FAdj_BSE_O2: Word;            //��������
    FAdj_Val_CO2:Word;
    FAdj_BSE_CO2:Word;            //������̼
    FAdj_LastActive: Int64;       //�ϴδ���
                                              
    FWQType: TWQType;             //β��������
    FWQStatus: TWQStatus;         //ҵ��״̬
    FWQStatusTime: Int64;         //ҵ��ʱ���

    FDeviceType: TDeviceType;     //�豸����
    FGWCheckType: TWQCheckType;   //�������
    FGWStatus: TMonStatus;        //�Ѵ���״̬�嵥

    FGWDataIndex: Integer;        //������������
    FGWDataIndexTime: TDateTime;  //����������ʱ
    FGWDataIndexSDS: Integer;     //˫��������(��ת�ٷ������)
    FGWDataTruck: string;         //��������
    FGWDataLast: Int64;           //����ʱ��
    FGWDataList: TWQDataList;     //��������

                                  //β������
    FWQBiliStart: Cardinal;       //��ʼ�����ʱ
    FWQBiliHC: Double;            //����: HC
    FWQBiliNO: Double;            //����: NO
    FWQBiliNO2: Double;           //����: NO2
    FWQBiliCO: Double;            //����: CO
    FWQBiliCO2: Double;           //����: CO2
  end;

  PDataItem = ^TDataItem;
  TDataItem = record
    Fsoh    : array[0..0] of Char;    //Э��ͷ
    Fno     : array[0..0] of Char;    //��������
    Fylr    : array[0..4] of Char;    //Զ������ƫ��
    Fyud    : array[0..4] of Char;    //Զ�����±���
    Fyi     : array[0..3] of Char;    //Զ��ǿ��
    Fjh     : array[0..2] of Char;    //����Ƹ�
    Fjlr    : array[0..4] of Char;    //��������ƫ��
    Fjud    : array[0..4] of Char;    //��������ƫ��
    Fjp     : array[0..3] of Char;    //�Ƹ߱�ֵ
    Fend    : array[0..0] of Char;    //Э��β
  end;

  TLightData_6A = record
    Fsppc   : array[0..4] of Char;    //ˮƽƫ��
    Fczpc   : array[0..4] of Char;    //��ֱƫ��
    Fgq     : array[0..3] of Char;    //��ǿ
    Fdg     : array[0..3] of Char;    //�Ƹ�
  end;

  PDataItem_6A = ^TDataItem_6A;
  TDataItem_6A = record
    FHead   : array[0..0] of Char;    //Э��ͷ
    FPos    : array[0..0] of Char;    //����(L,R)
    FFar    : TLightData_6A;          //Զ��
    FNear   : TLightData_6A;          //����
    FCRC    : array[0..0] of Char;    //У��λ
  end;

var
  gPath: string;                            //����·��
  gWQCO2AfterPipe: Integer;                 //��ܺ�CO2��Сֵ
  gWQStartInterval: Integer;                //��ܺ���ٺ��뿪ʼ�������
  gWQBili: TWQBiliDataList;                 //β��У������

function MonStatusToStr(const nStatus: TMonStatusItem): string;
function Item2Word(const nItem: array of Char): Word;
procedure Word2Item(var nItem: array of Char; const nWord: Word);
//��ں���

resourcestring
  sHint               = '��ʾ';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

implementation

const
  cStatusName: array[msNoRun..msIdle] of string = (
    'δ����', 'ҵ������', '2K5ģʽ', '3K5ģʽ',
    'vmas��ʼ', 'vmas������', 'vmas����', 'vmas�쳣',
    '˫���ٿ�ʼ', '˫����-2K5', '˫����-����', '˫���ٽ���', '˫�����쳣',
    '1K8ģʽ', '�����װ�����', '����(����)');
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


