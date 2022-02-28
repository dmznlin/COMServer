{*******************************************************************************
  ����: dmzn@163.com 2022-02-25
  ����: ��ӳ���
*******************************************************************************}
unit UFormAddTruck;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UFormNormal, uniButton, unimButton,
  uniGUIClasses, uniEdit, unimEdit, uniGUIBaseClasses, uniGUImJSForm,
  System.Classes, uniPanel, uniMemo, unimPanel, unimMemo, uniCheckBox,
  unimCheckBox;

type
  TfFormAddTruck = class(TfFormNormal)
    EditTrucks: TUnimMemo;
    PanelTool: TUnimContainerPanel;
    PanelR: TUnimContainerPanel;
    PanelC: TUnimContainerPanel;
    PanelL: TUnimContainerPanel;
    Check1: TUnimCheckBox;
    BtnSave: TUnimButton;
    procedure BtnSaveClick(Sender: TObject);
    procedure UnimFormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure GetValidTrucks(const nTrucks, nList: TStrings);
    //��ȡnTrucks�е���Ч����
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}
uses
  System.IniFiles, UManagerGroup, ULibFun, USysBusiness, USysDB;

procedure TfFormAddTruck.UnimFormCreate(Sender: TObject);
begin
  ActiveControl := EditTrucks;
end;

//Date: 2021-05-14
//Parm: ��������
//Desc: ��nText�м�������Ч�ĳ���,����nList��
procedure TfFormAddTruck.GetValidTrucks(const nTrucks, nList: TStrings);
var nNick: WideString;
    nIdx: Integer;
begin
  nList.Clear;
  nNick := nTrucks.Text;
  nIdx := Pos(':', nNick);

  if nIdx > 1 then
  begin
    nNick := Copy(nNick, 1, nIdx);
    nList.Text := StringReplace(nTrucks.Text, nNick, #13#10, [rfReplaceAll]);
    //xxxxx
  end else
  begin
    nList.AddStrings(nTrucks);
    //ÿ��һ����
  end;

  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nList[nIdx] := Trim(nList[nIdx]);
    if (nList[nIdx] = '') or (Pos(':', nList[nIdx]) > 0) then
      nList.Delete(nIdx);
    //�������
  end;
end;

procedure TfFormAddTruck.BtnSaveClick(Sender: TObject);
var nStr: string;
    nIdx,nAllow: Integer;
    nTrucks,nList: TStrings;
begin
  EditTrucks.Text := Trim(EditTrucks.Text);
  if EditTrucks.Lines.Count < 1 then
  begin
    ShowMessageN('����д���ƺ�');
    Exit;
  end;

  nList := nil;
  nTrucks := nil;
  EditTrucks.Lines.BeginUpdate;
  try
    nTrucks := gMG.FObjectPool.Lock(TStrings) as TStrings;
    GetValidTrucks(EditTrucks.Lines, nTrucks);

    if nTrucks.Count < 1 then
    begin
      ShowMessageN('�����б���Ч');
      Exit;
    end;

    if Check1.Checked then
         nAllow := 0
    else nAllow := 1;

    nList := gMG.FObjectPool.Lock(TStrings) as TStrings;
    with TSQLBuilder do
    for nIdx:=0 to nTrucks.Count - 1 do
    begin
      nStr := MakeSQLByStr([
              SF('t_truck', nTrucks[nIdx]),
              SF('t_user', sDefaultUser),
              SF('t_time', 'now()', sfVal),
              SF('t_valid', 0, sfVal),
              SF('t_allow', nAllow, sfVal)
              ], sTable_Truck, '', True);
      nList.Add(nStr);
    end;

    gMG.FDBManager.DBExecute(nList);
    //write db
  finally
    EditTrucks.Lines.EndUpdate;
    gMG.FObjectPool.Release(nList);
    gMG.FObjectPool.Release(nTrucks);
  end;

  ModalResult := mrOk;
end;

initialization
  RegisterClass(TfFormAddTruck);
end.
