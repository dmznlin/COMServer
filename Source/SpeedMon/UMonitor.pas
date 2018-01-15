{*******************************************************************************
  ����: dmzn@163.com 2018-01-12
  ����: ��λ���ϵͳ��ض���

  ��ע:
  *.����Ԫ���ڸ��ٹ�λϵͳ�Ĺ���״̬
*******************************************************************************}
unit UMonitor;

interface

uses
  Windows, Classes, SysUtils, Messages, SyncObjs, TLHelp32, UWaitItem,
  USysLoger;

type
  TMonStatus = (msNoRun, ms2K5, ms3K5);
  //״̬: δ����;2K5ģʽ,3K5ģʽ

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

  TMonManager = class(TObject)
  private
    FMonitor: TMonThread;
    //����߳�
    FSyncLock: TCriticalSection;
    //ͬ������
    FExeName,FFormName,FCtrlName,FKeyWord: string;
    //ϵͳ��Ϣ
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure StartMon(const nExe,nCtrl,nKey: string);
    procedure StopMon;
    //����ֹͣ
    function Status: TMonStatus;
    //ϵͳ״��
  end;

var
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
  gControlKeyword: string;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMonManager, '��λϵͳ���', nEvent);
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
var nWndClassName: array[0..254] of Char;
begin
  GetClassName(AHWnd, @nWndClassName, 254);
  if (nWndClassName = gControlName) and
     (Pos(UpperCase(gControlKeyword), UpperCase(GetControlText(AHWnd))) > 0) then
      gControlHandle := AHWnd; //get control
  Result := True;
end;

//Date: 2018-01-12
//Parm: ������;�ؼ���;�ؼ���
//Desc: ��ȡnWindow�ϵ�ָ���ؼ�
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
    nHwnd := GetFixControlID(FWindowID, FOwner.FCtrlName, FOwner.FKeyWord);
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
    FControlID := GetFixControlID(FWindowID, FOwner.FCtrlName, FOwner.FKeyWord);
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
    FTmpStatus := ms2K5;
    if FTmpStatus <> FStatus then
      WriteLog('��ʼ2500rpm���.');
    //xxxxx
  end else

  if Pos('3500', nStr) > 0 then
  begin
    FTmpStatus := ms3K5;
    if FTmpStatus <> FStatus then
      WriteLog('��ʼ3500rpm���.');
    //xxxxx
  end;
end;

initialization
  gMonManager := TMonManager.Create;
finalization
  FreeAndNil(gMonManager);
end.
