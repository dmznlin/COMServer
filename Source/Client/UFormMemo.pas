unit UFormMemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Menus, cxContainer, cxEdit, cxTextEdit, cxMemo,
  dxLayoutControl, StdCtrls, cxButtons;

type
  TfFormMemo = class(TForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    BtnOK: TcxButton;
    dxLayoutControl1Item1: TdxLayoutItem;
    BtnExit: TcxButton;
    dxLayoutControl1Item2: TdxLayoutItem;
    dxLayoutControl1Group2: TdxLayoutGroup;
    EditTrucks: TcxMemo;
    dxLayoutControl1Item3: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FTrucks: TStrings;
    procedure GetValidTrucks;
  public
    { Public declarations }
  end;

var
  gLocalName: string = '';

function ShowMemoForm: Boolean;
//��ں���

implementation

{$R *.dfm}

uses
  ULibFun, USysDB, USysGrid, UFormCtrl;

function ShowMemoForm: Boolean;
begin
  with TfFormMemo.Create(Application) do
  begin
    Result := ShowModal = mrOk;
    Free;
  end;
end;

procedure TfFormMemo.FormCreate(Sender: TObject);
begin
  FTrucks := TSTringList.Create;
  LoadFormConfig(Self);
end;

procedure TfFormMemo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveFormConfig(Self);
  FTrucks.Free;
end;

procedure TfFormMemo.GetValidTrucks;
var nNick: WideString;
    nIdx: Integer;
begin
  FTrucks.Clear;
  nNick := EditTrucks.Text;
  nIdx := Pos(':', nNick);

  if nIdx > 1 then
  begin
    nNick := Copy(nNick, 1, nIdx);
    FTrucks.Text := StringReplace(EditTrucks.Text, nNick, #13#10,
                    [rfReplaceAll]);
    //xxxxx 
  end else
  begin
    FTrucks.AddStrings(EditTrucks.Lines);
    //ÿ��һ����
  end;

  for nIdx:=FTrucks.Count - 1 downto 0 do
  begin
    FTrucks[nIdx] := Trim(FTrucks[nIdx]);
    if FTrucks[nIdx] = '' then
      FTrucks.Delete(nIdx);
    //��������
  end;
end;

procedure TfFormMemo.BtnOKClick(Sender: TObject);
var nStr: string;
    nIdx: Integer;
begin
  EditTrucks.Text := Trim(EditTrucks.Text);
  if EditTrucks.Lines.Count < 1 then
  begin
    ShowMsg('����д���ƺ�', sHint);
    Exit;
  end;

  EditTrucks.Lines.BeginUpdate;
  try
    BtnOK.Enabled := False;
    GetValidTrucks;
    
    if FTrucks.Count < 1 then
    begin
      ShowMsg('�����б���Ч', sHint);
      Exit;
    end;

    for nIdx:=0 to FTrucks.Count - 1 do
    begin
      nStr := MakeSQLByStr([
              SF('t_truck', FTrucks[nIdx]),
              SF('t_user', gLocalName),
              SF('t_time', 'now()', sfVal),
              SF('t_valid', 0, sfVal)
              ], sTable_Truck, '', True);
      FDM.ExecuteSQL(nStr);
    end;

    ModalResult := mrOk;
  finally
    EditTrucks.Lines.EndUpdate;
    BtnOK.Enabled := True;
  end;
end;

end.