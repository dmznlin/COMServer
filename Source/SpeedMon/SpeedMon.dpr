program SpeedMon;

uses
  FastMM4,
  Forms,
  Windows,
  UFormMain in 'UFormMain.pas' {fFormMain};

{$R *.res}

var
  gMutexHwnd: Hwnd;
  //������

begin
  gMutexHwnd := CreateMutex(nil, True, 'RunSoft_QL_SpeedMon');
  //����������
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    ReleaseMutex(gMutexHwnd);
    CloseHandle(gMutexHwnd); Exit;
  end; //����һ��ʵ��
  
  Application.Initialize;
  Application.CreateForm(TfFormMain, fFormMain);
  Application.Run;
end.
