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
    dxLayout1: TdxLayoutLookAndFeelList;
    XPM1: TXPManifest;
    dxLayoutWeb1: TdxLayoutWebLookAndFeel;
    cxLoF1: TcxLookAndFeelController;
    DBConn1: TUniConnection;
    SQLQuery: TUniQuery;
    Command: TUniQuery;
    SqlTemp: TUniQuery;
    MySQL1: TMySQLUniProvider;
    DBConn2: TUniConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FLastLoad: Int64;
    FTrucks: TTruckItems;
    FVIPTrucks: TStrings;
    //车辆列表
    function MakeVIPTruck: string;
    function GetTruckItem(const nTruck: string): Integer;
  public
    { Public declarations }
    function LoadDBConfig: Boolean;
    procedure LoadTruckList;
    procedure LoadTruckToList(const nList: TStrings);
    //读取数据
    function VIPTruckInLine(const nLine: Integer; const nType: TSystemType): Boolean;
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

const
  cTruckKeepLong = 1 * 1000 * 60 * 60;
  //车辆列表内保持: 1小时

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

    //Date: 2017-02-20
    //Parm: 链路;配置节点
    //Desc: 设置nConn参数
    procedure LoadConn(const nConn: TUniConnection; const nKey: string);
    begin
      with nIni, nConn do
      begin
        Disconnect;
        ProviderName := 'MySQL';
        SpecificOptions.Values['Charset'] := 'gb2312';

        Server := ReadString(nKey, 'Server', '');
        Port := ReadInteger(nKey, 'Port', 0);
        Database := ReadString(nKey, 'DBName', 'detect');
        Username := ReadString(nKey, 'User', '');
        Password := DecodeBase64(ReadString(nKey, 'Password', ''));

        if ReadInteger(nKey, 'DBEnable', 1) = 0 then
        begin
          nConn.Tag := 0;
          //no conn
        end else
        begin
          nConn.Tag := 10;
          Connect;
        end;
      end;
    end;
begin
  nIni := TIniFile.Create(gPath+sConfig);
  try
    LoadConn(DBConn1, 'DB');
    LoadConn(DBConn2, 'DB2');
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

//Date: 2017-02-27
//Parm: 车牌号
//Desc: 检索nTruck车辆索引
function TFDM.GetTruckItem(const nTruck: string): Integer;
var nIdx: Integer;
begin
  for nIdx:=Low(FTrucks) to High(FTrucks) do
  if CompareText(nTruck, FTrucks[nIdx].FTruck) = 0 then
  begin
    FTrucks[nIdx].FLastActive := GetTickCount;
    Result := nIdx;
    Exit;
  end;

  for nIdx:=Low(FTrucks) to High(FTrucks) do
  if GetTickCount - FTrucks[nIdx].FLastActive > cTruckKeepLong then
  begin
    FTrucks[nIdx].FLastActive := GetTickCount;
    Result := nIdx;
    Exit;
  end;

  nIdx := Length(FTrucks);
  SetLength(FTrucks, nIdx + 1);
  
  Result := nIdx;
  FTrucks[nIdx].FLastActive := GetTickCount;
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
  SqlTemp.Active := False;
  
  if DBConn1.Tag > 0 then
       SqlTemp.Connection := DBConn1
  else SqlTemp.Connection := DBConn2; //切换链路

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

  //----------------------------------------------------------------------------
  SqlTemp.Active := False;
  SqlTemp.Connection := DBConn1;
  //切换链路

  nStr := 'select car_num,goline from %s order by id asc';
  nStr := Format(nStr, [sTable_WQTruck]);
  nDS := QueryTemp(nStr);
  //尾气待检车辆

  if Assigned(nDS) and (nDS.RecordCount > 0) then
  with nDS do
  begin
    First;

    while not Eof do
    begin
      nIdx := GetTruckItem(Fields[0].AsString);
      with FTrucks[nIdx] do
      begin
        FTruck := Fields[0].AsString;
        FLine := Fields[1].AsInteger;
      end;

      Next;
    end;
  end;
                 
  //----------------------------------------------------------------------------
  SqlTemp.Active := False;
  SqlTemp.Connection := DBConn2;
  //切换链路

  nStr := 'select car_num,goline from %s where Gw_Three=1 order by id asc';
  nStr := Format(nStr, [sTable_DDTruck]);
  nDS := QueryTemp(nStr);
  //大灯待检车辆

  if Assigned(nDS) and (nDS.RecordCount > 0) then
  with nDS do
  begin
    First;

    while not Eof do
    begin
      nIdx := GetTruckItem(Fields[0].AsString);
      with FTrucks[nIdx] do
      begin
        FTruck := Fields[0].AsString;
        FLine := Fields[1].AsInteger;
      end;

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
  Result := FloatToStr(StrToInt(Result) / 17.7);

  nPos := Pos('.', Result);
  if nPos > 0 then
    Result := Copy(Result, nPos + 1, 5);
  //xxxxx
end;

//Date: 2016-10-15
//Parm: 工位线号
//Desc: 检查nLine线的当前车辆是否在VIP车辆列表中
function TFDM.VIPTruckInLine(const nLine: Integer; const nType: TSystemType): Boolean;
var nIdx: Integer;
begin
  {$IFDEF DEBUG}
  Result := True;
  Exit;
  {$ENDIF}

  Result := FVIPTrucks.IndexOf(MakeVIPTruck) >= 0;
  if Result then Exit;

  if nType = stDD then
    LoadTruckList;
  //大灯时刷新车辆列表

  for nIdx:=Low(FTrucks) to High(FTrucks) do
   with FTrucks[nIdx] do
    if (FLine = nLine) and (GetTickCount - FLastActive <= cTruckKeepLong) then
    begin
      Result := FVIPTrucks.IndexOf(FTruck) >= 0;
      Exit;
    end;
end;

procedure TFDM.LoadTruckToList(const nList: TStrings);
var nStr: string;
    nIdx: Integer;
begin
  LoadTruckList;
  nList.Add('待检车辆:');

  for nIdx:=Low(FTrucks) to High(FTrucks) do
  with FTrucks[nIdx] do
  begin
    if GetTickCount - FLastActive > cTruckKeepLong then Continue;
    if FVIPTrucks.IndexOf(FTruck) >= 0 then
         nStr := 'VIP'
    else nStr := '';

    nStr := Format('|--- %d.%s [%s %d线]', [nIdx+1, FTruck, nStr, FLine]);
    nList.Add(nStr);
  end;

  nList.Add(#13#10 + 'VIP车辆:');
  for nIdx:=0 to FVIPTrucks.Count-1 do
    nList.Add('|--- ' + IntToStr(nIdx+1) + '.' + FVIPTrucks[nIdx]);
  //xxxxx
end;

//------------------------------------------------------------------------------
//Desc: 执行nSQL写操作
function TFDM.ExecuteSQL(const nSQL: string): integer;
var nStep: Integer;
    nException: string;
begin
  Result := -1;
  if SqlTemp.Connection.Tag = 0 then Exit;

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
  if SQLQuery.Connection.Tag = 0 then Exit;

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
  if SQLTemp.Connection.Tag = 0 then Exit;

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
