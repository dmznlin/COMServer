unit UFormSimple;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Menus, cxContainer, cxEdit, cxTextEdit, cxMemo,
  dxLayoutControl, StdCtrls, cxButtons, cxCheckBox, cxMaskEdit,
  cxDropDownEdit;

type
  TfFormSimle = class(TForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    BtnOK: TcxButton;
    dxLayoutControl1Item1: TdxLayoutItem;
    BtnExit: TcxButton;
    dxLayoutControl1Item2: TdxLayoutItem;
    dxLayoutControl1Group3: TdxLayoutGroup;
    EditTruck: TcxTextEdit;
    dxLayoutControl1Item3: TdxLayoutItem;
    EditXH: TcxTextEdit;
    dxLayoutControl1Item4: TdxLayoutItem;
    EditType: TcxComboBox;
    dxLayoutControl1Item5: TdxLayoutItem;
    Check1: TcxCheckBox;
    dxLayoutControl1Item6: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function ShowSimpleForm: Boolean;
//入口函数

implementation

{$R *.dfm}

uses
  ULibFun, USysDB, USysGrid, UFormCtrl;

function ShowSimpleForm: Boolean;
begin
  with TfFormSimle.Create(Application) do
  begin
    Result := ShowModal = mrOk;
    Free;
  end;
end;

procedure TfFormSimle.FormCreate(Sender: TObject);
begin
  EditType.ItemIndex := 0;
  LoadFormConfig(Self);
end;

procedure TfFormSimle.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveFormConfig(Self);
end;

procedure TfFormSimle.BtnOKClick(Sender: TObject);
var nStr: string;
begin
  if EditType.ItemIndex < 0 then
  begin
    ShowMsg('请选择类型', sHint);
    Exit;
  end;

  EditTruck.Text := Trim(EditTruck.Text);
  if EditTruck.Text = '' then
  begin
    ShowMsg('请填写车牌号', sHint);
    Exit;
  end;

  EditXH.Text := Trim(EditXH.Text);
  if EditXH.Text = '' then
  begin
    ShowMsg('请填写流水号', sHint);
    Exit;
  end;

  BtnOK.Enabled := False;
  try 
    nStr := MakeSQLByStr([
            SF('t_truck', EditTruck.Text),
            SF('t_jcxh', EditXH.Text),
            SF_IF([SF('t_type', sFlag_Type_VMas),
                   SF('t_type', sFlag_Type_SDS)], EditType.ItemIndex),
            //xxxxx

            SF_IF([SF('t_allow', 0, sfVal),
                   SF('t_allow', 1, sfVal)], Check1.Checked),
            //xxxxx

            SF('t_user', gLocalName),
            SF('t_time', 'now()', sfVal),
            SF('t_valid', 0, sfVal)
            ], sTable_Simple, '', True);
    FDM.ExecuteSQL(nStr);

    ModalResult := mrOk;
  finally
    BtnOK.Enabled := True;
  end;
end;

end.
