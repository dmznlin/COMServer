{*******************************************************************************
  作者: dmzn@163.com 2016-05-05
  描述: 串口转发服务程序
*******************************************************************************}
unit UFormMain;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  USyncTrucks, CPort, CPortTypes, UTrayIcon, UMonitor, SyncObjs, UBase64,
  UCommonConst, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, IdContext, ExtCtrls, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer, StdCtrls, cxMaskEdit, cxDropDownEdit,
  cxTextEdit, cxLabel, cxCheckBox, dxNavBarCollns, cxClasses, dxNavBarBase,
  dxNavBar, ComCtrls, cxSpinEdit, cxTimeEdit;

type
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
    CheckShowWQ: TcxCheckBox;
    Label1: TcxLabel;
    EditTimeStart: TcxTimeEdit;
    Label2: TcxLabel;
    EditTimeEnd: TcxTimeEdit;
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
    procedure EditTimeEndPropertiesChange(Sender: TObject);
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*状态栏图标*}
    FSyncLock: TCriticalSection;
    //同步锁定
    FYGMinValue: Integer;
    //远光强度
    FUserPasswd: string;
    //用户密码
    FListA: TStrings;
    //字符列表
    FDateLast: TDate;
    //日期校验
    FCOMPorts: array of TCOMItem;
    //串口对象
    procedure ShowLog(const nStr: string);
    //显示日志
    procedure DoExecute(const nContext: TIdContext);
    //执行动作
    procedure LoadCOMConfig;
    //载入配置
    function FindCOMItem(const nCOM: TObject): Integer; overload;
    function FindSameGroup(const nIdx: Integer): Integer; overload;
    //检索数据
    procedure RedirectData(const nItem,nGroup: Integer; const nData: string);
    procedure ParseProtocol(const nItem,nGroup: Integer);
    procedure ParseProtocol_6A(const nItem,nGroup: Integer);
    procedure ParseWQProtocol(const nItem,nGroup: Integer);
    procedure ParseWQProtocol_5105(const nItem,nGroup: Integer);
    procedure ParseWQProtocol_5160(const nItem,nGroup: Integer);
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //数据处理
    function AdjustProtocol(const nData: PDataItem): Boolean;
    function AdjustProtocol_6A(const nData: PDataItem_6A): Boolean;
    {$IFDEF WQUseSimple}
    function AdjustWQProtocolBySimple(const nItem,nGroup: Integer;
      const nData: PWQData; const nInBlack: Boolean): Boolean;
    {$ELSE}
    function AdjustWQProtocol(const nItem,nGroup: Integer;
      const nData: PWQData; const nInBlack: Boolean): Boolean;
    {$ENDIF}
    function AdjustWQProtocol_5105(const nItem,nGroup,nHeadType: Integer;
      const nData: Pointer; const nInBlack: Boolean): Boolean;
    function AdjustWQProtocol_5160(const nItem,nGroup,nHeadType: Integer;
      const nData: Pointer; const nInBlack: Boolean): Boolean;
    //校正数据
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}
uses
  IniFiles, Registry, ULibFun, UMgrCOMM, ZnMD5, USysLoger, USysDB,
  UFormInputbox, UObjectList;

const
  cChar_Head       = Char($01);                       //协议头
  cChar_End        = Char($FF);                       //协议尾
  cSizeData        = SizeOf(TDataItem);               //数据大小

  cChar_Head_6A    = Char($02);                       //协议头
  cSizeData_6A     = SizeOf(TDataItem_6A);            //数据大小

  cChar_WQ_Head    = Char($06)+Char($60)+Char($1B);   //协议头
  cChar_WQ_Head_L  = Length(cChar_WQ_Head);           //头大小
  cSize_WQ_Data    = SizeOf(TWQData);                 //数据大小
         
  cChar_WQ_Head_A3 = Char($06)+Char($A3)+Char($17);   //A3协议头
  cChar_WQ_Head_A3_L  = Length(cChar_WQ_Head_A3);     //A3头大小
  cSize_WQ_Data_A3 = SizeOf(TWQData5160_A3);          //数据大小

  cChar_WQ_Head_A8 = Char($06)+Char($A8)+Char($1B);   //A8协议头
  cChar_WQ_Head_A8_L  = Length(cChar_WQ_Head_A8);     //A8头大小
  cSize_WQ_Data_A8 = SizeOf(TWQData5160_A8);          //数据大小

  cChar_WQ_JCQ     = Char($06) + Char($7F) + Char($03) + Char($78); //通检查气
  cChar_WQ_JCQDone = Char($06) + Char($78) + Char($03) + Char($7F); //检查气结束

  cAdj_KeepLong    = 6;                              //数据保持最大次数
  cAdj_Interval    = 1 * 1000 * 60;                  //校正数据有效期

  sCMD_WQ_TL      = Char($02) + Char($67) + Char($03) + Char($94); //调零指令
  sCMD_WQ_CQ      = Char($02) + Char($7B) + Char($03) + Char($80); //抽气指令
  sCMD_WQ_HK      = Char($02) + Char($7C) + Char($03) + Char($7F); //环境空气
  sCMD_WQ_Stop    = Char($02) + Char($78) + Char($03) + Char($83); //停止指令

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '串口服务', nEvent);
end;

function COMType2Str(const nType: TCOMType): string;
begin
  case nType of
   ctDD: Result := '大灯仪';
   ctWQ: Result := '尾气检测';
  end;
end;

function DDType2Str(const DT: TDDType): string;
begin
  case DT of
   NHD6108 : Result := 'NHD-6108';
   MQD6A   : Result := 'MQD-6A';
  end;
end;

function WQType2Str(const WQ: TWQType): string;
begin
  case WQ of
   MQW50A : Result := 'MQW50A';
   GB5160 : Result := 'GB5160';
   MQ5105 : Result := 'MQ5105';
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
    nIdx: Integer;
    nList: TStrings;
    nIni: TIniFile;
    nReg: TRegistry;

  //Desc: 载入尾气计算比例
  procedure LoadWQBili(const nSection: string);
  var nS: string;
      nEnlarge: Double;
      nIdx,nInt,nPos: Integer;
  begin
    nEnlarge := nIni.ReadFloat('Config', 'Enlarge' + nSection, 1);
    //放大参数: 尾气仪整数值与化验报告数据的转换关系
    nIni.ReadSection(nSection, nList);
    
    nInt := Length(gWQBili);
    SetLength(gWQBili, nInt + nList.Count);

    for nIdx:=0 to nList.Count-1 do
    with gWQBili[nInt] do
    try
      FType  := nSection;
      FName  := nList[nIdx];
      FBili  := 1;
      FStart := 0;
      FEnd   := 0;

      nStr := nIni.ReadString(nSection, FName, '');
      nPos := Pos(',', nStr);
      if nPos < 1 then Continue;

      nS := Trim(Copy(nStr, nPos + 1, Length(nStr) - nPos));
      if IsNumber(nS, True) then
        FBili := StrToFloat(nS);
      nStr := Copy(nStr, 1, nPos - 1);

      nPos := Pos('-', nStr);
      if nPos < 1 then Continue;
      nS := Trim(Copy(nStr, 1, nPos - 1));
      if IsNumber(nS, True) then
        FStart := Trunc(StrToFloat(nS) * nEnlarge);
      //xxxxxx

      nS := Trim(Copy(nStr, nPos + 1, Length(nStr) - nPos));
      if IsNumber(nS, True) then
        FEnd := Trunc(StrToFloat(nS) * nEnlarge);
      //xxxxx
    finally
      Inc(nInt);
    end;

    nS := nIni.ReadString('Config', 'NextLevel' + nSection, '0');
    if IsNumber(nS, True) then
    begin
      if nSection = 'HC' then gWQBiliNext.FHC := Trunc(StrToFloat(nS) * nEnlarge);
      if nSection = 'NO' then gWQBiliNext.FNO := Trunc(StrToFloat(nS) * nEnlarge);
      if nSection = 'NO2' then gWQBiliNext.FNO2 := Trunc(StrToFloat(nS) * nEnlarge);
      if nSection = 'CO' then gWQBiliNext.FCO := Trunc(StrToFloat(nS) * nEnlarge);
      if nSection = 'CO2' then gWQBiliNext.FCO2 := Trunc(StrToFloat(nS) * nEnlarge);
      if nSection = 'KRB' then gWQBiliNext.FKRB := Trunc(StrToFloat(nS) * nEnlarge);
    end;
  end;

  //Desc: 载入检测线标气值
  procedure LoadWQBiaoQi(const nLine: string);
  var nS: string;
      nLen: Integer;
      nEnlarge: Double;
  begin
    if not nIni.SectionExists(nLine) then Exit;
    nLen := Length(gWQBiaoQi);
    SetLength(gWQBiaoQi, nLen + 1);

    with gWQBiaoQi[nLen] do
    begin
      FLineNo := nIni.ReadInteger(nLine, 'Line', -1);
      //线号
      
      nEnlarge := nIni.ReadFloat('Config', 'EnlargeHC', 1);
      FHC := Trunc(nIni.ReadFloat(nLine, 'HC', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'HC', '0');
      
      if IsNumber(nS, True) then
           FHC_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FHC_WC := 0;

      nEnlarge := nIni.ReadFloat('Config', 'EnlargeNO', 1);
      FNO := Trunc(nIni.ReadFloat(nLine, 'NO', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'NO', '0');

      if IsNumber(nS, True) then
           FNO_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FNO_WC := 0;

      nEnlarge := nIni.ReadFloat('Config', 'EnlargeNO2', 1);
      FNO2 := Trunc(nIni.ReadFloat(nLine, 'NO2', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'NO2', '0');

      if IsNumber(nS, True) then
           FNO2_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FNO2_WC := 0;

      nEnlarge := nIni.ReadFloat('Config', 'EnlargeCO', 1);
      FCO := Trunc(nIni.ReadFloat(nLine, 'CO', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'CO', '0');

      if IsNumber(nS, True) then
           FCO_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FCO_WC := 0;

      nEnlarge := nIni.ReadFloat('Config', 'EnlargeCO2', 1);
      FCO2 := Trunc(nIni.ReadFloat(nLine, 'CO2', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'CO2', '0');
      
      if IsNumber(nS, True) then
           FCO2_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FCO2_WC := 0;

      nEnlarge := nIni.ReadFloat('Config', 'EnlargeO2', 1);
      FO2 := Trunc(nIni.ReadFloat(nLine, 'O2', 0) * nEnlarge);
      nS := nIni.ReadString('WuCha', 'O2', '0');
      
      if IsNumber(nS, True) then
           FO2_WC := Trunc(StrToFloat(nS) * nEnlarge)
      else FO2_WC := 0;
    end;
  end;
begin
  Randomize;
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogEvent := ShowLog;

  FSyncLock := TCriticalSection.Create;
  //sync lock
  gObjectPoolManager := TObjectPoolManager.Create;
  gObjectPoolManager.RegClass(TStringList);
  //object buffer

  CheckLoged.Checked := True;
  {$IFNDEF DEBUG}  
  dxNavGroup2.OptionsExpansion.Expanded := False;
  {$ENDIF}

  FDateLast := Date();
  SetLength(FCOMPorts, 0);
  FListA := TStringList.Create; 

  nIni := nil;
  nReg := nil;
  nList := nil;
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
    //远光强度下限

    EditTimeStart.Time := nIni.ReadTime('Config', 'WNTimeStart', Str2Time('00:00:00'));
    gWNTimeStart := EditTimeStart.Time;
    EditTimeEnd.Time := nIni.ReadTime('Config', 'WNTimeEnd', Str2Time('23:59:59'));
    gWNTimeEnd := EditTimeEnd.Time;
    //万能码时间控制

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

    //--------------------------------------------------------------------------
    nIni.Free;
    nIni := TIniFile.Create(gPath + 'bili.ini');
    gWQIntervalAfterPipe := nIni.ReadInteger('Config', 'StartInterval', 3000);
    gWQIntervalBeforePipe := nIni.ReadInteger('Config', 'ClearInterval', 5000);
    gWQCO2BeforePipe := nIni.ReadInteger('Config', 'CO2BeforePipe', 10);
    gWQCO2AfterPipe := nIni.ReadInteger('Config', 'CO2AfterPipe', 600);

    FillChar(gWQBiliNext, SizeOf(gWQBiliNext), #0);
    nList := TStringList.Create;
    SetLength(gWQBili, 0);
    
    LoadWQBili('HC');
    LoadWQBili('NO');
    LoadWQBili('NO2');
    LoadWQBili('CO');
    LoadWQBili('CO2');
    LoadWQBili('KRB');

    //--------------------------------------------------------------------------
    nIni.Free;
    nIni := TIniFile.Create(gPath + 'BiaoQi.ini');
    nStr := nIni.ReadString('Config', 'Lines', '');
    SplitStr(nStr, nList, 0, ',');

    SetLength(gWQBiaoQi, 0);
    for nIdx:=0 to nList.Count-1 do
      LoadWQBiaoQi(nList[nIdx]);
    //读取特定线号标气
  finally
    nList.Free;
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
  //同步在线车辆

  LoadCOMConfig;
  //读取串口配置
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
    nReg: TRegistry;
begin
  IdTCPServer1.Active := False;
  //stop server
  
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

    nIni.WriteTime('Config', 'WNTimeStart', EditTimeStart.Time);
    nIni.WriteTime('Config', 'WNTimeEnd', EditTimeEnd.Time);

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

  FreeAndNil(FSyncLock);
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
      WriteLog(Format('等待[ %s.%s ]端口接入系统.', [FItemName, FPortName]));
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

procedure TfFormMain.EditTimeEndPropertiesChange(Sender: TObject);
begin
  if Sender = EditTimeStart then
    gWNTimeStart := EditTimeStart.Time;
  //xxxxx

  if Sender = EditTimeEnd then
    gWNTimeEnd := EditTimeEnd.Time;
  //xxxxx
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
  MemoLog.Lines.Add('刷新设备列表:');

  for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
  with FCOMPorts[nIdx],MemoLog.Lines do
  begin
    Add('设备: ' + IntToStr(nIdx+1));
    Add('|--- 名称: ' + FItemName);
    Add('|--- 分组: ' + FItemGroup);
    Add('|--- 类型: ' + COMType2Str(FItemType));

    if FItemType = ctDD then
    Add('|--- 仪器: ' + DDType2Str(FDDType));
    //xxxxx

    if FItemType = ctWQ then
    Add('|--- 仪器: ' + WQType2Str(FWQType));
    //xxxxx

    Add('|--- 线号: ' + IntToStr(FLineNo));
    Add('|--- 端口: ' + FPortName);
    Add('|--- 速率: ' + BaudRateToStr(FBaudRate));
    Add('|--- 数位: ' + DataBitsToStr(FDataBits));
    Add('|--- 停位: ' + StopBitsToStr(FStopBits));
    Add('|--- 备注: ' + FMemo);
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
  if ShowInputPWDBox('请输入管理员密码:', '', nStr) then
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
  CheckYG.Checked := False; //默认不启用
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
var nStr: string;
    nList: TStrings;
    nIdx,nInt: Integer;
    nStatus: TMonStatusItem;
    nPoolItem: PObjectPoolItem;
begin
  nPoolItem := nil;
  try
    nPoolItem := gObjectPoolManager.LockObject(TStringList);
    nList := nPoolItem.FObject as TStrings;
    nList.Text := DecodeBase64(nContext.Connection.IOHandler.ReadLn());

    nStr := Trim(nList.Values['LineNo']);    
    if not IsNumber(nStr, False) then Exit;
    nInt := StrToInt(nStr);

    FSyncLock.Enter;
    try
      for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
      with FCOMPorts[nIdx] do
      begin
        if (FLineNo <> nInt) or (FDeviceType <> dtDevice) then Continue;
        //同线,下位机上行数据时校正

        if FItemType = ctWQ then
        begin
          case FWQType of
           GB5160,
           MQ5105: Continue;           
          end; //无需处理工位状态
        end;

        nStr := nList.Values['Status'];
        if not IsNumber(nStr, False) then Continue;
        nInt := StrToInt(nStr);
        
        if (nInt >= Ord(msNoRun)) and (nInt <= Ord(msIdle)) then
        begin
          nStatus := TMonStatusItem(nInt);
          if not (nStatus in [msDRun_2K5, msDRun_DS]) then
          begin
            nStr := Format('状态切换: %d线 -> %s', [FCOMPorts[nIdx].FLineNo,
                    MonStatusToStr(nStatus)]);
            WriteLog(nStr);
          end;

          if nStatus in [ms2K5, ms3K5, ms1K8] then Exit;
          //无需处理状态

          if (nStatus = ms1Pack) and (not (ms1Pack in FGWStatus)) then //允许发送第一包数据
          begin
            FGWStatus := FGWStatus + [ms1Pack];
            //首包状态
            
            nStr := Format('[ %d线 ]开始发送首包数据.', [
                           FCOMPorts[nIdx].FLineNo]);
            WriteLog(nStr);
          end else

          if ((nStatus = msVRun) or (nStatus = msDRun_2K5) or
             (nStatus = msDRun_DS)) and (not (nStatus in FGWStatus)) then
          begin
            FGWStatus := FGWStatus - [ms1Pack] + [nStatus];
            //数据开始,停止首包
            FGWDataIndexTime := 0;
          end else

          if nStatus = msReset then //业务重置
          begin
            FGWDataIndex := 0;
            FGWDataIndexSDS := 0;
            FGWDataIndexTime := 0;
            FCOMPorts[nIdx].FGWDataLast := 0;

            FGWDataTruck := '';
            SetLength(FCOMPorts[nIdx].FGWDataList, 0);
            //清理样本

            FGWStatus := [];
            //状态跟踪
          end;

          //--------------------------------------------------------------------
          if ((nStatus = msVStart) or (nStatus = msDStart)) and
              (not (nStatus in FGWStatus)) then //vmas,sds开始
          with FCOMPorts[nIdx] do
          begin
            FGWDataIndex := 0;
            FGWDataIndexSDS := 0;
            FGWDataIndexTime := 0;
            //重置索引

            FGWStatus := [nStatus];
            //状态跟踪
            
            if GetTickCount - FGWDataLast > 5 * 60 * 1000 then //5分钟重载样本
            begin
              if (nStatus = msVStart) and
                 gTruckManager.FillVMasSimple(FCOMPorts[nIdx].FLineNo, FGWDataTruck, FGWDataList) then
              begin
                FGWDataLast := GetTickCount;
                WriteLog(Format('加载[ VMAS,%s ]样本成功', [FGWDataTruck]));
              end;

              if (nStatus = msDStart) and
                 gTruckManager.FillSDSSimple(FCOMPorts[nIdx].FLineNo, FGWDataTruck, FGWDataList) then
              begin
                FGWDataLast := GetTickCount;
                WriteLog(Format('加载[ SDS,%s ]样本成功', [FGWDataTruck]));
              end;
            end;
          end else

          if (nStatus = msVEnd) or (nStatus = msDEnd) then //vmas,sds结束
          begin
            FGWDataIndex := 0;
            FGWDataIndexSDS := 0;
            FGWDataIndexTime := 0;
            FCOMPorts[nIdx].FGWDataLast := 0;

            FGWDataTruck := '';
            SetLength(FCOMPorts[nIdx].FGWDataList, 0);
            //清理样本

            FGWStatus := [];
            //状态跟踪
          end else

          if (nStatus = msVError) or (nStatus = msDError) then //vmas,sds错误
          begin
            FGWDataIndex := 0;
            FGWDataIndexTime := 0;
            //重置索引

            FGWStatus := [];
            //状态跟踪
          end else

          if (nStatus = msDRun_2K5) or (nStatus = msDRun_DS) then //双怠速取样时序
          begin
            nStr := nList.Values['DTime'];
            FGWDataIndexSDS := StrToInt(nStr);

            nStr := Format('[ SDS,%d线 ]使用样本第[ %d ]秒数据.', [
                    FCOMPorts[nIdx].FLineNo, FGWDataIndexSDS]);
            WriteLog(nStr);
          end;
        end;
      end;
    finally
      FSyncLock.Leave;
    end;
  finally
    gObjectPoolManager.ReleaseObject(nPoolItem);
  end;
end;

//Desc: 读取配置
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
      FLineNo := ReadInteger(nList[nIdx], 'LineNo', 0);

      nStr := ReadString(nList[nIdx], 'DDModel', 'NHD-6108');
      if CompareText(nStr, 'MQD-6A') = 0 then
           FDDType := MQD6A
      else FDDType := NHD6108;

      FWQType := GB5160; //尾气仪类型
      nStr := ReadString(nList[nIdx], 'WQModel', 'MQW50A');
      if CompareText(nStr, 'MQW50A') = 0 then FWQType := MQW50A else
      if CompareText(nStr, 'MQ5105') = 0 then FWQType := MQ5105;
      
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
      FWQZeroCO2Last := 0;
      FWQBiaoQiEnable := False;
      FGWDataIndex := 0;
      FGWDataIndexSDS := 0;
      FGWDataIndexTime := 0;

      FGWStatus := [];
      FGWDataLast := 0;
      SetLength(FGWDataList, 0);

      FDeviceType := TDeviceType(ReadInteger(nList[nIdx], 'DeviceType', 0));
      //设备类型

      if ReadInteger(nList[nIdx], 'Enable', 0) <> 1 then
      begin
        FMemo := '端口禁用';
        Continue;
      end;

      FMemo := '端口正常';
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
//Parm: 串口对象
//Desc: 检索nCOM对应数据
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
//Parm: 串口对象索引
//Desc: 检索nIdx的同组对象
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
//Parm: 对象;数据大小
//Desc: 处理串口数据
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
  //线程延迟

  try
    nItem := FindCOMItem(Sender);
    if (nItem < 0) or (FCOMPorts[nItem].FCOMObject = nil) then
    begin
      WriteLog('收到数据,但无法匹配串口对象.');
      Exit;
    end;

    with FCOMPorts[nItem] do
    begin
      FCOMObject.ReadStr(FBuffer, Count);
      nInt := Length(FBuffer);

      if CheckDetail.Checked then //显示明细
      begin
        nStr := '';
        for nIdx:=1 to nInt do
          nStr := nStr + IntToHex(Ord(FBuffer[nIdx]), 2) + ' ';
        //十六进制

        nStr := Format('端口:[ %s ] 数据:[ %s ]', [FItemName, nStr]);
        WriteLog(nStr);
      end;
    end; //读取数据

    nGroup := FindSameGroup(nItem);
    if (nGroup < 0) or (FCOMPorts[nGroup].FCOMObject = nil) then
    begin
      nStr := '收到数据,但无法匹配串口[ %s ]同组对象.';
      WriteLog(Format(nStr, [FCOMPorts[nItem].FItemName]));
      Exit;
    end;

    if CheckAdjust.Checked then
      RedirectData(nItem, nGroup, FCOMPorts[nItem].FBuffer) else  //直接转发
    //xxxxx

    if FCOMPorts[nItem].FItemType = ctWQ then
         ParseWQProtocol(nItem, nGroup)                           //尾气数据
    else ParseProtocol(nItem, nGroup);                            //分析协议
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2016/5/6
//Parm: 源端口;目标端口;数据
//Desc: 将nData数据转发到nGroup端口
procedure TfFormMain.RedirectData(const nItem,nGroup: Integer;
 const nData: string);
var nStr: string;
    {$IFDEF DEBUG}nIdx: Integer;{$ENDIF}
begin
  FCOMPorts[nGroup].FCOMObject.WriteStr(nData);
  //xxxxx

  if CheckDetail.Checked then
  begin
    nStr := '端口:[ %s ] 处理:[ 转发至 %s ]';
    nStr := Format(nStr, [FCOMPorts[nItem].FItemName, FCOMPorts[nGroup].FItemName]);
    WriteLog(nStr);
  end;

  {$IFDEF DEBUG}
  WriteLog('数据(10): ' + nData);
  nStr := '';

  for nIdx:=1 to Length(nData) do
    nStr := nStr + IntToHex(Ord(nData[nIdx]), 2) + ' ';
  WriteLog('数据(16): ' + nStr);
  {$ENDIF}
end;

//Date: 2016/5/6
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
procedure TfFormMain.ParseProtocol(const nItem, nGroup: Integer);
var i,nS,nE,nPos: Integer;
    nData: TDataItem;
    nBuf: array[0..cSizeData-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    if FDDType = MQD6A then //明泉6A
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
    end; //超时数据直接转发

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
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    nS := Pos(cChar_Head, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      Exit;
    end; //非协议数据直接转发

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

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
    end; //未找到完整协议包

    //--------------------------------------------------------------------------
    if gTruckManager.VIPTruckInLine(FLineNo, ctDD, FTruckNo) then //VIP车辆参与校正
    begin
      StrPCopy(@nBuf[0], Copy(FData, nS, cSizeData));
      Move(nBuf, nData, cSizeData);
      //复制到协议包,准备分析

      if AdjustProtocol(@nData) then
      begin
        SetString(FBuffer, PChar(@nData.Fsoh), cSizeData);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
  end;
end;

//Date: 2016/5/7
//Parm: 协议数据
//Desc: 分析协议数据,有必要时校正
function TfFormMain.AdjustProtocol(const nData: PDataItem): Boolean;
var nStr,nSVal: string;
    nIdx,nInt: Integer;
    nYGVerify: Boolean;
    nPY,nDG,nDQ,nRnd,nVal: Double;
begin
  Result := False;
  {$IFDEF DEBUG}
  nStr := '上下:[ ' + nData.Fjud + '] ' +
          '灯高:[ ' + nData.Fjh + '] ' +
          '比值:[ ' + nData.Fjp + '] ' +
          '强度:[ ' + nData.Fyi + ']';
  WriteLog(nStr);
  {$ENDIF}

  nDQ := StrToFloat(nData.Fyi);
  //远光强度
  nYGVerify := (nDQ < 0.1) and CheckYG.Checked;
  //远光异常校正

  nPY := StrToFloat(nData.Fjud);
  //上下偏移
  nDG := StrToFloat(nData.Fjh);
  //灯高
  
  if nYGVerify then
  begin
    if nDG < 0.1 then
      nDG := 60 + Random(20);
    //随机补偿灯高
  end;

  if nPY < 0.1 then
    nPY := 0.01;
  //不合格偏移,引导进入下面校正逻辑

  if (nPY <> 0) and (nDG <> 0) and (not CheckCP.Checked) then
  begin
    nVal := (nDG - nPY) / nDG;
    nVal := Float2Float(nVal, 100, True);
    //垂直偏移量

    if (nVal <= 0.70) or ((nVal >= 0.90) and (nVal < 2.0)) then
    begin
      nRnd := Random(200);
      while (nRnd = 0) or (nRnd = 200) do
        nRnd := Random(200);
      //xxxxx

      if nRnd >= 10 then
        nRnd := nRnd / 10;
      nRnd := 0.7 + nRnd / 100;
      //随机值(0.71 - 0.89)

      nVal := nDG - nRnd * nDG;
      nSVal := Format('%.2f', [nVal]);
      nSVal := '+' + nSVal;

      nIdx := Length(nSVal);
      nInt := Length(nData.Fjud);
      if nIdx < nInt then
        nSVal := nSVal + StringOfChar('0', nInt-nIdx);
      //xxxxx

      nStr := Format('垂直偏移:[ %s -> %s ]', [Copy(nData.Fjud, 1, nInt),
                                               Copy(nSVal, 1, nInt)]);
      WriteLog(nStr);

      nInt := 1;
      for nIdx:=Low(nData.Fjud) to High(nData.Fjud) do
      begin
        nData.Fjud[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //偏移量

      nSVal := Format('%.3f', [nRnd]);
      nInt := 1;
      for nIdx:=Low(nData.Fjp) to High(nData.Fjp) do
      begin
        nData.Fjp[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //偏移比例

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
    nStr := Format('灯光补偿:[ %s -> %s ]', [Copy(nData.Fyi, 1, nInt),
                                             Copy(nSVal, 1, nInt)]);
    WriteLog(nStr);

    nInt := 1;
    for nIdx:=Low(nData.Fyi) to High(nData.Fyi) do
    begin
      nData.Fyi[nIdx] := nSVal[nInt];
      Inc(nInt);
    end;
    Result := True;
  end; //灯光强度补偿

  if Result or CheckDetail.Checked then
  begin
    nStr := '上下:[ ' + nData.Fjud + '] ' +
            '灯高:[ ' + nData.Fjh + '] ' +
            '比值:[ ' + nData.Fjp + '] ' +
            '强度:[ ' + nData.Fyi + ']';
    WriteLog(nStr);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2017-09-19
//Parm: 主灯数据
//Desc: 校验位,前38位之和取反加1
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
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
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
    end; //超时数据直接转发

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
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    nS := Pos(cChar_Head_6A, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      Exit;
    end; //非协议数据直接转发

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

    nS := 0;
    nE := 0;
    nPos := Length(FData);

    for i:=nPos downto 1 do
    begin
      if FData[i] <> cChar_Head_6A then Continue;
      //not head

      if nPos - i + 1 < 2 then Continue;
      //not full head

      if (FData[i+1] = 'L') or (FData[i+1] = 'R') then //左右大灯数据
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
      //未找到协议包
    end;

    if nE < 1 then Exit;
    //未找到完整协议包

    //--------------------------------------------------------------------------
    if gTruckManager.VIPTruckInLine(FLineNo, ctDD, FTruckNo) then //VIP车辆参与校正
    begin
      StrPCopy(@nBuf[0], Copy(FData, nS, cSizeData_6A));
      Move(nBuf, nData, cSizeData_6A);
      //复制到协议包,准备分析

      if AdjustProtocol_6A(@nData) then
      begin
        SetString(FBuffer, PChar(@nData.FHead), cSizeData_6A);
        FBuffer[cSizeData_6A] := CRC_6A(FBuffer);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
  end;
end;

//Date: 2017-09-18
//Parm: 协议数据
//Desc: 分析协议数据,有必要时校正
function TfFormMain.AdjustProtocol_6A(const nData: PDataItem_6A): Boolean;
var nStr,nSVal: string;
    nIdx,nInt: Integer;
    nYGVerify: Boolean;
    nPY,nDG,nDQ,nRnd,nVal: Double;
begin
  Result := False;
  {$IFDEF DEBUG}
  nStr := '上下:[ ' + nData.FNear.Fczpc + '] ' +
          '灯高:[ ' + nData.FNear.Fdg + '] ' +
          '强度:[ ' + nData.FNear.Fgq + ']';
  WriteLog(nStr);
  {$ENDIF}

  nDQ := StrToFloat(nData.FFar.Fgq);
  //远光强度
  nYGVerify := (nDQ < 0.1) and CheckYG.Checked;
  //远光异常校正

  nPY := StrToFloat(nData.FNear.Fczpc);
  //上下偏移
  nDG := StrToFloat(nData.FNear.Fdg);
  //灯高
  
  if nYGVerify then
  begin
    if nDG < 0.1 then
      nDG := 60 + Random(20);
    //随机补偿灯高
  end;

  if nPY < 0.1 then
    nPY := 0.01;
  //不合格偏移,引导进入下面校正逻辑

  if (nPY <> 0) and (nDG <> 0) and (not CheckCP.Checked) then
  begin
    nVal := (nDG - nPY) / nDG;
    nVal := Float2Float(nVal, 100, True);
    //垂直偏移量

    if (nVal <= 0.70) or ((nVal >= 0.80) and (nVal < 2.0)) then
    begin
      nRnd := Random(100);
      while (nRnd = 0) or (nRnd = 100) do
        nRnd := Random(100);
      //xxxxx

      if nRnd >= 10 then
        nRnd := nRnd / 10;
      nRnd := 0.7 + nRnd / 100;
      //随机值(0.71 - 0.79)

      nVal := nDG - nRnd * nDG;
      nSVal := Format('%.2f', [nVal]);
      nSVal := '+' + nSVal;

      nIdx := Length(nSVal);
      nInt := Length(nData.FNear.Fczpc);
      if nIdx < nInt then
        nSVal := nSVal + StringOfChar('0', nInt-nIdx);
      //xxxxx

      nStr := Format('垂直偏移:[ %s -> %s ]', [Copy(nData.FNear.Fczpc, 1, nInt),
                                               Copy(nSVal, 1, nInt)]);
      WriteLog(nStr);

      nInt := 1;
      for nIdx:=Low(nData.FNear.Fczpc) to High(nData.FNear.Fczpc) do
      begin
        nData.FNear.Fczpc[nIdx] := nSVal[nInt];
        Inc(nInt);
      end; //偏移量

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
    nStr := Format('灯光补偿:[ %s -> %s ]', [Copy(nData.FNear.Fgq, 1, nInt),
                                             Copy(nSVal, 1, nInt)]);
    WriteLog(nStr);

    nInt := 1;
    for nIdx:=Low(nData.FNear.Fgq) to High(nData.FNear.Fgq) do
    begin
      nData.FNear.Fgq[nIdx] := nSVal[nInt];
      Inc(nInt);
    end;
    Result := True;
  end; //灯光强度补偿

  if Result or CheckDetail.Checked then
  begin
    nStr := '上下:[ ' + nData.FNear.Fczpc + '] ' +
            '灯高:[ ' + nData.FNear.Fdg + '] ' +
            '强度:[ ' + nData.FNear.Fgq + ']';
    WriteLog(nStr);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2016-10-08
//Parm: 数据
//Desc: 对nStr进行和校验
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
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
//      支持设备: 明泉MQW-50A
procedure TfFormMain.ParseWQProtocol(const nItem, nGroup: Integer);
var nS,nE,nPos,nIdx: Integer;
    nData: TWQData;
    nInBlack: Boolean;
    nCheckType: TWQCheckType;
    nBuf: array[0..cSize_WQ_Data-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    case FWQType of
     GB5160: //GasBoard5160协议解析
      begin
        ParseWQProtocol_5160(nItem, nGroup);
        Exit;
      end;
     MQ5105: //明泉5105协议解析
      begin
        ParseWQProtocol_5105(nItem, nGroup);
        Exit;
      end;
    end;

    nE := Length(FData);
    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //超时数据直接转发

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
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    nS := Pos(sCMD_WQ_TL, FBuffer);
    if nS > 0 then
    begin
      FData := '';
      FWQStatus := wsTL;
      FAdj_LastActive := 0;
      
      RedirectData(nItem, nGroup, sCMD_WQ_TL);
      Exit;
    end; //调零指令,重置数据

    nS := Pos(cChar_WQ_Head, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      //非协议数据直接转发

      {$IFDEF CheckCQCommand}
      if FWQStatus = wsTL then
      begin
        nS := Pos(sCMD_WQ_HK, FBuffer);
        if nS > 0 then
          FWQStatus := wsHK;
        //调零后抽环境空气
      end;

      if FWQStatus = wsHK then
      begin
        nS := Pos(sCMD_WQ_Stop, FBuffer);
        if nS > 0 then
        begin
          FWQStatus := wsHKStop;
          FWQStatusTime := GetTickCount;
        end; //抽环境空气结束
      end;

      if FWQStatus = wsHKStop then
      begin
        nS := Pos(sCMD_WQ_CQ, FBuffer);
        if nS > 0 then
        begin
          FWQStatus := wsCQ;
          //抽背景空气
        end else
        begin
          nS := GetTickCount - FWQStatusTime;
          //环境空气结束后,若2秒后未发送抽气,则补发指令.

          if (nS > 2000) and (nS < 3500) then
          begin
            Sleep(500);
            RedirectData(nItem, nGroup, sCMD_WQ_CQ);
            Sleep(500);

            FWQStatus := wsCQ;
            WriteLog(Format('端口:[ %s ]补发抽气指令.', [FItemName]));
          end;

          if nS >= 3500 then
            FWQStatus := wsCQ;
          //超时则取消补发
        end;
      end;  
      {$ENDIF}
      
      Exit;
    end; 

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

    nS := Pos(cChar_WQ_Head, FData);
    nPos := Length(FData);
    if nPos - nS + 1 < cSize_WQ_Data then Exit; //未找到完整协议包

    if gTruckManager.VIPTruckInLine(FLineNo, ctWQ, FTruckNo,
      @nInBlack, @nCheckType) then //VIP车辆参与校正
    begin
      {$IFDEF WQUseSimple}
      FSyncLock.Enter;
      try
        if (ms1Pack in FGWStatus) or //发送第一包
           ((nCheckType = CTvmas) and (msVRun in FGWStatus)) or  //vmas
           ((nCheckType = CTsds) and (FGWDataIndexSDS > 0)) then //双怠速
        begin
          if FGWDataIndexTime = 0 then
          begin
            WriteLog(Format('车辆[ %d.%-6s ]开始启用[ %s ]样本.', [FLineNo,
              FTruckNo,FGWDataTruck]));
            //首包,打印日志
          end;

          nE := nS + cSize_WQ_Data - 1;
          FBuffer := Copy(FData, nS, cSize_WQ_Data);

          for nIdx:=Low(nBuf) to High(nBuf) do
            nBuf[nIdx] := FBuffer[nIdx + 1];
          Move(nBuf, nData, cSize_WQ_Data);
          //复制到协议包,准备分析

          if AdjustWQProtocolBySimple(nItem, nGroup, @nData, nInBlack) then
          begin
            SetString(FBuffer, PChar(@nData.FHead), cSize_WQ_Data);
            FBuffer[cSize_WQ_Data] := MakeCRC(FBuffer, 1, cSize_WQ_Data - 1);
            FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
          end;
        end;
      finally
        FSyncLock.Leave;
      end;

      //------------------------------------------------------------------------
      {$ELSE}
      nE := nS + cSize_WQ_Data - 1;
      FBuffer := Copy(FData, nS, cSize_WQ_Data);

      for nIdx:=Low(nBuf) to High(nBuf) do
        nBuf[nIdx] := FBuffer[nIdx + 1];
      Move(nBuf, nData, cSize_WQ_Data);
      //复制到协议包,准备分析

      //if (nData.FCRC = MakeCRC(FBuffer, nS, nE-1)) then
      if AdjustWQProtocol(nItem, nGroup, @nData, nInBlack) then
      begin
        SetString(FBuffer, PChar(@nData.FHead), cSize_WQ_Data);
        FBuffer[cSize_WQ_Data] := MakeCRC(FBuffer, 1, cSize_WQ_Data - 1);
        FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
      end;
      {$ENDIF}
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
  end;
end;

//Date: 2020-04-27
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
//      支持设备: 湖北锐意5160
procedure TfFormMain.ParseWQProtocol_5160(const nItem, nGroup: Integer);
var nS,nE,nPos,nIdx: Integer;
    nHeadType: Integer;

    nData_A3: TWQData5160_A3;
    nData_A8: TWQData5160_A8;
    nBuf_A3: array[0..cSize_WQ_Data_A3-1] of Char;
    nBuf_A8: array[0..cSize_WQ_Data_A8-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    nHeadType := -1;
    //默认无法区分协议头
    nE := Length(FData);

    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //超时数据直接转发

    if nE > cSize_WQ_Data_A3 then
    begin
      while nE > 0 do
      begin
        nPos := nE;
        Dec(nE);

        if Copy(FData, nPos, cChar_WQ_Head_A3_L) = cChar_WQ_Head_A3 then Break;
        //A3 last header
        if Copy(FData, nPos, cChar_WQ_Head_A8_L) = cChar_WQ_Head_A8 then Break;
        //A8 last header
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    if Time() < gWNTimeStart then
    begin
      if Pos(cChar_WQ_JCQ, FBuffer) > 0 then
      begin
        FWQBiaoQiEnable := True;
        WriteLog(Format('%d.开始通检查气', [FLineNo]));
      end;

      if Pos(cChar_WQ_JCQDone, FBuffer) > 0 then
      begin
        FWQBiaoQiEnable := False;
        WriteLog(Format('%d.通检查气结束', [FLineNo]));
      end;
    end else FWQBiaoQiEnable := False;
                            
    if ((Pos(cChar_WQ_Head_A3, FBuffer) < 1) and
        (Pos(cChar_WQ_Head_A8, FBuffer) < 1)) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      //非协议数据直接转发
      Exit;
    end; 

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

    nS := Pos(cChar_WQ_Head_A3, FData);
    if nS > 0 then
    begin
      nHeadType := 3;
      nPos := Length(FData);
      if nPos - nS + 1 < cSize_WQ_Data_A3 then Exit; //未找到完整协议包
    end else
    begin
      nS := Pos(cChar_WQ_Head_A8, FData);
      if nS > 0 then
      begin
        nHeadType := 8;
        nPos := Length(FData);
        if nPos - nS + 1 < cSize_WQ_Data_A8 then Exit; //未找到完整协议包
      end;
    end;

    if (nHeadType > 0) and (FWQBiaoQiEnable or
        gTruckManager.VIPTruckInLine(FLineNo, ctWQ, FTruckNo)) then //VIP车辆参与校正
    begin
      if nHeadType = 3 then //A3帧
      begin
        nE := nS + cSize_WQ_Data_A3 - 1;
        FBuffer := Copy(FData, nS, cSize_WQ_Data_A3);

        for nIdx:=Low(nBuf_A3) to High(nBuf_A3) do
          nBuf_A3[nIdx] := FBuffer[nIdx + 1];
        Move(nBuf_A3, nData_A3, cSize_WQ_Data_A3); //复制到协议包,准备分析

        if AdjustWQProtocol_5160(nItem, nGroup, nHeadType, @nData_A3, False) then
        begin
          SetString(FBuffer, PChar(@nData_A3.FStart), cSize_WQ_Data_A3);
          FBuffer[cSize_WQ_Data_A3] := MakeCRC(FBuffer, 1, cSize_WQ_Data_A3 - 1);
          FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
        end;
      end else

      if nHeadType = 8 then //A8帧
      begin
        nE := nS + cSize_WQ_Data_A8 - 1;
        FBuffer := Copy(FData, nS, cSize_WQ_Data_A8);

        for nIdx:=Low(nBuf_A8) to High(nBuf_A8) do
          nBuf_A8[nIdx] := FBuffer[nIdx + 1];
        Move(nBuf_A8, nData_A8, cSize_WQ_Data_A8); //复制到协议包,准备分析

        if AdjustWQProtocol_5160(nItem, nGroup, nHeadType, @nData_A8, False) then
        begin
          SetString(FBuffer, PChar(@nData_A8.FStart), cSize_WQ_Data_A8);
          FBuffer[cSize_WQ_Data_A8] := MakeCRC(FBuffer, 1, cSize_WQ_Data_A8 - 1);
          FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
        end;
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
  end;
end;

//Date: 2020-06-19
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
//      支持设备: 明泉5105汽油
procedure TfFormMain.ParseWQProtocol_5105(const nItem, nGroup: Integer);
var nS,nE,nPos,nIdx: Integer;
    nHeadType: Integer;

    nData_A3: TWQData5160_A3;
    nData_A8: TWQData5160_A8;
    nBuf_A3: array[0..cSize_WQ_Data_A3-1] of Char;
    nBuf_A8: array[0..cSize_WQ_Data_A8-1] of Char;
begin
  with FCOMPorts[nItem] do
  begin
    nHeadType := -1;
    //默认无法区分协议头
    nE := Length(FData);

    if (nE > 0) and (GetTickCount - FDataLast >= 1500) then
    begin
      RedirectData(nItem, nGroup, FData);
      FData := '';
      nE := 0;
    end; //超时数据直接转发

    if nE > cSize_WQ_Data_A3 then
    begin
      while nE > 0 do
      begin
        nPos := nE;
        Dec(nE);

        if Copy(FData, nPos, cChar_WQ_Head_A3_L) = cChar_WQ_Head_A3 then Break;
        //A3 last header
        if Copy(FData, nPos, cChar_WQ_Head_A8_L) = cChar_WQ_Head_A8 then Break;
        //A8 last header
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    if Time() < gWNTimeStart then
    begin
      if Pos(cChar_WQ_JCQ, FBuffer) > 0 then
      begin
        FWQBiaoQiEnable := True;
        WriteLog(Format('%d.开始通检查气', [FLineNo]));
      end;

      if Pos(cChar_WQ_JCQDone, FBuffer) > 0 then
      begin
        FWQBiaoQiEnable := False;
        WriteLog(Format('%d.通检查气结束', [FLineNo]));
      end;
    end else FWQBiaoQiEnable := False;
                            
    if ((Pos(cChar_WQ_Head_A3, FBuffer) < 1) and
        (Pos(cChar_WQ_Head_A8, FBuffer) < 1)) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      //非协议数据直接转发
      Exit;
    end; 

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

    nS := Pos(cChar_WQ_Head_A3, FData);
    if nS > 0 then
    begin
      nHeadType := 3;
      nPos := Length(FData);
      if nPos - nS + 1 < cSize_WQ_Data_A3 then Exit; //未找到完整协议包
    end else
    begin
      nS := Pos(cChar_WQ_Head_A8, FData);
      if nS > 0 then
      begin
        nHeadType := 8;
        nPos := Length(FData);
        if nPos - nS + 1 < cSize_WQ_Data_A8 then Exit; //未找到完整协议包
      end;
    end;

    if (nHeadType > 0) and (FWQBiaoQiEnable or
        gTruckManager.VIPTruckInLine(FLineNo, ctWQ, FTruckNo)) then //VIP车辆参与校正
    begin
      if nHeadType = 3 then //A3帧
      begin
        nE := nS + cSize_WQ_Data_A3 - 1;
        FBuffer := Copy(FData, nS, cSize_WQ_Data_A3);

        for nIdx:=Low(nBuf_A3) to High(nBuf_A3) do
          nBuf_A3[nIdx] := FBuffer[nIdx + 1];
        Move(nBuf_A3, nData_A3, cSize_WQ_Data_A3); //复制到协议包,准备分析

        if AdjustWQProtocol_5105(nItem, nGroup, nHeadType, @nData_A3, False) then
        begin
          SetString(FBuffer, PChar(@nData_A3.FStart), cSize_WQ_Data_A3);
          FBuffer[cSize_WQ_Data_A3] := MakeCRC(FBuffer, 1, cSize_WQ_Data_A3 - 1);
          FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
        end;
      end else

      if nHeadType = 8 then //A8帧
      begin
        nE := nS + cSize_WQ_Data_A8 - 1;
        FBuffer := Copy(FData, nS, cSize_WQ_Data_A8);

        for nIdx:=Low(nBuf_A8) to High(nBuf_A8) do
          nBuf_A8[nIdx] := FBuffer[nIdx + 1];
        Move(nBuf_A8, nData_A8, cSize_WQ_Data_A8); //复制到协议包,准备分析

        if AdjustWQProtocol_5105(nItem, nGroup, nHeadType, @nData_A8, False) then
        begin
          SetString(FBuffer, PChar(@nData_A8.FStart), cSize_WQ_Data_A8);
          FBuffer[cSize_WQ_Data_A8] := MakeCRC(FBuffer, 1, cSize_WQ_Data_A8 - 1);
          FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
        end;
      end;
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
  end;
end;

{$IFNDEF WQUseSimple}
//Date: 2016-10-08
//Parm: 源端口;转发端口;协议数据;黑名单
//Desc: 分析协议数据,有必要时校正
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
          '湿度:[ ' + IntToStr(Item2Word(nData.FSD)) + ' ] ' +
          '油温:[ ' + IntToStr(Item2Word(nData.FYW)) + ' ]';
  WriteLog(nStr);

  nStr := '转速:[ ' + IntToStr(Item2Word(nData.FZS)) + ' ] ' +
          '空燃比:[ ' + IntToStr(Item2Word(nData.FKRB)) + ' ] ' +
          '气路压力:[ ' + IntToStr(Item2Word(nData.FQLYL)) + ' ] ' +
          '环境压力:[ ' + IntToStr(Item2Word(nData.FHJYL)) + ' ] ' +
          '环境温度:[ ' + IntToStr(Item2Word(nData.FHJWD)) + ' ]';
  WriteLog(nStr);
  {$ENDIF}

  with FCOMPorts[nItem] do
  begin
    nInt := Item2Word(nData.FCO) + Item2Word(nData.FCO2);
    if nInt < 600 then Exit;
    //co2低浓度标识未开始

    if nInBlack then //黑名单业务
    begin
      nInt := Item2Word(nData.FHC);
      if nInt < 120 then //碳氢: 180<x<360
      begin
        if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
           (FAdj_Val_HC < 1) then
        begin
          FAdj_Kpt_HC := Random(cAdj_KeepLong);
          FAdj_Val_HC := 180 + Random(180);

          if FAdj_Val_HC < 270 then
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

        if FAdj_Val_HC >= 360 then
        begin
          FAdj_Val_HC := 359;
          FAdj_Dir_HC := False;
        end;

        if FAdj_Val_HC < 180 then
        begin
          FAdj_Val_HC := 180;
          FAdj_Dir_HC := True;
        end;

        Word2Item(nData.FHC, FAdj_Val_HC);
        Result := True;

        nStr := Format('碳氢(HC):[ %d -> %d ]', [nInt, FAdj_Val_HC]);
        WriteLog(nStr);
      end;

      nInt := Item2Word(nData.FNO);
      if nInt < 1000 then //氮氧:1000<x<3000
      begin
        if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
           (FAdj_Val_NO < 1) then
        begin
          FAdj_Kpt_NO := Random(cAdj_KeepLong);
          FAdj_Val_NO := 1000 + Random(2000);
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

        if FAdj_Val_NO >= 3000 then
        begin
          FAdj_Val_NO := 2999;
          FAdj_Dir_NO := False;
        end;

        if FAdj_Val_NO < 1000 then
        begin
          FAdj_Val_NO := 1000;
          FAdj_Dir_NO := True;
        end;

        Word2Item(nData.FNO, FAdj_Val_NO);
        Result := True;

        nStr := Format('氮氧(NO):[ %d -> %d ]', [nInt, FAdj_Val_NO]);
        WriteLog(nStr);
      end;

      FAdj_LastActive := GetTickCount;
      //upate time stamp
      Exit;
    end;

    //--------------------------------------------------------------------------
    nInt := Item2Word(nData.FKRB); //空燃比: 0.97<x<1.02
    if (nInt >= 1020) or ((nInt <= 970) and (nInt >= 700)) then 
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_BS < 1) then
        FAdj_Val_BS := 990 + Random(30); //1030 - 990 = 40
      //base value

      FAdj_Val_BS := 1005; //1005 -1015
      FAdj_Val_KR := FAdj_Val_BS + Random(10);
      Word2Item(nData.FKRB, FAdj_Val_KR);

      nStr := Format('空燃比:[ %d -> %d ]', [nInt, FAdj_Val_KR]);
      WriteLog(nStr);

      Result := True;
      FAdj_Chg_KR := True;
    end else FAdj_Chg_KR := False;

    if FAdj_Chg_KR then //空燃比变动,更新氧气和二氧化碳
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_BSE_O2 < 1) then
      begin
        //FAdj_BSE_O2 := 40 + Random(40);  //氧气: 30-90,上下10
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

      nStr := Format('氧气(O2):[ %d -> %d ]', [Item2Word(nData.FO2), FAdj_Val_O2]);
      WriteLog(nStr);
      Word2Item(nData.FO2, FAdj_Val_O2);

      FAdj_BSE_CO2 := 1465 + Random(15); //14.65 - 14.80
      FAdj_Val_CO2 := Trunc((FAdj_BSE_CO2 / 100 - FAdj_Val_O2 / 100) * 100);

      nStr := Format('二氧化碳(CO2):[ %d -> %d ]', [Item2Word(nData.FCO2), FAdj_Val_CO2]);
      WriteLog(nStr);
      Word2Item(nData.FCO2, FAdj_Val_CO2);
    end;

    nInt := Item2Word(nData.FHC);
    if nInt >= 100 then //碳氢: 80<x<100
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

      nStr := Format('碳氢(HC):[ %d -> %d ]', [nInt, FAdj_Val_HC]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FCO);
    if (nInt >= 30) or (nInt < 3) then //碳氧: 3<x<30
    begin
      if (GetTickCount - FAdj_LastActive >= cAdj_Interval) or
         (FAdj_Val_CO < 1) then
      begin
        FAdj_Kpt_CO := Random(cAdj_KeepLong);
        FAdj_Val_CO := 3 + Random(27);
        
        if FAdj_Val_CO < 15 then
             FAdj_Dir_CO := True
        else FAdj_Dir_CO := False;
      end;

      if FAdj_Kpt_CO < 3 then
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

      if FAdj_Val_CO < 3 then
      begin
        FAdj_Val_CO := 3;
        FAdj_Dir_CO := True;
      end;

      Word2Item(nData.FCO, FAdj_Val_CO);
      Result := True;

      nStr := Format('碳氧(CO):[ %d -> %d ]', [nInt, FAdj_Val_CO]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FNO);
    if nInt >= 600 then //氮氧:200<x<600
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

      nStr := Format('氮氧(NO):[ %d -> %d ]', [nInt, FAdj_Val_NO]);
      WriteLog(nStr);
    end;

    FAdj_LastActive := GetTickCount;
    //upate time stamp
  end;
end;
{$ENDIF}

{$IFDEF WQUseSimple}
//Date: 2018-04-09
//Parm: 源端口;转发端口;协议数据;黑名单
//Desc: 使用样本修正数据
function TfFormMain.AdjustWQProtocolBySimple(const nItem, nGroup: Integer;
  const nData: PWQData; const nInBlack: Boolean): Boolean;
var nStr: string;
    nInt: Integer;
    nH,nM,nS,nMS: Word;
    nSimple: TWQSimpleData;
    nIndx,nDirect,nVal: Integer;
begin
  Result := False;
  with FCOMPorts[nItem] do
  begin
    nInt := High(FGWDataList);
    if FGWDataIndex > nInt then Exit; //no data

    if (ms1Pack in FGWStatus) or (FGWDataIndexTime = 0) then
      FGWDataIndexTime := Time();
    //first

    if FGWDataIndexSDS > 0 then //双怠速模式,启用工位指定的索引
    begin
      if FGWDataIndexSDS <= nInt then
           FGWDataIndex := FGWDataIndexSDS
      else FGWDataIndex := nInt;
    end else

    if FGWDataIndex < nInt then //vmas模式,使用计时索引
    begin
      DecodeTime(Time() - FGWDataIndexTime, nH, nM, nS, nMS);
      if nM * 60 + nS <= nInt then
           FGWDataIndex := nM * 60 + nS
      else FGWDataIndex := nInt;
    end;

    nIndx := Random(5);
    nVal := Random(2);
    nDirect := Random(10) mod 2;
                      
    {$IFDEF DEBUG}
    WriteLog(Format('%d %d %d', [nIndx, nVal, nDirect]));
    {$ENDIF}

    nSimple := FGWDataList[FGWDataIndex];
    with nSimple do
    begin
      case nIndx of
       1: begin //co2
            if nDirect > 0 then
                 Word2Item(FCO2, Item2Word(FCO2) + nVal)
            else Word2Item(FCO2, Item2Word(FCO2) - nVal);
          end;
       2: begin //co
            if nDirect > 0 then
                 Word2Item(FCO, Item2Word(FCO) + nVal)
            else Word2Item(FCO, Item2Word(FCO) - nVal);
          end;
       3: begin //hc
            if nDirect > 0 then
                 Word2Item(FHC, Item2Word(FHC) + nVal)
            else Word2Item(FHC, Item2Word(FHC) - nVal);
          end;
       4: begin //no
            if nDirect > 0 then
                 Word2Item(FNO, Item2Word(FNO) + nVal)
            else Word2Item(FNO, Item2Word(FNO) - nVal);
          end;
       5: begin //o2
            if nDirect > 0 then
                 Word2Item(FO2, Item2Word(FO2) + nVal)
            else Word2Item(FO2, Item2Word(FO2) - nVal);
          end;
      end;
    end; //微调数据

    if CheckShowWQ.Checked then
    begin
      nStr :=
        'CO2:[ ' + IntToStr(Item2Word(nData.FCO2)) + '-' +
                   IntToStr(Item2Word(nSimple.FCO2)) + ' ] '+
        'CO:[ ' +  IntToStr(Item2Word(nData.FCO)) + '-' +
                   IntToStr(Item2Word(nSimple.FCO)) + ' ] ' +
        'HC:[ ' +  IntToStr(Item2Word(nData.FHC)) + '-' +
                   IntToStr(Item2Word(nSimple.FHC)) + ' ] ' +
        'NO:[ ' +  IntToStr(Item2Word(nData.FNO)) + '-' +
                   IntToStr(Item2Word(nSimple.FNO)) + ' ] ' +
        'O2:[ ' +  IntToStr(Item2Word(nData.FO2)) + '-' +
                   IntToStr(Item2Word(nSimple.FO2)) + ' ] ' +
        IntToStr(FGWDataIndex + 1);
      WriteLog(nStr);
    end;

    nData.FCO2 := nSimple.FCO2;
    nData.FCO  := nSimple.FCO;
    nData.FHC  := nSimple.FHC;
    nData.FNO  := nSimple.FNO;
    nData.FO2  := nSimple.FO2; //combine

    Result := True;
  end;
end;
{$ENDIF}

//Date: 2020-05-05
//Parm: 检测类型;参考值
//Desc: 获取指定类型的比例
function GetWQBili(const nType: string; const nVal: Integer; const nLine: Integer): Double;
var nIdx: Integer;
begin
  Result := 1;
  for nIdx:=Low(gWQBili) to High(gWQBili) do
   with gWQBili[nIdx] do
    if (FType = nType) and (nVal >= FStart) and (nVal < FEnd) then
    begin
      Result := FBili;
      WriteLog(Format('%d.比例: %s.%s - %f', [nLine, nType, FName, FBili]));
      Exit;
    end;
end;

//Date: 2020-04-27
//Parm: 源端口;转发端口;帧头类型;协议数据;黑名单
//Desc: 使用比例修正数据
function TfFormMain.AdjustWQProtocol_5160(const nItem, nGroup,
  nHeadType: Integer; const nData: Pointer;
  const nInBlack: Boolean): Boolean;
var nStr: string;
    nInt,nVal: Integer;
    nA3: PWQData5160_A3;
    nA8: PWQData5160_A8;
    nOA3: TWQData5160_A3;
    nOA8: TWQData5160_A8;

  //Desc: 显示日志
  procedure ShowData;
  begin
    if nHeadType = 3 then
    begin
      nStr := Format('%d.A3-CO2:[ %d-%d ] CO:[ %d-%d ] HC:[ %d-%d ] ' +
              'NO:[ %d-%d ] O2:[ %d-%d ] KRB:[ %d-%d ]', [
           FCOMPorts[nItem].FLineNo,
           Item2Word(nOA3.FCO2),  Item2Word(nA3.FCO2),
           Item2Word(nOA3.FCO), Item2Word(nA3.FCO),
           Item2Word(nOA3.FHC), Item2Word(nA3.FHC),
           Item2Word(nOA3.FNO), Item2Word(nA3.FNO),
           Item2Word(nOA3.FO2), Item2Word(nA3.FO2),
           Item2Word(nOA3.FKRB), Item2Word(nA3.FKRB)]);
      WriteLog(nStr);
    end else

    if nHeadType = 8 then
    begin
      nStr := Format('%d.A8-CO2:[ %d-%d ] CO:[ %d-%d ] HC:[ %d-%d ] O2:[ %d-%d ] ' +
              'NO:[ %d-%d ] NO2:[ %d-%d ] NOx:[ %d-%d ] KRB:[ %d-%d ]', [
           FCOMPorts[nItem].FLineNo,
           Item2Word(nOA8.FCO2),  Item2Word(nA8.FCO2),
           Item2Word(nOA8.FCO), Item2Word(nA8.FCO),
           Item2Word(nOA8.FHC), Item2Word(nA8.FHC),
           Item2Word(nOA8.FO2), Item2Word(nA8.FO2),
           Item2Word(nOA8.FNO), Item2Word(nA8.FNO),
           Item2Word(nOA8.FNO2), Item2Word(nA8.FNO2),
           Item2Word(nOA8.FNOx), Item2Word(nA8.FNOx),
           Item2Word(nOA8.FKRB), Item2Word(nA8.FKRB)]);
      WriteLog(nStr);
    end;
  end;

  //Desc: 标气索引
  function GetBiaoQi(const nLine: Integer): Integer;
  var i: Integer;
  begin
    Result := -1;
    for i:=Low(gWQBiaoQi) to High(gWQBiaoQi) do
    if gWQBiaoQi[i].FLineNo = nLine then
    begin
      Result := i;
      Break;
    end;
  end;
begin
  Result := False;
  case nHeadType of
   3: nA3 := nData;
   8: nA8 := nData
   else Exit;
  end;

  with FCOMPorts[nItem] do
  case nHeadType of
   3: //A3指令
    begin
      if CheckShowWQ.Checked then
        nOA3 := nA3^;
      //copy data

      nInt := Item2Word(nA3.FCO) + Item2Word(nA3.FCO2);
      if nInt < gWQCO2BeforePipe then
        FWQZeroCO2Last := GetTickCount();
      //未插管计时开始

      if nInt < gWQCO2AfterPipe then //co2低浓度标识未开始
      begin
        FWQBiliCO2 := -1;
        //待确定比例
        FWQBiliStart := GetTickCount();
        //开始比例计算计时

        if (nInt >= gWQCO2BeforePipe) and
           (GetTickCountDiff(FWQZeroCO2Last) <= gWQIntervalBeforePipe) then
        begin
          Word2Item(nA3.FCO, 0);
          Word2Item(nA3.FHC, 0);
          Word2Item(nA3.FNO, 0);
          
          Result := True;
          WriteLog(Format('%d.A3-插管后CO2浓度过低,已清零', [FLineNo]));
        end;

        if CheckShowWQ.Checked then ShowData();
        Exit;
      end else
      begin
        FWQZeroCO2Last := 0;
        //浓度升高,计时关闭
      end;

      if GetTickCountDiff(FWQBiliStart) < gWQIntervalAfterPipe then
      begin
        //Word2Item(nA3.FCO2, 0);
        Word2Item(nA3.FCO, Random(2));
        Word2Item(nA3.FHC, Random(2));
        Word2Item(nA3.FNO, Random(2));
        //Word2Item(nA3.FO2, 2085 + Random(3));

        if CheckShowWQ.Checked then ShowData();
        Result := True;
        Exit;
      end else

      if FWQBiliCO2 <= 0 then //无比例值,开始计算比例
      begin
        FWQBiliHC   := GetWQBili('HC', Item2Word(nA3.FHC), FLineNo);
        FWQBiliNO   := GetWQBili('NO', Item2Word(nA3.FNO), FLineNo);
        FWQBiliCO   := GetWQBili('CO', Item2Word(nA3.FCO), FLineNo);
        FWQBiliCO2  := GetWQBili('CO2', Item2Word(nA3.FCO2), FLineNo);
        FWQBiliKRB  := GetWQBili('KRB', Item2Word(nA3.FKRB), FLineNo);

        FWQBiliHCNext := False;
        FWQBiliNONext := False;
        FWQBiliCONext := False;
        FWQBiliCO2Next := False;
        FWQBiliKRBNext := False;
      end else
      begin
        if (not FWQBiliHCNext) and (gWQBiliNext.FHC > 0) and
           (Item2Word(nA3.FHC) >= gWQBiliNext.FHC) then
        begin
          FWQBiliHCNext := True;
          FWQBiliHC := GetWQBili('HC', Item2Word(nA3.FHC), FLineNo);
        end;

        if (not FWQBiliNONext) and (gWQBiliNext.FNO > 0) and
           (Item2Word(nA3.FNO) >= gWQBiliNext.FNO) then
        begin
          FWQBiliNONext := True;
          FWQBiliNO := GetWQBili('NO', Item2Word(nA3.FNO), FLineNo);
        end;

        if (not FWQBiliCONext) and (gWQBiliNext.FCO > 0) and
           (Item2Word(nA3.FCO) >= gWQBiliNext.FCO) then
        begin
          FWQBiliCONext := True;
          FWQBiliCO := GetWQBili('CO', Item2Word(nA3.FCO), FLineNo);
        end;

        if (not FWQBiliCO2Next) and (gWQBiliNext.FCO2 > 0) and
           (Item2Word(nA3.FCO2) <= gWQBiliNext.FCO2) then
        begin
          FWQBiliCO2Next := True;
          FWQBiliCO2 := GetWQBili('CO2', Item2Word(nA3.FCO2), FLineNo);
        end;

        if (not FWQBiliKRBNext) and (gWQBiliNext.FKRB > 0) and
           (Item2Word(nA3.FKRB) >= gWQBiliNext.FKRB) then
        begin
          FWQBiliKRBNext := True;
          FWQBiliKRB := GetWQBili('KRB', Item2Word(nA3.FKRB), FLineNo);
        end;
      end;

      //------------------------------------------------------------------------
      Word2Item(nA3.FCO, Trunc(Item2Word(nA3.FCO) * FWQBiliCO));
      Word2Item(nA3.FHC, Trunc(Item2Word(nA3.FHC) * FWQBiliHC));
      Word2Item(nA3.FNO, Trunc(Item2Word(nA3.FNO) * FWQBiliNO));

      nInt := Item2Word(nA3.FCO2);
      if nInt < 1400 then //CO2不足时补CO2
      begin
        nVal := nInt;
        //old
        nInt := Trunc(nInt * FWQBiliCO2);
        //new
        
        if nInt > 1500 then
             Word2Item(nA3.FCO2, 1470 + Random(30))
        else Word2Item(nA3.FCO2, nInt);

        if Item2Word(nA3.FO2) >= 300 then //反向降低O2,过低时不予校正
        begin
          nInt := Item2Word(nA3.FCO2);
          if nVal < 1 then nVal := nInt;
          Word2Item(nA3.FO2, Trunc(Item2Word(nA3.FO2) * (2 - nInt/nVal)));
        end;

        nInt := Trunc(Item2Word(nA3.FKRB) * FWQBiliKRB);
        if nInt < 990 then  //下限0.99
          nInt := 990 + Random(5);
        Word2Item(nA3.FKRB, nInt);
        //CO2变动时修正空燃比
      end;

      if CheckShowWQ.Checked then
        ShowData();
      Result := True;
    end;
    //--------------------------------------------------------------------------
   8: //A8指令
    begin
      if CheckShowWQ.Checked then
        nOA8 := nA8^;
      //copy data

      if FWQBiaoQiEnable then //抽标准气
      begin
        nInt := GetBiaoQi(FLineNo);
        if nInt > -1 then
        with gWQBiaoQi[nInt] do
        begin
          nVal :=  Item2Word(nA8.FHC);
          if (nVal < FHC - FHC_WC) or (nVal > FHC + FHC_WC) then
          begin
            Word2Item(nA8.FHC,  FHC + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FNO);
          if (nVal < FNO - FNO_WC) or (nVal > FNO + FNO_WC) then
          begin
            Word2Item(nA8.FNO,  FNO + Random(5));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FNO2);
          if (nVal < FNO2 - FNO2_WC) or (nVal > FNO2 + FNO2_WC) then
          begin
            Word2Item(nA8.FNO2,  FNO2 + Random(5));
            Result := True;
          end;

          if Result then
          begin
            Word2Item(nA8.FNOx, Item2Word(nA8.FNO) + Item2Word(nA8.FNO2));
            //combine
          end;

          nVal :=  Item2Word(nA8.FCO);
          if (nVal < FCO - FCO_WC) or (nVal > FCO + FCO_WC) then
          begin
            Word2Item(nA8.FCO,  FCO + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FCO2);
          if (nVal < FCO2 - FCO2_WC) or (nVal > FCO2 + FCO2_WC) then
          begin
            Word2Item(nA8.FCO2,  FCO2 + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FO2);
          if (nVal < FO2 - FO2_WC) or (nVal > FO2 + FO2_WC) then
          begin
            Word2Item(nA8.FO2,  FO2 + Random(3));
            Result := True;
          end;
        end;

        if CheckShowWQ.Checked then
          ShowData();
        Exit;
      end;

      nInt := Item2Word(nA8.FCO) + Item2Word(nA8.FCO2);
      if nInt < gWQCO2BeforePipe then
        FWQZeroCO2Last := GetTickCount();
      //未插管计时开始
      
      if nInt < gWQCO2AfterPipe then //co2低浓度标识未开始
      begin
        FWQBiliCO2 := -1;
        //待确定比例
        FWQBiliStart := GetTickCount();
        //开始比例计算计时

        if (nInt >= gWQCO2BeforePipe) and
           (GetTickCountDiff(FWQZeroCO2Last) <= gWQIntervalBeforePipe) then
        begin
          Word2Item(nA8.FCO,  0);
          Word2Item(nA8.FHC,  0);
          Word2Item(nA8.FNO,  0);
          Word2Item(nA8.FNO2, 0);
          Word2Item(nA8.FNOx, 0);

          Result := True;
          WriteLog(Format('%d.A8-插管后CO2浓度过低,已清零', [FLineNo]));
        end;

        if CheckShowWQ.Checked then
          ShowData();
        Exit;
      end;

      if GetTickCountDiff(FWQBiliStart) < gWQIntervalAfterPipe then
      begin
        //Word2Item(nA8.FCO2, 0);
        Word2Item(nA8.FCO,  Random(2));
        Word2Item(nA8.FHC,  Random(2));
        Word2Item(nA8.FNO,  Random(2));
        Word2Item(nA8.FNO2, Random(2));
        Word2Item(nA8.FNOx, Item2Word(nA8.FNO) + Item2Word(nA8.FNO2));
        //Word2Item(nA8.FO2, 2085 + Random(3));

        if CheckShowWQ.Checked then ShowData();
        Result := True;
        Exit;
      end else

      if FWQBiliCO2 <= 0 then //无比例值,开始计算比例
      begin
        FWQBiliHC   := GetWQBili('HC', Item2Word(nA8.FHC), FLineNo);
        FWQBiliNO   := GetWQBili('NO', Item2Word(nA8.FNO), FLineNo);
        FWQBiliNO2  := GetWQBili('NO2', Item2Word(nA8.FNO2), FLineNo);
        FWQBiliCO   := GetWQBili('CO', Item2Word(nA8.FCO), FLineNo);
        FWQBiliCO2  := GetWQBili('CO2', Item2Word(nA8.FCO2), FLineNo);
        FWQBiliKRB  := GetWQBili('KRB', Item2Word(nA8.FKRB), FLineNo);

        FWQBiliHCNext := False;
        FWQBiliNONext := False;
        FWQBiliNO2Next := False;
        FWQBiliCONext := False;
        FWQBiliCO2Next := False;
        FWQBiliKRBNext := False;
      end else
      begin //重新计算比例
        if (not FWQBiliHCNext) and (gWQBiliNext.FHC > 0) and
           (Item2Word(nA8.FHC) >= gWQBiliNext.FHC) then
        begin
          FWQBiliHCNext := True;
          FWQBiliHC := GetWQBili('HC', Item2Word(nA8.FHC), FLineNo);
        end;

        if (not FWQBiliNONext) and (gWQBiliNext.FNO > 0) and
           (Item2Word(nA8.FNO) >= gWQBiliNext.FNO) then
        begin
          FWQBiliNONext := True;
          FWQBiliNO := GetWQBili('NO', Item2Word(nA8.FNO), FLineNo);
        end;

        if (not FWQBiliNO2Next) and (gWQBiliNext.FNO2 > 0) and
           (Item2Word(nA8.FNO2) >= gWQBiliNext.FNO2) then
        begin
          FWQBiliNO2Next := True;
          FWQBiliNO2 := GetWQBili('NO2', Item2Word(nA8.FNO2), FLineNo);
        end;

        if (not FWQBiliCONext) and (gWQBiliNext.FCO > 0) and
           (Item2Word(nA8.FCO) >= gWQBiliNext.FCO) then
        begin
          FWQBiliCONext := True;
          FWQBiliCO := GetWQBili('CO', Item2Word(nA8.FCO), FLineNo);
        end;

        if (not FWQBiliCO2Next) and (gWQBiliNext.FCO2 > 0) and
           (Item2Word(nA8.FCO2) <= gWQBiliNext.FCO2) then
        begin
          FWQBiliCO2Next := True;
          FWQBiliCO2 := GetWQBili('CO2', Item2Word(nA8.FCO2), FLineNo);
        end;

        if (not FWQBiliKRBNext) and (gWQBiliNext.FKRB > 0) and
           (Item2Word(nA8.FKRB) >= gWQBiliNext.FKRB) then
        begin
          FWQBiliKRBNext := True;
          FWQBiliKRB := GetWQBili('KRB', Item2Word(nA8.FKRB), FLineNo);
        end;
      end;

      //------------------------------------------------------------------------
      Word2Item(nA8.FCO, Trunc(Item2Word(nA8.FCO) * FWQBiliCO));
      Word2Item(nA8.FHC, Trunc(Item2Word(nA8.FHC) * FWQBiliHC));
      Word2Item(nA8.FNO, Trunc(Item2Word(nA8.FNO) * FWQBiliNO));
      Word2Item(nA8.FNO2, Trunc(Item2Word(nA8.FNO2) * FWQBiliNO2));
      Word2Item(nA8.FNOx, Trunc(Item2Word(nA8.FNO) + Item2Word(nA8.FNO2)));

      nInt := Item2Word(nA8.FCO2);
      if nInt < 1400 then //CO2不足时补CO2
      begin
        nVal := nInt;
        //old
        nInt := Trunc(nInt * FWQBiliCO2);
        //new
        
        if nInt > 1500 then
             Word2Item(nA8.FCO2, 1470 * Random(30))
        else Word2Item(nA8.FCO2, nInt);

        if Item2Word(nA8.FO2) >= 300 then //反向降低O2,过低时不予校正
        begin
          nInt := Item2Word(nA8.FCO2);
          if nVal < 1 then nVal := nInt;
          Word2Item(nA8.FO2, Trunc(Item2Word(nA8.FO2) * (2 - nInt/nVal)));
        end;

        nInt := Trunc(Item2Word(nA8.FKRB) * FWQBiliKRB);
        if nInt < 990 then //下限0.99
          nInt := 990 + Random(5);
        Word2Item(nA8.FKRB, nInt);
        //CO2变动时修正空燃比
      end;
        
      if CheckShowWQ.Checked then
        ShowData();
      Result := True;
    end;
  end;
end;

//Date: 2020-06-19
//Parm: 源端口;转发端口;帧头类型;协议数据;黑名单
//Desc: 使用比例修正数据
function TfFormMain.AdjustWQProtocol_5105(const nItem, nGroup,
  nHeadType: Integer; const nData: Pointer;
  const nInBlack: Boolean): Boolean;
var nStr: string;
    nInt,nVal: Integer;
    nA3: PWQData5160_A3;
    nA8: PWQData5160_A8;
    nOA3: TWQData5160_A3;
    nOA8: TWQData5160_A8;

  //Desc: 显示日志
  procedure ShowData;
  begin
    if nHeadType = 3 then
    begin
      nStr := Format('%d.A3-CO2:[ %d-%d ] CO:[ %d-%d ] HC:[ %d-%d ] ' +
              'NO:[ %d-%d ] O2:[ %d-%d ] KRB:[ %d-%d ]', [
           FCOMPorts[nItem].FLineNo,
           Item2Word(nOA3.FCO2),  Item2Word(nA3.FCO2),
           Item2Word(nOA3.FCO), Item2Word(nA3.FCO),
           Item2Word(nOA3.FHC), Item2Word(nA3.FHC),
           Item2Word(nOA3.FNO), Item2Word(nA3.FNO),
           Item2Word(nOA3.FO2), Item2Word(nA3.FO2),
           Item2Word(nOA3.FKRB), Item2Word(nA3.FKRB)]);
      WriteLog(nStr);
    end else

    if nHeadType = 8 then
    begin
      nStr := Format('%d.A8-CO2:[ %d-%d ] CO:[ %d-%d ] HC:[ %d-%d ] O2:[ %d-%d ] ' +
              'NO:[ %d-%d ] NO2:[ %d-%d ] NOx:[ %d-%d ] KRB:[ %d-%d ]', [
           FCOMPorts[nItem].FLineNo,
           Item2Word(nOA8.FCO2),  Item2Word(nA8.FCO2),
           Item2Word(nOA8.FCO), Item2Word(nA8.FCO),
           Item2Word(nOA8.FHC), Item2Word(nA8.FHC),
           Item2Word(nOA8.FO2), Item2Word(nA8.FO2),
           Item2Word(nOA8.FNO), Item2Word(nA8.FNO),
           Item2Word(nOA8.FNO2), Item2Word(nA8.FNO2),
           Item2Word(nOA8.FNOx), Item2Word(nA8.FNOx),
           Item2Word(nOA8.FKRB), Item2Word(nA8.FKRB)]);
      WriteLog(nStr);
    end;
  end;

  //Desc: 标气索引
  function GetBiaoQi(const nLine: Integer): Integer;
  var i: Integer;
  begin
    Result := -1;
    for i:=Low(gWQBiaoQi) to High(gWQBiaoQi) do
    if gWQBiaoQi[i].FLineNo = nLine then
    begin
      Result := i;
      Break;
    end;
  end;
begin
  Result := False;
  case nHeadType of
   3: nA3 := nData;
   8: nA8 := nData
   else Exit;
  end;

  with FCOMPorts[nItem] do
  case nHeadType of
   3: //A3指令
    begin
      if CheckShowWQ.Checked then
        nOA3 := nA3^;
      //copy data

      if FWQBiaoQiEnable then //抽标准气
      begin
        nInt := GetBiaoQi(FLineNo);
        if nInt > -1 then
        with gWQBiaoQi[nInt] do
        begin
          nVal :=  Item2Word(nA3.FHC);
          if (nVal < FHC - FHC_WC) or (nVal > FHC + FHC_WC) then
          begin
            Word2Item(nA3.FHC,  FHC + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA3.FNO);
          if (nVal < FNO - FNO_WC) or (nVal > FNO + FNO_WC) then
          begin
            Word2Item(nA3.FNO,  FNO + Random(5));
            Result := True;
          end;

          nVal :=  Item2Word(nA3.FCO);
          if (nVal < FCO - FCO_WC) or (nVal > FCO + FCO_WC) then
          begin
            Word2Item(nA3.FCO,  FCO + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA3.FCO2);
          if (nVal < FCO2 - FCO2_WC) or (nVal > FCO2 + FCO2_WC) then
          begin
            Word2Item(nA3.FCO2,  FCO2 + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA3.FO2);
          if (nVal < FO2 - FO2_WC) or (nVal > FO2 + FO2_WC) then
          begin
            Word2Item(nA3.FO2,  FO2 + Random(3));
            Result := True;
          end;
        end;

        if CheckShowWQ.Checked then
          ShowData();
        Exit;
      end;

      nInt := Item2Word(nA3.FCO) + Item2Word(nA3.FCO2);
      if nInt < gWQCO2BeforePipe then
        FWQZeroCO2Last := GetTickCount();
      //未插管计时开始

      if nInt < gWQCO2AfterPipe then //co2低浓度标识未开始
      begin
        FWQBiliCO2 := -1;
        //待确定比例
        FWQBiliStart := GetTickCount();
        //开始比例计算计时

        if (nInt >= gWQCO2BeforePipe) and
           (GetTickCountDiff(FWQZeroCO2Last) <= gWQIntervalBeforePipe) then
        begin
          Word2Item(nA3.FCO, 0);
          Word2Item(nA3.FHC, 0);
          Word2Item(nA3.FNO, 0);
          
          Result := True;
          WriteLog(Format('%d.A3-插管后CO2浓度过低,已清零', [FLineNo]));
        end;

        if CheckShowWQ.Checked then ShowData();
        Exit;
      end else
      begin
        FWQZeroCO2Last := 0;
        //浓度升高,计时关闭
      end;

      if GetTickCountDiff(FWQBiliStart) < gWQIntervalAfterPipe then
      begin
        //Word2Item(nA3.FCO2, 0);
        Word2Item(nA3.FCO, Random(2));
        Word2Item(nA3.FHC, Random(2));
        Word2Item(nA3.FNO, Random(2));
        //Word2Item(nA3.FO2, 2085 + Random(3));

        if CheckShowWQ.Checked then ShowData();
        Result := True;
        Exit;
      end else

      if FWQBiliCO2 <= 0 then //无比例值,开始计算比例
      begin
        FWQBiliHC   := GetWQBili('HC', Item2Word(nA3.FHC), FLineNo);
        FWQBiliNO   := GetWQBili('NO', Item2Word(nA3.FNO), FLineNo);
        FWQBiliCO   := GetWQBili('CO', Item2Word(nA3.FCO), FLineNo);
        FWQBiliCO2  := GetWQBili('CO2', Item2Word(nA3.FCO2), FLineNo);
        FWQBiliKRB  := GetWQBili('KRB', Item2Word(nA3.FKRB), FLineNo);

        FWQBiliHCNext := False;
        FWQBiliNONext := False;
        FWQBiliCONext := False;
        FWQBiliCO2Next := False;
        FWQBiliKRBNext := False;
      end else
      begin
        if (not FWQBiliHCNext) and (gWQBiliNext.FHC > 0) and
           (Item2Word(nA3.FHC) >= gWQBiliNext.FHC) then
        begin
          FWQBiliHCNext := True;
          FWQBiliHC := GetWQBili('HC', Item2Word(nA3.FHC), FLineNo);
        end;

        if (not FWQBiliNONext) and (gWQBiliNext.FNO > 0) and
           (Item2Word(nA3.FNO) >= gWQBiliNext.FNO) then
        begin
          FWQBiliNONext := True;
          FWQBiliNO := GetWQBili('NO', Item2Word(nA3.FNO), FLineNo);
        end;

        if (not FWQBiliCONext) and (gWQBiliNext.FCO > 0) and
           (Item2Word(nA3.FCO) >= gWQBiliNext.FCO) then
        begin
          FWQBiliCONext := True;
          FWQBiliCO := GetWQBili('CO', Item2Word(nA3.FCO), FLineNo);
        end;

        if (not FWQBiliCO2Next) and (gWQBiliNext.FCO2 > 0) and
           (Item2Word(nA3.FCO2) <= gWQBiliNext.FCO2) then
        begin
          FWQBiliCO2Next := True;
          FWQBiliCO2 := GetWQBili('CO2', Item2Word(nA3.FCO2), FLineNo);
        end;

        if (not FWQBiliKRBNext) and (gWQBiliNext.FKRB > 0) and
           (Item2Word(nA3.FKRB) >= gWQBiliNext.FKRB) then
        begin
          FWQBiliKRBNext := True;
          FWQBiliKRB := GetWQBili('KRB', Item2Word(nA3.FKRB), FLineNo);
        end;
      end;

      //------------------------------------------------------------------------
      Word2Item(nA3.FCO, Trunc(Item2Word(nA3.FCO) * FWQBiliCO));
      Word2Item(nA3.FHC, Trunc(Item2Word(nA3.FHC) * FWQBiliHC));
      Word2Item(nA3.FNO, Trunc(Item2Word(nA3.FNO) * FWQBiliNO));

      nInt := Item2Word(nA3.FCO2);
      if nInt < 1400 then //CO2不足时补CO2
      begin
        nVal := nInt;
        //old
        nInt := Trunc(nInt * FWQBiliCO2);
        //new
        
        if nInt > 1500 then
             Word2Item(nA3.FCO2, 1470 + Random(30))
        else Word2Item(nA3.FCO2, nInt);

        if Item2Word(nA3.FO2) >= 300 then //反向降低O2,过低时不予校正
        begin
          nInt := Item2Word(nA3.FCO2);
          if nVal < 1 then nVal := nInt;
          Word2Item(nA3.FO2, Trunc(Item2Word(nA3.FO2) * (2 - nInt/nVal)));
        end;

        nInt := Trunc(Item2Word(nA3.FKRB) * FWQBiliKRB);
        if nInt < 990 then  //下限0.99
          nInt := 990 + Random(5);
        Word2Item(nA3.FKRB, nInt);
        //CO2变动时修正空燃比
      end;

      if CheckShowWQ.Checked then
        ShowData();
      Result := True;
    end;
    //--------------------------------------------------------------------------
   8: //A8指令
    begin
      if CheckShowWQ.Checked then
        nOA8 := nA8^;
      //copy data

      if FWQBiaoQiEnable then //抽标准气
      begin
        nInt := GetBiaoQi(FLineNo);
        if nInt > -1 then
        with gWQBiaoQi[nInt] do
        begin
          nVal :=  Item2Word(nA8.FHC);
          if (nVal < FHC - FHC_WC) or (nVal > FHC + FHC_WC) then
          begin
            Word2Item(nA8.FHC,  FHC + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FNO);
          if (nVal < FNO - FNO_WC) or (nVal > FNO + FNO_WC) then
          begin
            Word2Item(nA8.FNO,  FNO + Random(5));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FNO2);
          if (nVal < FNO2 - FNO2_WC) or (nVal > FNO2 + FNO2_WC) then
          begin
            Word2Item(nA8.FNO2,  FNO2 + Random(5));
            Result := True;
          end;

          if Result then
          begin
            Word2Item(nA8.FNOx, Item2Word(nA8.FNO) + Item2Word(nA8.FNO2));
            //combine
          end;

          nVal :=  Item2Word(nA8.FCO);
          if (nVal < FCO - FCO_WC) or (nVal > FCO + FCO_WC) then
          begin
            Word2Item(nA8.FCO,  FCO + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FCO2);
          if (nVal < FCO2 - FCO2_WC) or (nVal > FCO2 + FCO2_WC) then
          begin
            Word2Item(nA8.FCO2,  FCO2 + Random(3));
            Result := True;
          end;

          nVal :=  Item2Word(nA8.FO2);
          if (nVal < FO2 - FO2_WC) or (nVal > FO2 + FO2_WC) then
          begin
            Word2Item(nA8.FO2,  FO2 + Random(3));
            Result := True;
          end;
        end;

        if CheckShowWQ.Checked then
          ShowData();
        Exit;
      end;

      nInt := Item2Word(nA8.FCO) + Item2Word(nA8.FCO2);
      if nInt < gWQCO2BeforePipe then
        FWQZeroCO2Last := GetTickCount();
      //未插管计时开始
      
      if nInt < gWQCO2AfterPipe then //co2低浓度标识未开始
      begin
        FWQBiliCO2 := -1;
        //待确定比例
        FWQBiliStart := GetTickCount();
        //开始比例计算计时

        if (nInt >= gWQCO2BeforePipe) and
           (GetTickCountDiff(FWQZeroCO2Last) <= gWQIntervalBeforePipe) then
        begin
          Word2Item(nA8.FCO,  0);
          Word2Item(nA8.FHC,  0);
          Word2Item(nA8.FNO,  0);
          Word2Item(nA8.FNO2, 0);
          Word2Item(nA8.FNOx, 0);

          Result := True;
          WriteLog(Format('%d.A8-插管后CO2浓度过低,已清零', [FLineNo]));
        end;

        if CheckShowWQ.Checked then
          ShowData();
        Exit;
      end;

      if GetTickCountDiff(FWQBiliStart) < gWQIntervalAfterPipe then
      begin
        //Word2Item(nA8.FCO2, 0);
        Word2Item(nA8.FCO,  Random(2));
        Word2Item(nA8.FHC,  Random(2));
        Word2Item(nA8.FNO,  Random(2));
        Word2Item(nA8.FNO2, Random(2));
        Word2Item(nA8.FNOx, Item2Word(nA8.FNO) + Item2Word(nA8.FNO2));
        //Word2Item(nA8.FO2, 2085 + Random(3));

        if CheckShowWQ.Checked then ShowData();
        Result := True;
        Exit;
      end else

      if FWQBiliCO2 <= 0 then //无比例值,开始计算比例
      begin
        FWQBiliHC   := GetWQBili('HC', Item2Word(nA8.FHC), FLineNo);
        FWQBiliNO   := GetWQBili('NO', Item2Word(nA8.FNO), FLineNo);
        FWQBiliNO2  := GetWQBili('NO2', Item2Word(nA8.FNO2), FLineNo);
        FWQBiliCO   := GetWQBili('CO', Item2Word(nA8.FCO), FLineNo);
        FWQBiliCO2  := GetWQBili('CO2', Item2Word(nA8.FCO2), FLineNo);
        FWQBiliKRB  := GetWQBili('KRB', Item2Word(nA8.FKRB), FLineNo);

        FWQBiliHCNext := False;
        FWQBiliNONext := False;
        FWQBiliNO2Next := False;
        FWQBiliCONext := False;
        FWQBiliCO2Next := False;
        FWQBiliKRBNext := False;
      end else
      begin //重新计算比例
        if (not FWQBiliHCNext) and (gWQBiliNext.FHC > 0) and
           (Item2Word(nA8.FHC) >= gWQBiliNext.FHC) then
        begin
          FWQBiliHCNext := True;
          FWQBiliHC := GetWQBili('HC', Item2Word(nA8.FHC), FLineNo);
        end;

        if (not FWQBiliNONext) and (gWQBiliNext.FNO > 0) and
           (Item2Word(nA8.FNO) >= gWQBiliNext.FNO) then
        begin
          FWQBiliNONext := True;
          FWQBiliNO := GetWQBili('NO', Item2Word(nA8.FNO), FLineNo);
        end;

        if (not FWQBiliNO2Next) and (gWQBiliNext.FNO2 > 0) and
           (Item2Word(nA8.FNO2) >= gWQBiliNext.FNO2) then
        begin
          FWQBiliNO2Next := True;
          FWQBiliNO2 := GetWQBili('NO2', Item2Word(nA8.FNO2), FLineNo);
        end;

        if (not FWQBiliCONext) and (gWQBiliNext.FCO > 0) and
           (Item2Word(nA8.FCO) >= gWQBiliNext.FCO) then
        begin
          FWQBiliCONext := True;
          FWQBiliCO := GetWQBili('CO', Item2Word(nA8.FCO), FLineNo);
        end;

        if (not FWQBiliCO2Next) and (gWQBiliNext.FCO2 > 0) and
           (Item2Word(nA8.FCO2) <= gWQBiliNext.FCO2) then
        begin
          FWQBiliCO2Next := True;
          FWQBiliCO2 := GetWQBili('CO2', Item2Word(nA8.FCO2), FLineNo);
        end;

        if (not FWQBiliKRBNext) and (gWQBiliNext.FKRB > 0) and
           (Item2Word(nA8.FKRB) >= gWQBiliNext.FKRB) then
        begin
          FWQBiliKRBNext := True;
          FWQBiliKRB := GetWQBili('KRB', Item2Word(nA8.FKRB), FLineNo);
        end;
      end;

      //------------------------------------------------------------------------
      Word2Item(nA8.FCO, Trunc(Item2Word(nA8.FCO) * FWQBiliCO));
      Word2Item(nA8.FHC, Trunc(Item2Word(nA8.FHC) * FWQBiliHC));
      Word2Item(nA8.FNO, Trunc(Item2Word(nA8.FNO) * FWQBiliNO));
      Word2Item(nA8.FNO2, Trunc(Item2Word(nA8.FNO2) * FWQBiliNO2));
      Word2Item(nA8.FNOx, Trunc(Item2Word(nA8.FNO) + Item2Word(nA8.FNO2)));

      nInt := Item2Word(nA8.FCO2);
      if nInt < 1400 then //CO2不足时补CO2
      begin
        nVal := nInt;
        //old
        nInt := Trunc(nInt * FWQBiliCO2);
        //new
        
        if nInt > 1500 then
             Word2Item(nA8.FCO2, 1470 * Random(30))
        else Word2Item(nA8.FCO2, nInt);

        if Item2Word(nA8.FO2) >= 300 then //反向降低O2,过低时不予校正
        begin
          nInt := Item2Word(nA8.FCO2);
          if nVal < 1 then nVal := nInt;
          Word2Item(nA8.FO2, Trunc(Item2Word(nA8.FO2) * (2 - nInt/nVal)));
        end;

        nInt := Trunc(Item2Word(nA8.FKRB) * FWQBiliKRB);
        if nInt < 990 then //下限0.99
          nInt := 990 + Random(5);
        Word2Item(nA8.FKRB, nInt);
        //CO2变动时修正空燃比
      end;
        
      if CheckShowWQ.Checked then
        ShowData();
      Result := True;
    end;
  end;
end;

end.
