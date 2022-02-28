{*******************************************************************************
  作者: dmzn@163.com 2022-02-25
  描述: 修改密码
*******************************************************************************}
unit UFormNewPassword;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFormNormal, uniButton, unimButton,
  uniGUIClasses, uniEdit, unimEdit, uniGUIBaseClasses, uniGUImJSForm,
  System.Classes;

type
  TfFormNewPwd = class(TfFormNormal)
    PanelLogin: TUnimContainerPanel;
    PanelL: TUnimContainerPanel;
    PanelM: TUnimContainerPanel;
    EditOld: TUnimEdit;
    EditNew: TUnimEdit;
    BtnLogin: TUnimButton;
    PanelR: TUnimContainerPanel;
    procedure BtnLoginClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}
uses
  System.IniFiles, ULibFun, USysBusiness;

procedure TfFormNewPwd.BtnLoginClick(Sender: TObject);
var nStr: string;
    nIni: TIniFile;
begin
  if EditOld.Text <> gSysParam.FAdminKey then
  begin
    ShowMessageN('旧密码无效');
    Exit;
  end;

  EditNew.Text := Trim(EditNew.Text);
  if EditNew.Text = '' then
  begin
    ShowMessageN('新密码不能为空');
    Exit;
  end;

  nIni := nil;
  try
    with TEncodeHelper,TApplicationHelper do
    begin
      nStr := Encode_3DES(EditNew.Text, sDefaultKey);
      //encode

      nIni := TIniFile.Create(TApplicationHelper.gSysConfig);
      nIni.WriteString(sConfigMain, sVerifyIgnore + 'AdminKey', nStr);
    end;
  finally
    nIni.Free;
  end;

  gSysParam.FAdminKey := EditNew.Text;
  ShowMessageN('新密码已生效');
  Close();
end;

initialization
  RegisterClass(TfFormNewPwd);
end.
