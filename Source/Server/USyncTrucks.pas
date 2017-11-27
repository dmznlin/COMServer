{*******************************************************************************
  作者: dmzn@163.com 2017-03-11
  描述: 同步更新在线车辆和VIP列表
*******************************************************************************}
unit USyncTrucks;

{$I Link.Inc}
interface

uses
  Windows, SysUtils, Classes, SyncObjs, DB, IniFiles, Uni, UniProvider,
  MySQLUniProvider, UWaitItem, USysLoger, ULibFun, UBase64, USysDB;

type
  TCOMType = (ctDD, ctWQ);
  //类型: 大灯仪,尾气检测仪

  TTruckItem = record
    FEnable: Boolean;          //是否有效
    FType: TCOMType;           //业务类型

    FTruck: string;            //车牌号
    FLine: Integer;            //检测线
  end;

  TTruckItems = array of TTruckItem;

  TTruckManager = class(TThread)
  private
    FDBConfig: string;
    //数据库配置
    FDBConnDD: TUniConnection;
    FDBConnWQ: TUniConnection;
    FSQLQuery: TUniQuery;
    FSQLCmd: TUniQuery;
    //数据库对象
    FTrucks: TTruckItems;
    FVIPTrucks: TStrings;
    FTempTrucks: TTruckItems;
    FTempVIPTrucks: TStrings;
    //车辆列表
    FWaiter: TWaitObject;
    //等待对象
    FSyncLock: TCriticalSection;
    //同步锁定
  protected
    procedure Execute; override;
    procedure DoExecute;
    //执行线程
    function MakeVIPTruck: string;
    function GetTruckItem(const nTruck: string): Integer;
  public
    constructor Create(const nFileName: string);
    destructor Destroy; override;
    //创建释放
    procedure StopMe;
    //停止同步
    function LoadDBConfig: Boolean;
    procedure LoadTruckToList(const nList: TStrings);
    //读取数据
    function VIPTruckInLine(const nLine: Integer; const nType: TCOMType;
      const nInBlack: PBoolean = nil): Boolean;
    //车辆在线
  end;

var
  gPath: string;                            //程序路径
  gTruckManager: TTruckManager = nil;       //车辆同步

resourcestring
  sHint               = '提示';
  sConfig             = 'Config.Ini';
  sAutoStartKey       = 'COMServer';

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TTruckManager, 'VIP车辆同步', nEvent);
end;

constructor TTruckManager.Create(const nFileName: string);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FDBConfig := nFileName;

  SetLength(FTrucks, 0);
  FVIPTrucks := TStringList.Create;
  FTempVIPTrucks := TStringList.Create;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 5 * 1000;
  FSyncLock := TCriticalSection.Create;
end;

destructor TTruckManager.Destroy;
begin
  FreeAndNil(FDBConnDD);
  FreeAndNil(FDBConnWQ);
  FreeAndNil(FSQLQuery);
  FreeAndNil(FSQLCmd);
  
  FTempVIPTrucks.Free;
  FVIPTrucks.Free;
  FSyncLock.Free;
  
  FWaiter.Free;
  inherited;
end;

procedure TTruckManager.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;
  
  WaitFor;
  Free;
end;

//Desc: 构建通用VIP车辆
function TTruckManager.MakeVIPTruck: string;
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

procedure TTruckManager.LoadTruckToList(const nList: TStrings);
var nStr: string;
    i,nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    nList.Add('待检车辆:');
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    begin
      if not FEnable then Continue;
      i := FVIPTrucks.IndexOf(FTruck);

      if i >= 0 then
      begin
        i := Integer(FVIPTrucks.Objects[i]);
        if i = 0 then
             nStr := '黑名单'
        else nStr := 'VIP';
      end else nStr := '';

      nStr := Format('|--- %2d.%-6s [%s %d线]', [nIdx+1, FTruck, nStr, FLine]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + 'VIP车辆:');
    for nIdx:=0 to FVIPTrucks.Count-1 do
    begin
      i := Integer(FVIPTrucks.Objects[nIdx]);
      if i = 0 then
           nStr := '黑名单'
      else nStr := 'VIP';

      nStr := Format('|--- %2d.%-6s [%s]', [nIdx+1, FVIPTrucks[nIdx], nStr]);
      nList.Add(nStr);
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: 载入数据库配置
function TTruckManager.LoadDBConfig: Boolean;
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
        SpecificOptions.Values['Direct'] := 'False';

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
  nIni := TIniFile.Create(FDBConfig);
  try
    LoadConn(FDBConnWQ, 'DB');
    LoadConn(FDBConnDD, 'DB2');
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
function TTruckManager.GetTruckItem(const nTruck: string): Integer;
var nIdx: Integer;
begin
  for nIdx:=Low(FTrucks) to High(FTrucks) do
  if CompareText(nTruck, FTrucks[nIdx].FTruck) = 0 then
  begin
    Result := nIdx;
    Exit;
  end;

  for nIdx:=Low(FTrucks) to High(FTrucks) do
  if not FTrucks[nIdx].FEnable then
  begin
    Result := nIdx;
    Exit;
  end;

  nIdx := Length(FTrucks);
  SetLength(FTrucks, nIdx + 1);  
  Result := nIdx;
end;

//------------------------------------------------------------------------------
procedure TTruckManager.Execute;
begin
  FDBConnDD := TUniConnection.Create(nil);
  FDBConnWQ := TUniConnection.Create(nil);
  FSQLQuery := TUniQuery.Create(nil);
  FSQLCmd := TUniQuery.Create(nil);

  FWaiter.EnterWait;
  //延迟加载数据库
  if not LoadDBConfig then Exit;
  FWaiter.Wakeup(True);

  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Break;

    if (FDBConnDD.Tag > 0) and (not FDBConnDD.Connected) then
      FDBConnDD.Connect;
    //xxxxx

    if (FDBConnWQ.Tag > 0) and (not FDBConnWQ.Connected) then
      FDBConnWQ.Connect;
    //xxxxx

    if FDBConnDD.Connected or FDBConnWQ.Connected then
    try
      DoExecute;
    except
      FDBConnDD.Disconnect;
      FDBConnWQ.Disconnect;
    end;
  except
    on nErr: Exception do
    begin
      WriteLog(nErr.Message);
    end;
  end;

  FreeAndNil(FDBConnDD);
  FreeAndNil(FDBConnWQ);
  FreeAndNil(FSQLQuery);
  FreeAndNil(FSQLCmd);
end;

procedure TTruckManager.DoExecute;
var nStr: string;
    i,nIdx: Integer;
begin
  FTempVIPTrucks.Clear;
  FSQLQuery.Close;
  
  if FDBConnWQ.Tag > 0 then
       FSQLQuery.Connection := FDBConnWQ
  else FSQLQuery.Connection := FDBConnDD; //切换链路

  nStr := 'select t_truck,t_allow from %s where t_valid=0 order by id asc';
  FSQLQuery.SQL.Text := Format(nStr, [sTable_Truck]);
  FSQLQuery.Open;

  if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
  with FSQLQuery do
  begin
    First;

    while not Eof do
    begin
      nIdx := Fields[1].AsInteger;
      FTempVIPTrucks.AddObject(Fields[0].AsString, Pointer(nIdx));
      Next;
    end;
  end;

  //----------------------------------------------------------------------------
  nIdx := 0;
  SetLength(FTempTrucks, 0);

  if FDBConnWQ.Tag > 0 then
  begin
    FSQLQuery.Close;
    FSQLQuery.Connection := FDBConnWQ; //切换链路

    nStr := 'select car_num,goline from %s order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_WQTruck]);
    FSQLQuery.Open; //尾气待检车辆

    if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
    with FSQLQuery do
    begin
      SetLength(FTempTrucks, RecordCount);
      First;

      while not Eof do
      begin
        with FTempTrucks[nIdx] do
        begin
          FType := ctWQ;
          FTruck := Fields[0].AsString;
          FLine := Fields[1].AsInteger;
        end;

        Inc(nIdx);
        Next;
      end;
    end;
  end;
                 
  //----------------------------------------------------------------------------
  if FDBConnDD.Tag > 0 then
  begin
    FSQLQuery.Close;
    FSQLQuery.Connection := FDBConnDD; //切换链路

    nStr := 'select car_num,goline from %s where Gw_Three=1 order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_DDTruck]);
    FSQLQuery.Open; //大灯待检车辆

    if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
    with FSQLQuery do
    begin
      SetLength(FTempTrucks, RecordCount + nIdx);
      First;

      while not Eof do
      begin
        with FTempTrucks[nIdx] do
        begin
          FType := ctDD;
          FTruck := Fields[0].AsString;
          FLine := Fields[1].AsInteger;
        end;

        Inc(nIdx);
        Next;
      end;
    end;
  end;

  //----------------------------------------------------------------------------
  FSyncLock.Enter;
  try
    FVIPTrucks.Clear;
    FVIPTrucks.AddStrings(FTempVIPTrucks);
    //combin vip list

    for nIdx:=Low(FTrucks) to High(FTrucks) do
      FTrucks[nIdx].FEnable := False;
    //invalid first

    for nIdx:=Low(FTempTrucks) to High(FTempTrucks) do
    begin
      i := GetTruckItem(FTempTrucks[nIdx].FTruck);
      FTrucks[i] := FTempTrucks[nIdx];
      FTrucks[i].FEnable := True;
    end;
  finally
    FSyncLock.Leave;
  end;   
end;

//Date: 2016-10-15
//Parm: 工位线号;业务类型;是否黑名单
//Desc: 检查nLine线的当前车辆是否在VIP车辆列表中
function TTruckManager.VIPTruckInLine(const nLine: Integer;
  const nType: TCOMType; const nInBlack: PBoolean): Boolean;
var i,nIdx: Integer;
begin
  if Assigned(nInBlack) then
    nInBlack^ := False;
  //init
  
  {$IFDEF DEBUG}
  Result := True;
  Exit;
  {$ENDIF}

  FSyncLock.Enter;
  try
    if (not (Assigned(FDBConnDD) and FDBConnDD.Connected)) and
       (not (Assigned(FDBConnWQ) and FDBConnWQ.Connected)) then
    begin
      Result := True;
      Exit;
    end;

    Result := FVIPTrucks.IndexOf(MakeVIPTruck) >= 0;
    if Result then Exit;

    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    if FEnable and (FType = nType) and (FLine = nLine) then
    begin
      i := FVIPTrucks.IndexOf(FTruck);
      Result := i >= 0;

      if Result and Assigned(nInBlack) then
        nInBlack^ := Integer(FVIPTrucks.Objects[i]) = 0;
      Exit;
    end;
  finally
    FSyncLock.Leave;
  end;
end;

end.
