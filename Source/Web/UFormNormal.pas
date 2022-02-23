{*******************************************************************************
  作者: dmzn@163.com 2020-01-17
  描述: 窗体基础类
*******************************************************************************}
unit UFormNormal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, uniGUITypes, uniGUIAbstractClasses,
  uniGUIClasses, uniGUImClasses, uniGUIForm, uniGUImForm, uniGUImJSForm,
  uniGUIBaseClasses, uniButton, unimButton;

type
  TfFormNormal= class(TUnimForm)
    procedure UnimFormTitleButtonClick(Sender: TUnimTitleButton);
  private
    { Private declarations }
  protected
    FEntityName: string;
    {*实体名称*}
  public
    { Public declarations }
  end;

implementation

uses
  uniGUIApplication;

{$R *.dfm}

procedure TfFormNormal.UnimFormTitleButtonClick(Sender: TUnimTitleButton);
begin
  Close();
end;

end.
