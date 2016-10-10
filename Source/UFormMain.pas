{*******************************************************************************
  作者: dmzn@163.com 2016-05-05
  描述: 串口转发服务程序
*******************************************************************************}
unit UFormMain;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  CPort, CPortTypes, UTrayIcon, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, IdContext, ExtCtrls,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, StdCtrls,
  cxTextEdit, cxLabel, cxCheckBox, dxNavBarCollns, cxClasses, dxNavBarBase,
  dxNavBar, ComCtrls, cxMaskEdit, cxDropDownEdit;

type
  TCOMType = (ctDD, ctWQ);
  //类型: 大灯仪,尾气检测仪

  TCOMItem = record
    FItemName: string;            //节点名
    FItemGroup: string;           //节点分组
    FItemType: TCOMType;          //节点类型
    FPortName: string;            //端口名称
    FBaudRate: TBaudRate;         //波特率
    FDataBits: TDataBits;         //数据位
    FStopBits: TStopBits;         //起停位

    FCOMObject: TComPort;         //串口对象
    FMemo: string;                //描述信息
    FBuffer: string;              //数据缓存
    FData: string;                //协议数据
    FDataLast: Int64;             //接收时间

    FAdj_Val_HC: Word;            //碳氢值(90<x<100,大于100矫正)
    FAdj_Dir_HC: Boolean;         //增减方向
    FAdj_Val_NO: Word;            //氧氮值(100<x<400,大于400矫正)
    FAdj_Dir_NO: Boolean;
    FAdj_Val_CO: Word;            //碳氧值(0.01<x<0.3,大于0.3矫正)
    FAdj_Dir_CO: Boolean;
    FAdj_Val_KR: Word;            //空燃比(0.97<x<1.03,大于1.03矫正)
    FAdj_LastActive: Int64;       //上次触发
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

  PWQData = ^TWQData;
  TWQData = record
    FHead   : array[0..2] of Char;    //协议头
    FCO2    : array[0..1] of Char;    //co2
    FCO     : array[0..1] of Char;    //co
    FHC     : array[0..1] of Char;    //碳氢
    FNO     : array[0..1] of Char;    //氮氧
    FO2     : array[0..1] of Char;    //氧气
    FSD     : array[0..1] of Char;    //湿度
    FYW     : array[0..1] of Char;    //油温
    FHJWD   : array[0..1] of Char;    //环境温度
    FZS     : array[0..1] of Char;    //转速
    FQLYL   : array[0..1] of Char;    //气路压力
    FKRB    : array[0..1] of Char;    //空燃比
    FHJYL   : array[0..1] of Char;    //环境压力
    FCRC    : array[0..0] of Char;    //校验位
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
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*状态栏图标*}
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
    procedure ParseWQProtocol(const nItem,nGroup: Integer);
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //数据处理
    function AdjustProtocol(const nData: PDataItem): Boolean;
    function AdjustWQProtocol(const nItem,nGroup: Integer;
      const nData: PWQData): Boolean;
    //校正数据
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
  cChar_Head       = Char($01);                       //协议头
  cChar_End        = Char($FF);                       //协议尾
  cSizeData        = SizeOf(TDataItem);               //数据大小

  cChar_WQ_Head    = Char($06)+Char($60)+Char($1B);   //协议头
  cChar_WQ_Head_L  = Length(cChar_WQ_Head);           //头大小
  cSize_WQ_Data    = SizeOf(TWQData);                 //数据大小
  cAdj_Interval    = 3 * 1000 * 60;                   //矫正数据有效期

type
  PSplitWord = ^TSplitWord;
  TSplitWord = packed record
    FLo: Byte;
    FHi: Byte;
  end;

var
  gPath: string;                        //程序路径

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '串口服务', nEvent);
end;

//------------------------------------------------------------------------------
function COMType2Str(const nType: TCOMType): string;
begin
  case nType of
   ctDD: Result := '大灯仪';
   ctWQ: Result := '尾气检测仪';
  end;
end;

function Str2COMType(const nStr: string): TCOMType;
begin
  if nStr = '1' then
       Result := ctWQ
  else Result := ctDD;
end;

function GetVerify(const nInit,nDays: Integer): string;
begin
  Result := MD5Print(MD5String('QL_' + IntToStr(nInit) + IntToStr(nDays)));
  Result := Copy(Result, Length(Result) - 5, 6);
end;

//Date: 2016-09-25
//Desc: 验证系统是否过期
function CheckSystemValid(const nIni: TIniFile = nil): Boolean;
var nStr: string;
    nCfg: TIniFile;
    nInit,nLast,nNow: Integer;
begin
  if not Assigned(nIni) then
       nCfg := TIniFile.Create(gPath + 'Config.ini')
  else nCfg := nIni;

  with nCfg do
  try
    nNow := Trunc(Date());
    nInit := ReadInteger('Config', 'DateFirst', 0);
    nLast := ReadInteger('Config', 'DateLast', 0);

    nStr := ReadString('Config', 'DateVerify', '');
    Result := nStr = GetVerify(nInit, nLast - nInit);

    if not Result then
    begin
      nStr := ReadString('Config', '1', '');
      if nStr <> '1' then Exit;
      //初始化标记不存在

      WriteInteger('Config', 'DateFirst', nNow);
      //初始化日期

      WriteInteger('Config', 'DateLast', nNow);
      //最后活动日期

      WriteString('Config', 'DateVerify', GetVerify(nNow, 0));
      //日期保护

      DeleteKey('Config', '1');
      Result := True;
      Exit;
    end;

    if nLast <> nNow then
    begin
      if nLast > nNow then
      begin
        Result := False;
        Exit;
      end; //日期向前调整,不合规

      nLast := nNow;
      nStr := GetVerify(nInit, nLast - nInit);
    
      WriteInteger('Config', 'DateLast', nLast);
      WriteString('Config', 'DateVerify', nStr);
    end; //日期调整

    Result := (nLast - nInit) / 365 < 1;
    //未满一年
  finally
    if not Assigned(nIni) then
      nCfg.Free;
    //xxxxx
  end;
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
    if not CheckSystemValid(nIni) then
    begin
      dxNavGroup2.Visible := False;
      Exit;
    end;
    
    EditPort.Text := nIni.ReadString('Config', 'Port', '8000');
    Timer1.Enabled := nIni.ReadBool('Config', 'Enabled', False);
    CheckAdjust.Checked := nIni.ReadBool('Config', 'CloseAdjust', False);
    CheckCP.Enabled := nIni.ReadInteger('Config', 'CloseCPEnable', 1) <> 0;

    if CheckCP.Enabled then
         CheckCP.Checked := nIni.ReadBool('Config', 'CloseCP', False)
    else CheckCP.Checked := False;

    CheckGQ.Checked := nIni.ReadBool('Config', 'CloseGQ', False);
    FUserPasswd := nIni.ReadString('Config', 'UserPassword', 'admin');
    FYGMinValue := nIni.ReadInteger('Config', 'YGMinValue', 5000);
    //远光强度下限

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

  LoadCOMConfig;
  //读取串口配置

  nStr := ChangeFileExt(Application.ExeName, '.ico');
  if FileExists(nStr) then
    Application.Icon.LoadFromFile(nStr);
  //change app icon

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := Caption;
  FTrayIcon.Visible := True;
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
    nReg: TRegistry;
begin
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
  if Timer2.Tag < 20 then Exit;
  Timer2.Tag := 0;

  //if FDateLast = Date() then Exit;
  FDateLast := Date();

  if not CheckSystemValid(nil) then
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
  MemoLog.Lines.Add('刷新设备列表:');

  for nIdx:=Low(FCOMPorts) to High(FCOMPorts) do
  with FCOMPorts[nIdx],MemoLog.Lines do
  begin
    Add('设备: ' + IntToStr(nIdx+1));
    Add('|--- 名称: ' + FItemName);
    Add('|--- 分组: ' + FItemGroup);
    Add('|--- 类型: ' + COMType2Str(FItemType));
    Add('|--- 端口: ' + FPortName);
    Add('|--- 速率: ' + BaudRateToStr(FBaudRate));
    Add('|--- 数位: ' + DataBitsToStr(FDataBits));
    Add('|--- 停位: ' + StopBitsToStr(FStopBits));
    Add('|--- 备注: ' + FMemo);
    Add('');
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
  CheckCP.Enabled := not CheckAdjust.Checked;
  CheckGQ.Enabled := not CheckAdjust.Checked;
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

//Desc: 读取配置
procedure TfFormMain.LoadCOMConfig;
var nIdx: Integer;
    nIni: TIniFile;
    nList: TStrings;
begin
  nList := TStringList.Create;
  nIni := TIniFile.Create(gPath + 'Ports.ini');
  try
    nIni.ReadSections(nList);
    SetLength(FCOMPorts, nList.Count);

    for nIdx:=nList.Count-1 downto 0 do
    with FCOMPorts[nIdx],nIni do
    begin
      FItemName  := ReadString(nList[nIdx], 'Name', '');
      FItemGroup := ReadString(nList[nIdx], 'Group', '');
      FItemType := Str2COMType(ReadString(nList[nIdx], 'Type', '0'));

      FPortName  := ReadString(nList[nIdx], 'PortName', '');
      FBaudRate  := StrToBaudRate(ReadString(nList[nIdx], 'BaudRate', '9600'));
      FDataBits  := StrToDataBits(ReadString(nList[nIdx], 'DataBits', '8'));
      FStopBits  := StrToStopBits(ReadString(nList[nIdx], 'StopBits', '1'));

      FBuffer := '';
      FData := '';
      FDataLast := 0;
      FCOMObject := nil;
      FAdj_LastActive := 0;

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
        ReadTotalConstant := 100;
        ReadTotalMultiplier := 10;
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

      if (nInt > 1) or CheckDetail.Checked then
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
    StrPCopy(@nBuf[0], Copy(FData, nS, cSizeData));
    Move(nBuf, nData, cSizeData);
    //复制到协议包,准备分析

    if AdjustProtocol(@nData) then
    begin
      SetString(FBuffer, PChar(@nData.Fsoh), cSizeData);
      FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
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

  nPY := StrToFloat(nData.Fjud);
  //上下偏移
  nDG := StrToFloat(nData.Fjh);
  //灯高

  if (nPY <> 0) and (nDG <> 0) and (not CheckCP.Checked) then
  begin
    nVal := (nDG - nPY) / nDG;
    nVal := Float2Float(nVal, 100, True);
    //垂直偏移量

    if (nVal <= 0.70) or ((nVal >= 0.80) and (nVal < 1.5)) then
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
  nDQ := StrToFloat(nData.Fyi);
  //远光强度

  if (nDQ > FYGMinValue / 100) and (nDQ < 150) and (not CheckGQ.Checked) then
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

  {.$IFDEF DEBUG}
  nStr := '上下:[ ' + nData.Fjud + '] ' +
          '灯高:[ ' + nData.Fjh + '] ' +
          '比值:[ ' + nData.Fjp + '] ' +
          '强度:[ ' + nData.Fyi + ']';
  WriteLog(nStr);
  {.$ENDIF}
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
procedure TfFormMain.ParseWQProtocol(const nItem, nGroup: Integer);
var nS,nE,nPos,nIdx: Integer;
    nData: TWQData;
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
    nS := Pos(cChar_WQ_Head, FBuffer);
    if (nS < 1) and (FData = '') then
    begin
      RedirectData(nItem, nGroup, FBuffer);
      Exit;
    end; //非协议数据直接转发

    FDataLast := GetTickCount;
    FData :=  FData + FBuffer;
    //保存数据待分析

    nS := Pos(cChar_WQ_Head, FData);
    nPos := Length(FData);
    if nPos - nS + 1 < cSize_WQ_Data then Exit; //未找到完整协议包

    nE := nS + cSize_WQ_Data - 1;
    FBuffer := Copy(FData, nS, cSize_WQ_Data);

    for nIdx:=Low(nBuf) to High(nBuf) do
      nBuf[nIdx] := FBuffer[nIdx + 1];
    Move(nBuf, nData, cSize_WQ_Data);
    //复制到协议包,准备分析

    if (nData.FCRC = MakeCRC(FBuffer, nS, nE-1)) and
       (AdjustWQProtocol(nItem, nGroup, @nData)) then
    begin
      SetString(FBuffer, PChar(@nData.FHead), cSize_WQ_Data);
      FBuffer[cSize_WQ_Data] := MakeCRC(FBuffer, 1, cSize_WQ_Data - 1);
      FData := Copy(FData, 1, nS-1) + FBuffer + Copy(FData, nE+1, nPos-nE+1);
    end;

    RedirectData(nItem, nGroup, FData);
    FData := '';
    //发送数据
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
//Parm: 源端口;转发端口;协议数据
//Desc: 分析协议数据,有必要时校正
function TfFormMain.AdjustWQProtocol(const nItem,nGroup: Integer;
  const nData: PWQData): Boolean;
var nStr: string;
    nInt: Integer;
begin
  Result := False;
  with FCOMPorts[nItem] do
  begin
    nInt := Item2Word(nData.FKRB);
    if nInt >= 1030 then //空燃比: 0.97<x<1.03
    begin
      FAdj_Val_KR := 971 + Random(60); //1030 - 970 = 60
      Word2Item(nData.FKRB, FAdj_Val_KR);

      nStr := Format('空燃比:[ %d -> %d ]', [nInt, FAdj_Val_KR]);
      WriteLog(nStr);
      Result := True;
    end;

    nInt := Item2Word(nData.FHC);
    if nInt >= 100 then //碳氢: 90<x<100
    begin
      if GetTickCount - FAdj_LastActive >= cAdj_Interval then
      begin
        FAdj_Val_HC := 90 + Random(10);
        if FAdj_Val_HC < 95 then
             FAdj_Dir_HC := True
        else FAdj_Dir_HC := False;
      end;

      if FAdj_Dir_HC then
           FAdj_Val_HC := FAdj_Val_HC + Random(3)
      else FAdj_Val_HC := FAdj_Val_HC - Random(3);

      if FAdj_Val_HC >= 100 then
      begin
        FAdj_Val_HC := 99;
        FAdj_Dir_HC := False;
      end;

      if FAdj_Val_HC <= 90 then
      begin
        FAdj_Val_HC := 91;
        FAdj_Dir_HC := False;
      end;

      Word2Item(nData.FHC, FAdj_Val_HC);
      Result := True;

      nStr := Format('碳氢(HC):[ %d -> %d ]', [nInt, FAdj_Val_HC]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FCO);
    if nInt >= 30 then //碳氧: 1<x<30
    begin
      if GetTickCount - FAdj_LastActive >= cAdj_Interval then
      begin
        FAdj_Val_CO := 1 + Random(29);
        if FAdj_Val_HC < 15 then
             FAdj_Dir_CO := True
        else FAdj_Dir_CO := False;
      end;

      if FAdj_Dir_CO then
           FAdj_Val_CO := FAdj_Val_CO + Random(5)
      else FAdj_Val_CO := FAdj_Val_CO - Random(5);

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

      nStr := Format('碳氧(CO):[ %d -> %d ]', [nInt, FAdj_Val_CO]);
      WriteLog(nStr);
    end;

    nInt := Item2Word(nData.FNO);
    if nInt >= 30 then //氮氧:100<x<400
    begin
      if GetTickCount - FAdj_LastActive >= cAdj_Interval then
      begin
        FAdj_Val_NO:= 100 + Random(300);
        FAdj_Dir_NO := not FAdj_Dir_HC;
      end;

      if FAdj_Dir_NO then
           FAdj_Val_NO := FAdj_Val_NO + Random(20)
      else FAdj_Val_NO := FAdj_Val_NO - Random(20);

      if FAdj_Val_NO >= 400 then
      begin
        FAdj_Val_NO := 399;
        FAdj_Dir_NO := False;
      end;

      if FAdj_Val_NO <= 100 then
      begin
        FAdj_Val_NO := 101;
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
end;

end.
