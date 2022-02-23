{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 项目通用函数定义单元
*******************************************************************************}
unit USysFun;

interface

uses
  Windows, Classes, Forms, SysUtils, IniFiles, UBaseObject;

procedure InitSystemEnvironment;
//初始化系统运行环境的变量
procedure LoadSysParameter(nIni: TIniFile = nil);
//载入系统配置参数

function MakeMenuID(const nEntity,nMenu: string): string;
//菜单标识
function MakeFrameName(const nFrameID: integer): string;
//创建Frame名称
function ReplaceGlobalPath(const nStr: string): string;
//替换nStr中的全局路径

implementation

uses
  ULibFun, USysBusiness;

//---------------------------------- 配置运行环境 ------------------------------
//Date: 2007-01-09
//Desc: 初始化运行环境
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
//Desc: 载入系统配置参数
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

//Desc: 菜单标识
function MakeMenuID(const nEntity,nMenu: string): string;
begin
  Result := nEntity + '_' + nMenu;
end;

//Desc: 依据FrameID生成组件名
function MakeFrameName(const nFrameID: integer): string;
begin
  Result := 'Frame' + IntToStr(nFrameID);
end;

//Desc: 替换nStr中的全局路径
function ReplaceGlobalPath(const nStr: string): string;
var nPath: string;
begin
  nPath := gPath;
  if Copy(nPath, Length(nPath), 1) = '\' then
    System.Delete(nPath, Length(nPath), 1);
  Result := StringReplace(nStr, '$Path', nPath, [rfReplaceAll, rfIgnoreCase]);
end;

end.


