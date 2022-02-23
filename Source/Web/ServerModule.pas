{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 系统全局控制模块
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
  //初始化系统环境
  LoadSysParameter();
  //载入系统配置参数

  if not TApplicationHelper.IsValidConfigFile(TApplicationHelper.gSysConfig,
    gSysParam.FActive.FProgram) then
  begin
    raise Exception.Create(sInvalidConfig);
    //配置文件被改动
  end;

  Title := gSysParam.FActive.FTitleApp;
  //程序标题
  Port := gSysParam.FActive.FPort;
  //服务端口

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
  //自动初始化COM对象
end;

procedure TUniServerModule.UniGUIServerModuleBeforeShutdown(Sender: TObject);
begin
  gMG.FObjectPool.RegistMe(False);
  //关闭对象池
end;

initialization
  RegisterServerModuleClass(TUniServerModule);
end.
