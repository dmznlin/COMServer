{*******************************************************************************
  ����: dmzn@163.com 2020-01-15
  ����: ҵ���嵥Ԫ
*******************************************************************************}
unit USysBusiness;

{$I Link.Inc}
interface

uses
  Windows, Classes, ComCtrls, Controls, Messages, Forms, SysUtils, IniFiles,
  Data.DB, Data.Win.ADODB, Datasnap.Provider, Datasnap.DBClient,
  System.SyncObjs, Vcl.Grids, Vcl.DBGrids, Vcl.Graphics,
  //----------------------------------------------------------------------------
  uniGUIAbstractClasses, uniGUITypes, uniGUIClasses, uniGUIBaseClasses,
  uniGUISessionManager, uniGUIApplication, uniTreeView, uniGUIForm,
  uniGUImForm, uniDBGrid, unimDBGrid, uniStringGrid, uniComboBox,
  //----------------------------------------------------------------------------
  UBaseObject, UManagerGroup, ULibFun, USysDB, USysFun;

var
  gPath: string;
  //ϵͳ·��
  gSysParam: TApplicationHelper.TAppParam;
  //ϵͳ����

procedure GlobalSyncLock;
procedure GlobalSyncRelease;
//ȫ��ͬ������

function SystemGetForm(const nClass: string;
  const nException: Boolean = False): TUnimForm;
//���������ƻ�ȡ�������
function UserFlagByID: string;
function UserConfigFile: TIniFile;
//�û��Զ��������ļ�

procedure DoStringGridColumnResize(const nGrid: TObject;
  const nParam: TUniStrings);
procedure UserDefineMGrid(const nForm: string; const nGrid: TUnimDBGrid;
  const nLoad: Boolean; const nIni: TIniFile = nil);
//�û��Զ�����

resourcestring
  sCheckFlagYes      = '��';                          //ѡ�б��
  sCheckFlagNo       = 'x';
  sDefaultUser       = 'admin';
  sInvalidConfig     = '�����ļ���Ч���Ѿ���';
  sEvent_StrGridColumnResize = 'StrGridColResize';   //�������б�

implementation

uses
  MainModule, ServerModule;

var
  gSyncLock: TCriticalSection;
  //ȫ����ͬ������

//Date: 2020-01-15
//Desc: ȫ��ͬ������
procedure GlobalSyncLock;
begin
  gSyncLock.Enter;
end;

//Date: 2020-01-15
//Desc: ȫ��ͬ�������Ӵ�
procedure GlobalSyncRelease;
begin
  gSyncLock.Leave;
end;

//Date: 2020-01-15
//Parm: ��������
//Desc: ��ȡnClass��Ķ���
function SystemGetForm(const nClass: string;const nException:Boolean): TUnimForm;
var nCls: TClass;
begin
  nCls := GetClass(nClass);
  if Assigned(nCls) then
       Result := TUnimForm(UniMainModule.GetFormInstance(nCls))
  else Result := nil;

  if (not Assigned(Result)) and nException then
    UniMainModule.FMainForm.ShowMessage(Format('������[ %s ]��Ч.', [nClass]));
  //xxxxx
end;

//Date: 2020-01-15
//Desc: �����û���ʶ
function UserFlagByID: string;
var nStr: string;
    nIdx: Integer;
begin
  with TEncodeHelper,UniMainModule do
    nStr := EncodeBase64(sDefaultUser);
  Result := '';

  for nIdx := 1 to Length(nStr) do
   if CharInSet(nStr[nIdx], ['a'..'z', 'A'..'Z','0'..'9']) then
    Result := Result + nStr[nIdx];
  //number & charactor
end;

//Date: 2020-01-15
//Desc: �û��Զ�������
function UserConfigFile: TIniFile;
var nStr: string;
begin
  nStr := gPath + 'users\';
  if not DirectoryExists(nStr) then
    ForceDirectories(nStr);
  //new folder

  nStr := nStr + UserFlagByID + '.ini';
  Result := TIniFile.Create(nStr);

  if not FileExists(nStr) then
  begin
    Result.WriteString('Config', 'User', sDefaultUser);
  end;
end;

//Desc: ��ȡ��������
procedure LoadFormConfig(const nForm: TUniForm; const nIni: TIniFile);
var nC: TIniFile;
begin
  nC := nil;
  try
    if Assigned(nIni) then
         nC := nIni
    else nC := UserConfigFile();

    nForm.Width := nC.ReadInteger(nForm.ClassName, 'Width', nForm.Width);
    nForm.Height := nC.ReadInteger(nForm.ClassName, 'Height', nForm.Height);
  finally
    if not Assigned(nIni) then
      nC.Free;
    //xxxxx
  end;
end;

//Desc: ���洰������
procedure SaveFormConfig(const nForm: TUniForm; const nIni: TIniFile);
var nC: TIniFile;
begin
  nC := nil;
  try
    if Assigned(nIni) then
         nC := nIni
    else nC := UserConfigFile();

    nC.WriteInteger(nForm.ClassName, 'Width', nForm.Width);
    nC.WriteInteger(nForm.ClassName, 'Height', nForm.Height);
  finally
    if not Assigned(nIni) then
      nC.Free;
    //xxxxx
  end;
end;

//Date: 2020-01-15
//Parm: ���;����
//Desc: �û������п�ʱ����,���û������Ľ��Ӧ�õ�nGrid.
procedure DoStringGridColumnResize(const nGrid: TObject;
  const nParam: TUniStrings);
var nStr: string;
    nIdx,nW: Integer;
begin
  with TStringHelper,TUniStringGrid(nGrid) do
  begin
    nStr := nParam.Values['idx'];
    if IsNumber(nStr, False) then
         nIdx := StrToInt(nStr)
    else nIdx := -1;

    if (nIdx < 0) or (nIdx >= Columns.Count) then Exit;
    //out of range

    nStr := nParam.Values['w'];
    if IsNumber(nStr, False) then
         nW := StrToInt(nStr)
    else nW := -1;

    if nW < 0 then Exit;
    if nW > 320 then
      nW := 320;
    Columns[nIdx].Width := nW;
  end;
end;

//Date: 2020-01-15
//Parm: ������;���;��ȡ
//Desc: ��дnForm.nGrid���û�����
procedure UserDefineMGrid(const nForm: string; const nGrid: TUnimDBGrid;
  const nLoad: Boolean; const nIni: TIniFile = nil);
var nStr: string;
    i,nCount: Integer;
    nTmp: TIniFile;
    nList: TStrings;
begin
  nTmp := nil;
  nList := nil;

  with TStringHelper do
  try
    if Assigned(nIni) then
         nTmp := nIni
    else nTmp := UserConfigFile;

    nCount := nGrid.Columns.Count - 1;
    //column num

    if nLoad then
    begin
      nList := gMG.FObjectPool.Lock(TStrings) as TStrings;
      nStr := nTmp.ReadString(nForm, 'GridWidth_' + nGrid.Name, '');
      if Split(nStr, nList, '', tpNo, nGrid.Columns.Count) then
      begin
        for i := 0 to nCount do
         if IsNumber(nList[i], False) then
          nGrid.Columns[i].Width := StrToInt(nList[i]);
        //apply width
      end;

      if not UniMainModule.FGridColumnAdjust then //����ʱȫ����ʾ
      begin
        nStr := nTmp.ReadString(nForm, 'GridVisible_' + nGrid.Name, '');
        if Split(nStr, nList, '', tpNo, nGrid.Columns.Count) then
        begin
          for i := 0 to nCount do
            nGrid.Columns[i].Visible := nList[i] = '1';
          //apply visible
        end;
      end;
    end else
    begin
      if UniMainModule.FGridColumnAdjust then //save manual adjust grid
      begin
        nStr := '';
        for i := 0 to nCount do
        begin
          nStr := nStr + IntToStr(nGrid.Columns[i].Width);
          if i <> nCount then nStr := nStr + ';';
        end;
        nTmp.WriteString(nForm, 'GridWidth_' + nGrid.Name, nStr);
      end else
      begin
        nStr := '';
        for i := 0 to nCount do
        begin
          if nGrid.Columns[i].Visible then
               nStr := nStr + '1'
          else nStr := nStr + '0';
          if i <> nCount then nStr := nStr + ';';
        end;
        nTmp.WriteString(nForm, 'GridVisible_' + nGrid.Name, nStr);
      end;
    end;
  finally
    gMG.FObjectPool.Release(nList);
    if not Assigned(nIni) then
      nTmp.Free;
    //xxxxx
  end;
end;

//Date: 2020-01-15
//Parm: �б���;���
//Desc: ʹ��nWideths����nGrid��ͷ���
procedure LoadGridColumn(const nWidths: string; const nGrid: TUniStringGrid);
var nList: TStrings;
    i,nCount: integer;
begin
  with nGrid do
  begin
    FixedCols := 0;
    FixedRows := 0;
    BorderStyle := ubsDefault;
    Options := [goVertLine,goHorzLine,goColSizing,goRowSelect];
    //style
  end;

  if (nWidths <> '') and (nGrid.Columns.Count > 0) then
  begin
    nList := TStringList.Create;
    try
      if TStringHelper.Split(nWidths, nList, ';', tpNo, nGrid.Columns.Count) then
      begin
        nCount := nList.Count - 1;
        for i:=0 to nCount do
         if TStringHelper.IsNumber(nList[i], False) then
          nGrid.Columns[i].Width := StrToInt(nList[i]);
      end;
    finally
      nList.Free;
    end;
  end;
end;

//Date: 2020-01-15
//Parm: ���
//Desc: ����nGrid��ͷ����ַ���
function MakeGridColumnInfo(const nGrid: TUniStringGrid): string;
var i,nCount: integer;
begin
  Result := '';
  nCount := nGrid.Columns.Count - 1;

  for i:=0 to nCount do
  if i = nCount then
       Result := Result + IntToStr(nGrid.Columns[i].Width)
  else Result := Result + IntToStr(nGrid.Columns[i].Width) + ';';
end;

initialization
  gSyncLock := TCriticalSection.Create;
finalization
  FreeAndNil(gSyncLock);
end.


