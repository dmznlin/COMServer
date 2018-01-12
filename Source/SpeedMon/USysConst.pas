{*******************************************************************************
  作者: dmzn@163.com 2018-01-11
  描述: 常量定义
*******************************************************************************}
unit USysConst;

interface

uses
  Windows, Classes, SyncObjs;
  
const
  cTimeOut_NoSrvSignal       = 5;        //没有收到服务器信号,则超时(秒)
  cSrvBroadcast_Interval     = 10;       //服务器发送广播间隔
  cSrvBroadcast_IP           = '255.255.255.255';
  cSrvBroadcast_Port         = 8081;     //默认广播地址

type
  TStringListItem = record
    FList: TStrings;
    FUsed: Boolean;
  end;

  PHostItem = ^THostItem;
  THostItem = record
    FName: string;
    FIP: string;
    FPort: Integer;
    FMAC: string;
    
    FStatus: string;
    FLast: Int64;
    FNodeSelected: Boolean;   
  end;

function LockStringList(const nClear: Boolean): TStrings;
procedure ReleaseStringList(const nList: TStrings);
//列表缓存

var
  gPath: string;
  gHosts: array of THostItem;
  gLocalName,gLocalIP,gLocalMAC: string;
                     
  gSyncLock: TCriticalSection;
  gStringListItems: array of TStringListItem;
                                        
resourcestring
  sHint               = '提示';
  sConfig             = 'SpeedMon.Ini';
  sForm               = 'FormInfo.Ini';
  sDB                 = 'DBConn.Ini';
  sAutoStartKey       = 'SpeedMon';

  sSrvName            = 'SrvName';
  sSrvIP              = 'SrvIP';
  sSrvPort            = 'SrvPort';
  sSrvMAC             = 'SrvMAC';
  sSrvCommand         = 'SrvCommand';

  sClientName         = 'ClientName';
  sClientIP           = 'ClientIP';
  sClientMAC          = 'ClientMAC';
  sClientStatus       = 'ClientStatus';
  sClientCommand      = 'ClientCommand';

  sCMD_Respone        = 'Rsp';
  sCMD_Adjust         = 'Adj';
  sCMD_NoAdjust       = 'Ndj';
  sCMD_Broadcast      = 'Brd';

implementation

function LockStringList(const nClear: Boolean): TStrings;
var nIdx: Integer;
begin
  gSyncLock.Enter;
  try
    Result := nil;
    //init
    
    for nIdx:=Low(gStringListItems) to High(gStringListItems) do
     with gStringListItems[nIdx] do
      if not FUsed then
      begin
        Result := FList;
        FUsed := True;
        Break;
      end;
    //xxxxx

    if not Assigned(Result) then
    begin
      nIdx := Length(gStringListItems);
      SetLength(gStringListItems, nIdx+1);

      with gStringListItems[nIdx] do
      begin
        FList := TStringList.Create;
        FUsed := True;
        Result := FList;
      end;
    end;

    if nClear then
      Result.Clear;
    //xxxxx
  finally
    gSyncLock.Leave;
  end;
end;

procedure ReleaseStringList(const nList: TStrings);
var nIdx: Integer;
begin
  gSyncLock.Enter;
  try
    for nIdx:=Low(gStringListItems) to High(gStringListItems) do
     with gStringListItems[nIdx] do
      if FList = nList then
      begin
        FUsed := False;
        Exit;
      end;
  finally
    gSyncLock.Leave;
  end;   
end;

procedure ClearStringList;
var nIdx: Integer;
begin
  for nIdx:=Low(gStringListItems) to High(gStringListItems) do
    gStringListItems[nIdx].FList.Free;
  SetLength(gStringListItems, 0);
end;

initialization
  SetLength(gHosts, 0);
  SetLength(gStringListItems, 0);
  gSyncLock := TCriticalSection.Create;
finalization
  ClearStringList;
  gSyncLock.Free;
end.
