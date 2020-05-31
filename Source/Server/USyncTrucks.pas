{*******************************************************************************
  作者: dmzn@163.com 2017-03-11
  描述: 同步更新在线车辆和VIP列表
*******************************************************************************}
unit USyncTrucks;

{$I Link.Inc}
interface

uses
  Windows, SysUtils, Classes, SyncObjs, DB, IniFiles, Uni, UniProvider,
  MySQLUniProvider, UWaitItem, USysLoger, ULibFun, UBase64, USysDB,
  UCommonConst;

type
  TTruckItem = record
    FEnable: Boolean;          //是否有效
    FType: TCOMType;           //业务类型

    FTruck: string;            //车牌号
    FLine: Integer;            //检测线
    FCheckType: TWQCheckType;  //尾气检测
  end;
  TTruckItems = array of TTruckItem;

  TVIPType = (vtVIP, vtBlack); //vip,黑名单
  TVIPItem = record
    FTruck: string;            //车牌号
    FType: TVIPType;           //类型
    FSimple: string;           //检测样本序号
    FSTruck: string;           //检测样本车辆
  end;
  TVIPItems = array of TVIPItem;

  TSQLType = (stVIPSimple);    //vip检测样本
  TSQLItem = record
    FSQL: string;              //语句
    FType: TSQLType;           //类型
    FValid: Boolean;           //有效
  end;
  TSQLItems = array of TSQLItem;
  
  TTruckManager = class(TThread)
  private
    FDBConfig: string;
    //数据库配置
    FDBConnDD: TUniConnection;
    FDBConnWQ: TUniConnection;
    FSQLQuery: TUniQuery;
    FSQLCmd: TUniQuery;
    //数据库对象
    FSQLItems: TSQLItems;
    //待执行语句
    FTrucks: TTruckItems;
    FVIPTrucks: TVIPItems;
    FTempTrucks: TTruckItems;
    FTempVIPTrucks: TVIPItems;
    //车辆列表
    FWQSimplesType: string;
    FWQSimplesIndex: Integer;
    FWQSimplesVMAS: TWQSimpleItems;
    FWQSimplesSDS: TWQSimpleItems;
    //尾气样本
    FWaiter: TWaitObject;
    FWaiterWQSimple: TWaitObject;
    //等待对象
    FSyncLock: TCriticalSection;
    //同步锁定
  protected
    procedure Execute; override;
    procedure DoExecute;
    //执行线程
    function MakeVIPTruck: string;
    function FindVIPTruck(const nTruck: string): Integer;
    function GetTruckItem(const nTruck: string): Integer;
    procedure DoLoadWQSimple(const nIndex: Integer);
    procedure LoadWQSimpleData(const nIndex: Integer; const nType: string);
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
      var nTruck: string; const nInBlack: PBoolean = nil;
      const nWQCheckType: PInteger = nil): Boolean;
    //车辆在线
    function FillVMasSimple(const nLineNo: Integer; var nTruck: string;
      var nData: TWQDataList): Boolean;
    //vmas样本
    function FillSDSSimple(const nLineNo: Integer;
      var nTruck: string; var nData: TWQDataList): Boolean;
    //vmas样本
  end;

var
  gTruckManager: TTruckManager = nil;       //车辆同步

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

  SetLength(FSQLItems, 0);
  SetLength(FTrucks, 0);
  SetLength(FVIPTrucks, 0);

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 5 * 1000;
  FSyncLock := TCriticalSection.Create;

  FWQSimplesIndex := -1;
  SetLength(FWQSimplesVMAS, 0);
  SetLength(FWQSimplesSDS, 0);
                             
  FWaiterWQSimple := TWaitObject.Create;
  FWaiterWQSimple.Interval := 10 * 1000;
end;

destructor TTruckManager.Destroy;
begin
  FreeAndNil(FDBConnDD);
  FreeAndNil(FDBConnWQ);
  FreeAndNil(FSQLQuery);
  FreeAndNil(FSQLCmd);

  FSyncLock.Free; 
  FWaiterWQSimple.Free;
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
var nStr,nCheck: string;
    i,nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    nList.Add('待检车辆:');
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    begin
      if not FEnable then Continue;
      i := FindVIPTruck(FTruck);

      if i >= 0 then
      begin
        if FVIPTrucks[i].FType = vtBlack then
             nStr := '黑名单'
        else nStr := 'VIP';
      end else nStr := '';

      if FCheckType = CTvmas then
        nCheck := 'VMAS' else
      if FCheckType = CTsds then
        nCheck := '双怠速' else
      if FCheckType = CTlugdown then
        nCheck := '加载减速' else
      if FCheckType = CTzyjs then
        nCheck := '自由加速'
      else nCheck := '未知';

      nStr := Format('|--- %2d.%-8s [%-4s %2d线 %-8s]', [nIdx+1, FTruck,
              nStr, FLine, nCheck]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + 'VIP车辆:');
    for nIdx:=Low(FVIPTrucks) to High(FVIPTrucks) do
    begin
      if FVIPTrucks[nIdx].FType = vtBlack then
           nStr := '黑名单'
      else nStr := 'VIP';

      nStr := Format('|--- %2d.%-8s [%-6s]', [nIdx+1, FVIPTrucks[nIdx].FTruck, nStr]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + '尾气样本: VMAS');
    for nIdx:=Low(FWQSimplesVMAS) to High(FWQSimplesVMAS) do
    with FWQSimplesVMAS[nIdx] do
    begin
      nStr := Format('|--- %2d.%-8s %s', [nIdx+1, FTruck, FXH]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + '尾气样本: 双怠速');
    for nIdx:=Low(FWQSimplesSDS) to High(FWQSimplesSDS) do
    with FWQSimplesSDS[nIdx] do
    begin
      nStr := Format('|--- %2d.%-8s %s', [nIdx+1, FTruck, FXH]);
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
var nIdx,nInt: Integer;
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

    nIdx := FWQSimplesIndex;
    //索引

    if FDBConnDD.Connected or FDBConnWQ.Connected then
    try
      if nIdx >= 0 then
           DoLoadWQSimple(nIdx)
      else DoExecute;
    except
      FDBConnDD.Disconnect;
      FDBConnWQ.Disconnect;
    end;

    if nIdx >= 0 then
      FWaiterWQSimple.Wakeup();
    //唤醒

    FSyncLock.Enter;
    try
      nInt := Length(FSQLItems);
      if nInt > 0 then
      begin
        nInt := 0;
        for nIdx:=Low(FSQLItems) to High(FSQLItems) do
        if FSQLItems[nIdx].FValid then
        begin
          Inc(nInt);
          Break;
        end;

        if nInt < 1 then
          SetLength(FSQLItems, 0);
        //clear sql array
      end;
    finally
      FSyncLock.Leave;
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

//Date: 2018-04-07
//Parm: 样本索引
//Desc: 加载样本数据
procedure TTruckManager.DoLoadWQSimple(const nIndex: Integer);
var nStr: string;
    nInt: Integer;
begin
  if FWQSimplesType = sFlag_Type_VMAS then
  with FWQSimplesVMAS[nIndex] do
  begin
    nInt := Length(FData);
    if nInt > 0 then Exit;

    FSQLQuery.Close;  
    if FDBConnWQ.Tag > 0 then
         FSQLQuery.Connection := FDBConnWQ
    else FSQLQuery.Connection := FDBConnDD; //切换链路

    nStr := 'select rhc,rco,co2,rno,o2fxy from %s ' +
            'where jylsh=''%s'' order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_VMas, FXH]);
    FSQLQuery.Open;

    if (not FSQLQuery.Active) or (FSQLQuery.RecordCount < 1) then Exit;
    //not valid
    
    with FSQLQuery do
    begin
      SetLength(FData, RecordCount);
      nInt := 0;
      First;

      while not Eof do
      with FData[nInt] do
      begin
        Word2Item(FCO2, Trunc(FieldByName('co2').AsFloat * 100));
        Word2Item(FCO,  Trunc(FieldByName('rco').AsFloat * 100));
        Word2Item(FHC,  Trunc(FieldByName('rhc').AsFloat));
        Word2Item(FNO,  Trunc(FieldByName('rno').AsFloat));
        Word2Item(FO2,  Trunc(FieldByName('o2fxy').AsFloat * 100));

        Inc(nInt);
        Next;
      end;
    end;
  end;

  //----------------------------------------------------------------------------
  if FWQSimplesType = sFlag_Type_SDS then
  with FWQSimplesSDS[nIndex] do
  begin
    nInt := Length(FData);
    if nInt > 0 then Exit;

    FSQLQuery.Close;  
    if FDBConnWQ.Tag > 0 then
         FSQLQuery.Connection := FDBConnWQ
    else FSQLQuery.Connection := FDBConnDD; //切换链路

    nStr := 'select hc,co,co2,o2 from %s ' +
            'where jylsh=''%s'' order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_SDS, FXH]);
    FSQLQuery.Open;

    if (not FSQLQuery.Active) or (FSQLQuery.RecordCount < 1) then Exit;
    //not valid
    
    with FSQLQuery do
    begin
      SetLength(FData, RecordCount);
      nInt := 0;
      First;

      while not Eof do
      with FData[nInt] do
      begin
        Word2Item(FCO2, Trunc(FieldByName('co2').AsFloat * 100));
        Word2Item(FCO,  Trunc(FieldByName('co').AsFloat * 100));
        Word2Item(FHC,  Trunc(FieldByName('hc').AsFloat));
        Word2Item(FNO,  10 + Random(15));
        Word2Item(FO2,  Trunc(FieldByName('o2').AsFloat * 100));

        Inc(nInt);
        Next;
      end;
    end;
  end;
end;

procedure TTruckManager.DoExecute;
var nStr: string;
    i,nIdx: Integer;
begin
  SetLength(FTempVIPTrucks, 0);
  FSQLQuery.Close;
  
  if FDBConnWQ.Tag > 0 then
       FSQLQuery.Connection := FDBConnWQ
  else FSQLQuery.Connection := FDBConnDD; //切换链路

  nStr := 'select t_truck,t_allow,t_simple,t_struck from %s ' +
          'where t_valid=0 order by id asc';
  FSQLQuery.SQL.Text := Format(nStr, [sTable_Truck]);
  FSQLQuery.Open;

  if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
  with FSQLQuery do
  begin
    SetLength(FTempVIPTrucks, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      with FTempVIPTrucks[nIdx] do
      begin
        FTruck  := Fields[0].AsString;
        if Fields[1].AsInteger = 0 then
             FType := vtBlack
        else FType := vtVIP;

        FSimple := Fields[2].AsString;
        FSTruck := Fields[3].AsString;
      end;

      Inc(nIdx);
      Next;
    end;
  end;

  FSyncLock.Enter;
  try
    nIdx := Length(FSQLItems);
    if nIdx > 0 then
    begin
      FSQLCmd.Close;
      FSQLCmd.Connection := FSQLQuery.Connection;
      //设置链路

      for nIdx:=Low(FSQLItems) to High(FSQLItems) do
      if FSQLItems[nIdx].FValid and (FSQLItems[nIdx].FType = stVIPSimple) then
      begin
        FSQLItems[nIdx].FValid := False;
        FSQLCmd.Close;
        FSQLCmd.SQL.Text := FSQLItems[nIdx].FSQL;
        FSQLCmd.Execute; //更新VIP车辆专用样本
      end;
    end;    
  finally
    FSyncLock.Leave;
  end;   

  //----------------------------------------------------------------------------
  if (Length(FWQSimplesVMAS) < 1) and (Length(FWQSimplesSDS) < 1) then
  begin
    nStr := 'select t_jcxh,t_truck,t_type,t_allow from %s ' +
            'where t_valid=0 order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_Simple]);
    FSQLQuery.Open;

    if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
    with FSQLQuery do
    begin
      First;

      while not Eof do
      begin
        nStr := Fields[2].AsString;
        if nStr = sFlag_Type_VMAS then //vmas样本
        begin
          nIdx := Length(FWQSimplesVMAS);
          SetLength(FWQSimplesVMAS, nIdx + 1);

          with FWQSimplesVMAS[nIdx] do
          begin
            FXH     := Fields[0].AsString;
            FTruck  := Fields[1].AsString;
            FType   := sFlag_Type_VMAS;
            FIsBlack := Fields[3].AsInteger = 0;

            FUsed := 0;
            SetLength(FData, 0);
          end;
        end else

        if nStr = sFlag_Type_SDS then //双怠速样本
        begin
          nIdx := Length(FWQSimplesSDS);
          SetLength(FWQSimplesSDS, nIdx + 1);

          with FWQSimplesSDS[nIdx] do
          begin
            FXH     := Fields[0].AsString;
            FTruck  := Fields[1].AsString;
            FType   := sFlag_Type_SDS;
            FIsBlack := Fields[3].AsInteger = 0;

            FUsed := 0;
            SetLength(FData, 0);
          end;
        end;

        Next;
      end;
    end;
  end;

  //----------------------------------------------------------------------------
  nIdx := 0;
  SetLength(FTempTrucks, 0);

  if FDBConnWQ.Tag > 0 then
  begin
    FSQLQuery.Close;
    FSQLQuery.Connection := FDBConnWQ; //切换链路

    nStr := 'select hphm,jcxdh,itemcode from %s order by id asc';
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
          FTruck := Trim(Fields[0].AsString);
          FLine := Fields[1].AsInteger;

          nStr := Trim(Fields[2].AsString);
          if CompareText(nStr, '00080000FF') = 0 then
            FCheckType := CTvmas else
          if CompareText(nStr, '00020000FF') = 0 then
            FCheckType := CTsds else
          if CompareText(nStr, '00400000FF') = 0 then
            FCheckType := CTlugdown else
          if CompareText(nStr, '00200000FF') = 0 then
            FCheckType := CTzyjs else FCheckType := CTUnknown;
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
    FVIPTrucks := FTempVIPTrucks;
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

//Date: 2018-09-19
//Parm: 车牌号
//Desc: 检索nTruck在vip列表中的索引
function TTruckManager.FindVIPTruck(const nTruck: string): Integer;
var nIdx: Integer;
begin
  Result := -1;
  if nTruck = '' then Exit;
  
  for nIdx:=Low(FVIPTrucks) to High(FVIPTrucks) do
  if CompareText(nTruck, FVIPTrucks[nIdx].FTruck) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2016-10-15
//Parm: 工位线号;业务类型;是否黑名单;尾气检测方式
//Desc: 检查nLine线的当前车辆是否在VIP车辆列表中
function TTruckManager.VIPTruckInLine(const nLine: Integer;
  const nType: TCOMType; var nTruck: string;
  const nInBlack: PBoolean; const nWQCheckType: PInteger): Boolean;
var i,nIdx: Integer;
begin
  if Assigned(nInBlack) then
    nInBlack^ := False;
  //init
  
  {$IFDEF DEBUG}
  Result := True;
  Exit;
  {$ELSE}
  Result := False;
  {$ENDIF}

  FSyncLock.Enter;
  try
    if (not (Assigned(FDBConnDD) and FDBConnDD.Connected)) and
       (not (Assigned(FDBConnWQ) and FDBConnWQ.Connected)) then
    begin
      Result := True;
      Exit;
    end;

    if (Time() >= gWNTimeStart) and (Time() <= gWNTimeEnd) then
    begin
      Result := FindVIPTruck(MakeVIPTruck) >= 0;
      if Result then Exit;
    end;
    
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    if FEnable and (FType = nType) and (FLine = nLine) then
    begin
      i := FindVIPTruck(FTruck);
      Result := i >= 0;

      if Result then
      begin
        nTruck := FTruck;
        //truck no
        
        if Assigned(nInBlack) then
          nInBlack^ := FVIPTrucks[i].FType = vtBlack;
        //xxxxx

        if Assigned(nWQCheckType) then
         nWQCheckType^ := Ord(FCheckType);
        //xxxxx
      end;

      Exit;
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2018-04-07
//Parm: 样本索引;类型
//Desc: 载入nIndex样本的数据
procedure TTruckManager.LoadWQSimpleData(const nIndex: Integer; const nType: string);
begin
  FSyncLock.Enter;
  try
    FWQSimplesType := nType;
    FWQSimplesIndex := nIndex;
    
    FWaiter.Wakeup(True);
    FWaiterWQSimple.EnterWait;
  finally
    FWQSimplesIndex := -1;
    FSyncLock.Leave;
  end;   
end;

//Date: 2018-04-07
//Parm: 样本车牌;vmas数据
//Desc: 填充样本数据到nData中
function TTruckManager.FillVMasSimple(const nLineNo: Integer; var nTruck: string;
 var nData: TWQDataList): Boolean;
var nSimple,nOnline: string;
    nIdx,nInt,nLen,nLoop: Integer;
    nIsVIP: Boolean;
begin
  Result := False;
  nLen := Length(FWQSimplesVMAS);

  if nLen < 1 then
  begin
    WriteLog('VMAS尾气样本数据为空.');
    Exit;
  end;

  FSyncLock.Enter;
  try
    nOnline := '';
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    if FEnable and (FType = ctWQ) and (FLine = nLineNo) then
    begin
      nOnline := FTruck; //当前线上车辆
      Break;
    end;

    nSimple := '';
    nIdx := FindVIPTruck(nOnline);
    nIsVIP := nIdx >= 0;

    if nIsVIP then
      nSimple := FVIPTrucks[nIdx].FSimple;
    //车辆指定样本

    if nSimple <> '' then
      WriteLog(Format('[ %d ]线车辆[ %s ]指定样本[ %s ].', [nLineNo, nOnline, nSimple]));
    //xxxxx
  finally
    FSyncLock.Leave;
  end;

  nInt := -1;
  if nSimple <> '' then
  begin
    for nIdx:=Low(FWQSimplesVMAS) to High(FWQSimplesVMAS) do
    if FWQSimplesVMAS[nIdx].FXH = nSimple then
    begin
      nInt := nIdx; //指定序号优先选中
      Break;
    end;
  end;
  
  if nInt < 0 then
  begin
    nLoop := 0;

    while True do
    begin
      Inc(nLoop);
      if nLoop > 1000 then
      begin
        WriteLog('无法选中有效的VMAS样本,VIP样本数量不足.');
        Exit;
      end;

      nInt := Random(nLen);
      if nInt >= nLen then Continue;
      if FWQSimplesVMAS[nInt].FIsBlack then Continue;

      for nIdx:=Low(FWQSimplesVMAS) to High(FWQSimplesVMAS) do
      if (not FWQSimplesVMAS[nIdx].FIsBlack) and
         (FWQSimplesVMAS[nInt].FUsed - FWQSimplesVMAS[nIdx].FUsed >= 2) then
      begin
        nInt := nIdx;
        Break; //样本均匀
      end;

      Break; //命中
    end;
  end;
  
  with FWQSimplesVMAS[nInt] do
  begin
    nLen := Length(FData);
    if nLen < 1 then
    begin
      LoadWQSimpleData(nInt, sFlag_Type_VMas);
      //载入数据
      nLen := Length(FData);
    end;

    if nLen < 1 then
    begin
      WriteLog(Format('加载车辆[ %s.%s ]错误,数据为空.', [FTruck, FXH]));
      Exit;
    end;

    Inc(FUsed);
    nTruck := FTruck; 
    SetLength(nData, nLen);

    for nIdx:=Low(FData) to High(FData) do
      nData[nIdx] := FData[nIdx];
    //数据合并

    if nIsVIP and (nSimple = '') then //VIP使用固定样本
    try
      FSyncLock.Enter;
      nIdx := Length(FSQLItems);
      SetLength(FSQLItems, nIdx+1);

      with FSQLItems[nIdx] do
      begin
        FSQL := 'update %s set t_simple=''%s'',t_struck=''%s'' where t_truck=''%s''';
        FSQL := Format(FSQL, [sTable_Truck, FXH, FTruck, nOnline]);

        FType := stVIPSimple;
        FValid := True;
      end;
    finally
      FSyncLock.Leave;
    end;
  end;

  Result := True;
  //done
end;

//Date: 2018-08-11
//Parm: 样本车牌;sds数据
//Desc: 填充样本数据到nData中
function TTruckManager.FillSDSSimple(const nLineNo: Integer; var nTruck: string;
  var nData: TWQDataList): Boolean;
var nSimple,nOnline: string;
    nIdx,nInt,nLen,nLoop: Integer;
    nIsVIP: Boolean;
begin
  Result := False;
  nLen := Length(FWQSimplesSDS);

  if nLen < 1 then
  begin
    WriteLog('SDS尾气样本数据为空.');
    Exit;
  end;

  FSyncLock.Enter;
  try
    nOnline := '';
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    if FEnable and (FType = ctWQ) and (FLine = nLineNo) then
    begin
      nOnline := FTruck; //当前线上车辆
      Break;
    end;

    nSimple := '';
    nIdx := FindVIPTruck(nOnline);
    nIsVIP := nIdx >= 0;

    if nIsVIP then
      nSimple := FVIPTrucks[nIdx].FSimple;
    //车辆指定样本

    if nSimple <> '' then
      WriteLog(Format('[ %d ]线车辆[ %s ]指定样本[ %s ].', [nLineNo, nOnline, nSimple]));
    //xxxxx
  finally
    FSyncLock.Leave;
  end;

  nInt := -1;
  if nSimple <> '' then
  begin
    for nIdx:=Low(FWQSimplesSDS) to High(FWQSimplesSDS) do
    if FWQSimplesSDS[nIdx].FXH = nSimple then
    begin
      nInt := nIdx; //指定序号优先选中
      Break;
    end;
  end;

  if nInt < 0 then
  begin
    nLoop := 0;

    while True do
    begin
      Inc(nLoop);
      if nLoop > 1000 then
      begin
        WriteLog('无法选中有效的SDS样本,VIP样本数量不足.');
        Exit;
      end;

      nInt := Random(nLen);
      if nInt >= nLen then Continue;
      if FWQSimplesSDS[nInt].FIsBlack then Continue;

      for nIdx:=Low(FWQSimplesSDS) to High(FWQSimplesSDS) do
      if (not FWQSimplesSDS[nIdx].FIsBlack) and
         (FWQSimplesSDS[nInt].FUsed - FWQSimplesSDS[nIdx].FUsed >= 2) then
      begin
        nInt := nIdx;
        Break; //样本均匀
      end;

      Break; //命中
    end;
  end;

  with FWQSimplesSDS[nInt] do
  begin
    nLen := Length(FData);
    if nLen < 1 then
    begin
      LoadWQSimpleData(nInt, sFlag_Type_SDS);
      //载入数据
      nLen := Length(FData);
    end;

    if nLen < 1 then
    begin
      WriteLog(Format('加载车辆[ %s.%s ]错误,数据为空.', [FTruck, FXH]));
      Exit;
    end;

    Inc(FUsed);
    nTruck := FTruck; 
    SetLength(nData, nLen);

    for nIdx:=Low(FData) to High(FData) do
      nData[nIdx] := FData[nIdx];
    //数据合并

    if nIsVIP and (nSimple = '') then //VIP使用固定样本
    try
      FSyncLock.Enter;
      nIdx := Length(FSQLItems);
      SetLength(FSQLItems, nIdx+1);

      with FSQLItems[nIdx] do
      begin
        FSQL := 'update %s set t_simple=''%s'',t_struck=''%s'' where t_truck=''%s''';
        FSQL := Format(FSQL, [sTable_Truck, FXH, FTruck, nOnline]);

        FType := stVIPSimple;
        FValid := True;
      end;
    finally
      FSyncLock.Leave;
    end;
  end;

  Result := True;
  //done
end;

end.
