{*******************************************************************************
  ����: dmzn 2008-9-23
  ����: �����غ���
*******************************************************************************}
unit USysGrid;

interface

uses
  Windows, Classes, ULibFun, SysUtils, IniFiles, cxGrid, cxGridTableView,
  cxTextEdit, cxEdit, cxGridDBTableView;

procedure InitTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
procedure InitTableViewStyle(const nView: TcxGridTableView);
//��ʼ�������ͼ
procedure SaveUserDefineTableView(const nID: string; const nView: TcxGridTableView;
  const nIni: TIniFile = nil; const nViewID: string = '');
procedure UserDefineViewWidth(const nWidth: string; const nView: TcxGridTableView);
procedure UserDefineViewIndex(const nIndex: string; const nView: TcxGridTableView);
procedure UserDefineViewVisible(const nVisible: string; const nView: TcxGridTableView);
//�û��Զ�������ͼ

var
  gPath: string;

resourcestring
  sHint               = '��ʾ';
  sConfig             = 'Config.Ini';
  sVIPDir             = 'AutoVip';

implementation

//Date: 2008-9-23
//Parm: Ψһ���;����ʼ�����
//Desc: ��ʼ�����ΪnID�ı����ͼnView
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
//Parm: �����ͼ
//Desc: ��ʼ��nView�ķ������
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
    //����ֻ��
  end;
end;

//Date: 2008-9-23
//Parm: Ψһ���;����ʼ�����
//Desc: ��nView���û����ݱ��浽nIDС����
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
//Parm: ��";"�ָ�Ŀ��;������ı����ͼ
//Desc: ��nWidthӦ�õ�nView�����ͼ��
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
//Parm: ��","�ָ�ı�ͷ˳��;������ı����ͼ
//Desc: ��nIndexӦ�õ�nView�����ͼ��
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
//Parm: ��","�ָ����������;������ı����ͼ
//Desc: ��nVisibleӦ�õ�nView�����ͼ��
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
