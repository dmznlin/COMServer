{*******************************************************************************
  作者: dmzn@163.com 2018-01-12
  描述: 工位检测系统监控对象

  备注:
  *.本单元用于跟踪工位系统的工作状态
*******************************************************************************}
unit UMonitor;

interface

uses
  Windows, Classes, SysUtils, Messages, SyncObjs, TLHelp32, UWaitItem,
  USysLoger;

type
  TMonStatus = (msNoRun, ms2K5, ms3K5);
  //状态: 未运行;2K5模式,3K5模式

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

  TMonManager = class(TObject)
  private
    FMonitor: TMonThread;
    //监控线程
    FSyncLock: TCriticalSection;
    //同步锁定
    FExeName,FFormName,FCtrlName,FKeyWord: string;
    //系统信息
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure StartMon(const nExe,nCtrl,nKey: string);
    procedure StopMon;
    //启动停止
    function Status: TMonStatus;
    //系统状体
  end;

var
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
  gControlKeyword: string;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMonManager, '工位系统监控', nEvent);
end;

//------------------------------------------------------------------------------
constructor TMonManager.Create;
begin
  FMonitor := nil;
  FSyncLock := TCriticalSection.Create;
end;

destructor TMonManager.Destroy;
begin
  StopMon;
  FSyncLock.Free;
  inherited;
end;

procedure TMonManager.StartMon(const nExe,nCtrl,nKey: string);
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

  if not Assigned(FMonitor) then
    FMonitor := TMonThread.Create(Self);
  FMonitor.Wakeup;
end;

procedure TMonManager.StopMon;
begin
  if Assigned(FMonitor) then
    FMonitor.StopMe;
  FMonitor := nil;
end;

function TMonManager.Status: TMonStatus;
begin
  FSyncLock.Enter;
  try
    Result := msNoRun;
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
  FStatus := msNoRun;
  FTmpStatus := msNoRun;

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
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    FTmpStatus := msNoRun;
    DoExecute;

    FOwner.FSyncLock.Enter;
    FStatus := FTmpStatus; //update
    FOwner.FSyncLock.Leave;

    if (FWindowID = 0) or (FProcessID = 0) then
         FWaiter.Interval := cInterval_Long
    else FWaiter.Interval := cInterval_Short;
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
var nWndClassName: array[0..254] of Char;
begin
  GetClassName(AHWnd, @nWndClassName, 254);
  if (nWndClassName = gControlName) and
     (Pos(UpperCase(gControlKeyword), UpperCase(GetControlText(AHWnd))) > 0) then
      gControlHandle := AHWnd; //get control
  Result := True;
end;

//Date: 2018-01-12
//Parm: 窗体句柄;控件名;关键字
//Desc: 获取nWindow上的指定控件
function GetFixControlID(const nWindow: THandle; const nName,nKey: string): THandle;
begin
  gControlHandle := 0;
  gControlName := nName;
  gControlKeyword := nKey;

  EnumChildWindows(nWindow, @EnumChildWndProc, 0);
  Result := gControlHandle;
end;

procedure TMonThread.DoExecute;
var nStr: string;
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
    nHwnd := GetFixControlID(FWindowID, FOwner.FCtrlName, FOwner.FKeyWord);
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
    FControlID := GetFixControlID(FWindowID, FOwner.FCtrlName, FOwner.FKeyWord);
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
    FTmpStatus := ms2K5;
    if FTmpStatus <> FStatus then
      WriteLog('开始2500rpm监控.');
    //xxxxx
  end else

  if Pos('3500', nStr) > 0 then
  begin
    FTmpStatus := ms3K5;
    if FTmpStatus <> FStatus then
      WriteLog('开始3500rpm监控.');
    //xxxxx
  end;
end;

initialization
  gMonManager := TMonManager.Create;
finalization
  FreeAndNil(gMonManager);
end.
