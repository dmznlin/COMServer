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
  TTruckItem = record
    FTruck: string;            //车牌号
    FLine: Integer;            //检测线
  end;

  TTruckItems = array of TTruckItem;

  TFDM = class(TDataModule)
    dxLayout1: TdxLayoutLookAndFeelList;
    XPM1: TXPManifest;
    dxLayoutWeb1: TdxLayoutWebLookAndFeel;
    cxLoF1: TcxLookAndFeelController;
    DBConn1: TUniConnection;
    SQLQuery: TUniQuery;
    Command: TUniQuery;
    SqlTemp: TUniQuery;
    MySQL1: TMySQLUniProvider;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FLastLoad: Int64;
    FTrucks: TTruckItems;
    FVIPTrucks: TStrings;
    //车辆列表
    function MakeVIPTruck: string;
  public
    { Public declarations }
    function LoadDBConfig: Boolean;
    procedure LoadTruckList;
    //读取数据
    function VIPTruckInLine(const nLine: Integer): Boolean;
    //车辆在线
    function QuerySQL(const nSQL: string): TDataSet;
    function QueryTemp(const nSQL: string): TDataSet;
    procedure QueryData(const nQuery: TUniQuery; const nSQL: string);
    function ExecuteSQL(const nSQL: string): integer;
    //读写操作
  end;

var
  FDM: TFDM;
  gPath: string;                        //程序路径

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UBase64, USysDB, USysLoger;

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TFDM, '数据模块', nEvent);
end;

//------------------------------------------------------------------------------
procedure TFDM.DataModuleCreate(Sender: TObject);
begin
  FLastLoad := 0;
  FVIPTrucks := TStringList.Create;
end;

procedure TFDM.DataModuleDestroy(Sender: TObject);
begin
  FVIPTrucks.Free;
end;

function TFDM.LoadDBConfig: Boolean;
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath+sConfig);
  with nIni,DBConn1 do
  try
    Disconnect;
    ProviderName := 'MySQL';
    SpecificOptions.Values['Charset'] := 'gb2312';

    Server := ReadString('DB', 'Server', '');
    Port := ReadInteger('DB', 'Port', 0);
    Database := ReadString('DB', 'DBName', 'detect');
    Username := ReadString('DB', 'User', '');
    Password := DecodeBase64(ReadString('DB', 'Password', ''));

    if ReadInteger('DB', 'DBEnable', 1) <> 0 then
      Connect;
    Result := True;
  except
    on E:Exception do
    begin
      Result := False;
      ShowDlg(E.Message, sHint);
    end;
  end;

  nIni.Free;
end;

procedure TFDM.LoadTruckList;
var nStr: string;
    nIdx: Integer;
    nDS: TDataSet;
begin
  if GetTickCount - FLastLoad < 5 * 1000 then
  begin
    FLastLoad := GetTickCount;
    Exit;
  end;

  FVIPTrucks.Clear;
  SetLength(FTrucks, 0);

  nStr := 'select car_num,goline from %s order by id asc';
  nStr := Format(nStr, [sTable_WQTruck]);
  nDS := QueryTemp(nStr);
  //待检车辆

  if Assigned(nDS) and (nDS.RecordCount > 0) then
  with nDS do
  begin
    SetLength(FTrucks, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      FTrucks[nIdx].FTruck := Fields[0].AsString;
      FTrucks[nIdx].FLine := Fields[1].AsInteger;

      Inc(nIdx);
      Next;
    end;
  end;

  nStr := 'select t_truck from %s where t_valid=0 order by id asc';
  nStr := Format(nStr, [sTable_Truck]);
  nDS := QueryTemp(nStr);
  //vip车辆

  if Assigned(nDS) and (nDS.RecordCount > 0) then
  with nDS do
  begin
    First;

    while not Eof do
    begin
      FVIPTrucks.Add(Fields[0].AsString);
      Next;
    end;
  end;

  FLastLoad := GetTickCount;
end;

//Desc: 构建通用VIP车辆
function TFDM.MakeVIPTruck: string;
var nPos: Integer;
begin
  Result := Date2Str(Now, False);
  Result := Copy(Result, 5, 4);
  Result := FloatToStr(StrToInt(Result) / 17);

  nPos := Pos('.', Result);
  if nPos > 0 then
    Result := Copy(Result, nPos + 1, 5);
  //xxxxx
end;

//Date: 2016-10-15
//Parm: 工位线号
//Desc: 检查nLine线的当前车辆是否在VIP车辆列表中
function TFDM.VIPTruckInLine(const nLine: Integer): Boolean;
var nIdx: Integer;
begin
  Result := FVIPTrucks.IndexOf(MakeVIPTruck) >= 0;
  if Result then Exit;

  for nIdx:=Low(FTrucks) to High(FTrucks) do
  if FTrucks[nIdx].FLine = nLine then
  begin
    Result := FVIPTrucks.IndexOf(FTrucks[nIdx].FTruck) >= 0;
    Exit;
  end;
end;

//------------------------------------------------------------------------------
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
end;

end.
