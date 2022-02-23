{*******************************************************************************
  ����: dmzn@163.com 2022-02-23
  ����: ϵͳȫ�ֿ���ģ��
*******************************************************************************}
unit ServerModule;

interface

uses
  Classes, SysUtils, uniGUIServer, uniGUITypes, UManagerGroup, ULibFun;

type
  TUniServerModule = class(TUniGUIServerModule)
    procedure UniGUIServerModuleBeforeInit(Sender: TObject);
    procedure UniGUIServerModuleBeforeShutdown(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure FirstInit; override;
  public
    { Public declarations }
  end;

function UniServerModule: TUniServerModule;

implementation

{$R *.dfm}

uses
  UniGUIVars, USysFun, USysBusiness;

function UniServerModule: TUniServerModule;
begin
  Result:=TUniServerModule(UniGUIServerInstance);
end;

procedure TUniServerModule.FirstInit;
begin
  InitServerModule(Self);
end;

procedure TUniServerModule.UniGUIServerModuleBeforeInit(Sender: TObject);
begin
  InitSystemEnvironment;
  //��ʼ��ϵͳ����
  LoadSysParameter();
  //����ϵͳ���ò���

  if not TApplicationHelper.IsValidConfigFile(TApplicationHelper.gSysConfig,
    gSysParam.FActive.FProgram) then
  begin
    raise Exception.Create(sInvalidConfig);
    //�����ļ����Ķ�
  end;

  Title := gSysParam.FActive.FTitleApp;
  //�������
  Port := gSysParam.FActive.FPort;
  //����˿�

  with gSysParam.FActive do
  begin
    Logger.AddLog('TUniServerModule', FExtRoot);

    if DirectoryExists(FExtRoot) then
      ExtRoot := FExtRoot;
    //xxxxx

    if DirectoryExists(FUniRoot) then
      UniMobileRoot := FUniRoot;
    //xxxxx
  end;

  AutoCoInitialize := True;
  //�Զ���ʼ��COM����
end;

procedure TUniServerModule.UniGUIServerModuleBeforeShutdown(Sender: TObject);
begin
  gMG.FObjectPool.RegistMe(False);
  //�رն����
end;

initialization
  RegisterServerModuleClass(TUniServerModule);
end.
