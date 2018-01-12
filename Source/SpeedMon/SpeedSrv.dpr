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
  //������

begin
  gMutexHwnd := CreateMutex(nil, True, 'RunSoft_QL_SpeedMonSrv');
  //����������
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    ReleaseMutex(gMutexHwnd);
    CloseHandle(gMutexHwnd); Exit;
  end; //����һ��ʵ��

  Application.Initialize;
  Application.CreateForm(TfFormSrv, fFormSrv);
  Application.Run;
end.
