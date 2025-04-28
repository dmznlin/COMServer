{*******************************************************************************
  作者: dmzn@163.com 2025-04-20
  描述: 发动机转速提升主界面
*******************************************************************************}
unit UFormMain;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, UCommonConst,
  USysConst, IdGlobal, IdSocketHandle, CPort, CPortTypes, IdTCPConnection, IdTCPClient,
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer, UHotKeyManager, ExtCtrls, StdCtrls,
  ComCtrls;

type
  TCOMItem = record
    FItemName: string;            //节点名
    FItemGroup: string;           //节点分组
    FPortName: string;            //端口名称
    FBaudRate: TBaudRate;         //波特率
    FDataBits: TDataBits;         //数据位
    FStopBits: TStopBits;         //起停位

    FCOMObject: TComPort;         //串口对象
    FDeviceType: TDeviceType;     //设备类型
    FMemo: string;                //描述信息
    FBuffer: string;              //数据缓存
    FData: string;                //协议数据
    FDataLast: Int64;             //接收时间
    FInWork: Boolean;             //业务开始
  end;

  TfFormMain = class(TForm)
    Timer1: TTimer;
    SBar1: TStatusBar;
    wPage1: TPageControl;
    Sheet1: TTabSheet;
    Sheet2: TTabSheet;
    HintPanel: TPanel;
    Image1: TImage;
    Image2: TImage;
    HintLabel: TLabel;
    HotKey1: THotKeyManager;
    Group2: TGroupBox;
    EditHotKey1: TLabeledEdit;
    EditHotKey2: TLabeledEdit;
    Group1: TGroupBox;
    CheckRun: TCheckBox;
    CheckMin: TCheckBox;
    Group3: TGroupBox;
    EditExe: TLabeledEdit;
    EditWin: TLabeledEdit;
    EditContent: TLabeledEdit;
    MemoLog: TMemo;
    Panel1: TPanel;
    CheckSrv: TCheckBox;
    UDPSrv1: TIdUDPServer;
    Group4: TGroupBox;
    EditNew: TLabeledEdit;
    EditNormal: TLabeledEdit;
    EditPwd: TLabeledEdit;
    EditPort: TLabeledEdit;
    Label1: TLabel;
    Timer2: TTimer;
    CheckDetail: TCheckBox;
    CheckShowLog: TCheckBox;
    IdTCPClient1: TIdTCPClient;
    EditLi: TLabeledEdit;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure HotKey1HotKeyPressed(HotKey: Cardinal; Index: Word);
    procedure EditHotKey1Change(Sender: TObject);
    procedure UDPSrv1UDPRead(AThread: TIdUDPListenerThread; AData: TIdBytes; ABinding:
      TIdSocketHandle);
    procedure CheckSrvClick(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure CheckShowLogClick(Sender: TObject);
  private
    { Private declarations }
    FHotKeyHide: Cardinal;
    FHotKeyRun: Cardinal;
    //全局热键
    FConfigChanged: Boolean;
    //配置变动
    FLineNo: string;
    FRemoteHost: string;
    FRemotePort: Integer;
    //远程服务
    FServer: THostItem;
    FSweetHeartBase: Integer;
    //控制台相关
    FRate: Single;
    //桶径比例
    FNiuLi: Single;
    //扭力放大
    FListA: TStrings;
    //字符列表
    FCOMPorts: array of TCOMItem;
    //串口对象
    procedure SystemConfig(const nLoad: Boolean);
    procedure ShowLog(const nStr: string);
    //显示日志
    procedure AddClientInfo(const nClient: TStrings);
    procedure SweetHeartWithServer;
    //控制台通讯
    procedure LoadCOMConfig;
    function ComportAction(const nOpen: Boolean): Boolean;
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //串口控制
    function FindCOMItem(const nCOM: TObject): Integer; overload;
    function FindSameGroup(const nIdx: Integer): Integer; overload;
    //检索数据
    function CalRate(): Boolean;
    function AdjustValue(const nData: string): string;
    procedure RedirectData(const nItem, nGroup: Integer; const nData: string);
    procedure ParseProtocol(const nItem, nGroup: Integer);
    //数据处理
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  IniFiles, Registry, StrUtils, ULibFun, UMgrCOMM, UBase64, UFormInputbox,
  UsysMAC, USysLoger;

const
  sDataCmd = Char($2A) + Char($47) + Char($52) + Char($C3) + Char($0D);
  cSizeCmd = Length(sDataCmd);
  //业务指令

  sDataDemo = '*000.69000010000.0000.0018005.7300000000000039.07000.00000.00000.000.00s0';
  //业务模拟数据
  cSizeData = Length(sDataDemo);

  cTagStart = '*';
  cTagEnd = #13;
  //开始结束符

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '车速服务', nEvent);
end;

//------------------------------------------------------------------------------
procedure TfFormMain.FormCreate(Sender: TObject);
begin
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath + sConfig, gPath + sForm, gPath + sDB);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogEvent := ShowLog;
  gSysLoger.LogSync := True;

  FListA := TStringList.Create;
  SetLength(FCOMPorts, 0);
  FillChar(FServer, SizeOf(FServer), #0);

  wPage1.ActivePageIndex := 0;
  gLocalMAC := MakeActionID_MAC;
  GetLocalIPConfig(gLocalName, gLocalIP);

  SystemConfig(True);
  Application.ShowMainForm := not CheckMin.Checked;

  FHotKeyHide := TextToHotKey(EditHotKey1.Text, False);
  HotKey1.AddHotKey(FHotKeyHide);
  FHotKeyRun := TextToHotKey(EditHotKey2.Text, False);
  HotKey1.AddHotKey(FHotKeyRun);

  LoadCOMConfig;
  //读取串口配置
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FConfigChanged then
    SystemConfig(False);
  //xxxxx

  UDPSrv1.Active := False;
  CheckSrv.Checked := False;
  FreeAndNil(FListA);
end;

//Date: 2025-04-20
//Parm: 读写
//Desc: 处理配置信息
procedure TfFormMain.SystemConfig(const nLoad: Boolean);
var
  nStr: string;
  nInt: Integer;
  nIni: TIniFile;
  nReg: TRegistry;
begin
  nIni := nil;
  nReg := nil;
  try
    nIni := TIniFile.Create(gPath + sConfig);
    //new obj

    if nLoad then
      with nIni do
      begin
        nStr := ReadString('Config', 'Password', '');
        if nStr <> '' then
          EditPwd.Text := DecodeBase64(nStr);

        nInt := ReadInteger('Config', 'Port', cSrvBroadcast_Port);
        EditPort.Text := IntToStr(nInt);
        CheckMin.Checked := ReadBool('Config', 'MinAfterRun', False);

        nStr := ReadString('Config', 'HotKeyHide', '');
        if nStr <> '' then
          EditHotKey1.Text := nStr;

        nStr := ReadString('Config', 'HostKeyRun', '');
        if nStr <> '' then
          EditHotKey2.Text := nStr;

        nStr := ReadString('Config', 'ExeName', '');
        if nStr <> '' then
          EditExe.Text := nStr;

        nStr := ReadString('Config', 'WinName', '');
        if nStr <> '' then
          EditWin.Text := nStr;

        nStr := ReadString('Config', 'MainText', '');
        if nStr <> '' then
          EditContent.Text := nStr;

        EditNormal.Text := ReadString('Config', 'DataNormal', '373');
        EditNew.Text := ReadString('Config', 'DataNew', '700');
        EditLi.Text := ReadString('Config', 'DataNiuLi', '1.2');
        
        FLineNo := ReadString('Config', 'LineNo', '0');
        FRemoteHost := ReadString('Config', 'RemoteHost', '127.0.0.1');
        FRemotePort := ReadInteger('Config', 'RemotePort', 8080);

        nReg := TRegistry.Create;
        nReg.RootKey := HKEY_CURRENT_USER;

        nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
        CheckRun.Checked := nReg.ValueExists(sAutoStartKey);
      end
    else
    begin
      nIni.WriteString('Config', 'Password', EncodeBase64(EditPwd.Text));
      nIni.WriteString('Config', 'Port', EditPort.Text);
      nIni.WriteBool('Config', 'MinAfterRun', CheckMin.Checked);

      nIni.WriteString('Config', 'HotKeyHide', EditHotKey1.Text);
      nIni.WriteString('Config', 'HostKeyRun', EditHotKey2.Text);
      nIni.WriteString('Config', 'ExeName', EditExe.Text);
      nIni.WriteString('Config', 'WinName', EditWin.Text);
      nIni.WriteString('Config', 'MainText', EditContent.Text);

      nIni.WriteString('Config', 'DataNormal', EditNormal.Text);
      nIni.WriteString('Config', 'DataNew', EditNew.Text);
      nIni.WriteString('Config', 'DataNiuLi', EditLi.Text);

      nReg := TRegistry.Create;
      nReg.RootKey := HKEY_CURRENT_USER;
      nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);

      if CheckRun.Checked then
      begin
        nReg.WriteString(sAutoStartKey, Application.ExeName);
      end else
      
      if nReg.ValueExists(sAutoStartKey) then
        nReg.DeleteValue(sAutoStartKey);
      //xxxxx
    end;

    FConfigChanged := False;
    //flag
  finally
    nIni.Free;
    nReg.Free;
  end;
end;

//Desc: 读取配置
procedure TfFormMain.LoadCOMConfig;
var
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

    for nIdx := nList.Count - 1 downto 0 do
      with FCOMPorts[nIdx], nIni do
      begin
        FCOMPorts[nIdx] := nDef;
        FItemName := ReadString(nList[nIdx], 'Name', '');
        FItemGroup := ReadString(nList[nIdx], 'Group', '');

        FPortName := ReadString(nList[nIdx], 'PortName', '');
        FBaudRate := StrToBaudRate(ReadString(nList[nIdx], 'BaudRate', '9600'));
        FDataBits := StrToDataBits(ReadString(nList[nIdx], 'DataBits', '8'));
        FStopBits := StrToStopBits(ReadString(nList[nIdx], 'StopBits', '1'));

        FBuffer := '';
        FData := '';
        FDataLast := 0;
        FInWork := False;

        FDeviceType := TDeviceType(ReadInteger(nList[nIdx], 'DeviceType', 0));
        //设备类型

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

procedure TfFormMain.EditHotKey1Change(Sender: TObject);
begin
  FConfigChanged := True;
end;

procedure TfFormMain.HotKey1HotKeyPressed(HotKey: Cardinal; Index: Word);
var
  nStr: string;
begin
  if HotKey = FHotKeyHide then //显示隐藏
  begin
    ShowInputPWDBox('请输入密码:', '管理员', nStr);
    if nStr = EditPwd.Text then
      Visible := not Visible;
    //xxxxx
  end
  else
if HotKey = FHotKeyRun then //是否校正
  begin
    CheckSrv.Checked := not CheckSrv.Checked;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 显示日志
procedure TfFormMain.ShowLog(const nStr: string);
var
  nIdx: Integer;
begin
  MemoLog.Lines.BeginUpdate;
  try
    MemoLog.Lines.Insert(0, nStr);
    if MemoLog.Lines.Count > 100 then
      for nIdx := MemoLog.Lines.Count - 1 downto 50 do
        MemoLog.Lines.Delete(nIdx);
  finally
    MemoLog.Lines.EndUpdate;
  end;

  Application.ProcessMessages;
end;

//Desc: 打开关闭串口
function TfFormMain.ComportAction(const nOpen: Boolean): Boolean;
var
  nIdx, nErr: Integer;
begin
  nErr := 0;
  for nIdx := Low(FCOMPorts) to High(FCOMPorts) do
    with FCOMPorts[nIdx] do
      if Assigned(FCOMObject) then
      try
        if nOpen then
          FCOMObject.Open
        else
          FCOMObject.Close;
      except
        on E: Exception do
        begin
          Inc(nErr);
          WriteLog(E.Message);
        end;
      end;
  //xxxxx

  Result := nErr < 1;
end;

procedure TfFormMain.Timer1Timer(Sender: TObject);
var
  nInt: Int64;
begin
  SBar1.Panels[0].Text := '※.' + DateTime2Str(Now()) + ' ' + Date2Week();
  //default
  try
    if SBar1.Tag < 10 then
    begin
      SBar1.Tag := 10;
      SBar1.Panels[0].Width := Canvas.TextWidth(SBar1.Panels[0].Text) + 10;

      UDPSrv1.DefaultPort := StrToInt(EditPort.Text);
      UDPSrv1.Active := True;
      FSweetHeartBase := cTimeOut_NoSrvSignal;
    end;

    if CheckSrv.Checked then
    begin
      nInt := GetTickCount - FServer.FLast;
      if nInt >= cTimeOut_NoSrvSignal * 1000 then
      begin
        CheckSrv.Checked := False;
        WriteLog('服务超时,校正自动退出.');
      end;
    end;

    Inc(FSweetHeartBase);
    if FSweetHeartBase >= cTimeOut_NoSrvSignal / 3 then
    begin
      FSweetHeartBase := 0;
      SweetHeartWithServer;
    end;
  except
    on nErr: Exception do
    begin
      WriteLog(nErr.Message);
    end;
  end;
end;

procedure TfFormMain.Timer2Timer(Sender: TObject);
var
  nIdx: Integer;
begin
  GetValidCOMPort(FListA);
  //enum port

  for nIdx := Low(FCOMPorts) to High(FCOMPorts) do
    with FCOMPorts[nIdx] do
      if FListA.IndexOf(FPortName) < 0 then
      begin
        WriteLog(Format('等待[ %s.%s ]端口接入系统.', [FItemName, FPortName]));
        Exit;
      end;

  if ComportAction(True) then
    Timer2.Enabled := False;
  //open ports
end;

procedure TfFormMain.AddClientInfo(const nClient: TStrings);
begin
  with nClient do
  begin
    Values[sClientIP] := gLocalIP;
    Values[sClientMAC] := gLocalMAC;
    Values[sClientName] := gLocalName;

    if CheckSrv.Checked then
      Values[sClientStatus] := sCMD_Adjust
    else
      Values[sClientStatus] := sCMD_NoAdjust;
  end;
end;

procedure TfFormMain.UDPSrv1UDPRead(AThread: TIdUDPListenerThread; AData: TIdBytes; ABinding:
  TIdSocketHandle);
var
  nList: TStrings;
begin
  try
    nList := LockStringList(False);
    try
      nList.Text := DecodeBase64(BytesToString(AData));
      if nList.Values[sSrvMAC] = '' then
        Exit; //invalid

      with FServer do
      begin
        FName := nList.Values[sSrvName];
        FIP := nList.Values[sSrvIP];
        FPort := StrToInt(nList.Values[sSrvPort]);
        FMAC := nList.Values[sSrvMAC];
        FLast := GetTickCount;
      end;

      if nList.Values[sSrvCommand] = sCMD_Broadcast then //广播
      begin
        nList.Clear;
        AddClientInfo(nList);

        UDPSrv1.Send(FServer.FIP, FServer.FPort, EncodeBase64(nList.Text));
        Exit;
      end;

      if nList.Values[sSrvCommand] = sClientStatus then //调整状态
      begin
        CheckSrv.Checked := nList.Values[sClientStatus] = sCMD_Adjust;
        nList.Clear;
        AddClientInfo(nList);

        UDPSrv1.Send(FServer.FIP, FServer.FPort, EncodeBase64(nList.Text));
        Exit;
      end;
    finally
      ReleaseStringList(nList);
    end;
  except
    on nErr: Exception do
    begin
      WriteLog(nErr.Message);
    end;
  end;
end;

//Desc: 向控制台发送心跳
procedure TfFormMain.SweetHeartWithServer;
var
  nList: TStrings;
begin
  if GetTickCount - FServer.FLast >= cSrvBroadcast_Interval * 3000 then
    Exit;
  //no server

  nList := LockStringList(True);
  try
    AddClientInfo(nList);
    nList.Values[sClientCommand] := sCMD_Respone;
    UDPSrv1.Send(FServer.FIP, FServer.FPort, EncodeBase64(nList.Text));
  finally
    ReleaseStringList(nList);
  end;
end;

//Desc: 计算桶径倍率
function TfFormMain.CalRate: Boolean;
var nVal: Single;
begin
  Result := False;
  if not IsNumber(EditNormal.Text, True) then
  begin
    WriteLog('原始桶径无效.');
    exit;
  end;

  if not IsNumber(EditNew.Text, True) then
  begin
    WriteLog('校正桶径无效.');
    exit;
  end;

  if not IsNumber(EditLi.Text, True) then
  begin
    WriteLog('轮径扭力无效.');
    exit;
  end;

  nVal := StrToFloat(EditNormal.Text);
  if nVal > 0 then
    FRate := StrToFloat(EditNew.Text) / nVal;
  //xxxxx

  FNiuLi := StrToFloat(EditLi.Text);
  Result := True;
end;

procedure TfFormMain.CheckSrvClick(Sender: TObject);
begin
  if not CalRate() then Exit;
  Group3.Enabled := not CheckSrv.Checked;
  Group4.Enabled := not CheckSrv.Checked;
end;

procedure TfFormMain.CheckShowLogClick(Sender: TObject);
begin
  gSysLoger.LogSync := CheckShowLog.Checked;
end;

//------------------------------------------------------------------------------
//Date: 2025-04-20
//Parm: 串口对象
//Desc: 检索nCOM对应数据
function TfFormMain.FindCOMItem(const nCOM: TObject): Integer;
var
  nIdx: Integer;
begin
  Result := -1;
  for nIdx := Low(FCOMPorts) to High(FCOMPorts) do
    if FCOMPorts[nIdx].FCOMObject = nCOM then
    begin
      Result := nIdx;
      Break;
    end;
end;

//Date: 2025-04-20
//Parm: 串口对象索引
//Desc: 检索nIdx的同组对象
function TfFormMain.FindSameGroup(const nIdx: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := Low(FCOMPorts) to High(FCOMPorts) do
    if (CompareText(FCOMPorts[i].FItemGroup, FCOMPorts[nIdx].FItemGroup) = 0) and (i <> nIdx)
      then
    begin
      Result := i;
      Break;
    end;
end;

//Date: 2025-04-20
//Parm: 源端口;目标端口;数据
//Desc: 将nData数据转发到nGroup端口
procedure TfFormMain.RedirectData(const nItem, nGroup: Integer; const nData: string);
var
  nStr: string;
    {$IFDEF DEBUG}  nIdx: Integer; {$ENDIF}
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

  for nIdx := 1 to Length(nData) do
    nStr := nStr + IntToHex(Ord(nData[nIdx]), 2) + ' ';
  WriteLog('数据(16): ' + nStr);
  {$ENDIF}
end;

//Date: 2025-04-20
//Parm: 对象;数据大小
//Desc: 处理串口数据
procedure TfFormMain.OnCOMData(Sender: TObject; Count: Integer);
var
  nStr: string;
  nIdx, nInt, nS, nE: Integer;
  nItem, nGroup: Integer;
begin
  if Count < 1 then
  begin
    Sleep(100);
    Exit;
  end
  else
    Sleep(1);
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
        for nIdx := 1 to nInt do
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

    if (not CheckSrv.Checked) or (FCOMPorts[nItem].FDeviceType = dtStation) or
       (not FCOMPorts[nGroup].FInWork) then
      //不校正,上位机,下位机非业务数据
    begin
      if FCOMPorts[nItem].FDeviceType = dtDevice then 
      begin
        if FCOMPorts[nItem].FData <> '' then //下位机残存数据
        begin
          RedirectData(nItem, nGroup, FCOMPorts[nItem].FData);
          FCOMPorts[nItem].FData := '';
        end;
      end;

      RedirectData(nItem, nGroup, FCOMPorts[nItem].FBuffer);
      //直接转发
    end;
       
    if FCOMPorts[nItem].FDeviceType = dtStation then //上位机
    with FCOMPorts[nItem] do
    begin
      FInWork := False; //解析出业务指令前,不校验
      FData := FData + FBuffer;

      while True do
      begin
        nS := Pos(cTagStart, FData);
        nE := Pos(cTagEnd, FData);

        if (nS = 0) and (nE = 0) then //无标识位
        begin
          if Length(FData) > cSizeCmd * 2 then //超大包,清空
            FData := '';
          Break;
        end;

        while (nE = 0) or (nE - nS > cSizeCmd) do //包异常
        begin
          nInt := PosEx(cTagStart, FData, nS + 1);
          //检查后面是否有新包
          if nInt < 1 then Break;

          System.Delete(FData, 1, nInt - 1);
          nS := 1;

          if nE > 0 then
            nE := Pos(cTagEnd, FData);
          //重新定位
        end;

        if (nE > 0) and (nE - nS + 1 = cSizeCmd) then //指令包
        begin
          nStr := Copy(FData, nS, nE - nS + 1);
          FInWork := nStr = sDataCmd;
          //判定是否为业务数据

          System.Delete(FData, 1, nE); 
          nS := 0;
          nE := 0; //reset tag
        end;

        if nS > 1 then //新包,前面数据删除
        begin
          System.Delete(FData, 1, nS - 1);
          if nE > 0 then
            nE := Pos(cTagEnd, FData);
          //删除后重新计算尾标
        end;

        if nE > 1 then
          System.Delete(FData, 1, nE);
        //删除旧包
      end;
    end;

    if (CheckSrv.Checked) and (FCOMPorts[nItem].FDeviceType = dtDevice) and
       (FCOMPorts[nGroup].FInWork) then //校正,下位机,上位机业务中
      ParseProtocol(nItem, nGroup);
    //分析协议
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2025-04-20
//Parm: 源端口;转发端口
//Desc: 分析nItem端口数据,校正符合条件的数据,然后转发到nGroup端口
procedure TfFormMain.ParseProtocol(const nItem, nGroup: Integer);
var nStr: string;
    nInt,nS,nE: Integer;
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

    if nE > cSizeData * 2 then
    begin
      while nE > 0 do
      begin
        if FData[nE] = cTagStart then
          Break;
        Dec(nE);
      end;

      if nE > 1 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE - 1));
        System.Delete(FData, 1, nE - 1);
      end;
    end; //数据包过大时,最后一个协议头位置,将前面的数据转发

    //--------------------------------------------------------------------------
    FDataLast := GetTickCount;
    FData := FData + FBuffer;
    //保存数据待分析

    while true do
    begin
      nS := Pos(cTagStart, FData);
      nE := Pos(cTagEnd, FData);

      if (nS = 0) and (nE = 0) then //无标识位
      begin
        if Length(FData) > cSizeData * 2 then //超大包,清空
        begin
          RedirectData(nItem, nGroup, FData);
          FData := '';
        end;

        Break;
      end;

      while (nE = 0) or (nE - nS > cSizeData) do //包异常
      begin
        nInt := PosEx(cTagStart, FData, nS + 1);
        //检查后面是否有新包
        if nInt < 1 then Break;

        RedirectData(nItem, nGroup, Copy(FData, 1, nInt - 1));
        System.Delete(FData, 1, nInt - 1);
        nS := 1;
        
        if nE > 0 then
          nE := Pos(cTagEnd, FData);
        //重新定位
      end;

      if (nE > 0) and (nE - nS + 1 = cSizeData) then //指令包
      begin
        if nS > 1 then
          RedirectData(nItem, nGroup, Copy(FData, 1, nS - 1));
        //协议包前数据

        nStr := AdjustValue(Copy(FData, nS, nE - nS + 1));
        RedirectData(nItem, nGroup, nStr);
        System.Delete(FData, 1, nE);

        nS := 0;
        nE := 0; //reset tag
      end;

      if nS > 1 then //新包,前面数据删除
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nS - 1));
        System.Delete(FData, 1, nS - 1);

        if nE > 0 then
          nE := Pos(cTagEnd, FData);
        //删除后重新计算尾标
      end;

      if nE > 0 then //旧尾包,全部转发
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end;
  end;
end;

//Date: 2025-04-20
//Parm: 数值
//Desc: 校正nData中的数值
function TfFormMain.AdjustValue(const nData: string): string;
var nStr: string;
    nBool:Boolean;
    nOld,nNew,nInt: Integer;
begin
  Result := nData;
  nBool := False;
  nStr := Copy(nData, 2, 6);

  if IsNumber(nStr, True) then
  begin
    nOld := Round(StrToFloat(nStr) * 100);
    nNew := Round(nOld * FRate);

    if nNew <> nOld then
    begin
      WriteLog(Format('车速: %d -> %d', [nOld, nNew]));
    end;

    nStr := Format('%.2f', [nNew / 100]);
    //校正数据,放大100倍,用于保留两位小数

    nInt := 6 - Length(nStr);
    if nInt > 0 then
      nStr := StringOfChar('0', nInt) + nStr;
    //xxxxx

    nBool := True;
    Result := '*' + nStr + Copy(Result, 8, cSizeData - 7);
  end;

  nStr := Copy(nData, 8, 5);
  if IsNumber(nStr, False) then
  begin
    nOld := StrToInt(nStr);
    nNew := Round(nOld * FNiuLi);
    
    if nNew <> nOld then
    begin
      WriteLog(Format('扭力: %d -> %d', [nOld, nNew]));
    end;

    nStr := IntToStr(nNew);
    nInt := 5 - Length(nStr);
    if nInt > 0 then
      nStr := StringOfChar('0', nInt) + nStr;
    //xxxxx

    nBool := True;
    Result := copy(Result, 1, 7) + nStr + Copy(Result, 13, cSizeData - 12);
  end;

  if nBool then //已变更,重新校验
  begin
    nNew := 0;
    for nInt:=1 to cSizeData - 2 do
     nNew := nNew + Ord(Result[nInt]);
    //累加

    Result[cSizeData - 1] := Char(nNew and $FF);
  end;
end;

end.

