{*******************************************************************************
  ����: dmzn@163.com 2017-03-11
  ����: ͬ���������߳�����VIP�б�
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
    FEnable: Boolean;          //�Ƿ���Ч
    FType: TCOMType;           //ҵ������

    FTruck: string;            //���ƺ�
    FLine: Integer;            //�����
    FCheckType: TWQCheckType;  //β�����
  end;
  TTruckItems = array of TTruckItem;
  
  TTruckManager = class(TThread)
  private
    FDBConfig: string;
    //���ݿ�����
    FDBConnDD: TUniConnection;
    FDBConnWQ: TUniConnection;
    FSQLQuery: TUniQuery;
    FSQLCmd: TUniQuery;
    //���ݿ����
    FTrucks: TTruckItems;
    FVIPTrucks: TStrings;
    FTempTrucks: TTruckItems;
    FTempVIPTrucks: TStrings;
    //�����б�
    FWQSimplesType: string;
    FWQSimplesIndex: Integer;
    FWQSimplesVMAS: TWQSimpleItems;
    FWQSimplesSDS: TWQSimpleItems;
    //β������
    FWaiter: TWaitObject;
    FWaiterWQSimple: TWaitObject;
    //�ȴ�����
    FSyncLock: TCriticalSection;
    //ͬ������
  protected
    procedure Execute; override;
    procedure DoExecute;
    //ִ���߳�
    function MakeVIPTruck: string;
    function GetTruckItem(const nTruck: string): Integer;
    procedure DoLoadWQSimple(const nIndex: Integer);
    procedure LoadWQSimpleData(const nIndex: Integer; const nType: string);
  public
    constructor Create(const nFileName: string);
    destructor Destroy; override;
    //�����ͷ�
    procedure StopMe;
    //ֹͣͬ��
    function LoadDBConfig: Boolean;
    procedure LoadTruckToList(const nList: TStrings);
    //��ȡ����
    function VIPTruckInLine(const nLine: Integer; const nType: TCOMType;
      var nTruck: string; const nInBlack: PBoolean = nil;
      const nWQCheckType: PInteger = nil): Boolean;
    //��������
    function FillVMasSimple(var nTruck: string; var nData: TWQDataList): Boolean;
    //vmas����
    function FillSDSSimple(var nTruck: string; var nData: TWQDataList): Boolean;
    //vmas����
  end;

var
  gTruckManager: TTruckManager = nil;       //����ͬ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TTruckManager, 'VIP����ͬ��', nEvent);
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
  
  FTempVIPTrucks.Free;
  FVIPTrucks.Free;
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

//Desc: ����ͨ��VIP����
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
    nList.Add('���쳵��:');
    for nIdx:=Low(FTrucks) to High(FTrucks) do
    with FTrucks[nIdx] do
    begin
      if not FEnable then Continue;
      i := FVIPTrucks.IndexOf(FTruck);

      if i >= 0 then
      begin
        i := Integer(FVIPTrucks.Objects[i]);
        if i = 0 then
             nStr := '������'
        else nStr := 'VIP';
      end else nStr := '';

      if FCheckType = CTvmas then
        nCheck := 'VMAS' else
      if FCheckType = CTsds then
        nCheck := '˫����' else
      if FCheckType = CTlugdown then
        nCheck := '���ؼ���' else
      if FCheckType = CTzyjs then
        nCheck := '���ɼ���'
      else nCheck := 'δ֪';

      nStr := Format('|--- %2d.%-8s [%-4s %2d�� %-8s]', [nIdx+1, FTruck,
              nStr, FLine, nCheck]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + 'VIP����:');
    for nIdx:=0 to FVIPTrucks.Count-1 do
    begin
      i := Integer(FVIPTrucks.Objects[nIdx]);
      if i = 0 then
           nStr := '������'
      else nStr := 'VIP';

      nStr := Format('|--- %2d.%-8s [%-6s]', [nIdx+1, FVIPTrucks[nIdx], nStr]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + 'β������: VMAS');
    for nIdx:=Low(FWQSimplesVMAS) to High(FWQSimplesVMAS) do
    with FWQSimplesVMAS[nIdx] do
    begin
      nStr := Format('|--- %2d.%-8s %s', [nIdx+1, FTruck, FXH]);
      nList.Add(nStr);
    end;

    nList.Add(#13#10 + 'β������: ˫����');
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

//Desc: �������ݿ�����
function TTruckManager.LoadDBConfig: Boolean;
var nIni: TIniFile;

    //Date: 2017-02-20
    //Parm: ��·;���ýڵ�
    //Desc: ����nConn����
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
//Parm: ���ƺ�
//Desc: ����nTruck��������
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
var nIdx: Integer;
begin
  FDBConnDD := TUniConnection.Create(nil);
  FDBConnWQ := TUniConnection.Create(nil);
  FSQLQuery := TUniQuery.Create(nil);
  FSQLCmd := TUniQuery.Create(nil);

  FWaiter.EnterWait;
  //�ӳټ������ݿ�
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
    //����

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
    //����
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
//Parm: ��������
//Desc: ������������
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
    else FSQLQuery.Connection := FDBConnDD; //�л���·

    nStr := 'select csgk_hc,csgk_co,csgk_co2,csgk_no,csgkfxy_o2 from %s ' +
            'where jcsxh=''%s'' order by id asc';
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
        Word2Item(FCO2, Trunc(FieldByName('csgk_co2').AsFloat * 100));
        Word2Item(FCO,  Trunc(FieldByName('csgk_co').AsFloat * 100));
        Word2Item(FHC,  Trunc(FieldByName('csgk_hc').AsFloat));
        Word2Item(FNO,  Trunc(FieldByName('csgk_no').AsFloat));
        Word2Item(FO2,  Trunc(FieldByName('csgkfxy_o2').AsFloat * 100));

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
    else FSQLQuery.Connection := FDBConnDD; //�л���·

    nStr := 'select hc,co,co2,o2 from %s ' +
            'where jcbgbh=''%s'' order by id asc';
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
  FTempVIPTrucks.Clear;
  FSQLQuery.Close;
  
  if FDBConnWQ.Tag > 0 then
       FSQLQuery.Connection := FDBConnWQ
  else FSQLQuery.Connection := FDBConnDD; //�л���·

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

  if (Length(FWQSimplesVMAS) < 1) and (Length(FWQSimplesSDS) < 1) then
  begin
    nStr := 'select t_jcxh,t_truck,t_type from %s where t_valid=0 order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_Simple]);
    FSQLQuery.Open;

    if FSQLQuery.Active and (FSQLQuery.RecordCount > 0) then
    with FSQLQuery do
    begin
      First;

      while not Eof do
      begin
        nStr := Fields[2].AsString;
        if nStr = sFlag_Type_VMAS then //vmas����
        begin
          nIdx := Length(FWQSimplesVMAS);
          SetLength(FWQSimplesVMAS, nIdx + 1);

          with FWQSimplesVMAS[nIdx] do
          begin
            FXH     := Fields[0].AsString;
            FTruck  := Fields[1].AsString;
            FType   := sFlag_Type_VMAS;

            FUsed := 0;
            SetLength(FData, 0);
          end;
        end else

        if nStr = sFlag_Type_SDS then //˫��������
        begin
          nIdx := Length(FWQSimplesSDS);
          SetLength(FWQSimplesSDS, nIdx + 1);

          with FWQSimplesSDS[nIdx] do
          begin
            FXH     := Fields[0].AsString;
            FTruck  := Fields[1].AsString;
            FType   := sFlag_Type_SDS;

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
    FSQLQuery.Connection := FDBConnWQ; //�л���·

    nStr := 'select car_num,goline,car_item from %s order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_WQTruck]);
    FSQLQuery.Open; //β�����쳵��

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
    FSQLQuery.Connection := FDBConnDD; //�л���·

    nStr := 'select car_num,goline from %s where Gw_Three=1 order by id asc';
    FSQLQuery.SQL.Text := Format(nStr, [sTable_DDTruck]);
    FSQLQuery.Open; //��ƴ��쳵��

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
//Parm: ��λ�ߺ�;ҵ������;�Ƿ������;β����ⷽʽ
//Desc: ���nLine�ߵĵ�ǰ�����Ƿ���VIP�����б���
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

      if Result then
      begin
        nTruck := FTruck;
        //truck no
        
        if Assigned(nInBlack) then
          nInBlack^ := Integer(FVIPTrucks.Objects[i]) = 0;
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
//Parm: ��������;����
//Desc: ����nIndex����������
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
//Parm: ��������;vmas����
//Desc: ����������ݵ�nData��
function TTruckManager.FillVMasSimple(var nTruck: string;
 var nData: TWQDataList): Boolean;
var nIdx,nInt,nLen: Integer;
begin
  Result := False;
  nInt := -1;
  nLen := Length(FWQSimplesVMAS);

  if nLen < 1 then
  begin
    WriteLog('VMASβ����������Ϊ��.');
    Exit;
  end;

  while True do
  begin
    nInt := Random(nLen);
    if nInt >= nLen then Continue;

    for nIdx:=Low(FWQSimplesVMAS) to High(FWQSimplesVMAS) do
    if FWQSimplesVMAS[nInt].FUsed - FWQSimplesVMAS[nIdx].FUsed >= 2 then
    begin
      nInt := nIdx;
      Break; //��������
    end;

    Break; //����
  end;

  with FWQSimplesVMAS[nInt] do
  begin
    nLen := Length(FData);
    if nLen < 1 then
    begin
      LoadWQSimpleData(nInt, sFlag_Type_VMas);
      //��������
      nLen := Length(FData);
    end;

    if nLen < 1 then
    begin
      WriteLog(Format('���س���[ %s.%s ]����,����Ϊ��.', [FTruck, FXH]));
      Exit;
    end;

    Inc(FUsed);
    nTruck := FTruck; 
    SetLength(nData, nLen);

    for nIdx:=Low(FData) to High(FData) do
      nData[nIdx] := FData[nIdx];
    //���ݺϲ�
  end;

  Result := True;
  //done
end;

//Date: 2018-08-11
//Parm: ��������;sds����
//Desc: ����������ݵ�nData��
function TTruckManager.FillSDSSimple(var nTruck: string;
  var nData: TWQDataList): Boolean;
var nIdx,nInt,nLen: Integer;
begin
  Result := False;
  nInt := -1;
  nLen := Length(FWQSimplesSDS);

  if nLen < 1 then
  begin
    WriteLog('SDSβ����������Ϊ��.');
    Exit;
  end;

  while True do
  begin
    nInt := Random(nLen);
    if nInt >= nLen then Continue;

    for nIdx:=Low(FWQSimplesSDS) to High(FWQSimplesSDS) do
    if FWQSimplesSDS[nInt].FUsed - FWQSimplesSDS[nIdx].FUsed >= 2 then
    begin
      nInt := nIdx;
      Break; //��������
    end;

    Break; //����
  end;

  with FWQSimplesSDS[nInt] do
  begin
    nLen := Length(FData);
    if nLen < 1 then
    begin
      LoadWQSimpleData(nInt, sFlag_Type_SDS);
      //��������
      nLen := Length(FData);
    end;

    if nLen < 1 then
    begin
      WriteLog(Format('���س���[ %s.%s ]����,����Ϊ��.', [FTruck, FXH]));
      Exit;
    end;

    Inc(FUsed);
    nTruck := FTruck; 
    SetLength(nData, nLen);

    for nIdx:=Low(FData) to High(FData) do
      nData[nIdx] := FData[nIdx];
    //���ݺϲ�
  end;

  Result := True;
  //done
end;

end.
