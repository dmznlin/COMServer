unit UFormMemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UCommonConst, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Menus, cxContainer, cxEdit, cxTextEdit, cxMemo,
  dxLayoutControl, StdCtrls, cxButtons, cxCheckBox, cxMaskEdit,
  cxDropDownEdit, cxGraphics;

type
  TfFormMemo = class(TForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    BtnOK: TcxButton;
    dxLayoutControl1Item1: TdxLayoutItem;
    BtnExit: TcxButton;
    dxLayoutControl1Item2: TdxLayoutItem;
    EditTrucks: TcxMemo;
    dxLayoutControl1Item3: TdxLayoutItem;
    Check1: TcxCheckBox;
    dxLayoutControl1Item4: TdxLayoutItem;
    dxLayoutControl1Group3: TdxLayoutGroup;
    EditSimple: TcxComboBox;
    dxLayoutControl1Item5: TdxLayoutItem;
    EditType: TcxComboBox;
    dxLayoutControl1Item6: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditTypePropertiesEditValueChanged(Sender: TObject);
    procedure EditSimpleKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    FTrucks: TStrings;
    procedure LoadSimples(const nType: TWQCheckType; const nTruck: string='');
    procedure GetValidTrucks;
  public
    { Public declarations }
  end;

function ShowMemoForm: Boolean;
//入口函数

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

procedure TfFormMemo.LoadSimples(const nType: TWQCheckType;const nTruck: string);
var nStr: string;
begin
  EditSimple.Properties.Items.BeginUpdate;
  try
    EditSimple.Properties.Items.Clear;
    EditSimple.Properties.Items.Add('');
    EditSimple.Text := '';
    if nType = CTUnknown then Exit;

    nStr := 'Select t_truck,t_jcxh from %s where t_type=''%s''';
    if nType = CTsds then
         nStr := Format(nStr, [sTable_Simple, sFlag_Type_SDS])
    else nStr := Format(nStr, [sTable_Simple, sFlag_Type_VMas]);

    if nTruck <> '' then
      nStr := nStr + Format(' and t_truck like ''%%%s%%''', [nTruck]);
    //xxxxx

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      First;
      while not Eof do
      begin
        nStr := Fields[1].AsString + '.' + Fields[0].AsString;
        EditSimple.Properties.Items.Add(nStr);
        Next;
      end;
    end;
  finally
    EditSimple.Properties.Items.EndUpdate;
  end;
end;

procedure TfFormMemo.EditTypePropertiesEditValueChanged(Sender: TObject);
begin
  case EditType.ItemIndex of
   0: LoadSimples(CTvmas);
   1: LoadSimples(CTsds) else LoadSimples(CTUnknown);
  end;
end;

procedure TfFormMemo.EditSimpleKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
  begin
    Key := 0;

    case EditType.ItemIndex of
     0: LoadSimples(CTvmas, EditSimple.Text);
     1: LoadSimples(CTsds, EditSimple.Text);
    end;
  end;
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
    //每行一车牌
  end;

  for nIdx:=FTrucks.Count - 1 downto 0 do
  begin
    FTrucks[nIdx] := Trim(FTrucks[nIdx]);
    if (FTrucks[nIdx] = '') or (Pos(':', FTrucks[nIdx]) > 0) then
      FTrucks.Delete(nIdx);
    //清理空行
  end;
end;

procedure TfFormMemo.BtnOKClick(Sender: TObject);
var nStr,nSimple,nTruck: string;
    nIdx,nAllow: Integer;
begin
  EditTrucks.Text := Trim(EditTrucks.Text);
  if EditTrucks.Lines.Count < 1 then
  begin
    ShowMsg('请填写车牌号', sHint);
    Exit;
  end;

  EditTrucks.Lines.BeginUpdate;
  try
    BtnOK.Enabled := False;
    GetValidTrucks;
    
    if FTrucks.Count < 1 then
    begin
      ShowMsg('车牌列表无效', sHint);
      Exit;
    end;

    if Check1.Checked then
         nAllow := 0
    else nAllow := 1;

    nTruck := Trim(EditSimple.Text);
    nIdx := Pos('.', nTruck);
    //id.truck
    
    if (nIdx > 1) and (EditSimple.ItemIndex >= 0) then
    begin
      nSimple := Copy(nTruck, 1, nIdx - 1);
      System.Delete(nTruck, 1, nIdx);
    end else
    begin
      nSimple := '';
      nTruck := '';
    end;

    for nIdx:=0 to FTrucks.Count - 1 do
    begin
      nStr := MakeSQLByStr([
              SF_IF([SF('t_simple', 'null', sfVal), SF('t_simple', nSimple)], nSimple = ''),
              SF_IF([SF('t_struck', 'null', sfVal), SF('t_struck', nTruck)], nTruck = ''),

              SF('t_truck', FTrucks[nIdx]),
              SF('t_user', gLocalName),
              SF('t_time', 'now()', sfVal),
              SF('t_valid', 0, sfVal),
              SF('t_allow', nAllow, sfVal)
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
