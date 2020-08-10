unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Btn1: TButton;
    PBar1: TProgressBar;
    procedure Btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Btn1Click(Sender: TObject);
var nStr,nPre1,nPre2: string;
    nIdx,nPos: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    nList.LoadFromFile('D:\MyWork\QL_COMSrv\Temp\2020-08-04.log');
    Memo1.Clear;
    PBar1.Max := nList.Count;
    PBar1.Position := 0;

    for nIdx:=0 to nList.Count - 1 do
    begin
      PBar1.Position := nIdx + 1;
      Application.ProcessMessages;

      nStr := nList[nIdx];
      nPos := Pos('[ 02', nStr);
      if nPos < 1 then Continue;

      nStr := Copy(nStr, nPos, MaxInt);
      if (nStr = nPre1) or (nStr = nPre2) then Continue;

      nPre2 := nPre1;
      nPre1 := nStr;
      Memo1.Lines.Add(Copy(nList[nIdx], 1, Pos(#9, nList[nIdx])) + nStr);

      //if nIdx > 1000 then break;
    end;
  finally
    nList.Free;
  end;   
end;

end.
