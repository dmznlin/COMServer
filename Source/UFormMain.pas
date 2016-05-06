{*******************************************************************************
  作者: dmzn@163.com 2016-05-05
  描述: 串口转发服务程序
*******************************************************************************}
unit UFormMain;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  CPortTypes, UTrayIcon, CPort, ExtCtrls, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer, ComCtrls, StdCtrls, IdContext;

type
  TCOMItem = record
    FItemName: string;            //节点名
    FItemGroup: string;           //节点分组,每组有"收-发"各一
    FPortName: string;            //端口名称
    FBaudRate: TBaudRate;         //波特率
    FDataBits: TDataBits;         //数据位
    FStopBits: TStopBits;         //起停位

    FCOMObject: TComPort;         //串口对象
    FBuffer: string;              //数据缓存
    FMemo: string;                //描述信息
  end;

  TfFormMain = class(TForm)
    GroupBox1: TGroupBox;
    MemoLog: TMemo;
    StatusBar1: TStatusBar;
    CheckSrv: TCheckBox;
    EditPort: TLabeledEdit;
    IdTCPServer1: TIdTCPServer;
    CheckAuto: TCheckBox;
    CheckLoged: TCheckBox;
    Timer1: TTimer;
    ComPort1: TComPort;
    BtnRefresh: TButton;
    CheckAdjust: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure CheckSrvClick(Sender: TObject);
    procedure CheckLogedClick(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure BtnRefreshClick(Sender: TObject);
  private
    { Private declarations }
    FTrayIcon: TTrayIcon;
    {*状态栏图标*}
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
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //数据处理
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}
uses
  IniFiles, Registry, ULibFun, USysLoger;

var
  gPath: string;               //程序路径

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '串口服务', nEvent);
end;

//------------------------------------------------------------------------------
procedure TfFormMain.FormCreate(Sender: TObject);
var nIni: TIniFile;
    nReg: TRegistry;
begin
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogEvent := ShowLog;

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := Application.Title;
  FTrayIcon.Visible := True;

  nIni := nil;
  nReg := nil;
  try
    nIni := TIniFile.Create(gPath + 'Config.ini');
    EditPort.Text := nIni.ReadString('Config', 'Port', '8000');
    Timer1.Enabled := nIni.ReadBool('Config', 'Enabled', False);
    
    nReg := TRegistry.Create;
    nReg.RootKey := HKEY_CURRENT_USER;

    nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
    CheckAuto.Checked := nReg.ValueExists(sAutoStartKey);
    LoadFormConfig(Self, nIni);
  finally
    nIni.Free;
    nReg.Free;
  end;

  SetLength(FCOMPorts, 0);
  LoadCOMConfig;
  //读取串口配置

  {$IFDEF DEBUG}
  CheckLoged.Checked := True;
  CheckAdjust.Checked := True;
  {$ENDIF}
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
end;

procedure TfFormMain.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  CheckSrv.Checked := True;
end;

procedure TfFormMain.CheckSrvClick(Sender: TObject);
var nIdx: Integer;
begin
  if not IdTCPServer1.Active then
    IdTCPServer1.DefaultPort := StrToInt(EditPort.Text);
  IdTCPServer1.Active := CheckSrv.Checked;
  EditPort.Enabled := not CheckSrv.Checked;

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
        FMemo := E.Message;
        WriteLog(E.Message);
      end;
    end;
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
    Add('|-- 名称: ' + FItemName);
    Add('|-- 分组: ' + FItemGroup);
    Add('|-- 端口: ' + FPortName);
    Add('|-- 速率: ' + BaudRateToStr(FBaudRate));
    Add('|-- 数位: ' + DataBitsToStr(FDataBits));
    Add('|-- 停位: ' + StopBitsToStr(FStopBits));
    Add('|-- 备注: ' + FMemo);
    Add('');
  end;
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
      FPortName  := ReadString(nList[nIdx], 'PortName', '');
      FBaudRate  := StrToBaudRate(ReadString(nList[nIdx], 'BaudRate', '9600'));
      FDataBits  := StrToDataBits(ReadString(nList[nIdx], 'DataBits', '8'));
      FStopBits  := StrToStopBits(ReadString(nList[nIdx], 'StopBits', '1'));

      FBuffer := '';
      FCOMObject := nil;

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

//Date: 2016-05-05
//Parm: 对象;数据大小
//Desc: 处理串口数据
procedure TfFormMain.OnCOMData(Sender: TObject; Count: Integer);
var nStr: string;
    nIdx,nInt: Integer;
    nItem,nGroup: Integer;
begin
  nItem := FindCOMItem(Sender);
  if (nItem < 0) or (FCOMPorts[nItem].FCOMObject = nil) then
  begin
    WriteLog('收到数据,但无法匹配串口对象.');
    Exit;
  end;

  nGroup := FindSameGroup(nItem);
  if (nGroup < 0) or (FCOMPorts[nGroup].FCOMObject = nil) then
  begin
    nStr := '收到数据,但无法匹配串口[ %s ]同组对象.';
    WriteLog(Format(nStr, [FCOMPorts[nItem].FItemName]));
    Exit;
  end;

  with FCOMPorts[nItem] do
  begin
    FCOMObject.ReadStr(FBuffer, Count);
    nStr := '';
    nInt := Length(FBuffer);

    for nIdx:=1 to nInt do
      nStr := nStr + IntToHex(Ord(FBuffer[nIdx]), 1) + ' ';
    //十六进制

    nStr := Format('串口:[ %s ] 数据:[ %s ]', [FItemName, nStr]);
    WriteLog(nStr);
  end; //读取数据

  if CheckAdjust.Checked then
  begin
    FCOMPorts[nGroup].FCOMObject.WriteStr(FCOMPorts[nItem].FBuffer);
    nStr := '串口:[ %s ] 处理:[ 转发至 %s ]';
    nStr := Format(nStr, [FCOMPorts[nItem].FItemName, FCOMPorts[nGroup].FItemName]);

    WriteLog(nStr);
    Exit;
  end; //直接转发
end;

end.
