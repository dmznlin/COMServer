{*******************************************************************************
  ����: dmzn@163.com 2022-02-23
  ����: �û�ȫ����ģ��
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
    //������
    FGridColumnAdjust: Boolean;
    //�������
    procedure DoDefaultAdjustEvent(Sender: TComponent; nEventName: string;
      nParams: TUniStrings);
    //Ĭ���¼�
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
  //Ĭ�������������п��˳��

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
//Parm: �¼�;����
//Desc: Ĭ��Adjust����
procedure TUniMainModule.DoDefaultAdjustEvent(Sender: TComponent;
  nEventName: string; nParams: TUniStrings);
begin
  if nEventName = sEvent_StrGridColumnResize then
    DoStringGridColumnResize(Sender, nParams);
  //�û������п�
end;

initialization
  RegisterMainModuleClass(TUniMainModule);
end.
