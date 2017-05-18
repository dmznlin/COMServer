unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TfFormMain = class(TForm)
    EditDate: TDateTimePicker;
    Label1: TLabel;
    BtnOK: TButton;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  ULibFun;

procedure TfFormMain.FormCreate(Sender: TObject);
begin
  EditDate.Date := Now() + 365;
end;

procedure TfFormMain.BtnOKClick(Sender: TObject);
var nStr: string;
begin
  nStr := ExtractFilePath(Application.ExeName) + 'Lock.ini';
  AddExpireDate(nStr, Date2Str(EditDate.Date), True);
  ShowMessage('�ѱ���: ' + nStr);
end;

end.
