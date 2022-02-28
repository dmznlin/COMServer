{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 用户全局主模块
*******************************************************************************}
unit MainModule;

interface

uses
  uniGUIMainModule, SysUtils, Classes, Vcl.Graphics, Data.Win.ADODB, Data.DB,
  Datasnap.DBClient, System.Variants, uniGUIBaseClasses, uniGUIClasses,
  uniImageList, uniGUIForm, uniDBGrid, uniGUImForm, uniGUITypes, IdTCPClient,
  IdBaseComponent, IdComponent, IdTCPConnection;

type
  TUniMainModule = class(TUniGUIMainModule)
    ImageListSmall: TUniNativeImageList;
    ImageListBar: TUniNativeImageList;
    TCPClient1: TIdTCPClient;
    procedure UniGUIMainModuleCreate(Sender: TObject);
    procedure UniGUIMainModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FMainForm: TUnimForm;
    //主窗体
    FGridColumnAdjust: Boolean;
    //允许调整
    procedure DoDefaultAdjustEvent(Sender: TComponent; nEventName: string;
      nParams: TUniStrings);
    //默认事件
  end;

function UniMainModule: TUniMainModule;

implementation

{$R *.dfm}

uses
  UniGUIVars, ServerModule, uniGUIApplication, USysBusiness;

function UniMainModule: TUniMainModule;
begin
  Result := TUniMainModule(UniApplication.UniMainModule)
end;

procedure TUniMainModule.UniGUIMainModuleCreate(Sender: TObject);
var nStr: string;
    nIdx: Integer;
begin
  FGridColumnAdjust := True;
  //默认允许调整表格列宽和顺序

  nStr := gSysParam.FActive.GetParam('RemoteHost');
  nIdx := Pos(':', nStr);
  if nIdx > 1 then
  begin
    TCPClient1.Host := Copy(nStr, 1, nIdx - 1);
    System.Delete(nStr, 1, nIdx);
    TCPClient1.Port := StrToInt(nStr);
  end;
end;

procedure TUniMainModule.UniGUIMainModuleDestroy(Sender: TObject);
begin
  GlobalSyncLock;
  try

  finally
    GlobalSyncRelease;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2018-05-24
//Parm: 事件;参数
//Desc: 默认Adjust处理
procedure TUniMainModule.DoDefaultAdjustEvent(Sender: TComponent;
  nEventName: string; nParams: TUniStrings);
begin
  if nEventName = sEvent_StrGridColumnResize then
    DoStringGridColumnResize(Sender, nParams);
  //用户调整列宽
end;

initialization
  RegisterMainModuleClass(TUniMainModule);
end.
