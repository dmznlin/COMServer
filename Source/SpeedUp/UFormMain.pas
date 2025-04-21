{*******************************************************************************
  ����: dmzn@163.com 2025-04-20
  ����: ������ת������������
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
    FItemName: string;            //�ڵ���
    FItemGroup: string;           //�ڵ����
    FPortName: string;            //�˿�����
    FBaudRate: TBaudRate;         //������
    FDataBits: TDataBits;         //����λ
    FStopBits: TStopBits;         //��ͣλ

    FCOMObject: TComPort;         //���ڶ���
    FDeviceType: TDeviceType;     //�豸����
    FMemo: string;                //������Ϣ
    FBuffer: string;              //���ݻ���
    FData: string;                //Э������
    FDataLast: Int64;             //����ʱ��
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
    //ȫ���ȼ�
    FConfigChanged: Boolean;
    //���ñ䶯
    FLineNo: string;
    FRemoteHost: string;
    FRemotePort: Integer;
    //Զ�̷���
    FServer: THostItem;
    FSweetHeartBase: Integer;
    //����̨���
    FRate: Single;
    //Ͱ������
    FListA: TStrings;
    //�ַ��б�
    FCOMPorts: array of TCOMItem;
    //���ڶ���
    procedure SystemConfig(const nLoad: Boolean);
    procedure ShowLog(const nStr: string);
    //��ʾ��־
    procedure AddClientInfo(const nClient: TStrings);
    procedure SweetHeartWithServer;
    //����̨ͨѶ
    procedure LoadCOMConfig;
    function ComportAction(const nOpen: Boolean): Boolean;
    procedure OnCOMData(Sender: TObject; Count: Integer);
    //���ڿ���
    function FindCOMItem(const nCOM: TObject): Integer; overload;
    function FindSameGroup(const nIdx: Integer): Integer; overload;
    //��������
    procedure CalRate();
    function AdjustValue(const nVal: Integer): Integer;
    procedure RedirectData(const nItem, nGroup: Integer; const nData: string);
    procedure ParseProtocol(const nItem, nGroup: Integer);
    //���ݴ���
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  IniFiles, Registry, ULibFun, UMgrCOMM, UBase64, UFormInputbox, UsysMAC, USysLoger;

const
  sDataDemo = '*000.00018830000.0000.0000027.490000000' + '0000000.00000.00000.00000.000.0';
  cDataSize = Length(sDataDemo);
  cSplitChar = '*';

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '���ٷ���', nEvent);
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
  //��ȡ��������
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
//Parm: ��д
//Desc: ����������Ϣ
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

//Desc: ��ȡ����
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

        FDeviceType := TDeviceType(ReadInteger(nList[nIdx], 'DeviceType', 0));
      //�豸����

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
  if HotKey = FHotKeyHide then //��ʾ����
  begin
    ShowInputPWDBox('����������:', '����Ա', nStr);
    if nStr = EditPwd.Text then
      Visible := not Visible;
    //xxxxx
  end
  else
if HotKey = FHotKeyRun then //�Ƿ�У��
  begin
    CheckSrv.Checked := not CheckSrv.Checked;
  end;
end;

//------------------------------------------------------------------------------
//Desc: ��ʾ��־
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
end;

//Desc: �򿪹رմ���
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
  SBar1.Panels[0].Text := '��.' + DateTime2Str(Now()) + ' ' + Date2Week();
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
        WriteLog('����ʱ,У���Զ��˳�.');
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
        WriteLog(Format('�ȴ�[ %s.%s ]�˿ڽ���ϵͳ.', [FItemName, FPortName]));
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

      if nList.Values[sSrvCommand] = sCMD_Broadcast then //�㲥
      begin
        nList.Clear;
        AddClientInfo(nList);

        UDPSrv1.Send(FServer.FIP, FServer.FPort, EncodeBase64(nList.Text));
        Exit;
      end;

      if nList.Values[sSrvCommand] = sClientStatus then //����״̬
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

//Desc: �����̨��������
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

//Desc: ����Ͱ������
procedure TfFormMain.CalRate;
var nVal: Single;
begin
  if not IsNumber(EditNormal.Text, True) then
  begin
    WriteLog('ԭʼͰ����Ч.');
    exit;
  end;

  if not IsNumber(EditNew.Text, True) then
  begin
    WriteLog('У��Ͱ����Ч.');
    exit;
  end;

  nVal := StrToFloat(EditNormal.Text);
  if nVal > 0 then
    FRate := StrToFloat(EditNew.Text) / nVal;
  //xxxxx
end;

procedure TfFormMain.CheckSrvClick(Sender: TObject);
begin
  CalRate();
  Group3.Enabled := not CheckSrv.Checked;
  Group4.Enabled := not CheckSrv.Checked;
end;

procedure TfFormMain.CheckShowLogClick(Sender: TObject);
begin
  gSysLoger.LogSync := CheckShowLog.Checked;
end;

//------------------------------------------------------------------------------
//Date: 2025-04-20
//Parm: ���ڶ���
//Desc: ����nCOM��Ӧ����
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
//Parm: ���ڶ�������
//Desc: ����nIdx��ͬ�����
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
//Parm: Դ�˿�;Ŀ��˿�;����
//Desc: ��nData����ת����nGroup�˿�
procedure TfFormMain.RedirectData(const nItem, nGroup: Integer; const nData: string);
var
  nStr: string;
    {$IFDEF DEBUG}  nIdx: Integer; {$ENDIF}
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

  for nIdx := 1 to Length(nData) do
    nStr := nStr + IntToHex(Ord(nData[nIdx]), 2) + ' ';
  WriteLog('����(16): ' + nStr);
  {$ENDIF}
end;

//Date: 2025-04-20
//Parm: ����;���ݴ�С
//Desc: ����������
procedure TfFormMain.OnCOMData(Sender: TObject; Count: Integer);
var
  nStr: string;
  nIdx, nInt: Integer;
  nItem, nGroup: Integer;
begin
  if Count < 1 then
  begin
    Sleep(100);
    Exit;
  end
  else
    Sleep(1);
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
        for nIdx := 1 to nInt do
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

    if (not CheckSrv.Checked) or (FCOMPorts[nItem].FDeviceType = dtStation) then
      //��У��,��λ��,δ����
    begin
      nStr := FCOMPorts[nItem].FBuffer;
      if FCOMPorts[nItem].FData <> '' then
      begin
        nStr := FCOMPorts[nItem].FData + nStr;
        FCOMPorts[nItem].FData := '';
      end;

      RedirectData(nItem, nGroup, nStr); //ֱ��ת��
      Exit;
    end;

    ParseProtocol(nItem, nGroup);
    //����Э��
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2025-04-20
//Parm: Դ�˿�;ת���˿�
//Desc: ����nItem�˿�����,У����������������,Ȼ��ת����nGroup�˿�
procedure TfFormMain.ParseProtocol(const nItem, nGroup: Integer);
var
  nStr: string;
  nIdx, nS, nE, nLen, nInt: Integer;
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

    if nE > cDataSize * 2 then
    begin
      while nE > 0 do
      begin
        if FData[nE] = cSplitChar then
          Break;
        Dec(nE);
      end;

      if nE > 0 then
      begin
        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
      end;
    end; //���ݰ�����ʱ,���һ��Э��ͷλ��,��ǰ�������ת��

    //--------------------------------------------------------------------------
    FDataLast := GetTickCount;
    FData := FData + FBuffer;
    //�������ݴ�����

    nLen := Length(FData);
    while nLen > 0 do
    begin
      nS := 0;
      nE := 0;

      for nIdx := 1 to nLen do
      begin
        if FData[nIdx] = cSplitChar then
        begin
          if nS = 0 then
               nS := nIdx
          else nE := nIdx;
        end;

        if (nS > 0) and (nE = 0) and (nIdx - nS + 1 = cDataSize) then
          nE := nIdx + 1;
        //end

        if nE = 0 then Continue;
        //invalid

        if nE - nS = cDataSize then
        begin
          nStr := Copy(FData, nS + 1, 6);
          if IsNumber(nStr, True) then
          begin
            nStr := Format('%.2f', [AdjustValue(Round(StrToFloat(nStr) * 100)) / 100]);
            //У������,�Ŵ�100��,���ڱ�����λС��

            nInt := 6 - Length(nStr);
            if nInt > 0 then
              nStr := StringOfChar('0', nInt) + nStr;
            //��ȫλ��

            RedirectData(nItem, nGroup, '*' + nStr + Copy(FData, nS + 7, nE - 7));
            System.Delete(FData, 1, nE);
            Break;
          end;
        end;

        RedirectData(nItem, nGroup, Copy(FData, 1, nE));
        System.Delete(FData, 1, nE);
        Break;
      end;

      if nE > 0 then
           nLen := Length(FData)
      else Break;
    end;
  end;
end;

//Date: 2025-04-20
//Parm: ��ֵ
//Desc: У��nVal��ֵ
function TfFormMain.AdjustValue(const nVal: Integer): Integer;
begin
  Result := Round(nVal * FRate);
  if Result <> nVal then
  begin
    WriteLog(Format('����: %d -> %d', [nVal, Result]));
  end;
end;

end.

