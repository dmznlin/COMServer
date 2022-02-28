{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 用户登录
*******************************************************************************}
unit UFormLogin;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, uniGUITypes, uniGUIAbstractClasses, uniGUIClasses, uniLabel,
  uniGUIForm, uniGUImForm, uniGUImJSForm, unimLabel, uniButton, unimButton,
  unimToggle, uniEdit, unimEdit, uniImage, unimImage, uniGUIBaseClasses;

type
  TfFormLogin = class(TUnimLoginForm)
    PanelMain: TUnimContainerPanel;
    PanelLogin: TUnimContainerPanel;
    PanelR: TUnimContainerPanel;
    PanelL: TUnimContainerPanel;
    PanelM: TUnimContainerPanel;
    EditUser: TUnimEdit;
    EditPwd: TUnimEdit;
    BtnLogin: TUnimButton;
    CheckPassword: TUnimToggle;
    ImageLogo: TUnimImage;
    UnimLabel1: TUnimLabel;
    procedure BtnLoginClick(Sender: TObject);
    procedure UnimLoginFormCreate(Sender: TObject);
    procedure UnimLoginFormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure UpdateCookies(const nClear: Boolean);
    //更新cookies
  public
    { Public declarations }
  end;

function fFormLogin: TfFormLogin;

implementation

{$R *.dfm}

uses
  uniGUIVars, MainModule, uniGUIApplication, ULibFun, USysBusiness;

function fFormLogin: TfFormLogin;
begin
  Result := TfFormLogin(UniMainModule.GetFormInstance(TfFormLogin));
end;

procedure TfFormLogin.UnimLoginFormCreate(Sender: TObject);
var nStr: string;
begin
  with UniApplication.Cookies do
  begin
    nStr := Trim(GetCookie('UserName'));
    CheckPassword.Toggled := nStr <> '';

    if CheckPassword.Toggled then
    begin
      CheckPassword.Tag := 10;
      EditUser.Text := nStr;
      EditPwd.Text := GetCookie('UserPassword');
    end;
  end;
end;

procedure TfFormLogin.UnimLoginFormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if (not CheckPassword.Toggled) and (CheckPassword.Tag = 10) then
    UpdateCookies(True);
  //xxxxx
end;

//Desc: 登录
procedure TfFormLogin.BtnLoginClick(Sender: TObject);
begin
  if (EditUser.Text <> sDefaultUser) or
     (EditPwd.Text <> gSysParam.FAdminKey) then
  begin
    ShowMessageN('用户名或密码错误');
    Exit;
  end;

  UpdateCookies(not CheckPassword.Toggled);
  ModalResult := mrOk;
end;

procedure TfFormLogin.UpdateCookies(const nClear: Boolean);
begin
  with UniApplication.Cookies do
  begin
    if nClear then
    begin
      SetCookie('UserName', '');
      SetCookie('UserPassword', '');
    end else
    begin
      SetCookie('UserName', EditUser.Text, Date() + 1);
      SetCookie('UserPassword', EditPwd.Text, Date() + 1);
    end;
  end;
end;

initialization
  RegisterAppFormClass(TfFormLogin);

end.
