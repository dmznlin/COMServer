{*******************************************************************************
  作者: dmzn@163.com 2009-5-20
  描述: 数据库连接、操作相关 
*******************************************************************************}
unit UDataModule;

{$I Link.Inc}
interface

uses
  Windows, Graphics, SysUtils, Classes, DB, MemDS, DBAccess, Uni,
  cxLookAndFeels, XPMan, dxLayoutLookAndFeels, cxEdit, UniProvider,
  MySQLUniProvider;

type
  TFDM = class(TDataModule)
    edtStyle: TcxDefaultEditStyleController;
    dxLayout1: TdxLayoutLookAndFeelList;
    XPM1: TXPManifest;
    dxLayoutWeb1: TdxLayoutWebLookAndFeel;
    cxLoF1: TcxLookAndFeelController;
    DBConn1: TUniConnection;
    SQLQuery: TUniQuery;
    Command: TUniQuery;
    SqlTemp: TUniQuery;
    MySQL1: TMySQLUniProvider;
  private
    { Private declarations }
  public
    { Public declarations }
    function QuerySQL(const nSQL: string): TDataSet;
    function QueryTemp(const nSQL: string): TDataSet;
    procedure QueryData(const nQuery: TUniQuery; const nSQL: string);
    function ExecuteSQL(const nSQL: string): integer;
    //读写操作
    procedure GetValidTrucks(const nTrucks, nList: TStrings);
    //获取nTrucks中的有效车牌
    procedure SaveVIPTrucks(const nFile: string);
    //保存nTrucks中的VIP车牌
  end;

var
  FDM: TFDM;

implementation

{$R *.dfm}

uses
  UFormCtrl, USysDB, USysLoger;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TFDM, '数据模块', nEvent);
end;

//Desc: 执行nSQL写操作
function TFDM.ExecuteSQL(const nSQL: string): integer;
var nStep: Integer;
    nException: string;
begin
  Result := -1;
  nException := '';
  nStep := 0;
  
  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SqlTemp.Close;
      SqlTemp.Connection := Command.Connection;
      SqlTemp.SQL.Text := 'select 1';
      SqlTemp.Open;

      SqlTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      Command.Connection.Close;
      Command.Connection.Open;
    end; //reconnnect

    Command.Close;
    Command.SQL.Text := nSQL;
    Command.Execute;

    Result := Command.FetchRows;
    nException := '';
    Break;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

//Desc: 常规查询
function TFDM.QuerySQL(const nSQL: string): TDataSet;
var nStep: Integer;
    nException: string;
begin
  Result := nil;
  nException := '';
  nStep := 0;

  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SQLQuery.Close;
      SQLQuery.SQL.Text := 'select 1';
      SQLQuery.Open;

      SQLQuery.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      SQLQuery.Connection.Close;
      SQLQuery.Connection.Open;
    end; //reconnnect

    SQLQuery.Close;
    SQLQuery.SQL.Text := nSQL;
    SQLQuery.Open;

    Result := SQLQuery;
    nException := '';
    Break;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

//Desc: 临时查询
function TFDM.QueryTemp(const nSQL: string): TDataSet;
var nStep: Integer;
    nException: string;
begin
  Result := nil;
  nException := '';
  nStep := 0;

  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SQLTemp.Close;
      SQLTemp.SQL.Text := 'select 1';
      SQLTemp.Open;

      SQLTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      SQLTemp.Connection.Close;
      SQLTemp.Connection.Open;
    end; //reconnnect

    SQLTemp.Close;
    SQLTemp.SQL.Text := nSQL;
    SQLTemp.Open;

    Result := SQLTemp;
    nException := '';
    Break;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

//Desc: 用nQuery执行nSQL语句
procedure TFDM.QueryData(const nQuery: TUniQuery; const nSQL: string);
var nStep: Integer;
    nException: string;
    nBookMark: Pointer;
begin
  nException := '';
  nStep := 0;

  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SqlTemp.Close;
      SqlTemp.Connection := nQuery.Connection;
      SqlTemp.SQL.Text := 'select 1';
      SqlTemp.Open;

      SqlTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      nQuery.Connection.Close;
      nQuery.Connection.Open;
    end; //reconnnect

    nQuery.DisableControls;
    nBookMark := nQuery.GetBookmark;
    try
      nQuery.Close;
      nQuery.SQL.Text := nSQL;
      nQuery.Open;
                 
      nException := '';
      nStep := 3;
      //delay break loop

      if nQuery.BookmarkValid(nBookMark) then
        nQuery.GotoBookmark(nBookMark);
    finally
      nQuery.FreeBookmark(nBookMark);
      nQuery.EnableControls;
    end;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

//Date: 2021-05-14
//Parm: 车牌数据
//Desc: 从nText中检索出有效的车牌,放入nList中
procedure TFDM.GetValidTrucks(const nTrucks, nList: TStrings);
var nNick: WideString;
    nIdx: Integer;
begin
  nList.Clear;
  nNick := nTrucks.Text;
  nIdx := Pos(':', nNick);

  if nIdx > 1 then
  begin
    nNick := Copy(nNick, 1, nIdx);
    nList.Text := StringReplace(nTrucks.Text, nNick, #13#10, [rfReplaceAll]);
    //xxxxx 
  end else
  begin
    nList.AddStrings(nTrucks);
    //每行一车牌
  end;

  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nList[nIdx] := Trim(nList[nIdx]);
    if (nList[nIdx] = '') or (Pos(':', nList[nIdx]) > 0) then
      nList.Delete(nIdx);
    //清理空行
  end;
end;

//Date: 2021-05-14
//Parm: 车牌文件
//Desc: 将nFile中的车牌存入vip表
procedure TFDM.SaveVIPTrucks(const nFile: string);
var nStr: string;
    nIdx: Integer;
    nTrucks,nList: TStrings;
begin
  nTrucks := TStringList.Create;
  nList := TStringList.Create;
  try
    try
      nStr := ChangeFileExt(nFile, '.old');
      RenameFile(nFile, nStr);

      nTrucks.LoadFromFile(nStr);
      GetValidTrucks(nTrucks, nList);

      for nIdx:=0 to nList.Count - 1 do
      begin
        nStr := MakeSQLByStr([
                SF('t_simple', 'null', sfVal),
                SF('t_struck', 'null', sfVal),
                SF('t_truck', nList[nIdx]),
                SF('t_user', gLocalName),
                SF('t_time', 'now()', sfVal),
                SF('t_valid', 0, sfVal),
                SF('t_allow', '1', sfVal)
                ], sTable_Truck, '', True);
        FDM.ExecuteSQL(nStr);
      end;
    except
      on nErr: Exception do
      begin
        WriteLog(nErr.Message);
      end;
    end;
  finally
    nList.Free;
    nTrucks.Free;
  end;   
end;

end.
