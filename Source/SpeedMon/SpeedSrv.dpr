program SpeedSrv;

uses
  FastMM4,
  Forms,
  Windows,
  UFormSrv in 'UFormSrv.pas' {fFormSrv},
  USysConst in 'USysConst.pas';

{$R *.res}

var
  gMutexHwnd: Hwnd;
  //互斥句柄

begin
  gMutexHwnd := CreateMutex(nil, True, 'RunSoft_QL_SpeedMonSrv');
  //创建互斥量
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    ReleaseMutex(gMutexHwnd);
    CloseHandle(gMutexHwnd); Exit;
  end; //已有一个实例

  Application.Initialize;
  Application.CreateForm(TfFormSrv, fFormSrv);
  Application.Run;
end.
