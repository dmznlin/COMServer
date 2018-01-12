{*******************************************************************************
  作者: dmzn@163.com 2018-01-11
  描述: 发动机转速监控主界面
*******************************************************************************}
unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  USysConst, IdGlobal, IdSocketHandle, IdBaseComponent, IdComponent,
  IdUDPBase, IdUDPServer, UHotKeyManager, ExtCtrls, StdCtrls, ComCtrls;

type
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
    EditMaxRange2: TLabeledEdit;
    EditRange2: TLabeledEdit;
    EditPwd: TLabeledEdit;
    EditPort: TLabeledEdit;
    Label1: TLabel;
    EditRange3: TLabeledEdit;
    Label2: TLabel;
    EditMaxRange3: TLabeledEdit;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure HotKey1HotKeyPressed(HotKey: Cardinal; Index: Word);
    procedure EditHotKey1Change(Sender: TObject);
    procedure UDPSrv1UDPRead(AThread: TIdUDPListenerThread;
      AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure CheckSrvClick(Sender: TObject);
  private
    { Private declarations }
    FHotKeyHide: Cardinal;
    FHotKeyRun: Cardinal;
    //全局热键
    FConfigChanged: Boolean;
    //配置变动
    FRangeLow,FRangeHigh: Integer;
    FMaxRangeLow,FMaxRangeHigh: Integer;
    //数据范围
    FServer: THostItem;
    FSweetHeartBase: Integer;
    //控制台相关
    procedure SystemConfig(const nLoad: Boolean);
    procedure ShowLog(const nStr: string);
    //显示日志
    procedure AddClientInfo(const nClient: TStrings);
    procedure SweetHeartWithServer;
    //控制台通讯
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}
uses
  IniFiles, Registry, ULibFun, UBase64, UFormInputbox, USysLoger, UsysMAC;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '转速监控服务', nEvent);
end;

//------------------------------------------------------------------------------
procedure TfFormMain.FormCreate(Sender: TObject);
begin
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sForm, gPath+sDB);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogEvent := ShowLog;
  gSysLoger.LogSync := True;

  FillChar(FServer, SizeOf(FServer), #0);
  gLocalMAC := MakeActionID_MAC;
  GetLocalIPConfig(gLocalName, gLocalIP);

  wPage1.ActivePageIndex := 0;
  SystemConfig(True);
  Application.ShowMainForm := not CheckMin.Checked;

  FHotKeyHide := TextToHotKey(EditHotKey1.Text, False);
  HotKey1.AddHotKey(FHotKeyHide);
  FHotKeyRun := TextToHotKey(EditHotKey2.Text, False);
  HotKey1.AddHotKey(FHotKeyRun);
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FConfigChanged then
    SystemConfig(False);
  //save config
end;

//Date: 2018-01-11
//Parm: 读写
//Desc: 处理配置信息
procedure TfFormMain.SystemConfig(const nLoad: Boolean);
var nStr: string;
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
      if nStr <> '' then EditPwd.Text := DecodeBase64(nStr);

      nInt := ReadInteger('Config', 'Port', cSrvBroadcast_Port);
      EditPort.Text := IntToStr(nInt);
      CheckMin.Checked := ReadBool('Config', 'MinAfterRun', False);

      nStr := ReadString('Config', 'HotKeyHide', '');
      if nStr <> '' then EditHotKey1.Text := nStr;

      nStr := ReadString('Config', 'HostKeyRun', '');
      if nStr <> '' then EditHotKey2.Text := nStr;

      nStr := ReadString('Config', 'ExeName', '');
      if nStr <> '' then EditExe.Text := nStr;

      nStr := ReadString('Config', 'WinName', '');
      if nStr <> '' then EditWin.Text := nStr;

      nStr := ReadString('Config', 'MainText', '');
      if nStr <> '' then EditContent.Text := nStr;

      EditRange2.Text := ReadString('Config', 'DataRange2', '2400-2600');
      EditMaxRange2.Text := ReadString('Config', 'DataMaxRange2', '2200-2800');
      EditRange3.Text := ReadString('Config', 'DataRange3', '3400-3600');
      EditMaxRange3.Text := ReadString('Config', 'DataMaxRange3', '3200-3800');

      nReg := TRegistry.Create;
      nReg.RootKey := HKEY_CURRENT_USER;

      nReg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True);
      CheckRun.Checked := nReg.ValueExists(sAutoStartKey);
    end else
    begin
      nIni.WriteString('Config', 'Password', EncodeBase64(EditPwd.Text));
      nIni.WriteString('Config', 'Port', EditPort.Text);
      nIni.WriteBool('Config', 'MinAfterRun', CheckMin.Checked);

      nIni.WriteString('Config', 'HotKeyHide', EditHotKey1.Text);
      nIni.WriteString('Config', 'HostKeyRun', EditHotKey2.Text);
      nIni.WriteString('Config', 'ExeName', EditExe.Text);
      nIni.WriteString('Config', 'WinName', EditWin.Text);
      nIni.WriteString('Config', 'MainText', EditContent.Text);

      nIni.WriteString('Config', 'DataRange2', EditRange2.Text);
      nIni.WriteString('Config', 'DataMaxRange2', EditMaxRange2.Text);
      nIni.WriteString('Config', 'DataRange3', EditRange3.Text);
      nIni.WriteString('Config', 'DataMaxRange3', EditMaxRange3.Text);

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

procedure TfFormMain.EditHotKey1Change(Sender: TObject);
begin
  FConfigChanged := True;
end;

procedure TfFormMain.HotKey1HotKeyPressed(HotKey: Cardinal; Index: Word);
var nStr: string;
begin
  if HotKey = FHotKeyHide then //显示隐藏
  begin
    ShowInputPWDBox('请输入密码:', '管理员', nStr);
    if nStr = EditPwd.Text then
      Visible := not Visible;
    //xxxxx
  end else

  if HotKey = FHotKeyRun then //是否校正
  begin
    CheckSrv.Checked := not CheckSrv.Checked;
  end;
end;

//------------------------------------------------------------------------------
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

procedure TfFormMain.Timer1Timer(Sender: TObject);
var nInt: Int64;
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
    on nErr:Exception do
    begin
      WriteLog(nErr.Message);
    end;
  end;
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
    else Values[sClientStatus] := sCMD_NoAdjust;
  end;
end;

procedure TfFormMain.UDPSrv1UDPRead(AThread: TIdUDPListenerThread;
  AData: TIdBytes; ABinding: TIdSocketHandle);
var nList: TStrings;
begin
  try
    nList := LockStringList(False);
    try
      nList.Text := DecodeBase64(BytesToString(AData));
      if nList.Values[sSrvMAC] = '' then Exit; //invalid

      with FServer do
      begin
        FName := nList.Values[sSrvName];
        FIP   := nList.Values[sSrvIP];
        FPort := StrToInt(nList.Values[sSrvPort]);
        FMAC  := nList.Values[sSrvMAC];
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
    on nErr:Exception do
    begin
      WriteLog(nErr.Message);
    end;
  end;
end;

//Desc: 向控制台发送心跳
procedure TfFormMain.SweetHeartWithServer;
var nList: TStrings;
begin
  if GetTickCount-FServer.FLast >= cSrvBroadcast_Interval * 3000 then Exit;
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

procedure TfFormMain.CheckSrvClick(Sender: TObject);
begin
  Group3.Enabled := not CheckSrv.Checked;
  Group4.Enabled := not CheckSrv.Checked;
end;

end.
