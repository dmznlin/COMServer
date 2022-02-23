{*******************************************************************************
  ����: dmzn@163.com 2022-02-23
  ����: ��Ŀͨ�ú������嵥Ԫ
*******************************************************************************}
unit USysFun;

interface

uses
  Windows, Classes, Forms, SysUtils, IniFiles, UBaseObject;

procedure InitSystemEnvironment;
//��ʼ��ϵͳ���л����ı���
procedure LoadSysParameter(nIni: TIniFile = nil);
//����ϵͳ���ò���

function MakeMenuID(const nEntity,nMenu: string): string;
//�˵���ʶ
function MakeFrameName(const nFrameID: integer): string;
//����Frame����
function ReplaceGlobalPath(const nStr: string): string;
//�滻nStr�е�ȫ��·��

implementation

uses
  ULibFun, USysBusiness;

//---------------------------------- �������л��� ------------------------------
//Date: 2007-01-09
//Desc: ��ʼ�����л���
procedure InitSystemEnvironment;
begin
  Randomize;
  gPath := TApplicationHelper.gPath;

  with FormatSettings do
  begin
    DateSeparator := '-';
    ShortDateFormat := 'yyyy-MM-dd';
  end;

  with TObjectStatusHelper do
  begin
    shData := 50;
    shTitle := 100;
  end;
end;

//Date: 2007-09-13
//Desc: ����ϵͳ���ò���
procedure LoadSysParameter(nIni: TIniFile = nil);
var nBool: Boolean;
begin
  try
    nBool := Assigned(nIni);
    if not nBool then
      nIni := TIniFile.Create(TApplicationHelper.gSysConfig);
    TApplicationHelper.LoadParameters(gSysParam, nIni);
  finally
    if not nBool then nIni.Free;
  end;
end;

//Desc: �˵���ʶ
function MakeMenuID(const nEntity,nMenu: string): string;
begin
  Result := nEntity + '_' + nMenu;
end;

//Desc: ����FrameID���������
function MakeFrameName(const nFrameID: integer): string;
begin
  Result := 'Frame' + IntToStr(nFrameID);
end;

//Desc: �滻nStr�е�ȫ��·��
function ReplaceGlobalPath(const nStr: string): string;
var nPath: string;
begin
  nPath := gPath;
  if Copy(nPath, Length(nPath), 1) = '\' then
    System.Delete(nPath, Length(nPath), 1);
  Result := StringReplace(nStr, '$Path', nPath, [rfReplaceAll, rfIgnoreCase]);
end;

end.


