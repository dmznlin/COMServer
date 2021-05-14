{*******************************************************************************
  作者: dmzn 2008-9-23
  描述: 表格相关函数
*******************************************************************************}
unit USysGrid;

interface

uses
  Windows, Classes, ULibFun, SysUtils, IniFiles, cxGrid, cxGridTableView,
  cxTextEdit, cxEdit, cxGridDBTableView;

procedure InitTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
procedure InitTableViewStyle(const nView: TcxGridTableView);
//初始化表格视图
procedure SaveUserDefineTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
procedure UserDefineViewWidth(const nWidth: string; const nView: TcxGridTableView);
procedure UserDefineViewIndex(const nIndex: string; const nView: TcxGridTableView);
procedure UserDefineViewVisible(const nVisible: string; const nView: TcxGridTableView);
//用户自定义表格试图

var
  gPath: string;

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sVIPDir             = 'AutoVip';

implementation

//Date: 2008-9-23
//Parm: 唯一标记;待初始化表格
//Desc: 初始化标记为nID的表格试图nView
procedure InitTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
var nStr: string;
    nTmp: TIniFile;
begin
  if Assigned(nIni) then
       nTmp := nIni
  else nTmp := TIniFile.Create(gPath + sConfig);
  try
    InitTableViewStyle(nView);
    nStr := nTmp.ReadString(nID, 'GridIndex_' + nView.Name + nViewID, '');
    if nStr <> '' then UserDefineViewIndex(nStr, nView);

    nStr := nTmp.ReadString(nID, 'GridWidth_' + nView.Name + nViewID, '');
    if nStr <> '' then UserDefineViewWidth(nStr, nView);

    nStr := nTmp.ReadString(nID, 'GridVisible_' + nView.Name + nViewID, '');
    if nStr <> '' then UserDefineViewVisible(nStr, nView);
  finally
    if not Assigned(nIni) then nTmp.Free;
  end;
end;

//Date: 2008-9-23
//Parm: 表格视图
//Desc: 初始化nView的风格属性
procedure InitTableViewStyle(const nView: TcxGridTableView);
var i,nCount: integer;
begin
  nView.OptionsData.Deleting := False;
  nView.OptionsData.Editing := True;
  nView.OptionsBehavior.ImmediateEditor := False;

  nView.OptionsView.Indicator := True;
  nView.OptionsCustomize.ColumnsQuickCustomization := True;

  nCount := nView.ColumnCount - 1;
  for i:=0 to nCount do
  begin
    if not Assigned(nView.Columns[i].Properties) then
      nView.Columns[i].PropertiesClass := TcxTextEditProperties;
    nView.Columns[i].Tag := i;

    if nView.Columns[i].Properties is TcxCustomEditProperties then
      TcxCustomEditProperties(nView.Columns[i].Properties).ReadOnly := True;
    //设置只读
  end;
end;

//Date: 2008-9-23
//Parm: 唯一标记;待初始化表格
//Desc: 将nView的用户数据保存到nID小节下
procedure SaveUserDefineTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
var nStr: string;
    nTmp: TIniFile;
    i,nCount: integer;
begin
  nCount := nView.ColumnCount - 1;
  if nCount < 0 then Exit;

  if Assigned(nIni) then
       nTmp := nIni
  else nTmp := TIniFile.Create(gPath + sConfig);
  try
    nStr := '';
    for i:=0 to nCount do
    begin
      nStr := nStr + IntToStr(nView.Columns[i].Width);
      if i <> nCount then nStr := nStr + ';';
    end;

    nTmp.WriteString(nID, 'GridWidth_' + nView.Name + nViewID, nStr);
    nStr := '';

    for i:=0 to nCount do
    begin
      nStr := nStr + IntToStr(nView.Columns[i].Tag);
      if i <> nCount then nStr := nStr + ';';
    end;

    nTmp.WriteString(nID, 'GridIndex_' + nView.Name + nViewID, nStr);
    nStr := '';

    for i:=0 to nCount do
    begin
      if nView.Columns[i].Visible then
           nStr := nStr + '1'
      else nStr := nStr + '0';
      if i <> nCount then nStr := nStr + ';';
    end;
    nTmp.WriteString(nID, 'GridVisible_' + nView.Name + nViewID, nStr);
  finally
    if not Assigned(nIni) then nTmp.Free;
  end;
end;

//Date: 2008-9-23
//Parm: 用";"分割的宽度;待处理的表格试图
//Desc: 将nWidth应用到nView表格试图上
procedure UserDefineViewWidth(const nWidth: string; const nView: TcxGridTableView);
var nList: TStrings;
    i,nCount: integer;
begin
  nList := TStringList.Create;
  try
    nList.Text := StringReplace(nWidth, ';', #13, [rfReplaceAll]);
    if nList.Count <> nView.ColumnCount then Exit;

    nCount := nView.ColumnCount - 1;
    for i:=0 to nCount do
     if IsNumber(nList[i], False) then
       nView.Columns[i].Width := StrToInt(nList[i]);
    //xxxxx
  finally
    nList.Free;
  end;
end;

//Date: 2008-9-23
//Parm: 用","分割的表头顺序;待处理的表格试图
//Desc: 将nIndex应用到nView表格试图上
procedure UserDefineViewIndex(const nIndex: string; const nView: TcxGridTableView);
var nList: TStrings;
    i,nCount,nIdx: integer;
begin
  nList := TStringList.Create;
  try
    nList.Text := StringReplace(nIndex, ';', #13, [rfReplaceAll]);
    if nList.Count <> nView.ColumnCount then Exit;
    nCount := nList.Count - 1;

    for i:=0 to nCount do
    begin
      nIdx := nList.IndexOf(IntToStr(nView.Columns[i].Tag));
      if nIdx > -1 then nView.Columns[i].Index := nIdx;
    end;
  finally
    nList.Free;
  end;
end;

//Date: 2008-9-23
//Parm: 用","分割的显隐数据;待处理的表格试图
//Desc: 将nVisible应用到nView表格试图上
procedure UserDefineViewVisible(const nVisible: string; const nView: TcxGridTableView);
var nList: TStrings;
    i,nCount: integer;
begin
  nList := TStringList.Create;
  try
    nList.Text := StringReplace(nVisible, ';', #13, [rfReplaceAll]);
    if nList.Count <> nView.ColumnCount then Exit;

    nCount := nView.ColumnCount - 1;
    for i:=0 to nCount do
      nView.Columns[i].Visible := nList[i] <> '0';
    //xxxxx
  finally
    nList.Free;
  end;
end;

end.
