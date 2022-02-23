{*******************************************************************************
  作者: dmzn@163.com 2022-02-23
  描述: 管理VIP车辆
*******************************************************************************}
unit UFormTruckVIP;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  UFormNormal, uniGUIBaseClasses, uniGUIClasses, uniGUImJSForm, uniDBGrid,
  unimDBGrid, Data.DB, kbmMemTable, unimMenu, uniBasicGrid, unimDBListGrid,
  uniButton, unimButton, uniEdit, unimEdit;

type
  TfFormTruckVIP = class(TfFormNormal)
    PanelMain: TUnimContainerPanel;
    DBGrid1: TUnimDBGrid;
    DataSource1: TDataSource;
    PanelBottom: TUnimContainerPanel;
    PanelTop: TUnimContainerPanel;
    EditTruck: TUnimEdit;
    BtnFind: TUnimButton;
    BtnDel: TUnimButton;
    BtnDelQuery: TUnimButton;
    BtnAdd: TUnimButton;
    MenuBottom: TUnimMenu;
    MTable1: TkbmMemTable;
    procedure UnimFormCreate(Sender: TObject);
    procedure UnimFormDestroy(Sender: TObject);
    procedure DBGrid1Click(Sender: TObject);
    procedure BtnFindClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnDelQueryClick(Sender: TObject);
    procedure EditTruckChange(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure MenuBottomClick(Sender: TUnimMenuItem);
  private
    { Private declarations }
    FLoadValidTruck: Boolean;
    //载入标记
    procedure LoadVIPTruckData(nHasDel: Boolean = False; nWhere: string = '');
    //载入车辆状态
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}
uses
  UManagerGroup, ULibFun, USysBusiness, USysDB;

procedure TfFormTruckVIP.UnimFormCreate(Sender: TObject);
begin
  FEntityName := 'MAIN_A01';
  UserDefineMGrid(ClassName, DBGrid1, True);
  LoadVIPTruckData;
end;

procedure TfFormTruckVIP.UnimFormDestroy(Sender: TObject);
begin
  UserDefineMGrid(ClassName, DBGrid1, False);
  if MTable1.Active then
    MTable1.Close;
  //清空数据集
end;

//Date: 2022-02-23
//Desc: 载入vip车辆列表
procedure TfFormTruckVIP.LoadVIPTruckData(nHasDel: Boolean; nWhere: string);
var nStr: string;
    nQuery: TDataSet;
begin
  nQuery := nil;
  with TStringHelper, gMG.FDBManager do
  try
    FLoadValidTruck := not nHasDel;
    nStr := 'Select case T_Valid when 0 then ''正常'' else ''删除'' end ' +
            'as T_Valid,id,T_Truck,T_User,T_Time,'' '' as Checked ' +
            'from %s Where t_valid=%d %s Order By id';

    if nWhere <> '' then
      nWhere := Format('And (%s)', [nWhere]);
    //xxxxx

    if nHasDel then
         nStr := Format(nStr, [sTable_Truck, 1, nWhere])
    else nStr := Format(nStr, [sTable_Truck, 0, nWhere]);

    nQuery := LockDBQuery();
    DBQuery(nStr, nQuery);

    MTable1.LoadFromDataSet(nQuery, [mtcpoStructure]);
    MTable1.FieldByName('Checked').ReadOnly := False;
    //转换数据集
    ActiveControl := DBGrid1;
  finally
    ReleaseDBQuery(nQuery);
  end;
end;

//Date: 2020-01-18
//Desc: 切换记录选中状态
procedure TfFormTruckVIP.DBGrid1Click(Sender: TObject);
begin
  if (not MTable1.Active) or (MTable1.RecordCount < 1) then Exit;
  MTable1.Edit;
  if MTable1.FieldByName('Checked').AsString = sCheckFlagYes then
       MTable1.FieldByName('Checked').AsString := ''
  else MTable1.FieldByName('Checked').AsString := sCheckFlagYes;
  MTable1.Post;
end;

procedure TfFormTruckVIP.MenuBottomClick(Sender: TUnimMenuItem);
var nBK: TBookmark;
begin
  if (not MTable1.Active) or (MTable1.RecordCount < 1) then Exit;
  //invalid data

  MTable1.DisableControls;
  nBK := MTable1.GetBookmark;
  try
    MTable1.First;
    while not MTable1.Eof do
    begin
      MTable1.Edit;
      case Sender.MenuId of
       0: MTable1.FieldByName('Checked').AsString := sCheckFlagYes;
       1: MTable1.FieldByName('Checked').AsString := '';
       2: //反选
        begin
          if MTable1.FieldByName('Checked').AsString = sCheckFlagYes then
               MTable1.FieldByName('Checked').AsString := ''
          else MTable1.FieldByName('Checked').AsString := sCheckFlagYes;
        end;
      end;

      MTable1.Post;
      MTable1.Next;
    end;

    if MTable1.BookmarkValid(nBK) then
      MTable1.GotoBookmark(nBK);
    //xxxxx
  finally
    MTable1.FreeBookmark(nBK);
    MTable1.EnableControls;
  end;

  MenuBottom.Visible := False;
  DBGrid1.Refresh;
end;

procedure TfFormTruckVIP.EditTruckChange(Sender: TObject);
begin
  if EditTruck.Text = '' then
       BtnFind.Caption := '刷新'
  else BtnFind.Caption := '查找';
end;

//Desc: 查找车牌
procedure TfFormTruckVIP.BtnFindClick(Sender: TObject);
var nStr: string;
begin
  EditTruck.Text := Trim(EditTruck.Text);
  if EditTruck.Text = '' then
  begin
    LoadVIPTruckData(False);
    Exit;
  end;

  nStr := 't_truck like ''%%%s%%''';
  nStr := Format(nStr, [EditTruck.Text]);
  LoadVIPTruckData(not FLoadValidTruck, nStr);
end;

//Desc: 删除
procedure TfFormTruckVIP.BtnDelClick(Sender: TObject);
var nStr,nID: string;
    nBK: TBookmark;
begin
   if (not MTable1.Active) or (MTable1.RecordCount < 1) then Exit;
  //invalid data

  MTable1.DisableControls;
  nBK := MTable1.GetBookmark;
  try
    nID := '';
    MTable1.First;

    while not MTable1.Eof do
    begin
      if MTable1.FieldByName('Checked').AsString = sCheckFlagYes then
      begin
        if nID = '' then
             nID := MTable1.FieldByName('id').AsString
        else nID := nID + ',' + MTable1.FieldByName('id').AsString;
      end;

      MTable1.Next;
    end;

    if MTable1.BookmarkValid(nBK) then
      MTable1.GotoBookmark(nBK);
    //xxxxx
  finally
    MTable1.FreeBookmark(nBK);
    MTable1.EnableControls;
  end;

  if nID = '' then
  begin
    ShowMessageN('请选择要删除的记录');
    Exit;
  end;

  MessageDlg('确定删除选中的记录吗?', mtConfirmation, mbYesNo,
    procedure(Sender: TComponent; Res: Integer)
    begin
      if Res = mrYes then
      begin
        if FLoadValidTruck then
        begin
          nStr := 'update %s set t_valid=1,t_user=''%s'',t_time=now() where id in (%s)';
          nStr := Format(nStr, [sTable_Truck, sDefaultUser, nID]);
        end else
        begin
          nStr := 'delete from %s where id in (%s)';
          nStr := Format(nStr, [sTable_Truck, nID]);
        end;

        gMG.FDBManager.DBExecute(nStr);
        LoadVIPTruckData(not FLoadValidTruck);
      end;
    end);
  //xxxxx
end;

//Desc: 查询删除
procedure TfFormTruckVIP.BtnDelQueryClick(Sender: TObject);
begin
  LoadVIPTruckData(True);
end;

//Desc: 添加车辆
procedure TfFormTruckVIP.BtnAddClick(Sender: TObject);
begin
//
end;

initialization
  RegisterClass(TfFormTruckVIP);
end.
