{*******************************************************************************
  ����: dmzn@163.com 2016-05-05
  ����: ����ת���������
*******************************************************************************}
unit UFormMain;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  USyncTrucks, CPort, CPortTypes, UTrayIcon, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, IdContext,
  ExtCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer,
  StdCtrls, cxMaskEdit, cxDropDownEdit, cxTextEdit, cxLabel, cxCheckBox,
  dxNavBarCollns, cxClasses, dxNavBarBase, dxNavBar, ComCtrls;

type
  TDDType = (NHD6108, MQD6A);
  //���������: �ϻ�6108,��Ȫ

  TWQStatus = (wsTL, wsHK, wsHKStop, wsCQ);
  //β��ҵ��״̬: ����,��������,��������ֹͣ,�鱳������

  TCOMItem = record
    FItemName: string;            //�ڵ���
    FItemGroup: string;           //�ڵ����
    FItemType: TCOMType;          //�ڵ�����
    FDDType: TDDType;             //����ͺ�

    FLineNO: Integer;             //����ߺ�
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

    FWQStatus: TWQStatus;         //ҵ��״̬
    FWQStatusTime: Int64;         //ҵ��ʱ���
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

  PWQData = ^TWQData;
  TWQData = record
    FHead   : array[0..2] of Char;    //Э��ͷ
    FCO2    : array[0..1] of Char;    //co2
    FCO     : array[0..1] of Char;    //co
    FHC     : array[0..1] of Char;    //̼��
    FNO     : array[0..1] of Char;    //����
    FO2     : array[0..1] of Char;    //����
    FSD     : array[0..1] of Char;    //ʪ��
    FYW     : array[0..1] of Char;    //����
    FHJWD   : array[0..1] of Char;    //�����¶�
    FZS     : array[0..1] of Char;    //ת��
    FQLYL   : array[0..1] of Char;    //��·ѹ��
    FKRB    : array[0..1] of Char;    //��ȼ��
    FHJYL   : array[0..1] of Char;    //����ѹ��
    FCRC    : array[0..0] of Char;    //У��λ
  end;

  TfFormMain = class(TForm)
    MemoLog: TMemo;
    StatusBar1: TStatusBar;
    IdTCPServer1: TIdTCPServer;
    Timer1: TTimer;
    dxNavBar1: TdxNavBar;
    dxNavGroup1: TdxNavBarGroup;
    dxNavGroup2: TdxNavBarGroup;
    dxNavGroup2Control: TdxNavBarGroupControl;
    CheckAuto: TcxCheckBox;
    CheckSrv: TcxCheckBox;
    CheckDetail: TcxCheckBox;
    EditPort: TcxTextEdit;
    cxLabel1: TcxLabel;
    HintPanel: TPanel;
    Image1: TImage;
    Image2: TImage;
    Bevel1: TBevel;
    dxNavGroup1Control: TdxNavBarGroupControl;
    CheckLoged: TcxCheckBox;
    HintLabel: TLabel;
    BtnRefresh: TcxLabel;
    CheckAdjust: TcxCheckBox;
    CheckCP: TcxCheckBox;
    CheckGQ: TcxCheckBox;
    dxNavGroup3: TdxNavBarGroup;
    dxNavGroup3Control: TdxNavBarGroupControl;
    ComboGQ: TcxComboBox;
    cxLabel2: TcxLabel;
    Timer2: TTimer;
    CheckYG: TcxCheckBox;
    BtnOnline: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure CheckSrvClick(Sender: TObject);
    procedure CheckLogedClick(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure dxNavGroup2Expanded(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure CheckAdjustClick(Sender: TObject);
    procedure dxNavGroup2Collapsed(Sender: TObject);
    procedure ComboGQPropertiesChange(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure BtnOnlineClick(Sender: TObject);
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*״̬��ͼ��*}
    FYGMinValue: Integer;
    //Զ��ǿ��
    FUserPasswd: string;
    //�û�����
    FListA: TStrings;
    //�ַ��б�
    FDateLast: TDate;
    //����У��
    FCOMPorts: array of TCOMItem;
    //���ڶ���
    procedure ShowLog(const nStr: string);
    //��ʾ��־
    procedure DoExecute(const nContext: TIdContext);
    //ִ�ж���
    procedure LoadCOMConfig;
    //��������
    function FindCOMItem(const nCOM: TObject): Integer; overload;
    function FindSameGroup(const nIdx: Integer): Integer; overload;
    //��������
    procedure RedirectData(const nItem,nGroup: Integer; const nData: string);
    procedure ParseProtocol(const nItem,nGroup: Integer);
    procedure ParseProtocol_6A(const nItem,nGroup: Integer);
    procedure ParseWQProtocol(const nItem,nGroup: Integer);
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //���ݴ���
    function AdjustProtocol(const nData: PDataItem): Boolean;
    function AdjustProtocol_6A(const nData: PDataItem_6A): Boolean;
    function AdjustWQProtocol(const nItem,nGroup: Integer;
      const nData: PWQData; const nInBlack: Boolean): Boolean;
    //У������
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}
uses
  IniFiles, Registry, ULibFun, UMgrCOMM, ZnMD5, USysLoger, UFormInputbox;

const
  cChar_Head       = Char($01);                       //Э��ͷ
  cChar_End        = Char($FF);                       //Э��β
  cSizeData        = SizeOf(TDataItem);               //���ݴ�С

  cChar_Head_6A    = Char($02);                       //Э��ͷ
  cSizeData_6A     = SizeOf(TDataItem_6A);            //���ݴ�С

  cChar_WQ_Head    = Char($06)+Char($60)+Char($1B);   //Э��ͷ
  cChar_WQ_Head_L  = Length(cChar_WQ_Head);           //ͷ��С
  cSize_WQ_Data    = SizeOf(TWQData);                 //���ݴ�С

  cAdj_KeepLong    = 6;                              //���ݱ���������
  cAdj_Interval    = 1 * 1000 * 60;                  //У��������Ч��

  sCMD_WQ_TL      = Char($02) + Char($67) + Char($03) + Char($94); //����ָ��
  sCMD_WQ_CQ      = Char($02) + Char($7B) + Char($03) + Char($80); //����ָ��
  sCMD_WQ_HK      = Char($02) + Char($7C) + Char($03) + Char($7F); //��������
  sCMD_WQ_Stop    = Char($02) + Char($78) + Char($03) + Char($83); //ָֹͣ��

type
  PSplitWord = ^TSplitWord;
  TSplitWord = packed record
    FLo: Byte;
    FHi: Byte;
  end;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '���ڷ���', nEvent);
end;

function COMType2Str(const nType: TCOMType): string;
begin
  case nType of
   ctDD: Result := '�����';
   ctWQ: Result := 'β�����';
  end;
end;

function DDType2Str(const DT: TDDType): string;
begin
  case DT of
   NHD6108 : Result := 'NHD-6108';
   MQD6A   : Result := 'MQD-6A';
  end;
end;

function Str2COMType(const nStr: string): TCOMType;
begin
  if nStr = '1' then
       Result := ctWQ
  else Result := ctDD;
end;

//------------------------------------------------------------------------------
procedure TfFormMain.FormCreate(Sender: TObject);
var nStr: string;
    nIni: TIniFile;
    nReg: TRegistry;
begin
  Randomize;
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogEvent := ShowLog;

  CheckLoged.Checked := True;
  {$IFNDEF DEBUG}  
  dxNavGroup2.OptionsExpansion.Expanded := False;
  {$ENDIF}

  FDateLast := Date();
  SetLength(FCOMPorts, 0);
  FListA := TStringList.Create; 

  nIni := nil;
  nReg := nil;
  try
    nIni := TIniFile.Create(gPath + 'Config.ini');
    if IsSystemExpire(gPath + 'Lock.ini') then
    begin
      dxNavGroup2.Visible := False;
      Exit;
    end;
    
    EditPort.Text := nIni.ReadString('Config', 'Port', '8000');
    Timer1.Enabled := nIni.ReadBool('Config', 'Enabled', False);
    CheckAdjust.Checked := nIni.ReadBool('Config', 'CloseAdjust', False);

    CheckCP.Tag := nIni.ReadInteger('Config', 'CloseCPEnable', 1);
    CheckCP.Enabled := CheckCP.Tag <> 0;

    if CheckCP.Enabled then
         CheckCP.Checked := nIni.ReadBool('Config', 'CloseCP', False)
    else CheckCP.Checked := False;

    CheckGQ.Checked := nIni.ReadBool('Config', 'CloseGQ', False);
    FUserPasswd := nIni.ReadString('Config', 'UserPassword', 'admin');
    FYGMinValue := nIni.ReadInteger('Config', 'YGMinValue', 5000);
    //Զ��ǿ������

    with ComboGQ do
    begin
      nStr := nIni.ReadString('Config', 'YGMinValueList', '');
      SplitStr(nStr, Properties.Items, 0, ',');
      nStr := IntToStr(FYGMinValue);

      if Properties.Items.IndexOf(nStr) < 0 then
        Properties.Items.Add(nStr);
      ComboGQ.Text := nStr;

      if ItemIndex < 0 then
        ItemIndex := 0;
      //xxxxx
    end;

    nStr := nIni.ReadString('Config', 'Title', '');
    if nStr <> '' then
      Caption := nStr;
    //xxxxx

    nReg := TRegistry.Create;
    nReg.RootKey := HKEY_CURRENT_USER;

    nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
    CheckAuto.Checked := nReg.ValueExists(sAutoStartKey);
    LoadFormConfig(Self, nIni);
  finally
    nIni.Free;
    nReg.Free;
  end;

  nStr := ChangeFileExt(Application.ExeName, '.ico');
  if FileExists(nStr) then
    Application.Icon.LoadFromFile(nStr);
  //change app icon

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := Caption;
  FTrayIcon.Visible := True;

  gTruckManager := TTruckManager.Create(gPath + sConfig);
  //ͬ�����߳���

  LoadCOMConfig;
  //��ȡ��������
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
    nReg: TRegistry;
begin
  if Assigned(gTruckManager) then
    gTruckManager.StopMe;
  gTruckManager := nil;
  
  nIni := nil;
  nReg := nil;
  try
    nIni := TIniFile.Create(gPath + 'Config.ini');
    nIni.WriteBool('Config', 'Enabled', CheckSrv.Checked);
    nIni.WriteBool('Config', 'CloseAdjust', CheckAdjust.Checked);

    nIni.WriteBool('Config', 'CloseCP', CheckCP.Checked);
    nIni.WriteBool('Config', 'CloseGQ', CheckGQ.Checked);
    SaveFormConfig(Self, nIni);

    if nIni.ReadString('Config', 'Port', '') = '' then
      nIni.WriteString('Config', 'Port', EditPort.Text);
    //xxxxx

    nReg := TRegistry.Create;
    nReg.RootKey := HKEY_CURRENT_USER;

    nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
    if CheckAuto.Checked then
      nReg.WriteString(sAutoStartKey, Application.ExeName)
    else if nReg.ValueExists(sAutoStartKey) then
      nReg.DeleteValue(sAutoStartKey);
    //xxxxx
  finally
    nIni.Free;
    nReg.Free;
  end;

  FreeAndNil(FListA);
end;

procedure TfFormMain.Timer1Timer(Sender: TObject);
var i: Integer;
begin
  GetValidCOMPort(FListA);
  //enum port

  for i:=Low(FCOMPorts) to High(FCOMPorts) do
   with FCOMPorts[i] do
    if FListA.IndexOf(FPortName) < 0 then
    begin
      WriteLog(Format('�ȴ�[ %s.%s ]�˿ڽ���ϵͳ.', [FItemName, FPortName]));
      Exit;
    end;

  Timer1.Enabled := False;
  CheckSrv.Checked := True;

  {$IFNDEF DEBUG}
  if CheckSrv.Checked then
    FTrayIcon.Minimize;
  //xxxxx
  {$ENDIF}
end;

procedure TfFormMain.Timer2Timer(Sender: TObject);
begin
  Timer2.Tag := Timer2.Tag + 1;
  if Timer2.Tag < 3600 then Exit;
  Timer2.Tag := 0;

  //if FDateLast = Date() then Exit;
  FDateLast := Date();

  if IsSystemExpire(gPath + 'Lock.ini') then
  begin
    Timer2.Enabled := False;
    CheckSrv.Checked := False;
    dxNavGroup2.Visible := False;
  end;
end;

procedure TfFormMain.CheckSrvClick(Sender: TObject);
var nIdx,nErr: Integer;
begin
  nErr := 0;
  for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
   with FCOMPorts[nIdx] do
    if Assigned(FCOMObject) then
    try
      if CheckSrv.Checked then
           FCOMObject.Open
      else FCOMObject.Close;
    except
      on E:Exception do
      begin
        Inc(nErr);
        FMemo := E.Message;
        WriteLog(E.Message);
      end;
    end;

  if nErr > 0 then
  begin
    CheckSrv.Checked := False;
    Exit;
  end; //any error

  if not IdTCPServer1.Active then
    IdTCPServer1.DefaultPort := StrToInt(EditPort.Text);
  IdTCPServer1.Active := CheckSrv.Checked;
  EditPort.Enabled := not CheckSrv.Checked;
end;

procedure TfFormMain.CheckLogedClick(Sender: TObject);
begin
  gSysLoger.LogSync := CheckLoged.Checked;
end;

procedure TfFormMain.ShowLog(const nStr: string);
var nIdx: Integer;
begin
  MemoLog.Lines.BeginUpdate;
  try
    MemoLog.Lines.Insert(0, nStr);
    if MemoLog.Lines.Count > 100 then
     for nIdx:=MemoLog.Lines.Count - 1 downto 50 do
      MemoLog.Lines.Delete(nIdx);
  finally
    MemoLog.Lines.EndUpdate;
  end;
end;

procedure TfFormMain.BtnRefreshClick(Sender: TObject);
var nIdx: Integer;
begin
  MemoLog.Clear;
  MemoLog.Lines.Add('ˢ���豸�б�:');

  for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
  with FCOMPorts[nIdx],MemoLog.Lines do
  begin
    Add('�豸: ' + IntToStr(nIdx+1));
    Add('|--- ����: ' + FItemName);
    Add('|--- ����: ' + FItemGroup);
    Add('|--- ����: ' + COMType2Str(FItemType));

    if FItemType = ctDD then
    Add('|--- ����: ' + DDType2Str(FDDType));
    //xxxxx

    Add('|--- �ߺ�: ' + IntToStr(FLineNO));
    Add('|--- �˿�: ' + FPortName);
    Add('|--- ����: ' + BaudRateToStr(FBaudRate));
    Add('|--- ��λ: ' + DataBitsToStr(FDataBits));
    Add('|--- ͣλ: ' + StopBitsToStr(FStopBits));
    Add('|--- ��ע: ' + FMemo);
    Add('');
  end;
end;

procedure TfFormMain.BtnOnlineClick(Sender: TObject);
begin
  MemoLog.Lines.BeginUpdate;
  try
    MemoLog.Clear;
    gTruckManager.LoadTruckToList(MemoLog.Lines);
    MemoLog.SelStart := 0;
  finally
    MemoLog.Lines.EndUpdate;
  end;
end;

procedure TfFormMain.dxNavGroup2Expanded(Sender: TObject);
var nStr: string;
begin
  if ShowInputPWDBox('���������Ա����:', '', nStr) then
       dxNavGroup2.OptionsExpansion.Expanded := nStr = FUserPasswd
  else dxNavGroup2.OptionsExpansion.Expanded := False;

  with dxNavGroup3.OptionsExpansion do
    Expanded := dxNavGroup2.OptionsExpansion.Expanded;
  //xxxxx
end;

procedure TfFormMain.dxNavGroup2Collapsed(Sender: TObject);
begin
  with dxNavGroup3.OptionsExpansion do
    Expanded := dxNavGroup2.OptionsExpansion.Expanded;
  //xxxxx
end;

procedure TfFormMain.ComboGQPropertiesChange(Sender: TObject);
begin
  if ComboGQ.Focused then
    FYGMinValue := StrToInt(ComboGQ.Text);
  //xxxxx
end;

procedure TfFormMain.CheckAdjustClick(Sender: TObject);
begin
  CheckCP.Enabled := (not CheckAdjust.Checked) and (CheckCP.Tag <> 0);
  CheckGQ.Enabled := not CheckAdjust.Checked;

  CheckYG.Enabled := not CheckAdjust.Checked;
  CheckYG.Checked := False; //Ĭ�ϲ�����
end;

//------------------------------------------------------------------------------
procedure TfFormMain.IdTCPServer1Execute(AContext: TIdContext);
begin
  try
    DoExecute(AContext);
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
      AContext.Connection.Socket.InputBuffer.Clear;
    end;
  end;
end;

procedure TfFormMain.DoExecute(const nContext: TIdContext);
begin
  //
end;

//Desc: ��ȡ����
procedure TfFormMain.LoadCOMConfig;
var nStr: string;
    nIdx: Integer;
    nDef: TCOMItem;
    nIni: TIniFile;
    nList: TStrings;
begin
  nList := TStringList.Create;
  nIni := TIniFile.Create(gPath + 'Ports.ini');
  try
    nIni.ReadSections(nList);
    FillChar(nDef, SizeOf(nDef), #0);
    SetLength(FCOMPorts, nList.Count);

    for nIdx:=nList.Count-1 downto 0 do
    with FCOMPorts[nIdx],nIni do
    begin
      FCOMPorts[nIdx] := nDef;
      FItemName  := ReadString(nList[nIdx], 'Name', '');
      FItemGroup := ReadString(nList[nIdx], 'Group', '');
      FItemType := Str2COMType(ReadString(nList[nIdx], 'Type', '0'));
      FLineNO := ReadInteger(nList[nIdx], 'LineNo', 0);

      nStr := ReadString(nList[nIdx], 'DDModel', 'NHD-6108');
      if CompareText(nStr, 'MQD-6A') = 0 then
           FDDType := MQD6A
      else FDDType := NHD6108;

      FPortName  := ReadString(nList[nIdx], 'PortName', '');
      FBaudRate  := StrToBaudRate(ReadString(nList[nIdx], 'BaudRate', '9600'));
      FDataBits  := StrToDataBits(ReadString(nList[nIdx], 'DataBits', '8'));
      FStopBits  := StrToStopBits(ReadString(nList[nIdx], 'StopBits', '1'));

      FBuffer := '';
      FData := '';
      FDataLast := 0;
      FCOMObject := nil;
      FAdj_LastActive := 0;

      FWQStatus := wsTL;
      FWQStatusTime := 0;

      if ReadInteger(nList[nIdx], 'Enable', 0) <> 1 then
      begin
        FMemo := '�˿ڽ���';
        Continue;
      end;

      FMemo := '�˿�����';
      FCOMObject := TComPort.Create(Application);
      
      with FCOMObject do
      begin
        Port := FPortName;
        BaudRate := FBaudRate;
        FDataBits := FDataBits;
        FStopBits := FStopBits;

        SyncMethod := smNone;
        OnRxChar := OnCOMData;
      end;

      with FCOMObject.Timeouts do
      begin
        ReadTotalConstant := 1000;
        ReadTotalMultiplier := 100;
      end;  
    end;
  finally
    nList.Free;
    nIni.Free;
  end;   
end;

//Date: 2016-05-05
//Parm: ���ڶ���
//Desc: ����nCOM��Ӧ����
function TfFormMain.FindCOMItem(const nCOM: TObject): Integer;
var nIdx: Integer;
begin
  Result := -1;
  for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
  if FCOMPorts[nIdx].FCOMObject = nCOM then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2016-05-05
//Parm: ���ڶ�������
//Desc: ����nIdx��ͬ�����
function TfFormMain.FindSameGroup(const nIdx: Integer): Integer;
var i: Integer;
begin
  Result := -1;
  for i:=Low(FCOMPorts) to High(FCOMPorts) do
  if (CompareText(FCOMPorts[i].FItemGroup, FCOMPorts[nIdx].FItemGroup) = 0) and
     (i <> nIdx) then
  begin
    Result := i;
    Break;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-05-05
//Parm: ����;���ݴ�С
//Desc: ����������
procedure TfFormMain.OnCOMData(Sender: TObject; Count: Integer);
var nStr: string;
    nIdx,nInt: Integer;
    nItem,nGroup: Integer;
begin
  if Count < 1 then
  begin
    Sleep(100);
    Exit;
  end else Sleep(1);
  //�߳��ӳ�

  try
    nItem := FindCOMItem(Sender);
    if (nItem < 0) or (FCOMPorts[nItem].FCOMObject = nil) then
    begin
      WriteLog('�յ�����,���޷�ƥ�䴮�ڶ���.');
      Exit;
    end;

    with FCOMPorts[nItem] do
    begin
      FCOMObject.ReadStr(FBuffer, Count);
      nInt := Length(FBuffer);

      if CheckDetail.Checked then //��ʾ��ϸ
      begin
        nStr := '';
        for nIdx:=1 to nInt do
          nStr := nStr + IntToHex(Ord(FBuffer[nIdx]), 2) + ' ';
        //ʮ������

        nStr := Format('�˿�:[ %s ] ����:[ %s ]', [FItemName, nStr]);
        WriteLog(nStr);
      end;
    end; //��ȡ����

    nGroup := FindSameGroup(nItem);
    if (nGroup < 0) or (FCOMPorts[nGroup].FCOMObject = nil) then
    begin
      nStr := '�յ�����,���޷�ƥ�䴮��[ %s ]ͬ�����.';
      WriteLog(Format(nStr, [FCOMPorts[nItem].FItemName]));
      Exit;
    end;

    if CheckAdjust.Checked then
      RedirectData(nItem, nGroup, FCOMPorts[nItem].FBuffer) else  //ֱ��ת��
    //xxxxx

    if FCOMPorts[nItem].FItemType = ctWQ then
         ParseWQProtocol(nItem, nGroup)                           //β������
    else ParseProtocol(nItem, nGroup);                            //����Э��
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2016/5/6
//Parm: Դ�˿�;Ŀ��˿�;����
//Desc: ��nData����ת����nGroup�˿�
procedure TfFormMain.RedirectData(const nItem,nGroup: Integer;
 const nData: string);
var nStr: string;
    {$IFDEF DEBUG}nIdx: Integer;{$ENDIF}
begin
  FCOMPorts[nGroup].FCOMObject.WriteStr(nData);
  //xxxxx

  if CheckDetail.Checked then
  begin
    nStr := '�˿�:[ %s ] ����:[ ת���� %s ]';
    nStr := Format(nStr, [FCOMPorts[nItem].FItemName, FCOMPorts[nGroup].FItemName]);
    WriteLog(nStr);
  end;

  {$IFDEF DEBUG}
  WriteLog('����(10): ' + nData);
  nStr := '';

  for nIdx:=1 to Length(nData) do
    nStr := nStr + IntToHex(Ord(nData[nIdx]), 2) + ' ';
  WriteLog('����(16): ' + nStr);
  {$ENDIF}
end;

//Date: 2016/5/6
//Parm: Դ�˿�;ת���˿�
//Desc: ����nItem�˿�����,У����������������,Ȼ��ת����nGroup�˿�
procedure TfFormMain.ParseProtocol(const nItem, nGroup: Integer);
var i,nS,nE,nPos: Integer;
    nData: TDataItem;
    nBuf: array[0..cSizeData-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    if FDDType = MQD6A then //��Ȫ6A
    begin
      ParseProtocol_6A(nItem, nGroup);
      Exit;
    end;

    nE := Length(FData);
    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //��ʱ����ֱ��ת��

    if nE > cSizeData then
    begin
      while nE > 0 do
      begin
        nPos := nE;
        Dec(nE);
        if FData[nPos] = cChar_Head then Break;
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //���ݰ�����ʱ,���һ��Э��ͷλ��,��ǰ�������ת��

    //--------------------------------------------------------------------------
    nS := Pos(cChar_Head, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      Exit;
    end; //��Э������ֱ��ת��

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //�������ݴ�����

    nS := 0;
    nE := 0;
    nPos := Length(FData);

    for i:=nPos downto 1 do
    begin
      if FData[i] = cChar_End then
        nE := i;
      //xxxx

      if (FData[i] = cChar_Head) and (nE > 0) then
      begin
        nS := i;
        Break;
      end;
    end;

    if (nS < 1) or (nE-nS <> cSizeData-1) then
    begin
      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, FData);
        FData := '';
      end;

      Exit;
    end; //δ�ҵ�����Э���

    //--------------------------------------------------------------------------
    if gTruckManager.VIPTruckInLine(FLineNO, ctDD) then //VIP��������У��
    begin
      StrPCopy(@nBuf[0], Copy(FData, nS, cSizeData));
      Move(nBuf, nData, cSizeData);
      //���Ƶ�Э���,׼������

      if AdjustProtocol(@nData) then
      begin
        SetString(FBuffer, PChar(@nData.Fsoh), cSizeData);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //��������
  end;
end;

//Date: 2016/5/7
//Parm: Э������
//Desc: ����Э������,�б�ҪʱУ��
function TfFormMain.AdjustProtocol(const nData: PDataItem): Boolean;
var nStr,nSVal: string;
    nIdx,nInt: Integer;
    nYGVerify: Boolean;
    nPY,nDG,nDQ,nRnd,nVal: Double;
begin
  Result := False;
  {$IFDEF DEBUG}
  nStr := '����:[ ' + nData.Fjud + '] ' +
          '�Ƹ�:[ ' + nData.Fjh + '] ' +
          '��ֵ:[ ' + nData.Fjp + '] ' +
          'ǿ��:[ ' + nData.Fyi + ']';
  WriteLog(nStr);
  {$ENDIF}

  nDQ := StrToFloat(nData.Fyi);
  //Զ��ǿ��
  nYGVerify := (nDQ < 0.1) and CheckYG.Checked;
  //Զ���쳣У��

  nPY := StrToFloat(nData.Fjud);
  //����ƫ��
  nDG := StrToFloat(nData.Fjh);
  //�Ƹ�
  
  if nYGVerify then
  begin
    if nDG < 0.1 then
      nDG := 60 + Random(20);
    //��������Ƹ�
  end;

  if nPY < 0.1 then
    nPY := 0.01;
  //���ϸ�ƫ��,������������У���߼�

  if (nPY <> 0) and (nDG <> 0) and (not CheckCP.Checked) then
  begin
    nVal := (nDG - nPY) / nDG;
    nVal := Float2Float(nVal, 100, True);
    //��ֱƫ����

    if (nVal <= 0.70) or ((nVal >= 0.80) and (nVal < 2.0)) then
    begin
      nRnd := Random(100);
      while (nRnd = 0) or (nRnd = 100) do
        nRnd := Random(100);
      //xxxxx

      if nRnd >= 10 then
        nRnd := nRnd / 10;
      nRnd := 0.7 + nRnd / 100;
      //���ֵ(0.71 - 0.79)

      nVal := nDG - nRnd * nDG;
      nSVal := Format('%.2f', [nVal]);
      nSVal := '+' + nSVal;

      nIdx := Length(nSVal);
      nInt := Length(nData.Fjud);
      if nIdx < nInt then
        nSVal := nSVal + StringOfChar('0', nInt-nIdx);
      //xxxxx

      nStr := Format('��ֱƫ��:[ %s -> %s ]', [Copy(nData.Fjud, 1, nInt),
                                               Copy(nSVal, 1, nInt)]);
      WriteLog(nStr);

      nInt := 1;
      for nIdx:=Low(nData.Fjud) to High(nData.Fjud) do
      begin
        nData.Fjud[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //ƫ����

      nSVal := Format('%.3f', [nRnd]);
      nInt := 1;
      for nIdx:=Low(nData.Fjp) to High(nData.Fjp) do
      begin
        nData.Fjp[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //ƫ�Ʊ���

      Result := True;
    end;
  end;

  //----------------------------------------------------------------------------
  if (not CheckGQ.Checked) and (nYGVerify or (
     (nDQ > FYGMinValue / 100) and (nDQ < 150))) then
  begin
    nDQ := 150 + Random(50);
    nSVal := FloatToStr(nDQ);

    nInt := Length(nData.Fyi) - Length(nSVal);
    if nInt > 0 then
      nSVal := StringOfChar('0', nInt) + nSVal;
    //xxxxx

    nInt := Length(nData.Fyi);
    nStr := Format('�ƹⲹ��:[ %s -> %s ]', [Copy(nData.Fyi, 1, nInt),
                                             Copy(nSVal, 1, nInt)]);
    WriteLog(nStr);

    nInt := 1;
    for nIdx:=Low(nData.Fyi) to High(nData.Fyi) do
    begin
      nData.Fyi[nIdx] := nSVal[nInt];
      Inc(nInt);
    end;
    Result := True;
  end; //�ƹ�ǿ�Ȳ���

  if Result or CheckDetail.Checked then
  begin
    nStr := '����:[ ' + nData.Fjud + '] ' +
            '�Ƹ�:[ ' + nData.Fjh + '] ' +
            '��ֵ:[ ' + nData.Fjp + '] ' +
            'ǿ��:[ ' + nData.Fyi + ']';
    WriteLog(nStr);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2017-09-19
//Parm: ��������
//Desc: У��λ,ǰ38λ֮��ȡ����1
function CRC_6A(const nData: string): Char;
var nIdx,nLen,nVal: Integer;
begin
  nVal := 0;
  nLen := Length(nData) - 1;

  for nIdx:=1 to nLen do
    nVal := nVal + Ord(nData[nIdx]);
  //xxxxx
  
  nVal := Byte(nVal xor $FF) + 1;
  Result := Char(nVal);
end;

//Date: 2017-09-18
//Parm: Դ�˿�;ת���˿�
//Desc: ����nItem�˿�����,У����������������,Ȼ��ת����nGroup�˿�
procedure TfFormMain.ParseProtocol_6A(const nItem, nGroup: Integer);
var i,nS,nE,nPos: Integer;
    nData: TDataItem_6A;
    nBuf: array[0..cSizeData_6A-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    nE := Length(FData);
    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //��ʱ����ֱ��ת��

    if nE > cSizeData_6A then
    begin
      while nE > 0 do
      begin
        nPos := nE;
        Dec(nE);
        if FData[nPos] = cChar_Head_6A then Break;
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //���ݰ�����ʱ,���һ��Э��ͷλ��,��ǰ�������ת��

    //--------------------------------------------------------------------------
    nS := Pos(cChar_Head_6A, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      Exit;
    end; //��Э������ֱ��ת��

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //�������ݴ�����

    nS := 0;
    nE := 0;
    nPos := Length(FData);

    for i:=nPos downto 1 do
    begin
      if FData[i] <> cChar_Head_6A then Continue;
      //not head

      if nPos - i + 1 < 2 then Continue;
      //not full head

      if (FData[i+1] = 'L') or (FData[i+1] = 'R') then //���Ҵ������
           nS := i
      else nS := -1;

      if nS < 0 then Break;
      //not valid data

      if nPos - i + 1 >= cSizeData_6A then
      begin
        nE := i + cSizeData_6A - 1;
        Break;
      end;
    end;

    if (nS < 0) or ((nS < 1) and (nPos >= cSizeData_6A)) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';

      Exit;
      //δ�ҵ�Э���
    end;

    if nE < 1 then Exit;
    //δ�ҵ�����Э���

    //--------------------------------------------------------------------------
    if gTruckManager.VIPTruckInLine(FLineNO, ctDD) then //VIP��������У��
    begin
      StrPCopy(@nBuf[0], Copy(FData, nS, cSizeData_6A));
      Move(nBuf, nData, cSizeData_6A);
      //���Ƶ�Э���,׼������

      if AdjustProtocol_6A(@nData) then
      begin
        SetString(FBuffer, PChar(@nData.FHead), cSizeData_6A);
        FBuffer[cSizeData_6A] := CRC_6A(FBuffer);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //��������
  end;
end;

//Date: 2017-09-18
//Parm: Э������
//Desc: ����Э������,�б�ҪʱУ��
function TfFormMain.AdjustProtocol_6A(const nData: PDataItem_6A): Boolean;
var nStr,nSVal: string;
    nIdx,nInt: Integer;
    nYGVerify: Boolean;
    nPY,nDG,nDQ,nRnd,nVal: Double;
begin
  Result := False;
  {$IFDEF DEBUG}
  nStr := '����:[ ' + nData.FNear.Fczpc + '] ' +
          '�Ƹ�:[ ' + nData.FNear.Fdg + '] ' +
          'ǿ��:[ ' + nData.FNear.Fgq + ']';
  WriteLog(nStr);
  {$ENDIF}

  nDQ := StrToFloat(nData.FFar.Fgq);
  //Զ��ǿ��
  nYGVerify := (nDQ < 0.1) and CheckYG.Checked;
  //Զ���쳣У��

  nPY := StrToFloat(nData.FNear.Fczpc);
  //����ƫ��
  nDG := StrToFloat(nData.FNear.Fdg);
  //�Ƹ�
  
  if nYGVerify then
  begin
    if nDG < 0.1 then
      nDG := 60 + Random(20);
    //��������Ƹ�
  end;

  if nPY < 0.1 then
    nPY := 0.01;
  //���ϸ�ƫ��,������������У���߼�

  if (nPY <> 0) and (nDG <> 0) and (not CheckCP.Checked) then
  begin
    nVal := (nDG - nPY) / nDG;
    nVal := Float2Float(nVal, 100, True);
    //��ֱƫ����

    if (nVal <= 0.70) or ((nVal >= 0.80) and (nVal < 2.0)) then
    begin
      nRnd := Random(100);
      while (nRnd = 0) or (nRnd = 100) do
        nRnd := Random(100);
      //xxxxx

      if nRnd >= 10 then
        nRnd := nRnd / 10;
      nRnd := 0.7 + nRnd / 100;
      //���ֵ(0.71 - 0.79)

      nVal := nDG - nRnd * nDG;
      nSVal := Format('%.2f', [nVal]);
      nSVal := '+' + nSVal;

      nIdx := Length(nSVal);
      nInt := Length(nData.FNear.Fczpc);
      if nIdx < nInt then
        nSVal := nSVal + StringOfChar('0', nInt-nIdx);
      //xxxxx

      nStr := Format('��ֱƫ��:[ %s -> %s ]', [Copy(nData.FNear.Fczpc, 1, nInt),
                                               Copy(nSVal, 1, nInt)]);
      WriteLog(nStr);

      nInt := 1;
      for nIdx:=Low(nData.FNear.Fczpc) to High(nData.FNear.Fczpc) do
      begin
        nData.FNear.Fczpc[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //ƫ����

      Result := True;
    end;
  end;

  //----------------------------------------------------------------------------
  if (not CheckGQ.Checked) and (nYGVerify or (
     (nDQ > FYGMinValue / 100) and (nDQ < 150))) then
  begin
    nDQ := 150 + Random(50);
    nSVal := FloatToStr(nDQ);

    nInt := Length(nData.FNear.Fgq) - Length(nSVal);
    if nInt > 0 then
      nSVal := StringOfChar('0', nInt) + nSVal;
    //xxxxx

    nInt := Length(nData.FNear.Fgq);
    nStr := Format('�ƹⲹ��:[ %s -> %s ]', [Copy(nData.FNear.Fgq, 1, nInt),
                                             Copy(nSVal, 1, nInt)]);
    WriteLog(nStr);

    nInt := 1;
    for nIdx:=Low(nData.FNear.Fgq) to High(nData.FNear.Fgq) do
    begin
      nData.FNear.Fgq[nIdx] := nSVal[nInt];
      Inc(nInt);
    end;
    Result := True;
  end; //�ƹ�ǿ�Ȳ���

  if Result or CheckDetail.Checked then
  begin
    nStr := '����:[ ' + nData.FNear.Fczpc + '] ' +
            '�Ƹ�:[ ' + nData.FNear.Fdg + '] ' +
            'ǿ��:[ ' + nData.FNear.Fgq + ']';
    WriteLog(nStr);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-10-08
//Parm: ����
//Desc: ��nStr���к�У��
function MakeCRC(const nStr: string; const nS,nE: Integer): Char;
var nIdx: Integer;
    nRes: Byte;
begin
  nRes := 0;
  for nIdx:=nS to nE do
    nRes := nRes + Ord(nStr[nIdx]);
  //xxxxx

  nRes := nRes xor $FF + 1;
  Result := Char(nRes);
end;

//Date: 2016-10-08
//Parm: Դ�˿�;ת���˿�
//Desc: ����nItem�˿�����,У����������������,Ȼ��ת����nGroup�˿�
procedure TfFormMain.ParseWQProtocol(const nItem, nGroup: Integer);
var nS,nE,nPos,nIdx: Integer;
    nData: TWQData;
    nInBlack: Boolean;
    nBuf: array[0..cSize_WQ_Data-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    nE := Length(FData);
    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //��ʱ����ֱ��ת��

    if nE > cSize_WQ_Data then
    begin
      while nE > 0 do
      begin
        nPos := nE;
        Dec(nE);

        if Copy(FData, nPos, cChar_WQ_Head_L) = cChar_WQ_Head then Break;
        //last header
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //���ݰ�����ʱ,���һ��Э��ͷλ��,��ǰ�������ת��

    //--------------------------------------------------------------------------
    nS := Pos(sCMD_WQ_TL, FBuffer);
    if nS > 0 then
    begin
      FData := '';
      FWQStatus := wsTL;
      FAdj_LastActive := 0;
      
      RedirectData(nItem, nGroup, sCMD_WQ_TL);
      Exit;
    end; //����ָ��,��������

    nS := Pos(cChar_WQ_Head, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      //��Э������ֱ��ת��

      {$IFDEF CheckCQCommand}
      if FWQStatus = wsTL then
      begin
        nS := Pos(sCMD_WQ_HK, FBuffer);
        if nS > 0 then
          FWQStatus := wsHK;
        //�����黷������
      end;

      if FWQStatus = wsHK then
      begin
        nS := Pos(sCMD_WQ_Stop, FBuffer);
        if nS > 0 then
        begin
          FWQStatus := wsHKStop;
          FWQStatusTime := GetTickCount;
        end; //�黷����������
      end;

      if FWQStatus = wsHKStop then
      begin
        nS := Pos(sCMD_WQ_CQ, FBuffer);
        if nS > 0 then
        begin
          FWQStatus := wsCQ;
          //�鱳������
        end else
        begin
          nS := GetTickCount - FWQStatusTime;
          //��������������,��2���δ���ͳ���,�򲹷�ָ��.

          if (nS > 2000) and (nS < 3500) then
          begin
            Sleep(500);
            RedirectData(nItem, nGroup, sCMD_WQ_CQ);
            Sleep(500);

            FWQStatus := wsCQ;
            WriteLog(Format('�˿�:[ %s ]��������ָ��.', [FItemName]));
          end;

          if nS >= 3500 then
            FWQStatus := wsCQ;
          //��ʱ��ȡ������
        end;
      end;  
      {$ENDIF}
      
      Exit;
    end; 

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //�������ݴ�����

    nS := Pos(cChar_WQ_Head, FData);
    nPos := Length(FData);
    if nPos - nS + 1 < cSize_WQ_Data then Exit; //δ�ҵ�����Э���

    if gTruckManager.VIPTruckInLine(FLineNO, ctWQ, @nInBlack) then //VIP��������У��
    begin
      nE := nS + cSize_WQ_Data - 1;
      FBuffer := Copy(FData, nS, cSize_WQ_Data);

      for nIdx:=Low(nBuf) to High(nBuf) do
        nBuf[nIdx] := FBuffer[nIdx + 1];
      Move(nBuf, nData, cSize_WQ_Data);
      //���Ƶ�Э���,׼������

      //if (nData.FCRC = MakeCRC(FBuffer, nS, nE-1)) then
      if AdjustWQProtocol(nItem, nGroup, @nData, nInBlack) then
      begin
        SetString(FBuffer, PChar(@nData.FHead), cSize_WQ_Data);
        FBuffer[cSize_WQ_Data] := MakeCRC(FBuffer, 1, cSize_WQ_Data - 1);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //��������
  end;
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

//Date: 2016-10-08
//Parm: Դ�˿�;ת���˿�;Э������;������
//Desc: ����Э������,�б�ҪʱУ��
function TfFormMain.AdjustWQProtocol(const nItem,nGroup: Integer;
  const nData: PWQData; const nInBlack: Boolean): Boolean;
var nStr: string;
    nInt: Integer;
begin
  Result := False;

  {$IFDEF DEBUG}
  nStr := 'CO2:[ ' + IntToStr(Item2Word(nData.FCO2)) + ' ] ' +
          'CO:[ ' + IntToStr(Item2Word(nData.FCO)) + ' ] ' +
          'HC:[ ' + IntToStr(Item2Word(nData.FHC)) + ' ] ' +
          'NO:[ ' + IntToStr(Item2Word(nData.FNO)) + ' ] ' +
          'O2:[ ' + IntToStr(Item2Word(nData.FO2)) + ' ] ' +
          'ʪ��:[ ' + IntToStr(Item2Word(nData.FSD)) + ' ] ' +
          '����:[ ' + IntToStr(Item2Word(nData.FYW)) + ' ]';
  WriteLog(nStr);

  nStr := 'ת��:[ ' + IntToStr(Item2Word(nData.FZS)) + ' ] ' +
          '��ȼ��:[ ' + IntToStr(Item2Word(nData.FKRB)) + ' ] ' +
          '��·ѹ��:[ ' + IntToStr(Item2Word(nData.FQLYL)) + ' ] ' +
          '����ѹ��:[ ' + IntToStr(Item2Word(nData.FHJYL)) + ' ] ' +
          '�����¶�:[ ' + IntToStr(Item2Word(nData.FHJWD)) + ' ]';
  WriteLog(nStr);
  {$ENDIF}

  with FCOMPorts[nItem] do
  begin
    nInt := Item2Word(nData.FCO) + Item2Word(nData.FCO2);
    if nInt < 600 then Exit;
    //co2��Ũ�ȱ�ʶδ��ʼ

    if nInBlack then //������ҵ��
    begin
      nInt := Item2Word(nData.FCO);
      if nInt < 60 then //̼��: 60<x<130
      begin
        if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
           (FAdj_Val_CO < 1) then
        begin
          FAdj_Kpt_CO := Random(cAdj_KeepLong);
          FAdj_Val_CO := 60 + Random(70);
        
          if FAdj_Val_CO < 95 then
               FAdj_Dir_CO := True
          else FAdj_Dir_CO := False;
        end;

        if FAdj_Kpt_CO < 1 then
        begin
          FAdj_Kpt_CO := Random(cAdj_KeepLong);
          //xxxxx
        
          if FAdj_Dir_CO then
               FAdj_Val_CO := FAdj_Val_CO + Random(3)
          else FAdj_Val_CO := FAdj_Val_CO - Random(3);
        end else Dec(FAdj_Kpt_CO);

        if FAdj_Val_CO >= 130 then
        begin
          FAdj_Val_CO := 129;
          FAdj_Dir_CO := False;
        end;

        if FAdj_Val_CO <= 60 then
        begin
          FAdj_Val_CO := 61;
          FAdj_Dir_CO := True;
        end;

        Word2Item(nData.FCO, FAdj_Val_CO);
        Result := True;

        nStr := Format('̼��(CO):[ %d -> %d ]', [nInt, FAdj_Val_CO]);
        WriteLog(nStr);
      end;

      FAdj_LastActive := GetTickCount;
      //upate time stamp
      Exit;
    end;

    //--------------------------------------------------------------------------
    nInt := Item2Word(nData.FKRB); //��ȼ��: 0.97<x<1.02
    if (nInt >= 1020) or ((nInt <= 970) and (nInt >= 700)) then 
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_BS < 1) then
        FAdj_Val_BS := 990 + Random(30); //1030 - 990 = 40
      //base value

      FAdj_Val_BS := 1005; //1005 -1015
      FAdj_Val_KR := FAdj_Val_BS + Random(10);
      Word2Item(nData.FKRB, FAdj_Val_KR);

      nStr := Format('��ȼ��:[ %d -> %d ]', [nInt, FAdj_Val_KR]);
      WriteLog(nStr);

      Result := True;
      FAdj_Chg_KR := True;
    end else FAdj_Chg_KR := False;

    if FAdj_Chg_KR then //��ȼ�ȱ䶯,���������Ͷ�����̼
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_BSE_O2 < 1) then
      begin
        //FAdj_BSE_O2 := 40 + Random(40);  //����: 30-90,����10
        FAdj_BSE_O2 := 8; //0.08-0.4
        FAdj_Kpt_O2 := Random(cAdj_KeepLong);
        FAdj_Val_O2 := FAdj_BSE_O2 + Random(32);
      end;

      if FAdj_Kpt_O2 < 1 then
      begin
        FAdj_Kpt_O2 := Random(cAdj_KeepLong);
        //xxxxx

        if Random(10) mod 2 = 0 then
             FAdj_Val_O2 := FAdj_BSE_O2 + Random(32)
        else FAdj_Val_O2 := FAdj_BSE_O2 - Random(32);
      end else Dec(FAdj_Kpt_O2);

      nStr := Format('����(O2):[ %d -> %d ]', [Item2Word(nData.FO2), FAdj_Val_O2]);
      WriteLog(nStr);
      Word2Item(nData.FO2, FAdj_Val_O2);

      FAdj_BSE_CO2 := 1465 + Random(15); //14.65 - 14.80
      FAdj_Val_CO2 := Trunc((FAdj_BSE_CO2 / 100 - FAdj_Val_O2 / 100) * 100);

      nStr := Format('������̼(CO2):[ %d -> %d ]', [Item2Word(nData.FCO2), FAdj_Val_CO2]);
      WriteLog(nStr);
      Word2Item(nData.FCO2, FAdj_Val_CO2);
    end;

    nInt := Item2Word(nData.FHC);
    if nInt >= 100 then //̼��: 80<x<100
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_HC < 1) then
      begin
        FAdj_Kpt_HC := Random(cAdj_KeepLong);
        FAdj_Val_HC := 80 + Random(20);

        if FAdj_Val_HC < 90 then
             FAdj_Dir_HC := True
        else FAdj_Dir_HC := False;
      end;

      if FAdj_Kpt_HC < 1 then
      begin
        FAdj_Kpt_HC := Random(cAdj_KeepLong);
        //xxxxx

        if FAdj_Dir_HC then
             FAdj_Val_HC := FAdj_Val_HC + Random(3)
        else FAdj_Val_HC := FAdj_Val_HC - Random(3);
      end else Dec(FAdj_Kpt_HC);

      if FAdj_Val_HC >= 100 then
      begin
        FAdj_Val_HC := 99;
        FAdj_Dir_HC := False;
      end;

      if FAdj_Val_HC <= 80 then
      begin
        FAdj_Val_HC := 81;
        FAdj_Dir_HC := True;
      end;

      Word2Item(nData.FHC, FAdj_Val_HC);
      Result := True;

      nStr := Format('̼��(HC):[ %d -> %d ]', [nInt, FAdj_Val_HC]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FCO);
    if nInt >= 30 then //̼��: 1<x<30
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_CO < 1) then
      begin
        FAdj_Kpt_CO := Random(cAdj_KeepLong);
        FAdj_Val_CO := 1 + Random(29);
        
        if FAdj_Val_CO < 15 then
             FAdj_Dir_CO := True
        else FAdj_Dir_CO := False;
      end;

      if FAdj_Kpt_CO < 1 then
      begin
        FAdj_Kpt_CO := Random(cAdj_KeepLong);
        //xxxxx
        
        if FAdj_Dir_CO then
             FAdj_Val_CO := FAdj_Val_CO + Random(3)
        else FAdj_Val_CO := FAdj_Val_CO - Random(3);
      end else Dec(FAdj_Kpt_CO);

      if FAdj_Val_CO >= 30 then
      begin
        FAdj_Val_CO := 29;
        FAdj_Dir_CO := False;
      end;

      if FAdj_Val_CO <= 1 then
      begin
        FAdj_Val_CO := 2;
        FAdj_Dir_CO := True;
      end;

      Word2Item(nData.FCO, FAdj_Val_CO);
      Result := True;

      nStr := Format('̼��(CO):[ %d -> %d ]', [nInt, FAdj_Val_CO]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FNO);
    if nInt >= 600 then //����:200<x<600
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_NO < 1) then
      begin
        FAdj_Kpt_NO := Random(cAdj_KeepLong);
        FAdj_Val_NO := 200 + Random(400);
        FAdj_Dir_NO := not FAdj_Dir_HC;
      end;

      if FAdj_Kpt_NO < 1 then
      begin
        FAdj_Kpt_NO := Random(cAdj_KeepLong);
        //xxxxx

        if FAdj_Dir_NO then
             FAdj_Val_NO := FAdj_Val_NO + Random(20)
        else FAdj_Val_NO := FAdj_Val_NO - Random(20);
      end else Dec(FAdj_Kpt_NO);

      if FAdj_Val_NO >= 600 then
      begin
        FAdj_Val_NO := 599;
        FAdj_Dir_NO := False;
      end;

      if FAdj_Val_NO <= 200 then
      begin
        FAdj_Val_NO := 201;
        FAdj_Dir_NO := True;
      end;

      Word2Item(nData.FNO, FAdj_Val_NO);
      Result := True;

      nStr := Format('����(NO):[ %d -> %d ]', [nInt, FAdj_Val_NO]);
      WriteLog(nStr);
    end;

    FAdj_LastActive := GetTickCount;
    //upate time stamp
  end;
end;

end.
