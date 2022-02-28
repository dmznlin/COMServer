{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 主窗体,负责调取其它模块
*******************************************************************************}
unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, uniGUITypes, uniGUIAbstractClasses, uniGUIClasses,
  uniGUImClasses, uniGUIRegClasses, uniGUIForm, uniGUImForm, uniGUImJSForm,
  uniGUIBaseClasses, Vcl.Menus, uniMainMenu, uniTreeView, unimNestedList;

type
  TfFormMain = class(TUnimForm)
    MenuMain: TUniMenuItems;
    PanelMain: TUnimContainerPanel;
    Menu1: TUnimNestedList;
    MenuVIP1: TUniMenuItem;
    MenuPwd: TUniMenuItem;
    N1: TUniMenuItem;
    MenuAdjustCtrl: TUniMenuItem;
    procedure MenuVIP1Click(Sender: TObject);
    procedure MenuPwdClick(Sender: TObject);
    procedure MenuAdjustCtrlClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  uniGUIVars, MainModule, USysDB, USysBusiness;

function fFormMain: TfFormMain;
begin
  Result := TfFormMain(UniMainModule.GetFormInstance(TfFormMain));
end;

procedure TfFormMain.MenuAdjustCtrlClick(Sender: TObject);
var nForm: TUnimForm;
begin
  nForm := SystemGetForm('TfFormAdjustControl');
  nForm.ShowModal();
end;

procedure TfFormMain.MenuPwdClick(Sender: TObject);
var nForm: TUnimForm;
begin
  nForm := SystemGetForm('TfFormNewPwd');
  nForm.ShowModal();
end;

procedure TfFormMain.MenuVIP1Click(Sender: TObject);
var nForm: TUnimForm;
begin
  nForm := SystemGetForm('TfFormTruckVIP');
  nForm.ShowModal();
end;

initialization
  RegisterAppFormClass(TfFormMain);

end.
