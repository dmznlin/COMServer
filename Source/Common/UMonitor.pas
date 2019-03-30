{*******************************************************************************
  ����: dmzn@163.com 2018-01-12
  ����: ��λ���ϵͳ��ض���

  ��ע:
  *.����Ԫ���ڸ��ٹ�λϵͳ�Ĺ���״̬
*******************************************************************************}
unit UMonitor;

interface

uses
  Windows, Classes, SysUtils, Messages, SyncObjs, TLHelp32, UWaitItem, ULibFun,
  USysLoger, IdTCPConnection, IdTCPClient, IdGlobal, UBase64, UCommonConst;

type
  TStatusFlag = record
    FKeyWord: string;             //�ؼ���
    FStatus: TMonStatusItem;      //����״̬
  end;
  TStatusFlags = array of TStatusFlag;

  TMonManager = class;
  TMonThread = class(TThread)
  private
    FOwner: TMonManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FStatus,FTmpStatus: TMonStatus;
    //ϵͳ״̬
    FProcessID,FWindowID,FControlID: THandle;
    //���̱�ʶ
  protected
    procedure DoExecute;
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TMonManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //����ֹͣ
  end;

  TMonSyncItem = record
    FData: string;                //��������
    FUsed: Boolean;               //�Ƿ�ʹ����
  end;
  TMonSyncItems = array of TMonSyncItem;

  TMonRemoteSync = class(TThread)
  private
    FOwner: TMonManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FBuffer: TMonSyncItems;
    //���ͻ���
    FClient: TIdTCPClient;
    //�׽���
  protected
    function DoExecute: Boolean;
    procedure Execute; override;
    //ִ���߳�
    function FindItem(const nUsed: Boolean; nInc: Boolean = False): Integer;
    //������
    procedure CloseSocket(const nClient: TIdTCPClient);
    //�ر��׽���
  public
    constructor Create(AOwner: TMonManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //����ֹͣ
    procedure SyncData(const nData: string);
    //ͬ������
  end;

  TMonManager = class(TObject)
  private
    FMonitor: TMonThread;
    //����߳�
    FRemoteSync: TMonRemoteSync;
    //Զ��ͬ��
    FSyncLock: TCriticalSection;
    //ͬ������
    FLineNo: string;
    //����ߺ�
    FRemoteIP: string;
    FRemotePort: Integer;
    //Զ�̷���
    FKeyWords: TStrings;
    FExeName,FFormName,FCtrlName,FKeyWord: string;
    //ϵͳ��Ϣ
    FListA: TStrings;
    //�ַ��б�
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure StartMon(const nExe,nCtrl,nKey,nHost,nPort,nLine: string);
    procedure StopMon;
    //����ֹͣ
    function Status: TMonStatus;
    //ϵͳ״��
  end;

var
  gStatusFlags: TStatusFlags;
  gMonManager: TMonManager = nil;
  //ȫ��ʹ��

implementation

const
  cInterval_Long    = 5 * 1000;   //���ȴ�
  cInterval_Short   = 500;        //�̵ȴ�

var
  gWindowName: string;
  gWindowHandle: THandle;
  gControlName: string;
  gControlHandle: THandle;
  gControlKeyword: TStrings;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMonManager, '��λϵͳ���', nEvent);
end;

//------------------------------------------------------------------------------
constructor TMonManager.Create;
begin
  FMonitor := nil;
  FRemoteSync := nil;
  
  FListA := TStringList.Create;
  FKeyWords := TStringList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TMonManager.Destroy;
begin
  StopMon;
  FSyncLock.Free;
  FKeyWords.Free;

  FListA.Free;
  inherited;
end;

procedure TMonManager.StartMon(const nExe,nCtrl,nKey,nHost,nPort,nLine: string);
var nIdx: Integer;
begin
  nIdx := Pos('.', nCtrl);
  if nIdx < 2 then
    raise Exception.Create('invalid form name(ex: form.ctrl).');
  //xxxxx

  FExeName := nExe;
  FFormName := Trim(Copy(nCtrl, 1, nIdx-1));
  FCtrlName := Trim(Copy(nCtrl, nIdx+1, MaxInt));

  FKeyWord := nKey;
  SplitStr(nKey, FKeyWords, 0, ',');
  //key word list

  FLineNo := nLine;
  FRemoteIP := nHost;
  FRemotePort := StrToInt(nPort);

  for nIdx:=FKeyWords.Count-1 downto 0 do
    FKeyWords[nIdx] := UpperCase(FKeyWords[nIdx]);
  gControlKeyword := FKeyWords;

  if not Assigned(FRemoteSync) then
    FRemoteSync := TMonRemoteSync.Create(Self);
  FRemoteSync.Wakeup;

  if not Assigned(FMonitor) then
    FMonitor := TMonThread.Create(Self);
  FMonitor.Wakeup;
end;

procedure TMonManager.StopMon;
begin
  if Assigned(FMonitor) then
    FMonitor.StopMe;
  FMonitor := nil;

  if Assigned(FRemoteSync) then
    FRemoteSync.StopMe;
  FRemoteSync := nil;
end;

function TMonManager.Status: TMonStatus;
begin
  FSyncLock.Enter;
  try
    Result := [msNoRun];
    if Assigned(FMonitor) then
      Result := FMonitor.FStatus;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;   
end;

//------------------------------------------------------------------------------
constructor TMonThread.Create(AOwner: TMonManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FStatus := [msNoRun];
  FTmpStatus := [msNoRun];

  FProcessID := 0;
  FWindowID := 0;
  FControlID := 0;
  
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := cInterval_Short;
end;

destructor TMonThread.Destroy;
begin
  FWaiter.Free;
  inherited;
end;

procedure TMonThread.Wakeup;
begin
  FWaiter.Wakeup();
end;

procedure TMonThread.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TMonThread.Execute;
var nHasStart: Boolean;
begin
  nHasStart := False;
  //init

  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    FTmpStatus := [];
    DoExecute;

    FOwner.FSyncLock.Enter;
    if FTmpStatus = [] then
         FStatus := [msNoRun]
    else FStatus := FTmpStatus; //update
    FOwner.FSyncLock.Leave;

    if (FWindowID = 0) or (FProcessID = 0) then
         FWaiter.Interval := cInterval_Long
    else FWaiter.Interval := cInterval_Short;

    if FTmpStatus <> [] then
    begin
      if nHasStart and ((
         msVEnd in FTmpStatus) or (msDEnd in FTmpStatus)) then
        nHasStart := False;
      //vmas or sds end

      if (not nHasStart) and (
         (msVStart in FTmpStatus) or (msDStart in FTmpStatus)) then
        nHasStart := True;
      //ҵ��ʼ
    end;

    if nHasStart and ((FWindowID = 0) or (FProcessID = 0) or
       (msReset in FTmpStatus)) then //���ڹر�
    with FOwner do
    begin
      nHasStart := False;
      FListA.Values['Status'] := IntToStr(Ord(msReset));
      FListA.Values['LineNo'] := FLineNo;
      FRemoteSync.SyncData(EncodeBase64(FListA.Text));
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2018-01-12
//Parm: ��������
//Desc: ��ȡnExeName�Ľ��̱�ʶ
function GetFixProcessID(const nExeName: string): THandle;
var nStr: string;
    nSnapshotHandle: THandle;
    nProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  nSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    nProcessEntry32.dwSize := Sizeof(nProcessEntry32);
    if Process32First(nSnapshotHandle, nProcessEntry32) then
    repeat
      nStr := ExtractFileName(nProcessEntry32.szExeFile);
      //file name
      
      if CompareText(nStr, nExeName) = 0 then
      begin
        Result := nProcessEntry32.th32ProcessID;
        Break;
      end;
    until not Process32Next(nSnapshotHandle, nProcessEntry32);
  finally
    CloseHandle(nSnapshotHandle);
  end;
end;

//Desc: ��������ص�
function EnumThreadWndProc(AHWnd: HWnd; ALPARAM: LPARAM): Boolean; stdcall;
var nWndClassName: array[0..254] of Char;
begin
  GetClassName(AHWnd, @nWndClassName, 254);
  if nWndClassName = gWindowName then
    gWindowHandle := AHWnd; //win-handle
  Result := True;
end;

//Date: 2018-01-12
//Parm: ���̾��;��������
//Desc: ��ȡnProcess��ָ�������ʶ
function GetFixWindowID(const nProcess: THandle; const nForm: string): THandle;
var nSnapshotHandle: THandle;
    nThreadEntry: TThreadEntry32;
begin
  Result := 0;
  nSnapshotHandle := CreateToolHelp32Snapshot(TH32CS_SNAPTHREAD, nProcess);
  try
    nThreadEntry.dwSize := sizeOf(nThreadEntry);
    if Thread32First(nSnapshotHandle, nThreadEntry) then
    repeat
      if nThreadEntry.th32OwnerProcessID = nProcess then
      begin
        gWindowHandle := 0;
        gWindowName := nForm;
        
        EnumThreadWindows(nThreadEntry.th32ThreadID, @EnumThreadWndProc, 0);
        Result := gWindowHandle;
        Break;
      end;
    until not Thread32Next(nSnapshotHandle, nThreadEntry);
  finally
    CloseHandle(nSnapshotHandle);
  end;
end;

//Date: 2018-01-12
//Parm: �ؼ����
//Desc: ��ȡ�ؼ����ı�����
function GetControlText(const nHwnd: HWnd): string;
var nBuf: array[0..254] of Char;
begin
  if SendMessage(nHwnd, WM_GETTEXT, 255, Integer(@nBuf[0])) > 0 then
       Result := StrPas(@nBuf[0])
  else Result := '';
end;

//Desc: �����ؼ��ص�
function EnumChildWndProc(AHWnd: HWnd; ALPARAM: LPARAM): Boolean; stdcall;
var nIdx: Integer;
    nWndClassName: array[0..254] of Char;
begin
  GetClassName(AHWnd, @nWndClassName, 254);
  if nWndClassName = gControlName then
   for nIdx:=gControlKeyword.Count-1 downto 0 do
    if Pos(gControlKeyword[nIdx], UpperCase(GetControlText(AHWnd))) > 0 then
      gControlHandle := AHWnd; //get control
  Result := True;
end;

//Date: 2018-01-12
//Parm: ������;�ؼ���;�ؼ���
//Desc: ��ȡnWindow�ϵ�ָ���ؼ�
function GetFixControlID(const nWindow: THandle; const nName: string): THandle;
begin
  gControlHandle := 0;
  gControlName := nName;

  EnumChildWindows(nWindow, @EnumChildWndProc, 0);
  Result := gControlHandle;
end;

procedure TMonThread.DoExecute;
var nStr: string;
    nIdx,nPos: Integer;
    nHwnd: THandle;
begin
  if (FProcessID = 0) or (FWindowID = 0) then
  begin
    FProcessID := 0;
    nHwnd := GetFixProcessID(FOwner.FExeName);

    if nHwnd = 0 then
    begin
      WriteLog(Format('����[ %s ]δ����.', [FOwner.FExeName]));
      Exit;
    end;

    FProcessID := nHwnd;
    //���̾��
  end;

  if (FWindowID = 0) or (FControlID = 0) then
  begin
    FWindowID := 0;
    nHwnd := GetFixWindowID(FProcessID, FOwner.FFormName);
    
    if nHwnd = 0 then
    begin
      WriteLog(Format('����[ %s ]δ����.', [FOwner.FFormName]));
      Exit;
    end;

    FWindowID := nHwnd;
    //���̾��
  end;

  if FControlID = 0 then
  begin
    nHwnd := GetFixControlID(FWindowID, FOwner.FCtrlName);
    if nHwnd = 0 then
    begin
      WriteLog(Format('�ؼ�[ %s ]�޷���λ.', [FOwner.FCtrlName]));
      Exit;
    end;

    FControlID := gControlHandle;
    //�ؼ����
  end;

  nStr := GetControlText(FControlID);
  if nStr = '' then
  begin
    FControlID := GetFixControlID(FWindowID, FOwner.FCtrlName);
    if FControlID = 0 then
      FWindowID := GetFixWindowID(FProcessID, FOwner.FFormName);
    //xxxxx

    if FWindowID = 0 then
      FProcessID := GetFixProcessID(FOwner.FExeName);
    //xxxxx

    if FProcessID = 0 then
         WriteLog(Format('����[ %s ]�ѹر�.', [FOwner.FExeName]))
    else WriteLog(Format('����[ %s ]�ѹر�.', [FOwner.FFormName]));

    Exit;
  end;

  if Pos('2500', nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [ms2K5];
    if not (ms2K5 in FStatus) then
      WriteLog('��ʼ2500rpm���.');
    //xxxxx
  end else

  if Pos('3500', nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [ms3K5];
    if not (ms3K5 in FStatus) then
      WriteLog('��ʼ3500rpm���.');
    //xxxxx
  end;

  for nIdx:=Low(gStatusFlags) to High(gStatusFlags) do
  if Pos(gStatusFlags[nIdx].FKeyWord, nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [gStatusFlags[nIdx].FStatus];
    if FTmpStatus <> FStatus then
      WriteLog('��λ���: ' + nStr);
    //xxxxx

    if gStatusFlags[nIdx].FStatus in [msReset] then Continue;
    //���账��״̬

    if (FTmpStatus <> FStatus) or
       (gStatusFlags[nIdx].FStatus in [msDRun_2K5, msDRun_DS]) then
    begin
      if gStatusFlags[nIdx].FStatus = msDRun_2K5 then //˫����2k5ȡ��
      begin
        nPos := Pos('rpm', nStr); //�뱣��2500��100 rpm 29
        System.Delete(nStr, 1, nPos + 3);

        if IsNumber(nStr, False) then
             nStr := IntToStr(30 - StrToInt(nStr))
        else nStr := '1';
      end else

      if gStatusFlags[nIdx].FStatus = msDRun_DS then //˫���ٵ���ȡ��
      begin
        nPos := Pos('����', nStr); //���ֵ��� ���ڲ��� 29
        System.Delete(nStr, 1, nPos + 4);

        if IsNumber(nStr, False) then
             nStr := IntToStr(60 - StrToInt(nStr))
        else nStr := '30';
      end else nStr := '';

      with FOwner do
      begin
        FListA.Values['LineNo'] := FLineNo;
        FListA.Values['Status'] := IntToStr(Ord(gStatusFlags[nIdx].FStatus));
        FListA.Values['DTime']  := nStr;
        FRemoteSync.SyncData(EncodeBase64(FListA.Text));
      end;

      WriteLog('״̬�л�: ' + MonStatusToStr(gStatusFlags[nIdx].FStatus));
      //log
    end;
  end;
end;

//------------------------------------------------------------------------------
constructor TMonRemoteSync.Create(AOwner: TMonManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := cInterval_Short;

  FClient := TIdTCPClient.Create;
  with FClient do
  begin
    ReadTimeout := 3 * 1000;
    ConnectTimeout := 3 * 1000;
  end;
end;

destructor TMonRemoteSync.Destroy;
begin
  CloseSocket(FClient);
  FreeAndNil(FClient);

  FWaiter.Free;
  inherited;
end;

procedure TMonRemoteSync.Wakeup;
begin
  FWaiter.Wakeup();
end;

procedure TMonRemoteSync.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TMonRemoteSync.CloseSocket(const nClient: TIdTCPClient);
begin
  if Assigned(nClient) then
  begin
    nClient.Disconnect;
    if Assigned(nClient.IOHandler) then
      nClient.IOHandler.InputBuffer.Clear;
    //xxxxx
  end;
end;

//Date: 2018-04-06
//Parm: ʹ��״̬;�Ƿ�����
//Desc: ����״̬ΪnUsed����
function TMonRemoteSync.FindItem(const nUsed: Boolean; nInc: Boolean): Integer;
var nIdx: Integer;
begin
  Result := -1;
  for nIdx:=Low(FBuffer) to High(FBuffer) do
   if FBuffer[nIdx].FUsed = nUsed then
    Result := nIdx;
  //xxxxx

  if (Result < 0) and nInc then
  begin
    nIdx := Length(FBuffer);
    Result := nIdx;
    
    SetLength(FBuffer, nIdx+1);
    FBuffer[nIdx].FUsed := False;
  end;
end;

procedure TMonRemoteSync.Execute;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    while DoExecute do ;
    //loop to send
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      Sleep(500);
    end;
  end;
end;

function TMonRemoteSync.DoExecute: Boolean;
var nIdx: Integer;
    nItem: TMonSyncItem;
begin
  FOwner.FSyncLock.Enter;
  try
    Result := False;
    nIdx := FindItem(True);
    if nIdx < 0 then Exit;

    nItem := FBuffer[nIdx];
    FBuffer[nIdx].FUsed := False;
  finally
    FOwner.FSyncLock.Leave;
  end;

  try
    if not FClient.Connected then
    begin
      FClient.Host := FOwner.FRemoteIP;
      FClient.Port := FOwner.FRemotePort;
      FClient.Connect;
    end;

    FClient.IOHandler.WriteLn(nItem.FData);
    //send data
    Result := True;
  except
    on E:Exception do
    begin
      WriteLog(Format('Client:[ %s:%d ] Msg: %s', [FOwner.FRemoteIP,
        FOwner.FRemotePort, E.Message]));
      //xxxxx

      CloseSocket(FClient);
      //focus reconnect
    end;
  end;
end;

//Date: 2018-04-06
//Parm: ����������
//Desc: ��nData������Զ��
procedure TMonRemoteSync.SyncData(const nData: string);
var nIdx: Integer;
begin
  FOwner.FSyncLock.Enter;
  try
    nIdx := FindItem(False, True);
    with FBuffer[nIdx] do
    begin
      FData := nData;
      FUsed := True;
    end;
  finally
    FOwner.FSyncLock.Leave;
  end;

  Wakeup;
  //send at once
end;

initialization
  gMonManager := TMonManager.Create;
finalization
  FreeAndNil(gMonManager);
end.
