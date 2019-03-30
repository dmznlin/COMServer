{*******************************************************************************
  作者: dmzn@163.com 2018-01-12
  描述: 工位检测系统监控对象

  备注:
  *.本单元用于跟踪工位系统的工作状态
*******************************************************************************}
unit UMonitor;

interface

uses
  Windows, Classes, SysUtils, Messages, SyncObjs, TLHelp32, UWaitItem, ULibFun,
  USysLoger, IdTCPConnection, IdTCPClient, IdGlobal, UBase64, UCommonConst;

type
  TStatusFlag = record
    FKeyWord: string;             //关键字
    FStatus: TMonStatusItem;      //运行状态
  end;
  TStatusFlags = array of TStatusFlag;

  TMonManager = class;
  TMonThread = class(TThread)
  private
    FOwner: TMonManager;
    //拥有者
    FWaiter: TWaitObject;
    //等待对象
    FStatus,FTmpStatus: TMonStatus;
    //系统状态
    FProcessID,FWindowID,FControlID: THandle;
    //进程标识
  protected
    procedure DoExecute;
    procedure Execute; override;
    //执行线程
  public
    constructor Create(AOwner: TMonManager);
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //唤醒停止
  end;

  TMonSyncItem = record
    FData: string;                //待发数据
    FUsed: Boolean;               //是否使用中
  end;
  TMonSyncItems = array of TMonSyncItem;

  TMonRemoteSync = class(TThread)
  private
    FOwner: TMonManager;
    //拥有者
    FWaiter: TWaitObject;
    //等待对象
    FBuffer: TMonSyncItems;
    //发送缓冲
    FClient: TIdTCPClient;
    //套接字
  protected
    function DoExecute: Boolean;
    procedure Execute; override;
    //执行线程
    function FindItem(const nUsed: Boolean; nInc: Boolean = False): Integer;
    //检索项
    procedure CloseSocket(const nClient: TIdTCPClient);
    //关闭套接字
  public
    constructor Create(AOwner: TMonManager);
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //唤醒停止
    procedure SyncData(const nData: string);
    //同步数据
  end;

  TMonManager = class(TObject)
  private
    FMonitor: TMonThread;
    //监控线程
    FRemoteSync: TMonRemoteSync;
    //远程同步
    FSyncLock: TCriticalSection;
    //同步锁定
    FLineNo: string;
    //检测线号
    FRemoteIP: string;
    FRemotePort: Integer;
    //远程服务
    FKeyWords: TStrings;
    FExeName,FFormName,FCtrlName,FKeyWord: string;
    //系统信息
    FListA: TStrings;
    //字符列表
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure StartMon(const nExe,nCtrl,nKey,nHost,nPort,nLine: string);
    procedure StopMon;
    //启动停止
    function Status: TMonStatus;
    //系统状体
  end;

var
  gStatusFlags: TStatusFlags;
  gMonManager: TMonManager = nil;
  //全局使用

implementation

const
  cInterval_Long    = 5 * 1000;   //长等待
  cInterval_Short   = 500;        //短等待

var
  gWindowName: string;
  gWindowHandle: THandle;
  gControlName: string;
  gControlHandle: THandle;
  gControlKeyword: TStrings;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMonManager, '工位系统监控', nEvent);
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
      //业务开始
    end;

    if nHasStart and ((FWindowID = 0) or (FProcessID = 0) or
       (msReset in FTmpStatus)) then //窗口关闭
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
//Parm: 程序名称
//Desc: 获取nExeName的进程标识
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

//Desc: 检索窗体回调
function EnumThreadWndProc(AHWnd: HWnd; ALPARAM: LPARAM): Boolean; stdcall;
var nWndClassName: array[0..254] of Char;
begin
  GetClassName(AHWnd, @nWndClassName, 254);
  if nWndClassName = gWindowName then
    gWindowHandle := AHWnd; //win-handle
  Result := True;
end;

//Date: 2018-01-12
//Parm: 进程句柄;窗体类名
//Desc: 获取nProcess的指定窗体标识
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
//Parm: 控件句柄
//Desc: 获取控件的文本内容
function GetControlText(const nHwnd: HWnd): string;
var nBuf: array[0..254] of Char;
begin
  if SendMessage(nHwnd, WM_GETTEXT, 255, Integer(@nBuf[0])) > 0 then
       Result := StrPas(@nBuf[0])
  else Result := '';
end;

//Desc: 检索控件回调
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
//Parm: 窗体句柄;控件名;关键字
//Desc: 获取nWindow上的指定控件
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
      WriteLog(Format('程序[ %s ]未运行.', [FOwner.FExeName]));
      Exit;
    end;

    FProcessID := nHwnd;
    //进程句柄
  end;

  if (FWindowID = 0) or (FControlID = 0) then
  begin
    FWindowID := 0;
    nHwnd := GetFixWindowID(FProcessID, FOwner.FFormName);
    
    if nHwnd = 0 then
    begin
      WriteLog(Format('窗口[ %s ]未运行.', [FOwner.FFormName]));
      Exit;
    end;

    FWindowID := nHwnd;
    //进程句柄
  end;

  if FControlID = 0 then
  begin
    nHwnd := GetFixControlID(FWindowID, FOwner.FCtrlName);
    if nHwnd = 0 then
    begin
      WriteLog(Format('控件[ %s ]无法定位.', [FOwner.FCtrlName]));
      Exit;
    end;

    FControlID := gControlHandle;
    //控件句柄
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
         WriteLog(Format('程序[ %s ]已关闭.', [FOwner.FExeName]))
    else WriteLog(Format('窗口[ %s ]已关闭.', [FOwner.FFormName]));

    Exit;
  end;

  if Pos('2500', nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [ms2K5];
    if not (ms2K5 in FStatus) then
      WriteLog('开始2500rpm监控.');
    //xxxxx
  end else

  if Pos('3500', nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [ms3K5];
    if not (ms3K5 in FStatus) then
      WriteLog('开始3500rpm监控.');
    //xxxxx
  end;

  for nIdx:=Low(gStatusFlags) to High(gStatusFlags) do
  if Pos(gStatusFlags[nIdx].FKeyWord, nStr) > 0 then
  begin
    FTmpStatus := FTmpStatus + [gStatusFlags[nIdx].FStatus];
    if FTmpStatus <> FStatus then
      WriteLog('工位标记: ' + nStr);
    //xxxxx

    if gStatusFlags[nIdx].FStatus in [msReset] then Continue;
    //无需处理状态

    if (FTmpStatus <> FStatus) or
       (gStatusFlags[nIdx].FStatus in [msDRun_2K5, msDRun_DS]) then
    begin
      if gStatusFlags[nIdx].FStatus = msDRun_2K5 then //双怠速2k5取样
      begin
        nPos := Pos('rpm', nStr); //请保持2500±100 rpm 29
        System.Delete(nStr, 1, nPos + 3);

        if IsNumber(nStr, False) then
             nStr := IntToStr(30 - StrToInt(nStr))
        else nStr := '1';
      end else

      if gStatusFlags[nIdx].FStatus = msDRun_DS then //双怠速怠速取样
      begin
        nPos := Pos('采样', nStr); //保持怠速 正在采样 29
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

      WriteLog('状态切换: ' + MonStatusToStr(gStatusFlags[nIdx].FStatus));
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
//Parm: 使用状态;是否增加
//Desc: 检索状态为nUsed的项
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
//Parm: 待发送数据
//Desc: 将nData发送至远程
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
