{*******************************************************************************
  作者: dmzn@163.com 2016-10-14
  描述: 主单元
*******************************************************************************}
unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UDataModule, IniFiles, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, cxLabel,
  StdCtrls, cxButtons, dxLayoutControl, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, MemDS, DBAccess, Uni, cxNavigator, ExtCtrls,
  cxPC, dxStatusBar, cxGroupBox, cxMaskEdit, cxButtonEdit;

type
  TfFormClient = class(TForm)
    dxStatusBar1: TdxStatusBar;
    wPage: TcxPageControl;
    Sheet1: TcxTabSheet;
    Sheet2: TcxTabSheet;
    Sheet3: TcxTabSheet;
    HintPanel: TPanel;
    Image1: TImage;
    Image2: TImage;
    HintLabel: TLabel;
    UniQuery1: TUniQuery;
    cxGrid1: TcxGrid;
    cxView1: TcxGridDBTableView;
    cxLevel1: TcxGridLevel;
    DataSource1: TDataSource;
    UniQuery2: TUniQuery;
    DataSource2: TDataSource;
    cxGrid2: TcxGrid;
    cxView2: TcxGridDBTableView;
    cxLevel2: TcxGridLevel;
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    EditIP: TcxTextEdit;
    dxLayoutControl1Item1: TdxLayoutItem;
    EditPort: TcxTextEdit;
    dxLayoutControl1Item2: TdxLayoutItem;
    EditUser: TcxTextEdit;
    dxLayoutControl1Item3: TdxLayoutItem;
    EditPwd: TcxTextEdit;
    dxLayoutControl1Item4: TdxLayoutItem;
    EditDB: TcxTextEdit;
    dxLayoutControl1Item5: TdxLayoutItem;
    BtnSave: TcxButton;
    dxLayoutControl1Item6: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayoutControl1Item8: TdxLayoutItem;
    cxView1Column1: TcxGridDBColumn;
    cxView1Column2: TcxGridDBColumn;
    cxView1Column3: TcxGridDBColumn;
    cxView1Column4: TcxGridDBColumn;
    cxGroupBox1: TcxGroupBox;
    BtnRefresh: TcxButton;
    cxGroupBox2: TcxGroupBox;
    BtnAdd: TcxButton;
    BtnDel: TcxButton;
    BtnFreshVIP: TcxButton;
    cxView2Column1: TcxGridDBColumn;
    cxView2Column2: TcxGridDBColumn;
    cxView2Column3: TcxGridDBColumn;
    cxView2Column4: TcxGridDBColumn;
    BtnHasDel: TcxButton;
    cxLabel2: TcxLabel;
    EditFind: TcxButtonEdit;
    dxLayoutControl1Group2: TdxLayoutGroup;
    dxLayoutControl1Item7: TdxLayoutItem;
    EditPort2: TcxTextEdit;
    dxLayoutControl1Item9: TdxLayoutItem;
    EditIP2: TcxTextEdit;
    dxLayoutControl1Item10: TdxLayoutItem;
    EditDB2: TcxTextEdit;
    dxLayoutControl1Item11: TdxLayoutItem;
    EditUser2: TcxTextEdit;
    dxLayoutControl1Item12: TdxLayoutItem;
    EditPwd2: TcxTextEdit;
    dxLayoutControl1Item13: TdxLayoutItem;
    cxLabel3: TcxLabel;
    dxLayoutControl1Item14: TdxLayoutItem;
    BtnSave2: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure wPagePageChanging(Sender: TObject; NewPage: TcxTabSheet;
      var AllowChange: Boolean);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnFreshVIPClick(Sender: TObject);
    procedure BtnHasDelClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure EditFindPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditFindKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FUserPasswd: string;
    //用户密码
    FLoadValidTruck: Boolean;
    //载入标记
    procedure LoadFormConfig;
    procedure LoadDBConfig(const nRead: Boolean; const nIni: TIniFile = nil);
    //读取配置
    procedure RefreshTruckList;
    procedure RefreshVIPTruckList(nHasDel: Boolean = False; nWhere: string = '');
    //读取数据
    function GetVal(const nRow: Integer; const nField: string): string;
    //字段数据
  public
    { Public declarations }
  end;

var
  fFormClient: TfFormClient;

implementation

{$R *.dfm}

uses
  ULibFun, USysDB, USysLoger, UBase64, UcxChinese, USysGrid, USysMAC,
  UFormInputbox, UFormMemo;

//------------------------------------------------------------------------------
procedure TfFormClient.FormCreate(Sender: TObject);
var nStr: string;
begin
  Randomize;
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  wPage.ActivePage := Sheet2;

  LoadFormConfig;
  GetLocalIPConfig(gLocalName, nStr);
end;

procedure TfFormClient.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath+sConfig);
  try
    SaveFormConfig(Self, nIni);
    SaveUserDefineTableView(Name, cxView1, nIni);
    SaveUserDefineTableView(Name, cxView2, nIni);
  finally
    nIni.Free;
  end;
end;

procedure TfFormClient.LoadFormConfig;
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath+sConfig);
  try
    FUserPasswd := nIni.ReadString('Config', 'UserPassword', 'admin');
    //base config
    
    ULibFun.LoadFormConfig(Self, nIni);
    InitTableView(Name, cxView1, nIni);
    InitTableView(Name, cxView2, nIni);

    LoadDBConfig(True, nIni);
    RefreshTruckList;
    RefreshVIPTruckList;
  finally
    nIni.Free;
  end;
end;

procedure TfFormClient.RefreshTruckList;
var nStr: string;
begin
  nStr := 'Select id,car_num,car_xh,goline from %s ' +
          'Where car_num<>'''' Order By id';
  nStr := Format(nStr, [sTable_WQTruck]);

  UniQuery1.Close;
  UniQuery1.SQL.Text := nStr;
  UniQuery1.Open;
end;

procedure TfFormClient.RefreshVIPTruckList(nHasDel: Boolean; nWhere: string);
var nStr: string;
begin
  FLoadValidTruck := not nHasDel;
  nStr := 'Select * from %s Where t_valid=%d %s Order By id';

  if nWhere <> '' then
    nWhere := Format('And (%s)', [nWhere]);
  //xxxxx

  if nHasDel then
       nStr := Format(nStr, [sTable_Truck, 1, nWhere])
  else nStr := Format(nStr, [sTable_Truck, 0, nWhere]);

  UniQuery2.Close;
  UniQuery2.SQL.Text := nStr;
  UniQuery2.Open;
end;

procedure TfFormClient.LoadDBConfig(const nRead: Boolean; const nIni: TIniFile);
var nIF: TIniFile;
begin
  if Assigned(nIni) then
       nIF := nIni
  else nIF := TIniFile.Create(gPath+sConfig);

  with nIF do
  try
    if (ActiveControl = BtnSave2) or (ActiveControl <> BtnSave) then
    begin
      if nRead then
      begin
        EditIP2.Text := ReadString('DB2', 'Server', '');
        EditPort2.Text := IntToStr(ReadInteger('DB2', 'Port', 0));
        EditDB2.Text := ReadString('DB2', 'DBName', 'detect');
        EditUser2.Text := ReadString('DB2', 'User', '');
        EditPwd2.Text := DecodeBase64(ReadString('DB2', 'Password', ''));
      end else
      begin
        WriteString('DB2', 'Server', EditIP2.Text);
        WriteString('DB2', 'Port', EditPort2.Text);
        WriteString('DB2', 'DBName', EditDB2.Text);
        WriteString('DB2', 'User', EditUser2.Text);
        WriteString('DB2', 'Password', EncodeBase64(EditPwd2.Text));
      end;

      if ActiveControl = BtnSave2 then
        Exit;
      //xxxxx
    end;

    if nRead then
    begin
      EditIP.Text := ReadString('DB', 'Server', '');
      EditPort.Text := IntToStr(ReadInteger('DB', 'Port', 0));
      EditDB.Text := ReadString('DB', 'DBName', 'detect');
      EditUser.Text := ReadString('DB', 'User', '');
      EditPwd.Text := DecodeBase64(ReadString('DB', 'Password', ''));

      with FDM.DBConn1 do
      try
        Disconnect;
        ProviderName := 'MySQL';
        SpecificOptions.Values['Charset'] := 'gb2312';

        Server := EditIP.Text;
        Port := StrToInt(EditPort.Text);
        Database := EditDB.Text;

        Username := EditUser.Text;
        Password := EditPwd.Text;
        Connect;
      except
        on E:Exception do
        begin
          ShowDlg(E.Message, sHint);
        end;
      end;
    end else
    begin
      WriteString('DB', 'Server', EditIP.Text);
      WriteString('DB', 'Port', EditPort.Text);
      WriteString('DB', 'DBName', EditDB.Text);
      WriteString('DB', 'User', EditUser.Text);
      WriteString('DB', 'Password', EncodeBase64(EditPwd.Text));
    end;
  finally
    if not Assigned(nIni) then
      nIF.Free;
    //xxxxx
  end;   
end;

procedure TfFormClient.wPagePageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
var nStr: string;
begin
  if NewPage = Sheet3 then
  begin
    if ShowInputPWDBox('请输入管理员密码:', '', nStr) then
         AllowChange := nStr = FUserPasswd
    else AllowChange := False;
  end;
end;

procedure TfFormClient.BtnSaveClick(Sender: TObject);
begin
  BtnSave.Enabled := False;
  try
    LoadDBConfig(False);
    LoadDBConfig(True);
    ShowMsg('保存成功', sHint);
  finally
    BtnSave.Enabled := True;
  end;
end;

procedure TfFormClient.BtnRefreshClick(Sender: TObject);
begin
  RefreshTruckList;
end;

procedure TfFormClient.BtnFreshVIPClick(Sender: TObject);
begin
  RefreshVIPTruckList;
end;

procedure TfFormClient.BtnHasDelClick(Sender: TObject);
begin
  RefreshVIPTruckList(True);
end;

procedure TfFormClient.BtnAddClick(Sender: TObject);
begin
  if ShowMemoForm then RefreshVIPTruckList();
end;

//Desc: 获取nRow行nField字段的内容
function TfFormClient.GetVal(const nRow: Integer;
 const nField: string): string;
var nVal: Variant;
begin
  nVal := cxView2.DataController.GetValue(
            cxView2.Controller.SelectedRows[nRow].RecordIndex,
            cxView2.GetColumnByFieldName(nField).Index);
  //xxxxx

  if VarIsNull(nVal) then
       Result := ''
  else Result := nVal;
end;

procedure TfFormClient.BtnDelClick(Sender: TObject);
var nStr: string;
    nIdx,nLen: Integer;
begin
  if cxView2.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要删除的记录', sHint); Exit;
  end;

  if not QueryDlg('确定删除选中的记录吗?', '') then Exit;
  nLen := cxView2.DataController.GetSelectedCount - 1;
  
  for nIdx:=0 to nLen do
  begin
    if FLoadValidTruck then
    begin
      nStr := 'update %s set t_valid=1,t_user=''%s'',t_time=now() where id=%s';
      nStr := Format(nStr, [sTable_Truck, gLocalName, GetVal(nIdx, 'id')]);
    end else
    begin
      nStr := 'delete from %s where id=%s';
      nStr := Format(nStr, [sTable_Truck, GetVal(nIdx, 'id')]);
    end;

    FDM.ExecuteSQL(nStr);
  end;

  RefreshVIPTruckList(not FLoadValidTruck);
end;

procedure TfFormClient.EditFindPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nStr: string;
begin
  EditFind.Text := Trim(EditFind.Text);
  EditFind.SelStart := 0;
  EditFind.SelectAll;
  
  if EditFind.Text = '' then
  begin
    ShowMsg('请输入车牌号', sHint);
    Exit;
  end;

  nStr := 't_truck like ''%%%s%%''';
  nStr := Format(nStr, [EditFind.Text]);
  RefreshVIPTruckList(False, nStr);
end;

procedure TfFormClient.EditFindKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    EditFindPropertiesButtonClick(nil, 0);
  end;
end;

end.
