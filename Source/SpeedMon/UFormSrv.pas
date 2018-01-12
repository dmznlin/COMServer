{*******************************************************************************
  作者: dmzn@163.com 2018-01-11
  描述: 转速监控服务总开关 
*******************************************************************************}
unit UFormSrv;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  USysConst, ZnHideForm, ComCtrls, ExtCtrls, IdBaseComponent, IdComponent,
  IdUDPBase, IdUDPServer, IdGlobal, IdSocketHandle, ToolWin, ImgList;

type
  TfFormSrv = class(TForm)
    ZnHideForm1: TZnHideForm;
    UDPSrv1: TIdUDPServer;
    Timer1: TTimer;
    SBar1: TStatusBar;
    ListClient: TListView;
    ImageList1: TImageList;
    ToolBar1: TToolBar;
    BtnAdjust: TToolButton;
    BtnNoAdust: TToolButton;
    BtnRefresh: TToolButton;
    ToolButton4: TToolButton;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure UDPSrv1UDPRead(AThread: TIdUDPListenerThread;
      AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnAdjustClick(Sender: TObject);
  private
    { Private declarations }
    FBroadcastBase: Integer;
    FBroadcastIP: string;
    FBoradcastPort: Integer;
    //广播参数
    FFreshBase: Integer;
    //刷新参数
    procedure FormConfig(const nLoad: Boolean);
    //读写配置
    procedure AddSrvInfo(const nSrv: TStrings);
    procedure SendBroadcast;
    procedure SendAdjustCommand(const nClient: Integer; const nAdjust: Boolean);
    //发送数据
    procedure UpdateClientList(const nClient: TStrings);
    procedure FreshClientClient;
    //客户端列表
  public
    { Public declarations }
  end;

var
  fFormSrv: TfFormSrv;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UBase64, USysMAC;

procedure TfFormSrv.FormCreate(Sender: TObject);
begin
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sForm);

  gLocalMAC := MakeActionID_MAC;
  GetLocalIPConfig(gLocalName, gLocalIP);

  FFreshBase := cTimeOut_NoSrvSignal;
  FBroadcastBase := cSrvBroadcast_Interval;
  FormConfig(True);
end;

procedure TfFormSrv.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FormConfig(False);
end;

procedure LoadListViewColumn(const nWidths: string; const nLv: TListView);
var nList: TStrings;
    i,nCount: integer;
begin
  if nLv.Columns.Count > 0 then
  begin
    nList := TStringList.Create;
    try
      if SplitStr(nWidths, nList, nLv.Columns.Count, ';') then
      begin
        nCount := nList.Count - 1;
        for i:=0 to nCount do
         if IsNumber(nList[i], False) then
          nLv.Columns[i].Width := StrToInt(nList[i]);
      end;
    finally
      nList.Free;
    end;
  end;
end;

function MakeListViewColumnInfo(const nLv: TListView): string;
var i,nCount: integer;
begin
  Result := '';
  nCount := nLv.Columns.Count - 1;

  for i:=0 to nCount do
  if i = nCount then
       Result := Result + IntToStr(nLv.Columns[i].Width)
  else Result := Result + IntToStr(nLv.Columns[i].Width) + ';';
end;

procedure TfFormSrv.FormConfig(const nLoad: Boolean);
var nStr: string;
    nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sForm);
  try
    if nLoad then
    begin
      nStr := nIni.ReadString(Name, 'ListWidth', '');
      LoadListViewColumn(nStr, ListClient);
      LoadFormConfig(Self, nIni);
    end else
    begin
      nStr := MakeListViewColumnInfo(ListClient);
      nIni.WriteString(Name, 'ListWidth', nStr);
      SaveFormConfig(Self, nIni);
    end;
  finally
    nIni.Free;
  end;

  nIni := TIniFile.Create(gPath + sConfig);
  try
    if nLoad then
    begin
      FBroadcastIP := nIni.ReadString('Config', 'BroadcastIP', cSrvBroadcast_IP);
      FBoradcastPort := nIni.ReadInteger('Config', 'BroadcastPort', cSrvBroadcast_Port);

      UDPSrv1.DefaultPort := nIni.ReadInteger('Config', 'SrvPort', 8000);
      UDPSrv1.Active := True;
    end;
  finally
    nIni.Free;
  end;
end;

//------------------------------------------------------------------------------
procedure TfFormSrv.Timer1Timer(Sender: TObject);
begin
  SBar1.SimpleText := '※.' + DateTime2Str(Now()) + ' ' + Date2Week();
  //xxxxx

  Inc(FBroadcastBase);
  if FBroadcastBase >= cSrvBroadcast_Interval then
  begin
    FBroadcastBase := 0;
    SendBroadcast;
  end;

  Inc(FFreshBase);
  if FFreshBase >= cTimeOut_NoSrvSignal then
  begin
    FFreshBase := 0;
    FreshClientClient;
  end;
end;

//Desc: 添加服务器参数
procedure TfFormSrv.AddSrvInfo(const nSrv: TStrings);
begin
  with nSrv do
  begin
    Values[sSrvIP] := gLocalIP;
    Values[sSrvMAC] := gLocalMAC;
    Values[sSrvName] := gLocalName;
    Values[sSrvPort] := IntToStr(UDPSrv1.DefaultPort);
  end;
end;

//Desc: 广播
procedure TfFormSrv.SendBroadcast;
var nList: TStrings;
begin
  nList := nil;
  if UDPSrv1.Active then
  try
    nList := LockStringList(True);
    AddSrvInfo(nList);

    nList.Values[sSrvCommand] := sCMD_Broadcast;
    UDPSrv1.Send(FBroadcastIP, FBoradcastPort, EncodeBase64(nList.Text));
  finally
    ReleaseStringList(nList);
  end;
end;

procedure TfFormSrv.UDPSrv1UDPRead(AThread: TIdUDPListenerThread;
  AData: TIdBytes; ABinding: TIdSocketHandle);
var nStr: string;
    nList: TStrings;
begin
  try
    nList := LockStringList(False);
    try
      nList.Text := DecodeBase64(BytesToString(AData));
      if nList.Values[sClientMAC] = '' then Exit; //invalid

      UpdateClientList(nList);
      //update ui

      if nList.Values[sClientCommand] = sCMD_Respone then //need response
      begin
        AddSrvInfo(nList);
        nStr := EncodeBase64(nList.Text);
        UDPSrv1.Send(ABinding.PeerIP, ABinding.PeerPort, nStr);
      end;
    finally
      ReleaseStringList(nList);
    end;
  except
    //ignor any error
  end;
end;

//Date: 2018-01-12
//Parm: 客户端数据
//Desc: 更新客户端列表
procedure TfFormSrv.UpdateClientList(const nClient: TStrings);
var nStr: string;
    nIdx,nInt: Integer;
begin
  nInt := -1;
  nStr := nClient.Values[sClientMAC];

  for nIdx:=Low(gHosts) to High(gHosts) do
  if gHosts[nIdx].FMAC = nStr then
  begin
    nInt := nIdx;
    Break;
  end;

  if nInt < 0 then
  begin
    nInt := Length(gHosts);
    SetLength(gHosts, nInt + 1);

    with gHosts[nInt] do
    begin
      FMAC := nStr;
      FNodeSelected := False;
    end;
  end;

  with gHosts[nInt] do
  begin
    FName := nClient.Values[sClientName];
    FIP := nClient.Values[sClientIP];
    FStatus := nClient.Values[sClientStatus]; 
    FLast := GetTickCount;
  end;
end;

procedure TfFormSrv.FreshClientClient;
var nIdx: Integer;
    nInt: Int64;
begin
  ListClient.Items.BeginUpdate;
  try
    for nIdx:=ListClient.Items.Count-1 downto 0 do
    begin
      nInt := Integer(ListClient.Items[nIdx].Data);
      gHosts[nInt].FNodeSelected := ListClient.Items[nIdx].Selected;
    end;
    //备份选中状态

    ListClient.Clear;
    //init
    
    for nIdx:=Low(gHosts) to High(gHosts) do
    with ListClient.Items.Add,gHosts[nIdx] do
    begin
      Caption := FName;
      SubItems.Add(FIP);
      SubItems.Add(FMAC);

      Data := Pointer(nIdx);
      nInt := Trunc((GetTickCount - FLast) / 1000);
      SubItems.Add(IntToStr(nInt) + '秒');
      
      if (nInt < cTimeOut_NoSrvSignal) and (FStatus = sCMD_Adjust) then
           ImageIndex := 0
      else ImageIndex := 1;
      Selected := FNodeSelected;
    end;
  finally
    ListClient.Items.EndUpdate;
  end;   
end;

//Desc: 刷新列表
procedure TfFormSrv.BtnRefreshClick(Sender: TObject);
begin
  SendBroadcast;
  FreshClientClient;
end;

//Desc: 开启校正
procedure TfFormSrv.BtnAdjustClick(Sender: TObject);
var nIdx: Integer;
begin
  for nIdx:=ListClient.Items.Count-1 downto 0 do
  with ListClient.Items[nIdx] do
  begin
    if Selected then
      SendAdjustCommand(Integer(Data), TComponent(Sender).Tag = 10);
    //xxxxx
  end;

  FFreshBase := cTimeOut_NoSrvSignal - 1;
  //等待刷新
end;

//Desc: 发送校正命令
procedure TfFormSrv.SendAdjustCommand(const nClient: Integer;
  const nAdjust: Boolean);
var nStr: string;
    nList: TStrings;
begin
  nList := LockStringList(True);
  try
    AddSrvInfo(nList);
    nList.Values[sSrvCommand] := sClientStatus;
    //command

    if nAdjust then
         nList.Values[sClientStatus] := sCMD_Adjust
    else nList.Values[sClientStatus] := sCMD_NoAdjust;

    nStr := EncodeBase64(nList.Text);
    UDPSrv1.Send(gHosts[nClient].FIP, FBoradcastPort, nStr);
  finally
    ReleaseStringList(nList);
  end;
end;

end.
